---
name: databricks-devops-operate-monitor
description: Inventory Databricks workspace items, monitor job/cluster/warehouse health, and summarize run trends with actionable risk signals.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2025-07-21 | 1.0 | Self-contained capability skill for Databricks operations and monitoring. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `monitor`, `health`, `status`, `inventory`, `list`, `runs`, `failures` |
| Weight | 0.9 |
| Minimum Confidence | 0.40 |

## Scope

- List and inventory workspace items (notebooks, jobs, clusters, warehouses)
- Monitor job run health and failure trends
- Monitor cluster utilization and idle detection
- Monitor SQL warehouse query performance
- Produce PASS/WARN/FAIL health summaries

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `databricks-api` | List resources, get run history, cluster events |
| Secondary | `databricks-cli` | Quick listing and status checks |
| Tertiary | `databricks-sdk-py` | Batch collection and aggregation |
| Guidance | `context7-guidance` | API reference and monitoring patterns |

## Procedure

1. Resolve environment and workspace from [workspace-catalog.yaml](../databricks-devops/config/workspace-catalog.yaml).
2. Collect resource inventory for requested scope.
3. Pull run history / cluster events / warehouse query stats.
4. Compute health metrics (failure rate, idle %, latency).
5. Apply PASS/WARN/FAIL thresholds.
6. Return summary table with risk signals.

Canonical procedure reference: [operate-monitor.md](../databricks-devops/modules/operate-monitor.md)

## Inputs

- Environment (`DEV`, `UAT`, `PROD`)
- Scope (all items, specific job/cluster/warehouse)
- Time window (default: last 24 hours)

## Outputs

- Resource inventory table
- Health summary with PASS/WARN/FAIL per resource
- Escalation recommendations for FAIL items

## Guardrails

- Read-only operations — no mutations
- Respect API rate limits (batch requests where possible)
- Never expose credentials in monitoring output

Full safety policy: [safety-guardrails.md](../databricks-devops/modules/safety-guardrails.md)
