# Validate Module

## Goal

Validate deployment parity and readiness across DEV/UAT/PROD.

## Inputs

- Source and target environments
- Item set (reports/semantic models/notebooks/pipelines)
- Validation depth (`quick` or `full`)

## Preferred Route

- Primary: `fabric-sempy` (`sempy_labs` / semantic-link-labs)
- Secondary: `fabric-api`
- Operational fallback: `fabric-cli`
- Guidance fallback: `context7-guidance`

## Procedure

1. Compare item inventory by name and type.
2. Compare definitions and key bindings.
3. Run metadata parity checks for report and semantic model objects.
4. Validate semantic model compatibility and freshness indicators.
5. Summarize mismatches by severity.

### Metadata Parity Checks (semantic-link-labs)

- Use `rpt.list_semantic_model_objects(extended=True)` to detect invalid/missing report bindings.
- Use `labs.list_semantic_model_object_report_usage(..., include_dependencies=True, extended=True)` for usage and impact parity.
- Use `connect_semantic_model(..., readonly=True)` to compare model inventory (tables/columns/measures/hierarchies/relationships).
- Optional quality gate: `rep.run_report_bpa(...)` and `labs.run_model_bpa(..., extended=True)`.

## Outputs

- Validation matrix
- `PASS/WARN/FAIL` status
- Metadata parity summary (broken objects, missing mappings, dependency impact)
- Required fixes before promotion
