# Lakehouse Diagnostics Module

## Goal

Identify root causes for lakehouse ingestion and dependency failures.

## Inputs

- Lakehouse/workspace
- Failing pipeline/notebook IDs (optional)
- Suspected table or shortcut path (optional)

## Preferred Route

- Primary: `fabric-api`
- Secondary: `fabric-sempy`
- Operational fallback: `fabric-cli`
- Guidance fallback: `context7-guidance`

## Procedure

1. Enumerate lakehouse tables and shortcuts.
2. Correlate failures to upstream/downstream notebook and pipeline runs.
3. Check environment-specific dependency references.
4. Identify likely root cause and impact scope.
5. Provide remediation + verification steps.

## Outputs

- Root-cause hypothesis
- Impacted objects list
- Remediation plan with validation steps
