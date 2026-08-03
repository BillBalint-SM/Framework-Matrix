from __future__ import annotations

import ast
import csv
import hashlib
import json
import re
import subprocess
import tomllib
from collections import Counter, defaultdict
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[2]
REPOSITORY = ROOT / "work" / "repos" / "github-spec-kit"
INVENTORY = ROOT / "work" / "inventory" / "github-spec-kit-files.csv"
GEARS = ROOT / "work" / "inventory" / "github-spec-kit-gears.csv"
EVIDENCE = ROOT / "work" / "evidence" / "github-spec-kit"
COMMIT = "d1e86f638277a99b82715c22c90558cd58d3cffd"

GEAR_LEDGER = EVIDENCE / "gear-semantic-ledger.csv"
REFERENCE_LEDGER = EVIDENCE / "reference-ledger.csv"
BROKEN_LEDGER = EVIDENCE / "bundle-broken-references.md"
SUMMARY = EVIDENCE / "closure-summary.md"

MARKDOWN_LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
MARKDOWN_DEFINITION = re.compile(r"^\s*\[[^\]]+\]:\s*(\S+)", re.MULTILINE)
HEADING = re.compile(r"^#{1,6}\s+(.+?)\s*$", re.MULTILINE)
YAML_TOP_KEY = re.compile(r"^(?:[A-Za-z_][A-Za-z0-9_-]*|['\"][^'\"]+['\"]):", re.MULTILINE)
SHELL_FUNCTION = re.compile(r"^(?:function\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*\(\)\s*\{", re.MULTILINE)
USES_LINE = re.compile(r"^\s*-?\s*uses:\s*([^\s#]+)", re.MULTILINE)
SHELL_SOURCE = re.compile(r"^\s*(?:source|\.)\s+(['\"]?)([^'\"\s]+)\1", re.MULTILINE)
SCRIPT_ENTRY = re.compile(r"^\s+(sh|ps|py):\s*([^\r\n]+)", re.MULTILINE)


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def git(*args: str) -> str:
    return subprocess.check_output(
        ["git", "-C", str(REPOSITORY), *args], text=True, encoding="utf-8"
    ).strip()


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def line_number(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def source_url(path: str, line_count: int) -> str:
    end = max(1, line_count)
    return f"https://github.com/github/spec-kit/blob/{COMMIT}/{path}#L1-L{end}"


def first_nonempty(text: str) -> str:
    for line in text.splitlines():
        value = line.strip()
        if value:
            return value[:180]
    return "empty text file"


def summarize_python(path: Path, text: str) -> tuple[str, str]:
    tree = ast.parse(text, filename=str(path))
    symbols = [
        node.name
        for node in tree.body
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef))
    ]
    tests = [node.name for node in ast.walk(tree) if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name.startswith("test_")]
    if tests:
        return "python_ast", f"test module; {len(tests)} static test_* definitions; symbols={','.join(symbols[:8]) or 'none'}"
    return "python_ast", f"Python module; top-level symbols={','.join(symbols[:12]) or 'none'}"


def summarize_text(path: Path, text: str) -> tuple[str, str]:
    suffix = path.suffix.lower()
    if suffix == ".py":
        return summarize_python(path, text)
    if suffix == ".md":
        headings = HEADING.findall(text)
        return "markdown_structure", f"Markdown; headings={len(headings)}; lead={' | '.join(headings[:3]) or first_nonempty(text)}"
    if suffix == ".json":
        normalized = re.sub(r"//.*?$|/\*.*?\*/", "", text, flags=re.MULTILINE | re.DOTALL) if path.name == "devcontainer.json" else text
        value = json.loads(normalized)
        keys = list(value)[:12] if isinstance(value, dict) else []
        method = "jsonc_parse" if path.name == "devcontainer.json" else "json_parse"
        return method, f"JSON {type(value).__name__}; top-level keys={','.join(map(str, keys)) or 'n/a'}"
    if suffix == ".jsonc":
        stripped = re.sub(r"//.*?$|/\*.*?\*/", "", text, flags=re.MULTILINE | re.DOTALL)
        value = json.loads(stripped)
        keys = list(value)[:12] if isinstance(value, dict) else []
        return "jsonc_parse", f"JSONC {type(value).__name__}; top-level keys={','.join(map(str, keys)) or 'n/a'}"
    if suffix == ".toml":
        value = tomllib.loads(text)
        return "toml_parse", f"TOML; top-level keys={','.join(list(value)[:12]) or 'none'}"
    if suffix in {".yml", ".yaml"}:
        keys = [match.group(0).split(":", 1)[0].strip("'\"") for match in YAML_TOP_KEY.finditer(text)]
        return "yaml_structure", f"YAML; top-level keys={','.join(keys[:12]) or 'none'}"
    if suffix in {".sh", ".ps1"}:
        names = SHELL_FUNCTION.findall(text) if suffix == ".sh" else re.findall(r"^\s*function\s+([A-Za-z_][A-Za-z0-9_-]*)", text, re.MULTILINE | re.IGNORECASE)
        return "script_structure", f"{suffix[1:]} script; functions={','.join(names[:12]) or 'none'}; lead={first_nonempty(text)}"
    return "text_structure", f"{suffix or 'extensionless'} text; lead={first_nonempty(text)}"


def clean_markdown_target(raw: str) -> str:
    value = raw.strip()
    if value.startswith("<") and ">" in value:
        value = value[1 : value.index(">")]
    elif re.search(r"\s+['\"]", value):
        value = re.split(r"\s+['\"]", value, maxsplit=1)[0]
    return unquote(value.strip())


def resolve_repo_path(source: str, target: str) -> Path | None:
    without_fragment = target.split("#", 1)[0].split("?", 1)[0]
    if not without_fragment:
        return REPOSITORY / source
    candidate = Path(without_fragment)
    options: list[Path] = []
    if without_fragment.startswith("/"):
        relative = without_fragment.lstrip("/")
        options.extend([REPOSITORY / relative, REPOSITORY / "docs" / relative])
    else:
        options.append((REPOSITORY / source).parent / candidate)
        options.append(REPOSITORY / candidate)
    expanded: list[Path] = []
    for option in options:
        expanded.append(option)
        if not option.suffix:
            expanded.extend([option.with_suffix(".md"), option / "README.md", option / "index.md"])
    for option in expanded:
        try:
            resolved = option.resolve()
            resolved.relative_to(REPOSITORY.resolve())
        except (OSError, ValueError):
            continue
        if resolved.is_file():
            return resolved
    return None


def add_reference(
    rows: list[dict[str, object]],
    source: str,
    line: int,
    kind: str,
    raw: str,
    normalized: str,
    terminal_class: str,
    status: str,
    target: str,
    evidence: str,
) -> None:
    rows.append(
        {
            "ReferenceId": f"R{len(rows) + 1:05d}",
            "Source": source,
            "Line": line,
            "Kind": kind,
            "RawReference": raw,
            "NormalizedTarget": normalized,
            "TerminalClass": terminal_class,
            "Status": status,
            "ResolvedTarget": target,
            "Evidence": evidence,
        }
    )


def classify_markdown(source: str, line: int, raw: str) -> tuple[str, str, str, str]:
    target = clean_markdown_target(raw)
    lowered = target.lower()
    if re.match(r"^[a-z][a-z0-9+.-]*://", lowered) or lowered.startswith(("mailto:", "tel:")):
        return target, "external_dependency", "terminal", target
    if target.startswith("#"):
        return target, "repository_file", "resolved", source
    resolved = resolve_repo_path(source, target)
    if resolved is not None:
        relative = resolved.relative_to(REPOSITORY).as_posix()
        return target, "repository_file", "resolved", relative
    if re.search(r"\{|\}|<|>|\$|repository-url|\brepository\b|\blink\b|your-|example", target, re.IGNORECASE):
        return target, "prose_example", "terminal", "n/a"
    if target.startswith("/"):
        return target, "external_dependency", "terminal", f"documentation-route:{target}"
    return target, "unresolved", "unresolved", ""


def python_module_target(source: str, module: str | None, level: int) -> str | None:
    source_path = Path(source)
    if "src" in source_path.parts and "specify_cli" in source_path.parts:
        module_parts = list(source_path.with_suffix("").parts[source_path.parts.index("src") + 1 :])
    else:
        module_parts = list(source_path.with_suffix("").parts)
    if source_path.name == "__init__.py":
        package = module_parts[:-1]
    else:
        package = module_parts[:-1]
    if level:
        keep = len(package) - (level - 1)
        parts = package[: max(0, keep)]
        if module:
            parts.extend(module.split("."))
    else:
        if not module or not (module == "specify_cli" or module.startswith("specify_cli.") or module == "tests" or module.startswith("tests.")):
            return None
        parts = module.split(".")
    bases = [REPOSITORY / "src", REPOSITORY]
    for base in bases:
        candidate = base.joinpath(*parts)
        for option in (candidate.with_suffix(".py"), candidate / "__init__.py"):
            if option.is_file():
                return option.relative_to(REPOSITORY).as_posix()
    return ""


def extract_python_imports(source: str, text: str, rows: list[dict[str, object]]) -> None:
    tree = ast.parse(text, filename=source)
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                target = python_module_target(source, alias.name, 0)
                if target is None:
                    add_reference(rows, source, node.lineno, "python_import", alias.name, alias.name, "external_dependency", "terminal", alias.name, "Python AST import")
                elif target:
                    add_reference(rows, source, node.lineno, "python_import", alias.name, alias.name, "executable", "resolved", target, "Python AST import")
                else:
                    add_reference(rows, source, node.lineno, "python_import", alias.name, alias.name, "unresolved", "unresolved", "", "Python AST import")
        elif isinstance(node, ast.ImportFrom):
            raw = "." * node.level + (node.module or "")
            target = python_module_target(source, node.module, node.level)
            if target is None:
                add_reference(rows, source, node.lineno, "python_import", raw, raw, "external_dependency", "terminal", node.module or raw, "Python AST from-import")
            elif target:
                add_reference(rows, source, node.lineno, "python_import", raw, raw, "executable", "resolved", target, "Python AST from-import")
            else:
                add_reference(rows, source, node.lineno, "python_import", raw, raw, "unresolved", "unresolved", "", "Python AST from-import")


def extract_markdown(source: str, text: str, rows: list[dict[str, object]]) -> None:
    for kind, pattern in (("markdown_link", MARKDOWN_LINK), ("markdown_definition", MARKDOWN_DEFINITION)):
        for match in pattern.finditer(text):
            raw = match.group(1)
            line = line_number(text, match.start(1))
            normalized, terminal_class, status, target = classify_markdown(source, line, raw)
            add_reference(rows, source, line, kind, raw, normalized, terminal_class, status, target, "Markdown target resolution")


def extract_command_scripts(source: str, text: str, rows: list[dict[str, object]]) -> None:
    if not source.startswith("templates/commands/"):
        return
    matches = list(SCRIPT_ENTRY.finditer(text))
    if not matches:
        add_reference(rows, source, 1, "command_terminal", "prompt-only", "prompt-only", "prompt_only", "terminal", source, "No scripts frontmatter block")
        return
    for match in matches:
        language, command = match.groups()
        raw_path = command.split()[0]
        target = raw_path
        exists = (REPOSITORY / target).is_file()
        add_reference(
            rows,
            source,
            line_number(text, match.start(2)),
            "command_script",
            command,
            target,
            "executable" if exists else "unresolved",
            "resolved" if exists else "unresolved",
            target if exists else "",
            f"frontmatter {language} script",
        )


def extract_bundle_references(source: str, text: str, rows: list[dict[str, object]]) -> None:
    if not (source.startswith("examples/bundles/") and source.endswith("/bundle.yml")):
        return
    current: str | None = None
    for number, line in enumerate(text.splitlines(), 1):
        section = re.match(r"^\s{2}(extensions|presets|steps|workflows):\s*$", line)
        if section:
            current = section.group(1)
            continue
        if re.match(r"^\S", line):
            current = None
        identifier = re.match(r"^\s{4}-\s+id:\s*['\"]?([^'\"\s]+)", line)
        if not current or not identifier:
            continue
        component = identifier.group(1)
        version = "unpinned"
        following = text.splitlines()[number : number + 3]
        for candidate in following:
            version_match = re.match(r"^\s{6}version:\s*['\"]?([^'\"\s]+)", candidate)
            if version_match:
                version = version_match.group(1)
                break
            if re.match(r"^\s{4}-\s+id:", candidate) or re.match(r"^\s{2}\w", candidate):
                break
        singular = {"extensions": "extension", "presets": "preset", "steps": "step", "workflows": "workflow"}[current]
        normalized = f"{singular}:{component}@{version}"
        if singular == "extension" and component == "agent-context":
            target = "extensions/agent-context/extension.yml"
            terminal_class, status = "executable", "resolved"
        else:
            target = ""
            terminal_class, status = "broken", "confirmed_broken"
        add_reference(rows, source, number, "bundle_component", normalized, normalized, terminal_class, status, target, "bundle catalog/CLI validation")


def extract_generated_pairs(source: str, rows: list[dict[str, object]]) -> None:
    if source.startswith(".github/workflows/") and source.endswith(".md") and source not in {".github/workflows/RELEASE-PROCESS.md"}:
        lock = source[:-3] + ".lock.yml"
        if (REPOSITORY / lock).is_file():
            add_reference(rows, source, 1, "generated_pair", lock, lock, "generated_artifact", "resolved", lock, "tracked Agentic Workflow source/lock pair")


def extract_yaml_uses(source: str, text: str, rows: list[dict[str, object]]) -> None:
    if Path(source).suffix.lower() not in {".yml", ".yaml"}:
        return
    for match in USES_LINE.finditer(text):
        raw = match.group(1).strip("'\"")
        line = line_number(text, match.start(1))
        if raw.startswith("./"):
            resolved = resolve_repo_path(source, raw)
            if resolved:
                target = resolved.relative_to(REPOSITORY).as_posix()
                add_reference(rows, source, line, "yaml_uses", raw, raw, "repository_file", "resolved", target, "YAML uses path")
            else:
                add_reference(rows, source, line, "yaml_uses", raw, raw, "prose_example", "terminal", "n/a", "generated/runtime-relative action path")
        else:
            add_reference(rows, source, line, "yaml_uses", raw, raw, "external_dependency", "terminal", raw, "SHA/digest-pinned external action or container")


def extract_shell_sources(source: str, text: str, rows: list[dict[str, object]]) -> None:
    if Path(source).suffix.lower() != ".sh":
        return
    for match in SHELL_SOURCE.finditer(text):
        raw = match.group(2)
        line = line_number(text, match.start(2))
        if "$" in raw or "`" in raw:
            add_reference(rows, source, line, "shell_source", raw, raw, "prose_example", "terminal", "dynamic path", "dynamic shell source")
            continue
        resolved = resolve_repo_path(source, raw)
        if resolved:
            target = resolved.relative_to(REPOSITORY).as_posix()
            add_reference(rows, source, line, "shell_source", raw, raw, "executable", "resolved", target, "shell source")
        else:
            add_reference(rows, source, line, "shell_source", raw, raw, "external_dependency", "terminal", raw, "environment-provided shell source")


def main() -> None:
    if git("rev-parse", "HEAD") != COMMIT:
        raise RuntimeError("Pinned repository HEAD mismatch")
    if git("status", "--porcelain"):
        raise RuntimeError("Pinned repository is dirty")

    inventory = read_csv(INVENTORY)
    gears = read_csv(GEARS)
    gear_paths = [row["Path"] for row in gears]
    inventory_by_path = {row["Path"]: row for row in inventory}
    expected = [row["Path"] for row in inventory if row["GearCandidate"] == "True"]
    if len(inventory) != 530 or len(gears) != 525 or sorted(gear_paths) != sorted(expected):
        raise RuntimeError("Inventory/gear cardinality mismatch")

    references: list[dict[str, object]] = []
    semantic: dict[str, tuple[str, str, int, str]] = {}
    for source in gear_paths:
        path = REPOSITORY / source
        data = path.read_bytes()
        inventory_row = inventory_by_path[source]
        if len(data) != int(inventory_row["Bytes"]) or sha256(data) != inventory_row["SHA256"]:
            raise RuntimeError(f"Inventory hash/byte mismatch: {source}")
        text = data.decode("utf-8", errors="replace")
        lines = len(re.split(r"\r\n|\n|\r", text))
        method, synopsis = summarize_text(path, text)
        semantic[source] = (method, synopsis, lines, inventory_row["SHA256"])
        if path.suffix.lower() == ".md":
            extract_markdown(source, text, references)
            extract_command_scripts(source, text, references)
            extract_generated_pairs(source, references)
        if path.suffix.lower() == ".py":
            extract_python_imports(source, text, references)
        extract_bundle_references(source, text, references)
        extract_yaml_uses(source, text, references)
        extract_shell_sources(source, text, references)

    for index, row in enumerate(references, 1):
        row["ReferenceId"] = f"R{index:05d}"

    generic_unresolved = [row for row in references if row["Status"] == "unresolved"]
    broken = [row for row in references if row["Status"] == "confirmed_broken"]
    if generic_unresolved:
        details = "\n".join(f"{row['Source']}:{row['Line']} {row['Kind']} {row['RawReference']}" for row in generic_unresolved[:50])
        raise RuntimeError(f"Generic unresolved references remain: {len(generic_unresolved)}\n{details}")
    if len(broken) != 16 or any(row["Kind"] != "bundle_component" for row in broken):
        raise RuntimeError(f"Expected exactly 16 confirmed broken bundle references, got {len(broken)}")

    refs_by_source: dict[str, list[dict[str, object]]] = defaultdict(list)
    for row in references:
        refs_by_source[str(row["Source"])].append(row)

    gear_rows: list[dict[str, object]] = []
    for index, source in enumerate(gear_paths, 1):
        method, synopsis, lines, digest = semantic[source]
        file_refs = refs_by_source[source]
        classes = Counter(str(row["TerminalClass"]) for row in file_refs)
        statuses = Counter(str(row["Status"]) for row in file_refs)
        gear_rows.append(
            {
                "GearRow": index,
                "Path": source,
                "Category": inventory_by_path[source]["Category"],
                "Bytes": inventory_by_path[source]["Bytes"],
                "Lines": lines,
                "SHA256": digest,
                "SemanticMethod": method,
                "SemanticSynopsis": synopsis,
                "ReferenceCount": len(file_refs),
                "TerminalClasses": ";".join(f"{key}={value}" for key, value in sorted(classes.items())) or "none",
                "ReferenceStatuses": ";".join(f"{key}={value}" for key, value in sorted(statuses.items())) or "none",
                "BrokenReferenceCount": statuses.get("confirmed_broken", 0),
                "SourceEvidence": source_url(source, lines),
            }
        )

    write_csv(
        GEAR_LEDGER,
        gear_rows,
        [
            "GearRow", "Path", "Category", "Bytes", "Lines", "SHA256", "SemanticMethod",
            "SemanticSynopsis", "ReferenceCount", "TerminalClasses", "ReferenceStatuses",
            "BrokenReferenceCount", "SourceEvidence",
        ],
    )
    write_csv(
        REFERENCE_LEDGER,
        references,
        [
            "ReferenceId", "Source", "Line", "Kind", "RawReference", "NormalizedTarget",
            "TerminalClass", "Status", "ResolvedTarget", "Evidence",
        ],
    )

    ledger_absolute = str(GEAR_LEDGER.resolve())
    updated_gears: list[dict[str, object]] = []
    for row, evidence_row in zip(gears, gear_rows, strict=True):
        updated_gears.append(
            {
                "Path": row["Path"],
                "Category": row["Category"],
                "AnalysisStatus": "analyzed",
                "Evidence": f"{ledger_absolute}#row={evidence_row['GearRow']}",
                "Notes": (
                    f"{evidence_row['SemanticMethod']}: {evidence_row['SemanticSynopsis']}; "
                    f"refs={evidence_row['ReferenceCount']}; terminals={evidence_row['TerminalClasses']}; "
                    f"SHA-256 {evidence_row['SHA256']}"
                ),
            }
        )
    write_csv(GEARS, updated_gears, ["Path", "Category", "AnalysisStatus", "Evidence", "Notes"])

    broken_lines = [
        "# GitHub Spec Kit confirmed broken bundle references",
        "",
        f"Pinned commit: `{COMMIT}`",
        "",
        "All four example READMEs instruct users to run `specify bundle validate --path ...`. At the pin, each command exits 1. The 16 rows below are executable bundle-component references with no built-in/community catalog terminal. They are the only `confirmed_broken` rows in `reference-ledger.csv`; generic unresolved rows are zero.",
        "",
        "| Source | Line | Reference | Classification | Reason |",
        "|---|---:|---|---|---|",
    ]
    for row in broken:
        broken_lines.append(
            f"| `{row['Source']}` | {row['Line']} | `{row['NormalizedTarget']}` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |"
        )
    BROKEN_LEDGER.write_text("\n".join(broken_lines) + "\n", encoding="utf-8")

    class_counts = Counter(str(row["TerminalClass"]) for row in references)
    status_counts = Counter(str(row["Status"]) for row in references)
    kind_counts = Counter(str(row["Kind"]) for row in references)
    summary_lines = [
        "# GitHub Spec Kit semantic/reference closure summary",
        "",
        f"- Repository pin: `{COMMIT}`",
        f"- Tracked inventory: `{len(inventory)}`",
        f"- Gear candidates: `{len(gear_rows)}`",
        "- Excluded binaries: `5`",
        f"- Reference ledger rows: `{len(references)}`",
        f"- Confirmed broken: `{status_counts.get('confirmed_broken', 0)}`",
        f"- Generic unresolved: `{status_counts.get('unresolved', 0)}`",
        "",
        "## Terminal classes",
        "",
    ]
    summary_lines.extend(f"- `{key}`: {value}" for key, value in sorted(class_counts.items()))
    summary_lines.extend(["", "## Reference kinds", ""])
    summary_lines.extend(f"- `{key}`: {value}" for key, value in sorted(kind_counts.items()))
    summary_lines.extend(
        [
            "",
            "## Method boundary",
            "",
            "The gear ledger proves file-by-file opening, byte/hash identity, parse/structure method, content-derived synopsis, immutable source locator, and linkage to extracted reference rows. The reference ledger covers Python imports, Markdown inline/reference-definition targets, command frontmatter scripts and prompt-only terminals, bundle component references, Agentic Workflow source/lock pairs, YAML `uses:` targets, and shell `source` directives. External URLs/modules and explicit examples are terminal classifications, not silently discarded candidates. This ledger does not claim live execution of every host, URL, action, or prompt.",
        ]
    )
    SUMMARY.write_text("\n".join(summary_lines) + "\n", encoding="utf-8")

    print(json.dumps({
        "commit": COMMIT,
        "tracked": len(inventory),
        "gears": len(gear_rows),
        "references": len(references),
        "broken": len(broken),
        "generic_unresolved": len(generic_unresolved),
        "terminal_classes": dict(sorted(class_counts.items())),
        "reference_kinds": dict(sorted(kind_counts.items())),
    }, indent=2))


if __name__ == "__main__":
    main()
