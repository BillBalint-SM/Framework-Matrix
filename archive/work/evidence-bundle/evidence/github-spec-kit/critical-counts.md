# GitHub Spec Kit critical-count evidence

- Repository pin: `d1e86f638277a99b82715c22c90558cd58d3cffd`
- Evidence date: `2026-08-02`
- Repository: clean pinned clone/worktree

## Inventory methods and results

| Claim | Reproducible method | Result |
|---|---|---:|
| Tracked files | `git ls-files` | 530 |
| Semantic gears | tracked files minus five binary media files, each opened/hashed/classified by `work/scripts/build-github-spec-kit-evidence.py` | 525 |
| Registered integrations | import/registration statements in `src/specify_cli/integrations/__init__.py` | 37 |
| Built-in/community extensions | parse `extensions/catalog.json` and `extensions/catalog.community.json`; count `extensions` object keys | 4 / 144 |
| Built-in/community presets | parse `presets/catalog.json` and `presets/catalog.community.json`; count `presets` object keys | 2 / 29 |
| Built-in/community workflows | parse `workflows/catalog.json` and `workflows/catalog.community.json`; count `workflows` object keys | 1 / 2 |
| Built-in step types | registrations in `src/specify_cli/workflows/__init__.py` | 11 |
| Agentic Workflow source/lock pairs | pair `.github/workflows/*.md` with same-stem `.lock.yml` | 6 |
| Tracked tests subtree | `git ls-files tests` | 157 |
| Python test files | tracked `tests/**/*.py` | 152 |
| Static test definitions | Python AST: `FunctionDef` and `AsyncFunctionDef` named `test_*` | 4,230 |
| Runtime pytest cases | clean-clone `pytest --collect-only -q` | 6,388 |

## GitHub Actions pinning check

The reference extractor found 325 `uses:` occurrences in tracked YAML. It accepted a non-local action only when the reference matched `<owner>/<action>@<40-hex-SHA>` or `docker://...@sha256:<64-hex-digest>`; local `./...` actions were separately allowed. Result: **325 pinned/local, zero non-SHA external action references**. Exact source, line, and raw target are in `reference-ledger.csv` under `Kind=yaml_uses`.

## Markdown/reference extraction

The scanner parsed 578 standard inline Markdown targets and four reference-definition targets, retaining every occurrence and source line. These 582 rows are part of the 5,945-row reference ledger. Every row has a terminal class; generic unresolved is zero. The scanner also records Python AST imports, command frontmatter scripts, prompt-only command terminals, bundle components, Agentic Workflow source/lock pairs, YAML `uses:`, and shell `source` directives.

## Runtime boundary

The fresh targeted command, dependency versions, result, warnings, timing, and bounded scope are in `targeted-pytest-20260802.md`. Full-suite collection returned 6,388 cases. Full-suite execution exceeded the bounded observation window and is classified `timeout/inconclusive`.
