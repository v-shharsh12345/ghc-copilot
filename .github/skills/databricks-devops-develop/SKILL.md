---
name: databricks-devops-develop
description: Create, update, and manage Databricks notebooks, jobs, clusters, and SQL warehouses in non-PROD workspaces with dependency-safe defaults.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2025-07-21 | 1.0 | Self-contained capability skill for Databricks develop/build lifecycle. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `create`, `update`, `develop`, `build`, `notebook`, `job`, `cluster`, `warehouse` |
| Weight | 1.0 |
| Minimum Confidence | 0.45 |

## Scope

- Create or update notebooks, jobs, clusters, and SQL warehouses
- Validate dependencies before and after write operations
- Enforce non-PROD write safety checks

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `databricks-cli` | Create/update items, bundle operations |
| Secondary | `databricks-api` | Direct REST API for CRUD when CLI unavailable |
| Tertiary | `databricks-sdk-py` | Programmatic automation via Python SDK |
| Guidance | `context7-guidance` | Implementation patterns when engines are unavailable |

## Procedure

1. Resolve environment and workspace from [workspace-catalog.yaml](../databricks-devops/config/workspace-catalog.yaml).
2. Block operation if target is PROD and request is a write.
3. Validate dependencies (cluster existence, library availability, notebook paths).
4. Apply create/update operation via preferred engine.
5. Run smoke test where applicable (e.g., trigger a job run, start a cluster).
6. Return summary with resource IDs and status.

Canonical procedure reference: [develop.md](../databricks-devops/modules/develop.md)

## Inputs

- Environment (`DEV`, `UAT`, or read-only `PROD`)
- Workspace host or profile name
- Resource type (`notebook`, `job`, `cluster`, `sql_warehouse`)
- Source path / configuration payload

## Outputs

- Created/updated resource IDs
- Validation notes
- Next recommended step (test / review / promote)

## Guardrails

- Never perform write operations in PROD
- Require explicit environment confirmation before any write
- Always set `autotermination_minutes` on clusters (max 120)
- Cap `max_workers` at 10 unless explicitly approved

Full safety policy: [safety-guardrails.md](../databricks-devops/modules/safety-guardrails.md)
