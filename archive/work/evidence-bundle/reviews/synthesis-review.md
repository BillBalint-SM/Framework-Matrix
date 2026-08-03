# Independent cross-framework synthesis review

## Verdict

**REVISE AND RE-REVIEW — no P0.** A reusable-pattern catalog és a system-design DOCX szerkezetileg koherens, a 15 patternből 9 teljesen megfelel a hivatkozott repository evidence-nek, 6 pedig jó irányú, de a jelenlegi provenance/minősítés a közvetlen forrástényt összemossa a célrendszer clean-room, S3 designjával. A DOCX `Proposed` státusza helyesen jelzi, hogy nem kész runtime dokumentációja, és a legtöbb állítása konzisztens a katalógussal. Elfogadás előtt azonban a hat részleges pattern evidence-határát, a GSD failure semanticsot, a négy scope elemzői jellegét és a Paul runtime-következtetés megfogalmazását pontosítani kell.

| Severity | Count |
|---|---:|
| P0 — critical | 0 |
| P1 — major | 1 |
| P2 — medium | 3 |
| P3 — low | 2 |

## Scope, snapshot, and method

- Catalog snapshot: `outputs/06-reusable-pattern-catalog.md`, 37,067 byte, SHA-256 `12A8A8F5B97ADF452B46BDDA4FE44C6EBEBEBBA144BA5497D4F6099C2869848A`, modified 2026-08-02 15:49:28 local time.
- DOCX snapshot: `outputs/sdd-framework-system-design.docx`, 501,932 byte, SHA-256 `8EC1776C4E412466010F4A94CD320927AC4E82FE83C9C6C8F602B9EE9593FC63`, modified 2026-08-02 15:23:58 local time.
- Source pins independently refreshed and clean: OpenSpec `45cca5d`, Spec Kit `d1e86f6`, BMAD `770d425`, GSD `33985c1`, Paul `960b05c`.
- The catalog contains exactly 15 numbered patterns. All 34 short commit/path/line citations and all 5 pinned GitHub blob citations resolve to existing files and valid line ranges: 39/39 mechanically valid.
- The DOCX was read from complete OOXML paragraph/table content and rendered to seven pages. All seven pages were inspected; no clipping, overlap, missing text, or unreadable table was found. Layout was not a requested acceptance dimension, so no visual finding is raised.
- No candidate repository, catalog, or DOCX was modified by this review.

## Fifteen-pattern cross-check

| # | Pattern | Source match | Layer match | QA result |
|---:|---|---|---|---|
| 1 | Filesystem-derived Artifact DAG | OpenSpec schema/dependency/readiness evidence is direct | Project; pinned graph in Session | **PASS** |
| 2 | Canonical IR → host-native adapters | Host projection and descriptor data are real; the unified IR and exclusive adapter responsibility are synthesized | Global registry, Project projection | **PARTIAL — S3 boundary/citation range** |
| 3 | Pure `MaterializationPlan` + hash ownership | Hash/path/symlink/uninstall evidence is direct; a single pure plan for every lifecycle operation is broader than the cited manifest | Project ownership, Local staging | **PARTIAL — planner claim needs its own source/S3 label** |
| 4 | Global → Project → Session → Local precedence | OpenSpec project config and BMAD structural precedence are direct; the common four-layer resolver is not an upstream contract | All four | **PARTIAL — whole model is S3** |
| 5 | Role contract + fresh-context sub-agent | GSD producer/checker roles and fresh invocation are supported | Global/Project/Session/Local split is coherent as target design | **PASS** |
| 6 | Producer/checker bounded repair loop | GSD cap/stall behavior and BMAD review loop are supported | Session | **PASS** |
| 7 | Typed workflow algebra + human gates | Spec Kit gate behavior is direct; common algebra is explicitly S3 | Global schema, Project definition, Session PC | **PASS** |
| 8 | Closed event/contribution bus | Registries/contributions exist, but the proposed fail-closed bus is stronger than current GSD/Spec Kit behavior | All four | **PARTIAL — current-vs-target failure semantics** |
| 9 | Durable Run Journal + atomic transition | BMAD memlog body/frontmatter/atomic-write distinction is exact; full journal is labeled S3 | Session, archived evidence in Project | **PASS** |
| 10 | Consent-bound project extensions | GSD external consent store, realpath identity, bundle hash, disclosure and re-consent are supported | Global trust, Project request, Local code | **PASS** |
| 11 | Manifest-scoped worktree sandbox | GSD manifest ownership/recovery gates are supported | Local sandbox, Project evidence, Session owner | **PASS** |
| 12 | Progressive disclosure + reference index | GSD positive evidence is cited; the Paul installed-reference counterexample is correct but not cited in this pattern | Project graph, Session context, Local paths | **PARTIAL — missing Paul evidence link** |
| 13 | Preview-before-destructive merge | OpenSpec computes operations before apply; generalized transaction journal is labeled S3 | Project mutation, Local staging, Session approval | **PASS** |
| 14 | Generated parity + cross-platform contract tests | BMAD generation-hash check is cited; the Spec Kit/GSD S2 breadth and runtime comparison are not locally evidenced here | Global contract, Project CI, Local roots | **PARTIAL — incomplete multi-source provenance** |
| 15 | PLAN–APPLY–UNIFY vocabulary | Paul phase semantics and MIT boundary are directly cited; typed implementation is labeled S3 | Project vocabulary, Session macro-state | **PASS** |

## Severity-ranked findings

### P1-1 — Six patterns present mixed source fact and target design under an over-broad provenance grade

The systemic issue is not that the proposed mechanics are poor; it is that the catalog's own S1/S2/S3 contract is not applied at sentence level. Six patterns therefore read as more directly implemented or runtime-validated than the pinned sources establish:

1. Pattern 2 cites `base.py:L1533-L1603`, which is the `SkillsIntegration` path/destination/invocation specialization, and the GSD config-intent registry. Those ranges support host adapters and descriptor-driven layout, but not a unified canonical representation containing roles, workflow steps, events, capabilities and artifact contracts, nor immutable hashed generations and parity as one existing subsystem. Those are S3 target-design statements.
2. Pattern 3's manifest ranges support hashes, path confinement, symlink handling, safe uninstall and atomic manifest save. They do not establish the preceding pure planner that emits every `create/update/delete/preserve/conflict` operation and is consumed unchanged by preview and execution. Spec Kit does have a narrower same-plan `info/install` resolver (`d1e86f6:src/specify_cli/bundler/services/resolver.py:L1-L7`), but the generalized transaction remains S3.
3. Pattern 4's common four-scope resolver is synthesis. OpenSpec contributes a project schema; BMAD contributes layered structural merge. Neither source defines the catalog's uniform `Global → Project → Session → Local` contract.
4. Pattern 8 cites a GSD capability ADR for the generated registry and planned/runtime overlay, but not the closed event algebra, validated contribution intent, or proposed fail-closed policy. The catalog itself calls the vendor-neutral bus S3, while the preceding mechanism and `S1` grade blur that boundary.
5. Pattern 12 names Paul as negative evidence but gives no Paul source/runtime citation beside the claim. The exact supported statement is: 58 concrete installed `@src/...` paths have no distributed target, 46 are execution-relevant, and 17 command closures reach one; actual Claude resolution was not executed.
6. Pattern 14 cites only BMAD's immutable generation verification while grading Spec Kit + GSD + BMAD as S2. The assertion that isolated targeted suites proved themselves “much more informative” than a timed-out monolithic suite is an analyst judgment, not a repository fact, and the earlier GSD review found no persisted harness output for the aggregate run.

**Required correction:** split each mechanism into `(a)` observed source behavior with exact citation and `(b)` clean-room target contract marked S3. Add the missing Spec Kit resolver, GSD loop/event, Paul installer/reference-closure, and Spec Kit/GSD parity evidence, or narrow the provenance claim.

### P2-1 — The four-layer model is a sound target taxonomy, not a shared upstream persistence model

The layer table at catalog lines 27–34 and Pattern 4 are internally useful, and the DOCX consistently uses the same scopes. But the corrected BMAD and GSD evidence explicitly warns against treating their storage as four uniform peer layers:

- BMAD `.memlog.md`, story/spec state and sprint state are persistent Project artifacts even when a Session mutates them. BMAD's “Local” user config is logically personal but physically project-local.
- GSD debug/workstream files can be durable Project artifacts; active-workstream state has both temp Session and project fallback forms. GSD “Local” spans install/config and worktree-local concerns rather than one persistence owner.
- A linear-looking `Global → Project → Session → Local` order must not imply that later scopes may override Global trust/policy. The catalog's `forbidOverride` precondition helps, but this invariant belongs in the core layer definition, not only in Pattern 4.

**Required correction:** label the complete four-layer model as S3 target architecture in both deliverables. Define precedence per key/owner, with non-overridable Global policy/trust keys; state explicitly that physical location and logical ownership can differ. The DOCX may retain `scope` as a proposed enum because its front matter says `Proposed`.

### P2-2 — Pattern 8's fail-closed event semantics are a hardening proposal, not current GSD/Spec Kit behavior

Catalog lines 211–229 require security/policy handlers to fail closed and forbid silent no-op behavior for missing executable handlers. This is desirable target behavior, but it must not inherit `S1` from the cited frameworks:

- GSD's current optional loop contribution load is warning + fail-open, and unexpected safety-hook exceptions generally fail open; only positively recognized violations may block (`work/research/open-gsd-gsd-core-agent-report.md`, failure matrix and hook analysis).
- Spec Kit's native event dispatcher can return success when a referenced command is missing or prompt-only, so automation may silently no-op (`work/research/github-spec-kit-agent-report.md`, lines 500–502).

**Required correction:** mark the fail-closed split as S3 clean-room hardening. Cite the actual GSD loop resolver/contract and Spec Kit event dispatcher, then state which observed behaviors are being deliberately changed.

### P2-3 — The DOCX reintroduces ambiguous Paul “broken runtime” language

DOCX section 3/page 2 says Paul's installed references are “bizonyítottan töröttek”; section 10/page 6 says “58 törött installed reference”. The repository evidence proves a distribution-graph defect: 58 concrete installed `@src/...` references have no target in the emitted tree. It does **not** prove that Claude Code always fails, because the actual `@` parser/root semantics and model behavior were not run; project-relative resolution could also shadow the missing framework path.

The catalog is more careful: Patterns 12 and 15 reject raw paths/install behavior without claiming a demonstrated Claude crash. The DOCX should use the same qualification.

**Required correction:** replace the two phrases with “58 concrete installed references have no distributed target; actual Claude runtime failure remains an inference.” The missing CARL distribution and prompt-only enforcement statements may remain; both are source-supported.

### P3-1 — The DOCX's source-fact versus proposed-contract boundary is implicit rather than traceable

The title block's `STATUS Proposed` prevents most present-tense architecture statements from becoming literal claims about an existing implementation. Even so, exact target choices—`RunEnvelope` fields, `framework/schemas/` and `framework/adapters/`, single-writer/fsync behavior, `>=99%` SLO, release gates and the four-level scope enum—have no evidence tier or source mapping inside the DOCX. A reader can distinguish proposal from implementation only by remembering the title page.

**Recommended correction:** add a compact “Evidence status” note: candidate behavior = S1/S2, vendor-neutral contract/SLO/directory names = S3 proposed design. Link the five dossiers and the catalog or add a short source-to-design matrix. No claim needs removal merely because it is a proposal.

### P3-2 — `Direct reuse` combines an MIT obligation with a stronger internal provenance policy

The catalog's licensing conclusion is substantially correct: all five pinned repositories contain MIT licenses; direct copying of the Software or substantial portions requires the copyright and permission notice; BMAD separately publishes trademark rules; clean-room implementation is an engineering/coupling/branding choice, not an MIT requirement. Pattern 9 also correctly qualifies BMAD memlog as append-only only for the body while frontmatter remains mutable.

The definition at catalog line 22 says both “licencnotice” and “upstream provenance” are mandatory for direct reuse. MIT mandates the notice, not an arbitrary provenance metadata format. Upstream provenance is an excellent project policy, but should be labeled as such. The DOCX decision to build a clean-room vendor-neutral core is consistent with the catalog as an architecture choice; it should not be described as legally required.

**Recommended correction:** split the rule into “MIT obligation: retain notice for copies/substantial portions” and “project policy: retain commit/file provenance for every direct reuse.”

## Framework-risk qualification

| Framework | Result |
|---|---|
| Paul | Catalog treatment is accurate: reuse the vocabulary, not the installer/raw references/prompt-only controls. DOCX needs the runtime-inference wording in P2-3. |
| BMAD | Content-addressed generation, config precedence, ownership-aware cleanup and memlog semantics are represented accurately. The dependency-install catch-and-continue risk is also correctly present in the anti-pattern list, though adding its exact BMAD citation would improve traceability. |
| GSD | Consent and manifest-scoped worktree claims are source-supported. The catalog must distinguish these strong controls from fail-open optional contributions and unexpected hook failures; “GSD-derived” must not imply every proposed policy is already enforced. |

## Acceptance checklist

- [ ] Reclassify Patterns 2, 3, 4, 8, 12 and 14 at sentence level; add or narrow evidence.
- [ ] Mark Global/Project/Session/Local as the target framework's S3 taxonomy and define protected Global keys.
- [ ] State current GSD/Spec Kit fail-open/no-op behavior next to the proposed closed bus.
- [ ] Qualify the two Paul sentences in the DOCX as distribution-graph facts plus runtime inference.
- [ ] Make the DOCX's S1/S2 evidence versus S3 proposal boundary explicit.
- [ ] Separate MIT notice obligation from the project's stronger provenance policy.
- [ ] Re-run 15-pattern, citation-range, DOCX text and cross-document terminology checks after correction.

## Final assessment

The synthesis is architecturally strong and directionally safe. No P0 issue, invented license, false source pin, or unsupported claim of a completed vendor-neutral runtime was found. The remaining gap is epistemic precision: direct source behavior, independently observed runtime behavior and proposed clean-room hardening must remain visibly separate. After the six targeted corrections above, a focused re-review should be sufficient.
