---
name: fabric-devops
description: Shared resource layer for Fabric lifecycle skills — provides workspace catalog, engine definitions, safety guardrails, and canonical procedure modules.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-18 | 4.0 | Restructured as shared resource layer; capability skills self-declare intent and own routing. |
| 2026-02-18 | 3.0 | Consolidated capability skills back into unified single-skill architecture. |
| 2026-02-18 | 2.8 | Removed report formatting capability from Fabric DevOps routing and execution profiles. |
| 2026-02-18 | 2.7 | Added semantic-model-testing module and integrated compare-semantic-models workflow into Fabric lifecycle routing. |
| 2026-02-13 | 2.3 | Added semantic-link-labs-driven metadata generation patterns for report and semantic model analysis. |
| 2026-02-13 | 2.2 | Added analyze-lineage module for table, column, and report-level data lineage tracing. |
| 2026-02-12 | 2.1 | Added engine-aware routing with Fabric API, Fabric CLI, Fabric SemPy, and Context7 guidance fallback. |
| 2026-02-12 | 2.0 | Refactored to modular structure with config-driven intent routing and stage-specific modules. |
| 2026-02-12 | 1.0 | Added meta-orchestration skill to unify Fabric lifecycle workflows using existing Fabric skills. |

This skill provides **shared resources** consumed by the seven capability skills that handle Fabric lifecycle operations. It does not route requests itself — each capability skill declares its own intent scope, engine preference, and procedure.

> ⚠️ **CRITICAL: PRODUCTION ENVIRONMENT PROTECTION**
>
> - ✅ **READ-ONLY operations are allowed** on PROD (list, get, export, query, compare)
> - ❌ **WRITE operations are PROHIBITED** on PROD (create, update, delete, deploy, commit)
> - Require explicit confirmation before any write operation in non-PROD

## Capability Skills

Each skill self-declares its intent triggers, engine preference, and guardrails. The agent reads these declarations and dispatches accordingly.

| Skill | Lifecycle Domain | Intent Weight |
| --- | --- | --- |
| [fabric-devops-develop](../fabric-devops-develop/SKILL.md) | Build/update items | 1.0 |
| [fabric-devops-operate-monitor](../fabric-devops-operate-monitor/SKILL.md) | Inventory, monitoring, health | 1.0 |
| [fabric-devops-lakehouse-diagnostics](../fabric-devops-lakehouse-diagnostics/SKILL.md) | Lakehouse failure diagnostics | 1.0 |
| [fabric-devops-validate](../fabric-devops-validate/SKILL.md) | Cross-environment validation | 0.95 |
| [fabric-devops-semantic-model-testing](../fabric-devops-semantic-model-testing/SKILL.md) | Semantic model parity testing | 1.1 |
| [fabric-devops-analyze-lineage](../fabric-devops-analyze-lineage/SKILL.md) | Data lineage analysis | 1.05 |
| [fabric-devops-release-promote](../fabric-devops-release-promote/SKILL.md) | Lifecycle promotion | 1.0 |

## Shared Resources

| Path | Purpose |
| --- | --- |
| [config/workspace-catalog.yaml](config/workspace-catalog.yaml) | Central workspace/environment metadata (consumed by all skills) |
| [config/execution-router.yaml](config/execution-router.yaml) | Engine definitions and fallback policy (API/CLI/SemPy/Context7) |
| [config/intent-router.yaml](config/intent-router.yaml) | Intent routing reference index (skills are authoritative) |
| [modules/safety-guardrails.md](modules/safety-guardrails.md) | Safety rules and environment protections |
| [modules/capability-matrix.md](modules/capability-matrix.md) | Lifecycle event to engine coverage matrix |
| [modules/execution-routing.md](modules/execution-routing.md) | Deterministic engine selection workflow |
| [modules/runtime-checks.md](modules/runtime-checks.md) | Concrete engine availability checks |

## Procedure Modules

Canonical procedures consumed by capability skills via relative reference:

| Module | Consumed By |
| --- | --- |
| [modules/develop.md](modules/develop.md) | fabric-devops-develop |
| [modules/operate-monitor.md](modules/operate-monitor.md) | fabric-devops-operate-monitor |
| [modules/lakehouse-diagnostics.md](modules/lakehouse-diagnostics.md) | fabric-devops-lakehouse-diagnostics |
| [modules/validate.md](modules/validate.md) | fabric-devops-validate |
| [modules/semantic-model-testing.md](modules/semantic-model-testing.md) | fabric-devops-semantic-model-testing |
| [modules/analyze-lineage.md](modules/analyze-lineage.md) | fabric-devops-analyze-lineage |
| [modules/release-promote.md](modules/release-promote.md) | fabric-devops-release-promote |

## Engine Definitions

Available execution engines (shared across all capability skills):

| Engine | Type | Strength |
| --- | --- | --- |
| `fabric-api` | Fabric REST API | CRUD, jobs, deployment pipelines |
| `fabric-cli` | Fabric CLI | Scripted automation, CI/CD |
| `fabric-sempy` | sempy-python-sdk | Metadata analysis, lineage, semantic-link-labs |
| `context7-guidance` | Knowledge guidance | Advisory-only fallback |

## Response Contract

For each operation, the executing capability skill returns:

- Scope (workspace/environment/items)
- Chosen route (intent + primary engine + fallbacks)
- Actions executed
- Findings (PASS/WARN/FAIL)
- Risk notes (guardrails)
- Next step
- Execution metrics (tool calls, classification hops, engine used)

## Skill Loading Pattern

Skills follow a **fast-header + deferred-body** pattern:

1. **Fast header** (SKILL.md) — Intent triggers, weight, engine preference, guardrails (~50 lines). Loaded during routing to determine which skill matches.
2. **Procedure body** (modules/*.md) — Full step-by-step execution procedure (~100-300 lines). Loaded only AFTER the skill is confirmed as the routing winner.

This deferred loading reduces context window pressure during the scoring phase. When an orchestrator `## Skill Hint` is present, the agent can skip the fast-header scoring entirely and load the procedure body directly.
