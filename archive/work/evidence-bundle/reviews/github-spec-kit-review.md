# Adversarial review: `github/spec-kit`

## Verdict

**REVISE**

The report is a strong architectural synthesis and most inspected source claims are directionally correct. It is not yet acceptable as a zero-gap, exhaustive evidence report. The tracked-file/hash census is reproducible, all existing immutable citation paths and ranges are mechanically valid, and the new targeted suite is green. However, the report overstates semantic gear and internal-reference closure, omits a material security boundary, contains two exact inventory errors, and is stale relative to the available runtime evidence.

No P0 finding was identified. Acceptance requires all P1 and P2 corrections below; P3 is a reproducibility improvement.

## Review basis

```text
WORK_STATE: fresh=2026-08-02T13:53:19.8397137Z; repo=work/repos/github-spec-kit; branch=main; head=d1e86f638277a99b82715c22c90558cd58d3cffd; worktree=clean; upstream=origin/main; pr=3592/MERGED raw provider result; evidence=local+remote
```

The raw PR lookup is not used to infer that the analysis checkout owns an active delivery PR. The source under review remained unmodified.

Reviewed artifacts:

- `work/research/github-spec-kit-agent-report.md`
- `work/inventory/github-spec-kit-files.csv`
- `work/inventory/github-spec-kit-gears.csv`
- `work/evidence/github-spec-kit/targeted-pytest-20260802.md`
- pinned analysis checkout and disposable runtime clone at the same commit

## Findings

### P1-1 — “Exhaustive” gear and internal-reference closure is not evidenced, and 16 executable example references are actually broken

The file census is sound:

- 530 tracked files equal 530 file-inventory rows.
- All 530 inventory SHA-256 values match the pinned checkout.
- The 525 gear rows exactly equal the 525 `GearCandidate=True` rows, with no missing or extra path, no duplicate gear path, and all statuses set to `analyzed`.
- The five exclusions are exactly the five media binaries: `bootstrap-claude-code.gif`, `logo_large.webp`, `logo_small.webp`, `spec-kit-video-header.jpg`, and `specify_cli.gif`.

This proves **mechanical 525/525 coverage**, not per-file semantic analysis. Every gear row points to the same report and every Notes value has the same generic suffix, “covered by the pinned full-file census and the report's exhaustive semantic traversal.” The report does not mention numerous gear paths or provide a file-specific evidence locator. Examples include `.devcontainer/post-create.sh`, `.github/CODEOWNERS`, Dependabot and issue-template configuration, `_agent_config.py`, `_github_http.py`, `shared_infra.py`, the Chinese README, newsletters, and workspace metadata. The inventory therefore asserts the conclusion it is meant to prove.

The brief also requires every internal reference to reach executable code, an external dependency, a generated artifact, or a proven terminal endpoint. The report records only a 24-reference command-frontmatter parse and an undocumented 112-item Markdown-link scan. It does not provide a complete reference ledger. More importantly, report lines 172 and 560 soften the four example bundles as “not necessarily all resolvable,” but the repository's own CLI rejects every one of them through the usage path printed in each example README:

```powershell
& .\.venv\Scripts\specify.exe bundle validate --path examples\bundles\<name>
```

Each of the four invocations exited 1. The exact unresolved references and terminal classification are:

| Example | Reference | Terminal class | Evidence |
|---|---|---|---|
| `business-analyst` | `preset:requirements-elicitation@1.0.0` | **broken executable reference** | absent from built-in/community preset catalogs; CLI validation exit 1 |
| `business-analyst` | `step:capture-requirements@unpinned` | **broken executable reference** | both step catalogs are empty; CLI validation exit 1 |
| `business-analyst` | `step:trace-acceptance-criteria@unpinned` | **broken executable reference** | both step catalogs are empty; CLI validation exit 1 |
| `business-analyst` | `workflow:requirements-to-spec@1.0.0` | **broken executable reference** | absent from built-in/community workflow catalogs; CLI validation exit 1 |
| `developer` | `preset:implementation-planning@1.0.0` | **broken executable reference** | absent from built-in/community preset catalogs; CLI validation exit 1 |
| `developer` | `step:plan-implementation@unpinned` | **broken executable reference** | both step catalogs are empty; CLI validation exit 1 |
| `developer` | `step:break-down-tasks@unpinned` | **broken executable reference** | both step catalogs are empty; CLI validation exit 1 |
| `developer` | `workflow:spec-to-implementation@1.0.0` | **broken executable reference** | absent from built-in/community workflow catalogs; CLI validation exit 1 |
| `product-manager` | `preset:product-discovery@1.0.0` | **broken executable reference** | absent from built-in/community preset catalogs; CLI validation exit 1 |
| `product-manager` | `step:draft-spec@unpinned` | **broken executable reference** | both step catalogs are empty; CLI validation exit 1 |
| `product-manager` | `step:review-spec@unpinned` | **broken executable reference** | both step catalogs are empty; CLI validation exit 1 |
| `product-manager` | `workflow:spec-to-roadmap@1.0.0` | **broken executable reference** | absent from built-in/community workflow catalogs; CLI validation exit 1 |
| `security-researcher` | `preset:security-compliance@1.0.0` | **broken executable reference** | absent from built-in/community preset catalogs; CLI validation exit 1 |
| `security-researcher` | `step:threat-model@unpinned` | **broken executable reference** | both step catalogs are empty; CLI validation exit 1 |
| `security-researcher` | `step:security-review@unpinned` | **broken executable reference** | both step catalogs are empty; CLI validation exit 1 |
| `security-researcher` | `workflow:secure-sdd@1.0.0` | **broken executable reference** | absent from built-in/community workflow catalogs; CLI validation exit 1 |

The source locations are [d1e86f6:examples/bundles/business-analyst/bundle.yml:L17-L31], [d1e86f6:examples/bundles/developer/bundle.yml:L17-L31], [d1e86f6:examples/bundles/product-manager/bundle.yml:L19-L33], and [d1e86f6:examples/bundles/security-researcher/bundle.yml:L17-L31]. Their READMEs explicitly instruct users to run `bundle validate`, so these are not merely prose placeholders.

The other independently checked reference classes terminate as follows:

- The 24 `scripts:` references in the eight script-bearing core commands parse successfully and resolve to existing Bash, PowerShell, and Python source scripts: **valid executable terminal**.
- `constitution` and `specify` intentionally contain no script block: **prompt-only terminal**, not broken.
- The six Agentic Workflow Markdown sources each have a tracked generated `.lock.yml`: **generated-artifact terminal**.
- A simple independent Markdown scanner found five unresolved-looking tokens: `repository-url` in the extension skill and two catalog workflows, `repository` in the bundle workflow, and `link` in the bug-fix workflow. Their contexts are metavariables/examples: **prose/example terminal**, not broken.
- Root-relative media links resolve to tracked media: **valid repository terminal**.

Exact correction:

1. Rename the current 525/525 assertion to “mechanical tracked-gear census” unless a per-file evidence locator is added.
2. Add a machine-readable reference ledger with source, line, raw reference, normalized target, existence/resolution result, and one of: executable, external dependency, generated, prompt-only, prose/example, or broken.
3. List all 16 broken bundle references above and state that all four example validation commands fail at the pinned commit. Do not describe them only as “not necessarily resolvable.”
4. Either make the examples resolvable in the repository or explicitly label them non-runnable conceptual examples and remove the currently failing validation instructions. That source change is outside this report-review task.

### P1-2 — Runtime evidence is stale and the 1,487-pass result must be precisely scoped

Report lines 465-473 and unresolved item 1 say no current pytest result is available because the analysis checkout lacks dependencies. That statement was true for that checkout, but it is no longer an adequate report-level runtime conclusion. A dependency-complete disposable clone exists at the exact pin.

The targeted command was independently rerun during this review:

```powershell
& .\.venv\Scripts\python.exe -m pytest -q -rs `
  tests\contract `
  tests\workflows `
  tests\test_workflows.py `
  tests\integrations\test_events.py `
  tests\test_download_security.py `
  -p no:cacheprovider
```

Observed result:

- platform `win32`; Python 3.14.6; pytest 9.1.1; pluggy 1.6.0; pytest-cov 7.1.0;
- 1,494 collected;
- **1,487 passed, 7 skipped, 6 warnings, exit 0** in 27.14 seconds on the independent rerun;
- all seven skips are explicit Windows exclusions for POSIX permission/mode behavior (`chmod`, `fchown`, or POSIX permission bits);
- five warnings are Copilot legacy-Markdown deprecation warnings emitted from init tests; one is the expected Python `zipfile` duplicate-member warning in a rejection test.

This is positive runtime evidence for:

- contract bundle/catalog/manifest/wheel packaging tests (115 collected cases);
- workflow overlay/resolver/security tests (179);
- the main workflow engine suite (914);
- integration-event behavior (104);
- download/archive security (182).

It is **not** a full-suite result. A separate full collection completed with exit 0 and reported **6,388 tests collected in 0.99s**. The earlier full execution did not produce a terminal pass/fail summary, so it remains `timed out/inconclusive`; it must never be called passing or failing. The targeted 1,487 count is executed passes, not total collected cases, because seven were skipped.

The disposable runtime clone also contains a materialized `spec-smoke-20260802` project with `.agents/skills`, `.specify` manifests, scripts, templates, and the bundled workflow. Because no exact invocation, exit code, or terminal log is preserved for that smoke artifact, it is corroborating filesystem state only, not reportable runtime proof of the complete init path.

Exact correction:

1. Replace report lines 472-473 and unresolved item 1 with the exact targeted command, environment, counts, skips, warnings, exit code, and bounded scope above.
2. State separately: “full suite: 6,388 collected; execution timed out/inconclusive before terminal summary.”
3. Preserve the existing statement that no external agent CLI, remote catalog, destructive lifecycle, or lock compiler was exercised.
4. Do not use the targeted green suite as proof for integrations, extensions, presets, authentication, self-upgrade, cross-platform shell parity, or the whole repository beyond the selected paths.

### P1-3 — The authentication boundary is overbroad; extension URL trust and credential sourcing are separate controls

Report line 483 states, without subsystem qualification, that authentication is opt-in through `~/.specify/auth.json` and that absent configuration means unauthenticated requests. That is correct for the config-driven authentication layer [d1e86f6:src/specify_cli/authentication/config.py:L1-L4], but not for every HTTP helper exposed by the package.

`specify_cli._github_http.build_github_request()` independently reads `GITHUB_TOKEN` or `GH_TOKEN` and attaches a Bearer header for four GitHub-owned hosts [d1e86f6:src/specify_cli/_github_http.py:L30-L58]. The function appears not to be called by the pinned production tree; release-asset resolution in that module receives the config-driven opener from callers. Nevertheless, the report's global wording and gear-coverage claim omit this credential-bearing public helper entirely.

This is separate from the correctly reported default-deny trust decision for URL-installed extensions. `init` requires interactive confirmation or `--trust-extension-urls` before those URL sources are accepted [d1e86f6:src/specify_cli/commands/init.py:L582-L592]. URL-source trust decides whether content may be installed; credential sourcing decides what authorization material an HTTP request may carry. One does not prove the other.

Exact correction:

- Change line 483 to: “The config-driven catalog/asset authentication layer is opt-in through `~/.specify/auth.json`; absent a valid matching entry, that layer attempts unauthenticated access. Separately, the public `_github_http.build_github_request()` helper can attach `GITHUB_TOKEN` or `GH_TOKEN` to a fixed GitHub host allowlist.”
- Retain the default-deny extension URL trust claim as a distinct install-authorization control.
- Add `_github_http.py` to the security evidence index and state whether its env-token helper is live production reachability or currently an unused API surface at the pin.

### P2-1 — The AST count is right, but “across 157 files” is wrong

Report line 448 says “4,230 Python test functions across 157 files.” Independent AST enumeration reproduces **4,230** test function definitions and every category subtotal in the report, but those functions are in **152 Python files**. The 157-file census is the entire tracked `tests/` subtree: 152 `.py` files plus five non-Python hook fixture/document files.

The 4,230 static definitions are also not equivalent to pytest cases: parametrization expands the current collection to 6,388 cases.

Exact correction: use “4,230 AST-enumerated `test_*` function definitions across 152 Python files; the tracked `tests/` subtree contains 157 files total; pytest collects 6,388 cases at this pin.” Apply the same distinction in report lines 448 and 618.

### P2-2 — The integration family inventory omits `kiro-cli`

The 37-ID registry list itself is complete, but the output-family bullets in report lines 123-129 account for only 36 IDs. `kiro-cli` is missing. It subclasses `MarkdownIntegration` and declares `.kiro/prompts`, format `markdown`, and `.md` output [d1e86f6:src/specify_cli/integrations/kiro_cli/__init__.py:L14-L35].

Exact correction: add `kiro-cli` to the Markdown command-layout bullet. Keep `generic` described as configurable/bespoke if desired, but ensure the family inventory accounts for all 37 unique registry IDs exactly once.

### P2-3 — Citation syntax is valid, but critical exact claims are under-cited and one range only partially supports its sentence

The report contains 56 immutable source citations (55 unique). Every citation uses the correct commit prefix, every path exists at the pin, and every line range is ordered and within file bounds. There are no malformed path/range citations.

That mechanical success does not satisfy the brief's critical-claim evidence requirement. Important exact claims have no commit/file/line citation, including:

- the 37-ID registry and output-family classification (report lines 119-129);
- built-in/community extension and preset counts (144 and 166);
- the 11 step-type registry and workflow catalog counts (184-206);
- Agentic Workflow source/lock counts and compiler/runtime versions (346-357);
- self-upgrade detection, credential scrubbing, and recovery behavior (413);
- the statement that all inspected Actions uses are SHA-pinned (442);
- the runtime census, AST method, and Markdown-link method.

In addition, the citation at report line 223 supports the TypeScript event handler's default timeout but not, by itself, the complete outer-timeout-buffer claim; the buffer definition/conversion lives elsewhere in `events.py`.

Exact correction: add immutable citations to each exact security/runtime/registry count and split compound sentences when different source ranges prove different clauses. For generated/check-derived claims, cite a reproducible evidence artifact containing the command and result rather than inventing a source citation.

### P3-1 — The Markdown-link result cannot be reproduced from the report

Report lines 471 and 515-517 give 112 checked references and seven dismissed candidates, but record neither extraction rules nor a command/result artifact. An independent simple scanner over 138 tracked Markdown files observed 582 standard inline/reference-definition links, 111 local-file candidates, and five unresolved-looking metavariables/examples. The different denominator is not proof that the report's number is wrong; it proves that the reported method is underspecified.

Exact correction: persist the scanner implementation or exact command, define whether images, reference definitions, anchors, root-relative site paths, escaped URLs, generated files, and placeholders are included, and list every non-terminal candidate with its classification.

## Claim-by-claim disposition

| Area | Disposition | Review conclusion |
|---|---|---|
| Pinned snapshot / census | **Verified** | commit, branch, clean worktree, 530 files, byte/hash inventory all reproduce |
| 525/525 gear coverage | **Qualified** | exact mechanical coverage verified; semantic per-file coverage not proven |
| Core command/script graph | **Verified for declared frontmatter** | ten commands, eight script-bearing commands, 24 valid sh/ps/py references, two prompt-only commands |
| Integration registry | **Verified with correction** | 37 IDs; `kiro-cli` omitted from the report's Markdown family |
| Installer/materialization | **Source-backed; runtime incomplete** | ordering and default-deny URL trust supported; smoke artifact exists but lacks exact recorded command/result |
| Manifest ownership/uninstall | **Source-backed** | hash ownership, containment/symlink guards, conservative uninstall, and atomic save ranges support the claims; not destructively exercised |
| Extensions/presets/bundles | **Source-backed with broken examples** | catalog counts reproduce; four example bundles have 16 exact broken refs |
| Events | **Source-backed plus targeted runtime tests** | no-op success, `shell=False`, resolution/refresh behavior supported; selected event suite passed |
| Agent/persona model | **Reasonable inference** | external integration as cognitive runtime is well supported; no external agent CLI was live-tested |
| Workflows | **Source-backed plus targeted runtime tests** | engine/overlays/security have strong selected-suite evidence; not a full-suite verdict |
| Download/archive security | **Source-backed plus targeted runtime tests** | selected 182-case file passed; broader authentication/helper wording needs correction |
| CI/action pinning | **Statically rechecked** | no non-SHA `uses:` reference was found in tracked YAML workflows; report still needs a reproducible command/evidence citation |
| Runtime health | **Targeted pass only** | 1,487 passed / 7 skipped of 1,494 selected; 6,388 full collection; full execution inconclusive |

## Acceptance checklist

The report can move to **ACCEPT** when all are true:

- [ ] “Exhaustive semantic 525/525” is either proven per file or downgraded to mechanical census coverage.
- [ ] A complete reference ledger is attached, including all 16 broken example-bundle references and exact terminal classes.
- [ ] The targeted 1,487-pass evidence is included with its 1,494-case boundary, seven skips, six warnings, environment, command, and exit code.
- [ ] The 6,388-case full suite is described as collected but execution-inconclusive, never as passing.
- [ ] “4,230 across 157 files” is corrected to 4,230 definitions across 152 Python files, with 157 total tracked test-subtree files.
- [ ] `kiro-cli` is added to the Markdown integration family.
- [ ] The `auth.json` statement is scoped to the config-driven layer and the separate `GITHUB_TOKEN`/`GH_TOKEN` helper is documented.
- [ ] Critical counts and security/installer/runtime claims receive immutable source citations or reproducible evidence artifacts.
- [ ] The Markdown/reference scanning method is reproducible and every candidate is explicitly classified.

## Review limitation

The research skill called for an independent background check. A sub-agent launch was attempted but the shared collaboration pool was already at its thread limit. This review therefore used one reviewer with independent reruns and machine-checkable inventories, not a second-agent opinion. That limitation does not change the **REVISE** verdict or any finding above.
