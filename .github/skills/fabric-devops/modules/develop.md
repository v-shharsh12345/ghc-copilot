# Develop Module

## Goal

Create/update Fabric items in non-PROD environments with dependency-safe defaults.

## Inputs

- Environment (`DEV` or `UAT`)
- Workspace ID or workspace name
- Item type (`Notebook`, `DataPipeline`, `Lakehouse`, `SemanticModel`, `Report`)
- Source path and deployment intent

## Preferred Route

- Primary: `fabric-api`
- Secondary: `fabric-cli`
- Guidance fallback: `context7-guidance`

## Procedure

1. Resolve environment and workspace from `config/workspace-catalog.yaml`.
2. Block operation if target is PROD and request is a write.
3. Validate dependencies (notebook metadata, lakehouse attachment, item references).
4. Apply create/update operation.
5. Run smoke test where applicable.
6. Return summary with item IDs and status.

## Outputs

- Updated item list with IDs
- Validation notes
- Next recommended step (test/review/promote)
