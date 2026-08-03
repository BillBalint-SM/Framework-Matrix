# Upstream source pinning

The snapshots in this directory are source evidence for the research. They
were exported from clean local checkouts with `git archive` and therefore do
not contain nested `.git` directories or dependency/runtime trees.

| Candidate | Upstream | Branch | Commit |
|---|---|---|---|
| GitHub Spec Kit | `https://github.com/github/spec-kit.git` | `main` | `d1e86f638277a99b82715c22c90558cd58d3cffd` |
| OpenSpec | `https://github.com/Fission-AI/openspec.git` | `main` | `45cca5db6137ed209117cc70510eb3e057fb981b` |
| GSD Core | `https://github.com/open-gsd/gsd-core.git` | `next` | `33985c11a9f0a27443f8b8fb114b2122d653cd78` |
| PAUL | `https://github.com/ChristopherKahler/paul.git` | `main` | `960b05c0b8e1f876f49674a700c9a087afebb8ac` |
| BMAD Method | `https://github.com/bmad-code-org/BMAD-METHOD.git` | `main` | `770d4259853b9600680745bb2c710bee82604cb4` |

Each snapshot retains the upstream license and notice files present at its
pinned commit. The research reports and evidence ledgers remain the authority
for what was observed, executed, rejected, or merely proposed; the snapshots
are not an instruction to install or run the upstream frameworks.
