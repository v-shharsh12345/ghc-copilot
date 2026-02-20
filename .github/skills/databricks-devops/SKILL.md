---
name: databricks-devops
description: Shared resource layer for Databricks lifecycle skills — provides workspace catalog, engine definitions, safety guardrails, and canonical procedure modules.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-19 | 1.0 | Initial shared resource layer for Databricks DevOps capability skills. |

This skill provides **shared resources** consumed by the seven capability skills that handle Databricks lifecycle operations. It does not route requests itself — each capability skill declares its own intent scope, engine preference, and procedure.

> ⚠️ **CRITICAL: PRODUCTION ENVIRONMENT PROTECTION**
>
> - ✅ **READ-ONLY operations are allowed** on PROD (list, get, export, query, compare, status)
> - ❌ **WRITE operations are PROHIBITED** on PROD (create, update, delete, deploy, terminate)
> - ❌ **NEVER expose tokens, secrets, or credentials** in any output
> - Require explicit confirmation before any write operation in non-PROD

## Capability Skills

Each skill self-declares its intent triggers, engine preference, and guardrails. The agent reads these declarations and dispatches accordingly.

| Skill | Lifecycle Domain | Intent Weight |
| --- | --- | --- |
| [databricks-devops-develop](../databricks-devops-develop/SKILL.md) | Build/update notebooks, jobs, clusters, warehouses | 1.0 |
| [databricks-devops-operate-monitor](../databricks-devops-operate-monitor/SKILL.md) | Inventory, job/cluster monitoring, health | 1.0 |
| [databricks-devops-cluster-diagnostics](../databricks-devops-cluster-diagnostics/SKILL.md) | Cluster failure diagnostics, Spark troubleshooting | 1.0 |
| [databricks-devops-validate](../databricks-devops-validate/SKILL.md) | Cross-environment validation, config drift | 0.95 |
| [databricks-devops-data-ops](../databricks-devops-data-ops/SKILL.md) | Unity Catalog, Delta tables, DBFS, data quality | 1.1 |
| [databricks-devops-security](../databricks-devops-security/SKILL.md) | Permissions, secrets, ACLs, cluster policies | 1.0 |
| [databricks-devops-release-promote](../databricks-devops-release-promote/SKILL.md) | Bundle deployments, lifecycle promotion | 1.0 |

## Shared Resources

| Path | Purpose |
| --- | --- |
| [config/workspace-catalog.yaml](config/workspace-catalog.yaml) | Central workspace/environment metadata (consumed by all skills) |
| [config/execution-router.yaml](config/execution-router.yaml) | Engine definitions and fallback policy (API/CLI/SDK/SQL/Context7) |
| [modules/safety-guardrails.md](modules/safety-guardrails.md) | Safety rules and environment protections |

## Procedure Modules

Canonical procedures consumed by capability skills via relative reference:

| Module | Consumed By |
| --- | --- |
| [modules/develop.md](modules/develop.md) | databricks-devops-develop |
| [modules/operate-monitor.md](modules/operate-monitor.md) | databricks-devops-operate-monitor |
| [modules/cluster-diagnostics.md](modules/cluster-diagnostics.md) | databricks-devops-cluster-diagnostics |
| [modules/validate.md](modules/validate.md) | databricks-devops-validate |
| [modules/data-ops.md](modules/data-ops.md) | databricks-devops-data-ops |
| [modules/security.md](modules/security.md) | databricks-devops-security |
| [modules/release-promote.md](modules/release-promote.md) | databricks-devops-release-promote |

## Engine Definitions

Available execution engines (shared across all capability skills). All engines execute via **terminal commands** or **Python scripts** — there are no MCP server bindings for Databricks.

| Engine | Execution Method | Strength |
| --- | --- | --- |
| `databricks-cli` | Terminal: `databricks <command>` | Bundle deploy/validate, workspace sync, cluster/job lifecycle, CI/CD |
| `databricks-sdk-py` | Terminal: `python <script>` | Programmatic automation, SDK-native workspace operations |
| `databricks-sql` | Terminal: Python + `databricks-sql-connector` | SQL execution, query history, warehouse management |
| `databricks-api` | Terminal: `curl` or Python `requests` | Direct REST API calls when CLI doesn't cover the endpoint |
| `context7-guidance` | Context7 MCP (advisory only) | Implementation patterns and best practices |

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

This deferred loading reduces context window pressure during the scoring phase.
