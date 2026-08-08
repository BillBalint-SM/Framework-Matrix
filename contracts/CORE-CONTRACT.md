# Framework-Matrix Core Contract

Contract version: `1.0.0`

| ID | Mandatory dimension |
|---|---|
| `CC-01` | Funkció és felhasználói cél |
| `CC-02` | Trigger, input, output és side effect |
| `CC-03` | Workflow, state és terminálási modell |
| `CC-04` | Agent, role, tool és authority modell |
| `CC-05` | Config, precedence és scope-kezelés |
| `CC-06` | Artefaktum-, adat-, memória- és reference-kezelés |
| `CC-07` | Install, initialize, update, migrate, recover és uninstall |
| `CC-08` | Hibakezelés, retry, rollback, idempotencia és megszakítás |
| `CC-09` | Security, trust boundary, secret-, path- és inputkezelés |
| `CC-10` | Observability, log, audit, provenance és evidence |
| `CC-11` | Teljesítmény, futási overhead, context- és tokenhasználat |
| `CC-12` | Windows-, PowerShell-, filesystem- és hostkompatibilitás |
| `CC-13` | Tesztelhetőség, karbantarthatóság és bővíthetőség |
| `CC-14` | Licenc, eredet, supply chain és dependency-kockázat |
| `CC-15` | Dokumentáció–kód–config–teszt konzisztencia |

Every session, task, and work part validates this contract at step zero. Every
work unit records at least one affected dimension and its expected evidence.
Missing receipt, hash mismatch, unknown dimension, or an unreviewed critical
gap stops work.

Version `1.0.0` is immutable within this campaign. A content change requires
explicit human approval, a new version and hash, and impact analysis. Reports
and tasks link dimension IDs instead of copying their descriptions.
