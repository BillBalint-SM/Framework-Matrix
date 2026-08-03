# Fission OpenSpec isolated full-suite evidence

- Date: 2026-08-02
- Repository pin: `45cca5db6137ed209117cc70510eb3e057fb981b`
- Disposable clone: `work/runtime/fission-openspec-test`
- Package manager: `pnpm 9.15.9` invoked through `npx --yes pnpm@9.15.9`
- Install: `287` packages; prepare/build exit `0`
- Test runner: Vitest `3.2.6`
- Worker cap: `VITEST_MAX_WORKERS=2`
- Telemetry: `OPENSPEC_TELEMETRY=0`

## Isolation

The run redirected all configuration and data roots under `work/runtime/fission-openspec-test-user`:

```text
APPDATA=<isolated-root>/AppData/Roaming
LOCALAPPDATA=<isolated-root>/AppData/Local
XDG_CONFIG_HOME=<isolated-root>/xdg-config
XDG_DATA_HOME=<isolated-root>/xdg-data
```

The real `%APPDATA%\openspec\config.json` remained absent after the suite. The disposable checkout remained clean at the pinned commit.

## Command

```powershell
$env:OPENSPEC_TELEMETRY = '0'
$env:VITEST_MAX_WORKERS = '2'
$env:APPDATA = '<isolated-root>\AppData\Roaming'
$env:LOCALAPPDATA = '<isolated-root>\AppData\Local'
$env:XDG_CONFIG_HOME = '<isolated-root>\xdg-config'
$env:XDG_DATA_HOME = '<isolated-root>\xdg-data'
npx --yes pnpm@9.15.9 test
```

## Result

- Exit code: `0`
- Test files: `119 passed / 119`
- Tests: `3450 passed`, `24 skipped`, `3474 total`
- Vitest duration: `142.57s`
- Tool wall time: `147.5s`
- Full stdout: `full-suite.stdout.log` (`247,528` bytes at verification)

Terminal summary:

```text
Test Files  119 passed (119)
Tests       3450 passed | 24 skipped (3474)
Duration    142.57s
EXIT_CODE=0
```

This is a completed isolated full-suite result. It supersedes the earlier 60-second inconclusive attempt but does not erase the separately reproduced production test-isolation defect: without redirected config/data roots, selected telemetry/subprocess tests can touch the user's real OpenSpec configuration path.
