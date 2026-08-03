# Independent review: BMAD-METHOD agent architecture report

## Verdict

**REVISE BEFORE ACCEPTANCE.** The report is strong on the repository's main architecture and gets most high-level inventories right, but it does not meet the brief's zero-gap/evidence contract. Three major findings affect auditability or omit material failure behavior; seven medium findings require factual or architectural correction; one low finding needs qualification.

| Severity | Count |
|---|---:|
| P0 — critical | 0 |
| P1 — major | 3 |
| P2 — medium | 7 |
| P3 — low | 1 |
| **Total** | **11** |

Acceptance should be withheld until P1 findings are corrected and P2 factual statements/citations are repaired. No source changes are requested or authorized; corrections belong only in the research report.

## Review scope and current state

Reviewed:

- brief: `work/briefs/bmad-method-research-brief.md`;
- submitted report: `work/research/bmad-method-agent-report.md`;
- pinned repository source, tests, docs, manifests, installer, renderer, skills, modules, platform config, license, and trademark notice;
- selected runtime checks reproduced independently on Windows/PowerShell.

Current work state at review start:

```text
WORK_STATE: fresh=2026-08-02T13:00:32.3298133Z; repo=work/repos/bmad-method; branch=main; head=770d4259853b9600680745bb2c710bee82604cb4; worktree=clean; upstream=origin/main; pr=2632/OPEN raw provider evidence; evidence=local+remote
```

The unrelated `main -> main` provider PR remains raw discovery evidence only. No branch, source, commit, push, install, or publication operation was performed.

## Zero-gap coverage assessment

**Result: NO — zero-gap coverage is not established.**

The report demonstrates broad structural coverage: the tracked-file census is exact, all source/test/config file types were enumerated, every skill ID is listed, core subsystems are described, and important static/runtime checks were run. It does not demonstrate the brief's required terminal coverage for all internal references or all behavior-defining tests:

1. the dependency-backed reference validator did not run, while only docs links and snapshot tokens were independently closed in the report;
2. the runtime table substitutes `<11 self-contained suites>` for the actual file list;
3. two additional dependency-free Python suites were omitted from that selection, including one that produces four Windows failures;
4. external modules, full installer integration, global host targets, full quality gates, and live host-agent behavior remain explicitly unresolved;
5. the evidence index groups large globs and subsystems but does not provide a file-by-file terminal/reference ledger proving the claimed manual traversal of every behavior-bearing Markdown/config artifact.

As an independent cross-check, I reproduced the principal inventories and implemented a read-only standard-library/PyYAML equivalent of the repository's file-reference extraction/resolution logic. It scanned 202 source Markdown/YAML/XML/CSV files, resolved 187 statically resolvable references, and found 0 broken targets, 0 absolute-path leaks, and 0 parse failures. That reduces the likelihood of an actual broken reference, but it does not repair the report's missing exact command/evidence record.

## Severity-ranked findings

### P1-1 — Runtime evidence is not reproducible and omits two runnable suites

**Report locations:** lines 330–362, especially line 341.

The brief requires exact commands, exit codes, relevant output, and root causes. The report records:

```text
python -m pytest -q -p no:cacheprovider <11 self-contained suites>
```

`<11 self-contained suites>` is a placeholder, not an executable command. Several other rows similarly shorten the command to a script basename or prose description rather than preserving full paths/arguments. This prevents independent reproduction of the claimed `147 passed` result.

The placeholder conceals a material selection gap. The 147 tests are exactly the 11 core/shared suites. Two more dependency-free suites exist and run in the same environment:

- `src/bmm-skills/plan/bmad-architecture/scripts/tests/test_lint_spine.py`: independently reproduced **28 passed**;
- `src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_git_evidence.py`: independently reproduced **27 passed, 4 failed**.

The Git-evidence failures occur in tests that prepend POSIX `#!/bin/sh` fake-`git` files to `PATH`. On Windows, those shims are not selected as executables, so the real Git runs instead. Evidence:

- fake shim creation and PATH overlay: `src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_git_evidence.py:480-520`, `561-605`, `660-668`;
- four observed failures: non-UTF-8 path separation, repeated merge-header dedupe, invocation recording, and empty-stderr exit-code reporting.

These are primarily test-portability failures, not proof that production `git_evidence.py` is wrong. They are still required runtime evidence and extend the report's Windows-blind-spot analysis beyond the skill validator and renderer tests.

**Required correction:** replace every pseudo-command with the exact command and full argument list; add the architecture suite result; add the Git-evidence suite's 27/31 result, four failure names, observed output, and Windows shim root cause. State explicitly which of the 15 Python test files were and were not executed.

### P1-2 — The required complete internal-reference closure was not performed or evidenced

**Report locations:** lines 209–213, 328, 353, 362, 446.

The report correctly says `node tools/validate-file-refs.js --strict` could not run because `yaml` was absent. It then limits its positive result to docs links and 39 snapshot-token occurrences. The brief, however, required following **every internal reference** to executable code, dependency, generated artifact, or terminal endpoint.

The repository validator covers more than docs/snapshot links: project-root mappings, `_bmad` shorthands, relative file paths, `exec="..."`, `<invoke-task>`, step metadata, load directives, CSV workflow-file references, and absolute path leaks (`tools/validate-file-refs.js:1-18`, `34-66`, `182-327`). The report does not provide an equivalent complete ledger or result.

Independent review found no breakage in a faithful read-only reimplementation (202 files, 187 references, 0 broken, 0 leaks), so this is presently an evidence-contract gap rather than a confirmed repository defect.

**Required correction:** either run the official validator in a disposable dependency-provisioned checkout and record its exact output, or include an exact, reproducible dependency-free equivalent plus counts by reference class and a path-level exception ledger. Do not claim zero broken internal references from docs/snapshot checks alone.

### P1-3 — Dependency-install failure semantics are omitted from security/failure analysis

**Report locations:** lines 276–280, 306–318, 435.

The report identifies `npm install` in cloned modules as a supply-chain execution boundary, but it misses a separate reliability/security property: both official-external and custom-module managers catch dependency-install failures, emit a spinner error/warning, and still return the cache directory as usable.

- official modules: `tools/installer/modules/external-manager.js:448-502`;
- custom modules: `tools/installer/modules/custom-module-manager.js:556-575`.

This means a module can continue through resolution/installation with absent or stale production dependencies. In silent mode, the detailed exception warning is suppressed. This is exactly the kind of fallback/partial-success behavior the brief's failure-mode analysis must surface.

**Required correction:** add this to failure semantics and weaknesses; distinguish clone/ref success from dependency readiness; explain the possible partial-install state and the lack of rollback/fail-fast propagation. Include the current timeout (120 seconds), command flags, lifecycle-script exposure, and silent-mode observability consequence.

### P2-1 — The install call graph omits the pinned commit's two-phase `--set` behavior

**Report locations:** lines 217–238.

The graph shows configuration generation followed by `--set` application. That late patch still exists, but the pinned commit's defining change occurs earlier in the UI collection path: `setOverrides.core` seeds core configuration **before** dependent module configuration is collected (`tools/installer/ui.js:780-835`). The late TOML patch then still applies all selected overrides after central config files are generated (`tools/installer/core/installer.js:295-342`).

The report mentions the early ordering in prose at line 238 but does not place it in the call path or explain why two phases exist. A reader could infer that the pinned fix moved all `--set` work earlier, which is false.

**Required correction:** show both phases:

```text
parse/filter --set
  -> seed core overrides before config collection
  -> derive dependent module paths/config
  -> generate central/module config files
  -> post-write applySetOverrides patch for core and non-core values
```

### P2-2 — Test inventory count is factually wrong and script labeling is misleading

**Report location:** lines 38–52.

The report says “24 top-level test files plus colocated Python test suites.” The pinned tree has:

- 11 top-level files under `test/`;
- 10 top-level executable test files (8 `.js`, 2 `.mjs`) plus `test/README.md`;
- 24 **tracked paths total** under `test/`, including fixtures/subdirectories;
- 15 colocated Python test files under `src/**/scripts/tests/`.

It also labels all 31 `.py` and 65 `.js`/`.mjs` tracked files as “Runtime scripts,” even though those counts include tests, build tools, configs, and website code.

**Required correction:** replace the test row with the exact 11/10/24/15 breakdown and relabel language-extension counts as tracked Python and JavaScript/ESM files, then separately count runtime, installer, tool, test, and website files if those categories matter.

### P2-3 — The 45-host claim overstates pointer generation and physical copying

**Report locations:** lines 24, 63, 75–81.

All 45 platform profiles are real, and every profile has an installer target. However:

- only `github-copilot` and `opencode` configure `commands_target_dir`, so only those two receive extra generated command pointer files;
- 25 platform codes share the `.agents/skills` project target, and batch setup deduplicates writes to shared targets;
- other hosts consume the copied native Agent Skills directory directly.

The phrases “copied verbatim to 45 configured host platforms, with generated host pointers” and “emits host-specific command/agent pointers” imply one physical copy and pointer set per host. The source supports 45 profiles, not that uniform artifact shape. The cited range `platform-codes.yaml:3-14` describes the schema but does not enumerate the 45 entries.

Evidence: `tools/installer/ide/platform-codes.yaml:15-343`; conditional pointer generation and shared-target deduplication at `tools/installer/ide/_config-driven.js:218-257`, `266-405`.

**Required correction:** say that 45 profiles map hosts to project/global skill directories; shared targets are deduplicated; all install native skill directories; only configured platforms receive auxiliary command pointers.

### P2-4 — Project-persistent state is misclassified as Session state

**Report location:** lines 83–92.

The Session row includes story/spec status and append-only `.memlog.md`, but both are durable project files. `memlog.py` explicitly says logs persist across sessions (`src/scripts/memlog.py:5-12`), and story/spec status is written into project artifacts. These belong in the Project layer, even though an active session reads and mutates them.

**Required correction:** restrict Session to active persona, resolved prompt context, transient workflow variables, current dispatch choice, and model/subagent context. Move memlogs and story/spec/sprint statuses to Project. Keep Local/personal as a logical ownership/precedence layer while noting that its files physically live inside the project.

### P2-5 — The displayed build state machine uses non-canonical status names

**Report location:** lines 102–117.

The report presents:

```text
intent/draft -> planning -> ready-for-development -> implementation -> in-review -> done
```

The actual frontmatter status vocabulary is:

```text
draft -> ready-for-dev -> in-progress -> in-review -> done
```

Build Auto additionally permits `blocked` (`src/bmm-skills/ship/bmad-build/spec-template.md:1-7`; `src/bmm-skills/ship/bmad-build-auto/spec-template.md:1-7`). “Planning” and “implementation” are workflow phases, not stored statuses; “ready-for-development” is the standard's prose name, while the persisted value is `ready-for-dev`.

**Required correction:** separate conceptual phases from exact persisted states, and include `blocked` for Build Auto.

### P2-6 — Critical-claim citation coverage is incomplete, and three evidence-index paths are non-resolvable

**Report locations:** throughout; evidence index lines 453–482.

Positive result: all 42 commit-prefixed citation starts resolve to existing files and their stated line endpoints are within file bounds. They cover 25 unique primary-source files.

Problems:

1. the 45-host list cites only the schema header (`platform-codes.yaml:3-14`), not the entries that establish the inventory;
2. the distribution/compiler paragraph cites `package.json:21-28`, which proves CLI aliases but not module selection, config generation, manifests, or host dispatch;
3. activation behavior for all persona/workflow skills is generalized from a single analyst example;
4. the install/update/recovery section contains many critical behavioral claims without commit+file+line citations;
5. the evidence index uses three non-resolvable shorthand paths: `bmad-build-auto/step-04-review.md`, `bmad-build/step-05-present.md`, and `bmad-sprint-planning/scripts/sprint_plan.py` rather than repository-root-relative paths;
6. several compound citations repeat only a line range after a comma or omit the commit on the second file, weakening mechanical traceability.

**Required correction:** use one mechanically resolvable format for every critical claim, preferably `770d425:<repo-relative-path>:Lx-Ly`; cite the exact platform entries/installer methods; expand evidence-index shorthands to full paths; add citations to operations, recovery, module install failure, and host deduplication claims.

### P2-7 — The workflow inventory does not identify all terminal/compatibility semantics precisely

**Report locations:** lines 199–213 and the lifecycle graph at lines 170–197.

The compatibility graph usefully distinguishes forwarding shims from two self-contained legacy workflows, but the primary lifecycle graph collapses several shipped terminal paths: one-shot Build, halt-after-planning, blocked result-file creation, preview-only checkpointing, and ad hoc review. Because the brief requests state transitions, loops, and proven terminal endpoints, the synthesis graph should label these branch/terminal outcomes instead of showing only the happy path.

**Required correction:** add the major branch terminals (`done`, `blocked`, `ready-for-dev` halt, one-shot commit completion, no-VCS completion), identify which are prompt-enforced versus script-enforced, and map Checkpoint Preview/QA E2E/ad hoc Code Review as side-entry workflows rather than only downstream boxes.

### P3-1 — “Append-only memory” needs a metadata-scope qualification

**Report locations:** lines 89, 125–129, 402–409.

The memlog body is append-only and has no edit/delete subcommand, but `memlog.py` also exposes `set`, which replaces descriptive frontmatter fields (`src/scripts/memlog.py:61-67`, `110-129`). The report's reusable-pattern wording can be read as saying the entire file is immutable except for appended lines.

**Required correction:** state that log entries are append-only while descriptive frontmatter is mutable through `set`; lifecycle status remains forbidden and must be an appended event.

## Citation validation summary

| Check | Result |
|---|---|
| Commit identity in report | correct: `770d4259853b9600680745bb2c710bee82604cb4` |
| Commit-prefixed citation occurrences | 42 |
| Unique commit-prefixed source paths | 25 |
| Missing commit-prefixed paths | 0 |
| Out-of-bounds commit-prefixed ranges | 0 |
| Non-resolvable evidence-index shorthands | 3 |
| Semantic support | mixed; several broad claims cite only headers/entrypoints or no source range |
| Critical-claim contract | not satisfied until operations, host behavior, failure semantics, and full runtime commands receive precise citations |

## Independently validated claims

The following important claims are correct at the pinned snapshot:

- repository state: clean `main`, exact pinned HEAD, `origin/main`, `git describe` = `v6.10.0-52-g770d4259`;
- package identity/version/bin aliases/license in `package.json`;
- 618 tracked files and 7,384,940 bytes;
- extension counts: 403 Markdown, 56 JavaScript, 9 MJS, 31 Python, 36 TOML, 20 YAML, 11 JSON;
- 48 canonical skills: 34 BMM and 14 core, with the listed active/shim breakdown;
- five BMM personas and the analyst menu drift;
- six local Claude marketplace packages;
- seven official external module entries, one deprecated, with BMad Loop using marketplace-plugin resolution;
- 45 platform codes, all with project installer targets, 42 with global targets;
- four-layer central config and three-layer per-skill customization, strict present-file TOML failure, structural merge semantics;
- renderer one-pass opacity, source declaration guard, project-root-bound content identity, staged directory publication, and existing-generation verification;
- Build/Build Auto mandatory/synchronous subagent rules, bounded five-iteration repair, local commit/no-push behavior;
- sprint and retrospective status vocabularies and atomic update intent;
- CRLF validator defect: independently reproduced 48/48 skills rejected with 144 findings; normalization produces zero findings;
- renderer test result: independently reproduced 20/24 on Windows with the reported failure groups;
- docs validator: independently reproduced 168 files, 0 issues;
- template sync and site URL tests: independently reproduced pass / 8 passed;
- Python prerequisite, core-skill arithmetic, analyst-menu, and workflow-map documentation drift;
- MIT code license and separate BMad trademark restrictions.

## Reusable-pattern and licensing assessment

The seven reusable patterns satisfy the requested structure: source, prerequisites, adaptation, trade-offs, provenance/license, and direct-reuse versus clean-room guidance are present. The legal distinction is substantially correct:

- source code is MIT licensed and substantial copied portions must retain the notice (`LICENSE:1-21`);
- BMad names, marks, logo, and branding are separately reserved (`LICENSE:22-27`; `TRADEMARK.md:1-50`);
- the trademark guide explicitly permits use of the software, compatibility references, and redistribution under a distinct name.

One wording improvement is advisable: the final “clean-room, unbranded implementation is the safest default” is an engineering/branding-risk recommendation, not a license requirement. Direct unbranded reuse is expressly permitted by MIT when the notice is preserved. The report should avoid implying that trademark separation requires clean-room reimplementation.

## Required correction checklist

Before acceptance, the report should:

1. replace pseudo-commands with exact commands and arguments;
2. add the omitted 28-pass architecture and 27-pass/4-fail Git-evidence suite results;
3. complete or reproducibly emulate the full internal-reference validator and report class counts;
4. document caught-and-continued module dependency-install failures;
5. show both early core `--set` seeding and late post-write patching;
6. correct the top-level test count and language-file labels;
7. qualify the 45-host copy/pointer model and shared-target deduplication;
8. repair Project/Session state ownership;
9. use exact persisted build status names and include blocked/alternate terminals;
10. normalize every critical citation and expand evidence-index shorthand paths;
11. qualify memlog append-only semantics and the clean-room licensing recommendation.

## Residual limits of this review

- `npm ci`, the full `npm run quality`, dependency-backed installer/reference/site suites, and a real install/update/uninstall were not run because the checkout has no `node_modules` and source/environment mutation was out of scope.
- No external module repository was cloned; supply-chain conclusions concern this repository's resolver/cache/execution boundary only.
- No external host agent was launched, so current consumption of all 45 configured target paths remains unverified.
- The reference cross-check reimplemented the repository validator's documented extraction/resolution rules but is not byte-for-byte execution of the official Node validator.
- Git-evidence failures were reproduced only on the present Windows environment; their POSIX behavior remains source/test-asserted rather than independently run here.
- The research skill requested an independent background agent, but the collaboration pool was already at its thread limit. This review therefore used a single-agent local cross-check with independent reruns instead of a second agent pass.
