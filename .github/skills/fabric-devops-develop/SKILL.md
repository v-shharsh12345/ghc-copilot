---
name: fabric-devops-develop
description: Create, update, and build Fabric items (notebooks, pipelines, lakehouses, semantic models) in non-PROD workspaces with dependency-safe defaults.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-18 | 1.0 | Self-contained capability skill for Fabric develop/build lifecycle. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `create`, `update`, `develop`, `build`, `notebook`, `pipeline` |
| Weight | 1.0 |
| Minimum Confidence | 0.45 |

## Scope

- Create or update notebooks, pipelines, lakehouses, semantic models, and reports
- Validate dependencies before and after write operations
- Enforce non-PROD write safety checks

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `fabric-api` | Create/update/delete item operations, job execution |
| Secondary | `fabric-cli` | Scripted operational workflows, CI/CD automation |
| Guidance | `context7-guidance` | Implementation patterns when engines are unavailable |

## Procedure

1. Resolve environment and workspace from [workspace-catalog.yaml](../fabric-devops/config/workspace-catalog.yaml).
2. Block operation if target is PROD and request is a write.
3. Validate dependencies (notebook metadata, lakehouse attachment, item references).
4. Apply create/update operation via preferred engine.
5. Run smoke test where applicable.
6. Return summary with item IDs and status.

Canonical procedure reference: [develop.md](../fabric-devops/modules/develop.md)

## Inputs

- Environment (`DEV` or `UAT`)
- Workspace ID or workspace name
- Item type (`Notebook`, `DataPipeline`, `Lakehouse`, `SemanticModel`, `Report`)
- Source path and deployment intent

## Outputs

- Updated item list with IDs
- Validation notes
- Next recommended step (test / review / promote)

## Guardrails

- Never perform write operations in PROD
- Require explicit environment confirmation before any write
- Prefer minimal, idempotent update operations
- Stop and ask for confirmation if environment cannot be resolved

Full safety policy: [safety-guardrails.md](../fabric-devops/modules/safety-guardrails.md)
