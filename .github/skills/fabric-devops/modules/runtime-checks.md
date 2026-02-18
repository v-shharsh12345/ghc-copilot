# Runtime Checks Module

## Goal

Verify execution engine availability before selecting route.

## Checks

### Fabric API readiness

- `az account show`
- `az account get-access-token --resource https://api.fabric.microsoft.com`
- Permission check on target workspace using list/get operation

### Fabric CLI readiness

- `Get-Command fabric -ErrorAction SilentlyContinue`
- `fabric --version`
- Basic workspace list/read command succeeds

### Fabric SemPy readiness

- `python -c "import sempy; print(sempy.__version__)"`
- `python -c "import sempy_labs; print(sempy_labs.__version__)"`
- `python -c "from sempy_labs.report import ReportWrapper; from sempy_labs.tom import connect_semantic_model; print('ok')"`
- Notebook/runtime has required credentials and workspace access

### Context7 guidance readiness

- Verify guidance source `io.github.upstash/context7` is configured
- Use only as advisory fallback, not execution

## Decision Rule

- Mark engine `available` only if all mandatory checks pass.
- Prefer highest-ranked available engine from `config/execution-router.yaml`.
- If no execution engine is available, return guidance-only plan with blocker list.
