# Independent review: open-gsd/gsd-core agent report

## Verdict

**REVISE AND RE-REVIEW — NOT ZERO-GAP.** The submitted report is a strong architectural synthesis, and most central structure claims survive independent checking: the pinned checkout and inventory reconcile at 2,730 files; all 2,730 hashes match; the CSV marks 2,725 gear candidates; all 98 pinned citations resolve to existing files and valid line ranges; the 44 capability manifests, 19 runtimes, 34 agents, 71 commands, 71 generated skills, plugin copies, hook registry, workflows, references, state machinery, history, and MIT license are substantially represented correctly.

Acceptance is blocked by three major evidence failures and three material corrections. The report's alleged gear-candidate byte/line census is actually a non-NUL-file census whose cardinality happens to equal 2,725; its top-level table sums to 2,726 rather than 2,730; no terminal reference ledger demonstrates the required all-file traversal; and the 865-pass/timeout evidence has no persisted command or output. The generated loop contract is also misreported, generated-sync is not qualified as a post-build result, and the Global/Project/Session/Local table conflates persistence scopes.

| Severity | Count |
|---|---:|
| P0 — critical | 0 |
| P1 — major | 3 |
| P2 — medium | 3 |
| P3 — low | 0 |
| **Total** | **6** |

## Scope and current state

Reviewed against:

- `work/briefs/open-gsd-gsd-core-research-brief.md`;
- `work/research/open-gsd-gsd-core-agent-report.md`;
- `work/repos/open-gsd-gsd-core` at `33985c11a9f0a27443f8b8fb114b2122d653cd78`;
- `work/inventory/open-gsd-gsd-core-files.csv` and `open-gsd-gsd-core-gears.csv`;
- the clean disposable runtime clone at the same commit;
- fresh hash/census/reference/citation scripts, generated checks, selected tests, source/history inspection, and the empty supplied evidence directory.

Review-start state:

```text
WORK_STATE: fresh=2026-08-02T13:18:06.5385790Z; repo=work/repos/open-gsd-gsd-core; branch=next; head=33985c11a9f0a27443f8b8fb114b2122d653cd78; worktree=clean; upstream=origin/next; pr=259/MERGED; evidence=local+remote
```

The merged PR value is remote metadata, not the analysis base. No repository source, branch, commit, remote, credentials, global installation, paid API, or production service was modified. Checks that need compiled artifacts ran only in the existing disposable runtime clone.

## Zero-gap assessment

**Result: NO.** Path/hash coverage is complete; exhaustive semantic and terminal-reference evidence is not.

What is proven:

- inventory paths equal `git ls-files`: 2,730 versus 2,730, missing 0, extra 0;
- all 2,730 inventory SHA-256 values match the pinned checkout;
- category counts and the five declared non-gear assets reconcile;
- the gear ledger contains 2,725 unique rows marked analyzed;
- all 98 citations use the pinned shorthand, target 41 existing files, and have valid ranges;
- command workflow includes have no missing live terminal target under the canonical installed-path convention;
- generated checks pass after the disposable clone's build has materialized ignored CJS outputs.

What is not proven:

- that every gear candidate received semantic analysis rather than hashing/text classification;
- that every internal reference was followed and classified to a terminal layer;
- the exact 18-file/877-test command and its 865/12 outcome;
- the pre-timeout assertion stream, process cleanup, and causal timing of the reported EPIPE;
- live behavior in any supported vendor host.

`open-gsd-gsd-core-gears.csv` adds a path-level status row, but every row's evidence is the report itself and its note is only a SHA-256 plus the same boilerplate assertion of “exhaustive semantic traversal.” It is not an independently inspectable semantic/reference ledger.

## Severity-ranked findings

### P1-1 — The “2,725 gear candidates” byte/line census is a different 2,725-file set, and the top-level table is four files short

Report lines 54 and 626 say the 2,725 gear candidates covered 36,112,848 bytes and 774,236 lines and that five NUL files matched the binary boundary. Independent byte reads show:

| Set | Files | Bytes | LF bytes | NUL-bearing files |
|---|---:|---:|---:|---:|
| Full tracked tree | 2,730 | 36,309,998 | 773,586 | 5 |
| Gear candidates | 2,725 | 36,203,101 | 773,276 | 3 |
| Non-NUL files | 2,725 | 36,112,848 | 771,511 | 0 by definition |

The report's byte count is exactly the non-NUL set, not the gear set. The sets differ in six paths:

- NUL-bearing gear candidates omitted from that byte total: `tests/fix-2284-hermes-agent-delegate-task-projection.test.cjs`, `tests/fixtures/adversarial/frontmatter/null-byte-value.md`, and `tests/security-prompt-injection.security.test.cjs`;
- non-gear text assets included in it: `assets/gsd-logo-2000-transparent.svg`, `assets/gsd-logo-2000.svg`, and `assets/terminal.svg`.

The reported 774,236 line value equals 771,511 LF bytes plus one nominal line for each of the 2,725 non-NUL files. It is likewise not a gear-candidate line count. The statement that the five NUL files match the asset boundary is false: two are PNG assets and three are behavior-defining test/fixture files.

The top-level table at report lines 73–87 independently sums to 2,726. The actual tree has 30 root files, not the table's 27 “singleton root/config files,” and also has `.plans/1755-install-audit-fix.md`, whose top-level area is absent. Required correction: replace both census tables with explicit set definitions and independently sum them to 2,730/2,725.

### P1-2 — The report does not demonstrate the required all-reference terminal traversal

The brief requires every internal reference to be followed to a terminal layer. Report lines 113–124 instead give an unpersisted aggregate scan (5,952 candidates, 1,540 naively unresolved), then validate only selected high-confidence surfaces: command workflow targets, generated skill parity, installed-prefix text, the context index, and nine tracked compiled artifacts.

No `references.csv` or equivalent source-line ledger exists in `work/evidence/open-gsd-gsd-core`; that directory is empty. The report's own limits say the coarse scanner is not a broken-link oracle. The gear CSV cannot fill this gap because it contains no source line, raw token, interpretation class, target, install/runtime root, terminal status, or exclusion rationale.

The narrow command check is reproducible and passes: 71 commands divide into 14 with no direct canonical `@` workflow include, 49 with one, and 8 with multiple; every referenced workflow target exists. That does not establish terminal closure for the other scripts, skills, agents, hooks, docs, configuration, generated files, tests, templates, or nested workflow/reference edges.

Required correction: persist a reference ledger with at least `source_path`, `source_line`, `raw_reference`, `syntax/context`, `resolution_root`, `normalized_target`, `exists`, `terminal/class`, and `exclusion_reason`; reconcile all rows and summarize only from that ledger. Until then, change “exhaustive semantic traversal” to bounded architecture analysis.

### P1-3 — The 865-pass and timeout claims are not independently auditable

Report lines 629–635 claim an 18-file run with 877 tests/865 pass/12 skip, a 244-second full install timeout with zero remaining children, and a 122.7-second Codex timeout whose EPIPE occurred only after stdout was broken. The report does not name the 18 files, give the exact commands, identify the timeout harness, or link persisted stdout/stderr/process evidence. The supplied evidence directory is empty.

Independent review could confirm these smaller claims in the disposable clone under Node 22.23.2:

- `npm run check:env`: exit 0, all five environment checks passed;
- `npm run lint:generated-sync`: exit 0 after build outputs were present;
- `node --test tests/issue-607-installer-dry-run.install.test.cjs`: 5 pass, 0 fail;
- direct `atRefContractStillResolvesAfterComposition`: 1 pass, 0 fail.

The 865/12 run and both timeout narratives remain unverified. The classification “timeout is inconclusive, not a product assertion failure” is methodologically correct, but “no pre-timeout assertion failure,” `REMAINING=0`, and the causal EPIPE sequencing require the missing log. Required correction: persist exact commands, the 18 paths, Node/npm versions, timestamps/durations, complete TAP summaries, timeout mechanism, child PID/process cleanup evidence, and stdout/stderr. Otherwise label the entries “reported by coordinator; not independently verified.”

### P2-1 — Three generated loop-role rows contradict the cited contract

Report lines 295–305 say the table is declared by `loop-host-contract.cjs`, but lines 299, 302, and 303 list Discuss=`none`, Verify=`verifier`, and Ship=`none`. The generated contract says:

- Discuss: `agentRoles: ["orchestrator"]` [33985c1:gsd-core/bin/lib/loop-host-contract.cjs:L13-L25];
- Verify: `agentRoles: ["orchestrator"]` [33985c1:gsd-core/bin/lib/loop-host-contract.cjs:L70-L85];
- Ship: `agentRoles: ["orchestrator"]` [33985c1:gsd-core/bin/lib/loop-host-contract.cjs:L88-L100].

Plan and Execute are correct. If the table intends “specialist subagents,” it needs that label and must not claim to reproduce the generated `agentRoles` field. Required correction: use the contract's values or explicitly separate orchestrator roles from specialist-agent roles.

### P2-2 — Generated-sync is a post-build runtime-clone result, not a clean tracked-tree result

The report says the inventory manifest is current “according to its generator” (line 93) and lists it among synchronized surfaces at the pin. In the pinned analysis checkout, only 17 `gsd-core/bin/lib/*.cjs` files are tracked/present. The committed inventory manifest lists 173 CLI modules, and its non-recursive generator reads the live directory [33985c1:scripts/gen-inventory-manifest.cjs:L44-L55] [33985c1:scripts/gen-inventory-manifest.cjs:L63-L72]. Therefore:

- analysis checkout: `node scripts/gen-inventory-manifest.cjs --check` exits 1 and reports 156 absent CLI modules;
- disposable runtime clone after `npm ci`/`prepare` build: 173 CJS files exist and the check exits 0;
- 156 of those runtime files are ignored build outputs, so ordinary `git status --short` remains clean.

This is consistent with the repository's build-at-publish design, not necessarily a product defect. It is an evidence-scope defect in the report. Required correction: say that generated-sync passed in a **built** disposable clone, distinguish 17 tracked compiled artifacts from the 173 post-build CLI-module roster, and avoid using clean Git status as proof that no ignored generated state affected the check.

### P2-3 — The four-layer table is a useful inference but misassigns durable project state to Session

The repository does not define Global, Project, Session, and Local as four uniform peer layers. The report labels only its final Local interpretation as inference, while the whole table is a synthesis.

Two corrections are required:

- `.planning/debug/*.md`, resolved debug sessions, and the debug knowledge base are persistent project artifacts, not temporary Session-layer material [33985c1:docs/ARCHITECTURE.md:L644-L695] [33985c1:agents/gsd-debugger.md:L791-L838].
- The active-workstream pointer is session-scoped only when a stable host session key is available; otherwise it falls back to project-local `.planning/active-workstream` [33985c1:src/active-workstream-store.cts:L84-L143] [33985c1:src/active-workstream-store.cts:L197-L230].

“Local” is also overloaded across local installation roots, user-private host settings, worktree-local state, and project-local overrides. Required correction: label the four-way map as reviewer/report inference, place durable debug artifacts under Project, show the workstream fallback as dual-scope, and split Local into runtime install/config and worktree-local subscopes.

## Independently validated claims

### Inventory, citations, and surfaces

| Check | Result |
|---|---|
| pin and branch | exact `33985c11...`, `next`, clean, `origin/next` |
| inventory paths/hashes | 2,730/2,730; missing 0; extra 0; mismatch/error 0 |
| gear flags | 2,725 true; five named assets false |
| citations | 98 total, 96 unique ranges, 41 source files; bad path/range 0 |
| capability manifests | 44 = 20 feature + 5 reviewer + 19 runtime |
| install runtime split | 18 CLI-selected runtimes + separate VS Code descriptor |
| agents | 34; 10 with explicit adversarial stance; only debug session manager has Agent delegation |
| commands/skills | 71/71; generated skill check passes |
| workflows/references | 91 root Markdown workflows, 117 total workflow files; 97 root references, 115 total |
| hooks | 25 managed JS/shell hooks; 30 tracked hook-area files total |
| OpenCode/Kilo adapters | byte-identical SHA-256 `71E892E5...C166E758` |
| history | all seven cited short commits exist and their subjects match the stated architectural changes |
| license | MIT; 2026 Open GSD; notice-retention and warranty terms represented accurately |

### Architecture, registry, plugins, agents, skills, hooks, and workflows

The report's core control-flow account is supported: host command/skill/palette surface → canonical command adapter → workflow → deterministic CLI and optional loop contributions → specialist agent(s) → `.planning` artifacts. Canonical source/derived ownership, descriptor-driven layout/conversion, capability overlay consent, first-party precedence, active/enabled state composition, bounded planning/execution loops, state-transition intent union, worktree manifest ownership, agent tool asymmetry, plugin/embedded-host roles, and mixed fail-open/fail-closed hook policy are all materially consistent with the pinned source.

The hook graph matches `hooks/hooks.json`; the 12 loop points and artifact edges match the generated contract after correcting the three role rows. The command/workflow hand-offs and the 14 self-contained versus 8 multi-workflow router counts are reproducible. The report appropriately treats prompt scanners as advisory/fail-open by default and shell-capable prompts as non-sandboxed.

### Generated and runtime checks

| Check | Independent result |
|---|---|
| generated-sync in built runtime clone | exit 0; all listed generators/parity checks green |
| inventory-manifest check in source checkout | exit 1; 156 ignored/unbuilt CLI modules absent |
| environment gate | exit 0; Node 22.23.2, npm 10.9.8, lockfile and `.nvmrc` checks pass |
| issue-607 installer dry-run test | 5 pass, 0 fail |
| composed `@`-reference contract test | 1 pass, 0 fail |
| claimed 18-file bundle | not reproducible from submitted artifact; exact file list/command absent |
| two timeout runs | classification sensible, execution evidence absent |

## Required corrections before acceptance

1. Replace the byte/line/NUL and top-level census with correct, explicitly defined sets that independently sum to 2,730 and 2,725.
2. Produce a terminal reference ledger for the whole tracked behavioral surface; do not infer zero-gap traversal from hashes plus selected generated checks.
3. Persist exact commands and logs for the 865-pass bundle and timeout runs, or downgrade them to unverified coordinator reports.
4. Correct Discuss/Verify/Ship roles in the loop table.
5. Qualify generated-sync as a built-runtime result and distinguish 17 tracked CJS files from 173 post-build roster entries.
6. Reframe Global/Project/Session/Local as an inference and correct debug/workstream scope.
7. Re-run citation/range, census arithmetic, generated-sync, selected runtime, and final clean-state checks after editing the report.

## Residual limits after correction

- No supported vendor host was live-tested; descriptor/test evidence is not vendor certification.
- Network reviewers, MCP services, Graphify, search providers, registry/update paths, credentials, paid APIs, and production services remain untested.
- Full install and grouped Codex suites remain incomplete until rerun with persisted output and an adequate timeout budget.
- Windows cannot independently exercise Unix FIFO, symlink, and invalid-filename cases skipped by the suite.
- Generated parity only covers registered/generated surfaces; prose and unregistered references still need separate drift controls.
- Aggregate full-file reading cannot prove semantic comprehension of 2,725 files; only a per-file/reference evidence ledger can close that claim.

## Final assessment

The report should be retained and corrected rather than discarded. Its architectural explanation, registry/runtime inventory, role model, workflow/state analysis, security framing, reuse guidance, and license treatment are valuable. The current submission is not acceptable as an **exhaustive zero-gap report** because the central census uses the wrong file set, terminal references are not auditable, and decisive runtime evidence is missing. After the seven corrections above, a focused re-review should be sufficient.
