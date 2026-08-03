# GitHub Spec Kit targeted pytest evidence

- Date: 2026-08-02
- Repository pin: `d1e86f638277a99b82715c22c90558cd58d3cffd`
- Disposable clone: `work/runtime/github-spec-kit-test`
- Platform: `win32`
- Python: `3.14.6`
- pytest: `9.1.1`
- pluggy: `1.6.0`
- pytest-cov: `7.1.0`

## Command

```powershell
& .\.venv\Scripts\python.exe -m pytest -q tests\contract tests\workflows tests\test_workflows.py tests\integrations\test_events.py tests\test_download_security.py
```

## Result

- Exit code: `0`
- Collected: `1494`
- Passed: `1487`
- Skipped: `7`
- Warnings: `6`
- Duration reported by pytest: `29.47s`
- Wall time reported by the tool: `30.5s`

Terminal summary:

```text
================ 1487 passed, 7 skipped, 6 warnings in 29.47s =================
```

Five warnings concern deprecated Copilot legacy Markdown mode in `init.py`; one warning comes from Python `zipfile` while testing rejection of duplicate archive paths. No assertion failure occurred.

## Qualification

This targeted suite is positive evidence for contract schemas, workflow overlays/resolution/security, the main workflow engine tests, integration events, and download/extraction security. It is not a substitute for a completed full-suite result. The separate 6,388-test full-suite attempt exceeded the bounded runtime before producing a terminal pass/fail summary and must be reported as `timed out / inconclusive`, not as passing.
