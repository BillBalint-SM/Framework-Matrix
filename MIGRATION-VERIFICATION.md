# Migration verification

This document records the local read-back for the initial Framework-Matrix
project import.

| Check | Result |
|---|---:|
| `outputs/` files copied | 13 |
| `outputs/` source/hash differences | 0 |
| archived non-runtime work files copied | 608 |
| archived work source/hash differences | 0 |
| upstream tracked files in `sources/` | 5,027 |
| upstream snapshot missing files | 0 |
| nested `.git` directories in snapshots | 0 |
| evidence ZIP entries | 184 |
| evidence ZIP readable | PASS |
| System Design DOCX readable as ZIP package | PASS |

SHA-256 read-back:

- `outputs/sdd-framework-evidence-bundle.zip` —
  `7C4E84D5D672AECFB3A92EA87ABD03DBFB902012B8AD185B6EF9ACC6A5325245`
- `outputs/sdd-framework-system-design.docx` —
  `ED19B49730E1E2DFB42B0459039C070BA683D3F3118CA8296B83426C0F8E7FA2`

The source snapshot contains two upstream JSONC files (`.devcontainer` files)
that are intentionally not strict JSON; all other JSON parsing checks passed.
The synthetic token strings present in upstream tests and the adversarial
fixture are test data documented by the evidence bundle, not credentials.
