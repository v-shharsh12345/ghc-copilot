---
name: fabric-devops-operate-monitor
description: Inventory Fabric items, monitor job execution health, and summarize run trends with actionable risk signals.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-18 | 1.0 | Self-contained capability skill for Fabric operations and monitoring. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `monitor`, `status`, `inventory`, `jobs`, `run history`, `health` |
| Weight | 1.0 |
| Minimum Confidence | 0.45 |

## Scope

- Inventory Fabric items by workspace, type, and owner
- Monitor pipeline and notebook job execution health
- Summarize run trends, highlight failures, and recommend next actions
- Escalate correlated failures to lakehouse diagnostics

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `fabric-api` | Workspace and item metadata retrieval, job status |
| Secondary | `fabric-cli` | Scripted inventory and automation workflows |
| Analytical | `fabric-sempy` | Notebook-native diagnostics and checks |
| Guidance | `context7-guidance` | Advisory when tooling is unavailable |

## Procedure

1. Resolve workspace from [workspace-catalog.yaml](../fabric-devops/config/workspace-catalog.yaml).
2. Inventory items by type for target workspace.
3. Pull job instance status for notebooks and pipelines.
4. Highlight failures, retries, and long-running jobs.
5. Produce concise run-health summary (PASS / WARN / FAIL).

Canonical procedure reference: [operate-monitor.md](../fabric-devops/modules/operate-monitor.md)

## Inputs

- Workspace scope
- Item scope (optional)
- Time window (optional)

## Outputs

- Health summary (`PASS`, `WARN`, `FAIL`)
- Failing items with latest run references
- Follow-up recommendations

## Guardrails

- PROD access is strictly read-only — no create, update, delete, deploy, or commit
- Escalate correlated failures to the lakehouse-diagnostics skill
- Never trigger write operations from monitoring flows

Full safety policy: [safety-guardrails.md](../fabric-devops/modules/safety-guardrails.md)
