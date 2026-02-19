---
name: databricks-devops-data-ops
description: Manage Unity Catalog objects, Delta table operations, DBFS file management, and data quality checks across environments.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2025-07-21 | 1.0 | Self-contained capability skill for Databricks data operations. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `catalog`, `schema`, `table`, `delta`, `optimize`, `vacuum`, `dbfs`, `volume`, `data quality`, `lineage` |
| Weight | 0.9 |
| Minimum Confidence | 0.45 |

## Scope

- Unity Catalog CRUD (catalogs, schemas, tables, volumes, functions)
- Delta table maintenance (OPTIMIZE, ZORDER, VACUUM, DESCRIBE HISTORY)
- DBFS and volume file operations
- Table lineage tracing
- Cross-environment data quality checks

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `databricks-api` | Unity Catalog CRUD, DBFS operations |
| Secondary | `databricks-sql` | Delta table operations, data quality queries |
| Tertiary | `databricks-cli` | File copy, catalog listing |
| Guidance | `context7-guidance` | Delta Lake best practices, Unity Catalog patterns |

## Procedure

1. Resolve environment and workspace from [workspace-catalog.yaml](../databricks-devops/config/workspace-catalog.yaml).
2. Identify target catalog/schema/table.
3. Execute requested operation via preferred engine.
4. Validate operation result (row counts, schema checks, file listings).
5. Return summary with operation details.

Canonical procedure reference: [data-ops.md](../databricks-devops/modules/data-ops.md)

## Inputs

- Environment (`DEV`, `UAT`, `PROD` for reads; `DEV`/`UAT` for writes)
- Catalog, schema, and table names
- Operation type (list, describe, optimize, vacuum, quality check, lineage)

## Outputs

- Operation result (item list, table details, quality metrics)
- Data quality PASS/WARN/FAIL verdicts
- Lineage graphs (upstream/downstream)

## Guardrails

- VACUUM must retain at least 168 hours (7 days)
- Never disable `retentionDurationCheck` in PROD
- Write operations (CREATE, ALTER, DROP) blocked in PROD
- Data quality checks are read-only across all environments

Full safety policy: [safety-guardrails.md](../databricks-devops/modules/safety-guardrails.md)
