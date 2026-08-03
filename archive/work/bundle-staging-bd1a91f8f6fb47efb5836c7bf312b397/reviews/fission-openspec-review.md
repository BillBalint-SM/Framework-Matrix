# Adversarial review: `Fission-AI/OpenSpec`

## Verdict

**REVISE**

The report is a strong architectural synthesis and its central model is source-correct: OpenSpec is a filesystem-backed workflow compiler/state reader, not an internal agent runtime; the artifact DAG, root selection/provenance, event lifecycle, store/reference boundaries, and most workset semantics are accurately described. The tracked-file and gear inventories are mechanically complete and hash-consistent.

It is not yet acceptable as a zero-gap exhaustive report. The 1,036-row gear ledger does not demonstrate 1,036 file-specific semantic analyses, there is no complete typed reference ledger, one runtime command is syntactically invalid at the pinned commit, the report omits the now-available isolated full-suite result, and the claimed 126 TypeScript test files is false. There is also a material capability-versus-delivery semantic conflation and several critical claims exceed their citations.

No P0 finding was identified. Acceptance requires every P1 and P2 correction below. P3 items are reproducibility/evidence-quality corrections.

## Review basis

```text
WORK_STATE: fresh=2026-08-02T13:57:46.5223101Z; repo=work/repos/fission-openspec; branch=main; head=45cca5db6137ed209117cc70510eb3e057fb981b; worktree=clean; upstream=origin/main; pr=#1276/MERGED raw provider result; evidence=local+remote
```

The raw PR lookup was not used to infer analysis ownership. The pinned checkout and source report were not modified.

Reviewed artifacts:

- `work/research/fission-openspec-agent-report.md`
- `work/inventory/fission-openspec-files.csv`
- `work/inventory/fission-openspec-gears.csv`
- `work/evidence/fission-openspec/full-suite-20260802.md`
- `work/evidence/fission-openspec/full-suite.stdout.log`
- pinned analysis checkout and disposable runtime clone at the same commit

The research procedure called for a background verifier. An attempted verifier spawn was rejected because the shared agent-thread limit had already been reached, so this is an independent main-reviewer audit without the additional requested subagent cross-check.

## Findings

### P1-1 — 1,036/1,036 mechanical inventory closure is proven; per-file semantic and full reference closure are not

Independent reconciliation confirms:

- 1,041 `git ls-files` paths = 1,041 file-inventory rows, with no missing or extra path.
- Every recorded SHA-256 matches the pinned checkout.
- 1,036 `GearCandidate=True` paths = 1,036 gear rows, with no missing, extra, or duplicate gear path.
- The five non-gears are exactly four image assets and `website/app/icon.svg`.
- 1,035 gear rows are `analyzed`; `flake.lock` is `runtime-relevant-generated`.

That proves exhaustive **mechanical census/hash coverage**. It does not prove exhaustive semantic traversal. Every gear row points to the same report and carries the same generic assertion that it was covered. There is no file-specific claim/evidence locator, and many paths are neither named nor semantically classified in the report.

The reference claim has the same boundary. The report's Markdown scan is useful, and its one genuine broken historical link is correct. An independent broad Markdown-regex pass found four unresolved-looking candidates: that same historical link plus three code/example false positives (`[links](url)` twice and a `string[];` signature). The report says 296 relative references and three candidates, while the independent broad pass found 297 and four; the difference is plausibly scanner filtering, but the scanner and normalized result ledger were not preserved, so the count is not reproducible.

More importantly, Markdown links are only one reference class. There is no all-edge ledger for TypeScript imports, package exports/bin targets, workflow/template references, schema/config references, generated artifacts, CI/script references, or external dependencies. Build success supplies strong TypeScript import evidence and strict spec validation supplies current-spec evidence, but neither closes every required reference class.

Exact correction:

1. Rename the present assertion to “1,036/1,036 mechanical tracked-gear census” unless a per-file evidence locator is added.
2. Add a machine-readable gear ledger with path, semantic role, relevant claim/report locator, analysis result, and terminal classification.
3. Add a machine-readable reference ledger with source path/line, raw and normalized target, reference class, resolution result, and terminal type: executable source, external dependency, generated artifact, prose/example, or broken.
4. Preserve the scanner/version/rules so the 296-versus-297 denominator and exclusions are reproducible.

### P1-2 — Runtime section contains an invalid CLI command and is stale relative to the completed isolated suite

Report line 492 records:

```text
status fix-spec-parser-fidelity --json
```

At the pinned commit that command exits 1 with “too many arguments.” `openspec status --help` defines the change selector as `--change <id>`. The valid pinned command is:

```text
node bin/openspec.js status --change fix-spec-parser-fidelity --json
```

It exits 0 and returns `isComplete: true`, all four planning artifacts `done`, and `root.source: "nearest"`. The report's interpretation says `complete: true`, which is also not the actual field name.

The runtime table also ends with the older opt-out suite, while stronger evidence now exists. The isolated pinned run used `npx --yes pnpm@9.15.9`, `OPENSPEC_TELEMETRY=0`, `VITEST_MAX_WORKERS=2`, and temporary `APPDATA`, `LOCALAPPDATA`, `XDG_CONFIG_HOME`, and `XDG_DATA_HOME`. It passed:

```text
Test Files  119 passed (119)
Tests       3450 passed | 24 skipped (3474)
Duration    142.57s
process exit code 0; wall time 147.5s
```

The real `%APPDATA%\openspec\config.json` remained absent during that suite and the disposable checkout remained clean. This supersedes the 60-second timeout as the authoritative full-suite result. It does **not** invalidate the report's reproduced production test/config-isolation defect.

Exact correction:

1. Replace the line-492 command with `status --change fix-spec-parser-fidelity --json` and the result field with `isComplete: true`.
2. Add the isolated full-suite row and cite `work/evidence/fission-openspec/full-suite-20260802.md` plus the stdout log.
3. Label the earlier unisolated and opt-out runs as defect-reproduction history, not the best final verification state.
4. State explicitly that isolation was supplied by the external harness; it is not a repository fix.

### P1-3 — The 126-TypeScript-test-file inventory is false

Report line 436 says the test tree contains 126 TypeScript test files. The pinned Git tree contains **119** tracked `*.test.ts`, `*.spec.ts`, `*.test.tsx`, or `*.spec.tsx` files in total (118 under `test/` plus one elsewhere). Vitest independently collected and passed those same 119 files in the isolated full suite.

The report already qualifies the approximately 2,429 declaration and 605 mock counts as lexical approximations; that qualification does not cure the exact file-count error.

Exact correction: replace “126 TypeScript test files” with “119 tracked TypeScript test/spec files; the isolated Vitest run collected and passed 119/119.” Keep lexical declaration/mock counts explicitly approximate and do not compare them directly with parameterized Vitest case totals.

### P2-1 — Target capability and requested delivery mode are conflated

Report line 94 says delivery is computed from adapter availability and skill invocation, producing `skills`, `commands`, or `both`. The source models two separate concepts:

- global requested `Delivery = 'both' | 'skills' | 'commands'`, defaulting to `both` (`src/core/global-config.ts:12,29-33`);
- per-target `CommandSurfaceCapability = 'adapter-backed' | 'skills-invocable' | 'none'` (`src/core/command-surface.ts:5,17-27`).

Those two inputs determine what gets materialized. Report line 129's “other six are skills-only by configuration” is consequently too strong. The six no-adapter/non-Codex targets receive skills under `skills` or default `both`; under `commands` they receive no usable surface and their skills are removed. Codex is distinct: it remains skill-generated even when requested delivery is `commands` because its capability is `skills-invocable` (`command-surface.ts:29-38`).

The 35-target, 28-adapter, seven-no-adapter counts themselves are correct.

Exact correction: describe the global delivery preference and per-tool capability as independent axes, and replace “skills-only by configuration” with the conditional materialization behavior above. Adjust the reusable-idea wording at line 540 similarly.

### P2-2 — Several critical claims are uncited or cite ranges that do not support the whole sentence

All 150 commit citations were mechanically checked: all 113 unique `45cca5d:path:Lx-Ly` targets exist and every range is in bounds. Mechanical validity is strong, but semantic support is incomplete.

Examples requiring correction:

- Report line 394 says durable workset state precedes derived workspace “cleanup/regeneration,” but the cited `worksets.ts:L236-L275` proves lock/atomic state update only. Removal ordering is at `worksets.ts:L339-L356`; open/regeneration needs its own command/service citation.
- The 1,041 census, extension totals, `npm pack` observations, static test/mock counts, and runtime result table have no durable command-output artifact citation in the report.
- The separate 13th release-skill behavior at line 150 is uncited.
- The pinned specs-apply/archive change claim at line 398, store-setup transaction claim at line 412, CI/action-pinning claim at line 422, and Nix partial-transaction claim at line 430 are material implementation assertions without local source citations.

Exact correction: add the missing narrow source citations, cite generated evidence artifacts for observed counts/commands, and split compound sentences where one range proves only one half.

### P2-3 — The test/config isolation defect is correct and remains a source defect after the green isolated suite

This is a confirmation that must survive revision, not a contradiction:

- `test/commands/spec.test.ts:58-68` spawns the real CLI without telemetry opt-out or isolated config/data roots and asserts stdout equals the raw spec.
- `src/telemetry/index.ts:167-184` prints the first-run notice to stdout and persists `noticeSeen`.
- `src/telemetry/config.ts:131-163` resolves and writes the global config path.
- `test/telemetry/index.test.ts:14-23` redirects only `HOME`; on Windows it leaves `APPDATA`/XDG effective. Tests later remove opt-out variables and exercise enabled telemetry.

During this adversarial review, one accidentally unisolated valid `status --change` invocation reproduced the write again, creating the real 107-byte `%APPDATA%\openspec\config.json`. The exact reviewer-created file was immediately removed and absence was verified. This confirms the report's root cause with an independent CLI path, not only the original failing test.

Exact correction: keep the defect and recommended fix. Add that a green externally isolated suite proves the tests can pass safely under a controlled process environment, while the repository's default test harness and normal CLI first-run behavior still write global user state. The remedy remains test-owned/injected config and data roots plus a negative assertion that the real user path is untouched.

### P3-1 — Runtime exit evidence and Markdown scan need a stricter provenance distinction

`full-suite.stdout.log` contains the Vitest summary but does not literally contain `EXIT_CODE=0`; that value came from the process/tool result and was reconstructed in the Markdown evidence's “Terminal summary.” The value is credible, but the label should not imply it was verbatim stdout.

Exact correction: label the block “combined observed summary,” or separate “stdout summary” from “process exit metadata.” Preserve the exact command harness or a script so environment isolation and exit capture can be rerun.

Likewise, preserve the Markdown scanner and its output ledger rather than only prose totals. This will make exclusions such as code spans/signatures explicit and prevent denominator drift.

## Accepted critical claims

The following high-value claims survived independent source/runtime challenge:

- **Artifact DAG/state:** `proposal -> {specs, design} -> tasks -> apply`; schema validation rejects bad references/duplicates/cycles; readiness is deterministically computed from declared dependencies and output existence.
- **Root selection/provenance:** explicit store, nearest planning root, project store pointer, global default store, fail-if-stores-exist, then implicit cwd compatibility; structured responses expose selected root/source.
- **Agent model:** no model client, conversation store, internal multi-agent scheduler, or subagent orchestration primitive was found in current runtime source. Agent behavior is external-host execution of generated skills/commands. This remains a negative-search inference, properly bounded to the pinned repository.
- **Events:** Commander pre/post actions drive notice/capture/flush; no general application event bus or hook/plugin runtime was found.
- **Adapters:** 35 targets, 28 registered command adapters, seven without adapters; canonical bodies are rendered through presentation adapters.
- **Worksets/references/stores:** worksets are durable named personal views with locked/atomic state writes and derived workspace artifacts; references are read-only and one-level; stores deliberately do not fetch/pull/push.
- **Runtime:** package/build/typecheck/lint/focused checks reported by the source report are consistent with the checkout, and the new isolated full suite is fully green. Strict current-spec validation is 36/36.
- **Isolation defect:** the report's causal chain and remediation direction are correct.
- **Citations:** every existing immutable commit/path/range citation is mechanically valid; the problem is missing or semantically incomplete support, not broken citation syntax.

## Acceptance gate

**Current gate: REVISE.** Accept after all of the following are true:

1. exhaustive semantic/reference language is narrowed or backed by file-specific gear and typed reference ledgers;
2. the invalid `status` command and `complete` field are corrected;
3. the 119-file isolated full-suite evidence is incorporated and separated from defect-reproduction history;
4. the 126 test-file count becomes 119;
5. global delivery preference is separated from per-target capability/materialization;
6. the cited workset range and other uncited critical implementation/runtime claims receive narrow source or durable evidence citations;
7. the test/config-isolation defect remains explicitly unresolved at source level.

No source-report changes, repository-source changes, commits, pushes, or external mutations were made by this review. The only user-state mutation encountered was the reviewer-reproduced telemetry config file described above; it was removed and verified absent.
