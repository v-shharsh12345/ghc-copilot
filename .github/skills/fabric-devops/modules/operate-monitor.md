# Operate and Monitor Module

## Goal

Provide operational visibility for Fabric items, runs, and job health.

## Inputs

- Workspace scope
- Item scope (optional)
- Time window (optional)

## Preferred Route

- Primary: `fabric-api`
- Secondary: `fabric-cli`
- Analytical fallback: `fabric-sempy`
- Guidance fallback: `context7-guidance`

## Procedure

1. Inventory items by type for target workspace.
2. Pull job instance status for notebooks/pipelines.
3. Highlight failures, retries, and long-running jobs.
4. Produce concise run-health summary.

## Outputs

- Health summary (`PASS`, `WARN`, `FAIL`)
- Failing items and latest run references
- Follow-up recommendation
