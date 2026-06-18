---
name: databricks-devops-cluster-diagnostics
description: Diagnose Databricks cluster start failures, job failures, driver log issues, OOM conditions, and Spark performance bottlenecks in non-PROD and read-only PROD workflows.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-03-07 | 1.0 | Added dedicated capability skill wrapper for Databricks cluster diagnostics. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `cluster failure`, `driver logs`, `Spark UI`, `OOM`, `timeout`, `slow job`, `diagnostics`, `job failure` |
| Weight | 1.0 |
| Minimum Confidence | 0.45 |

## Scope

- Diagnose cluster start failures and termination reasons
- Investigate Databricks job run failures and task-level errors
- Analyze OOM and performance bottlenecks
- Review driver logs and event timelines for root cause identification

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `databricks-api` | Cluster events, run details, diagnostics endpoints |
| Secondary | `databricks-cli` | Cluster and job inspection via terminal workflows |
| Tertiary | `databricks-sdk-py` | Programmatic diagnostics and structured analysis |
| Guidance | `context7-guidance` | Troubleshooting patterns when execution tooling is unavailable |

## Procedure

1. Resolve environment and workspace from [workspace-catalog.yaml](../databricks-devops/config/workspace-catalog.yaml).
2. Treat PROD as read-only and block any mutating remediation steps.
3. Gather diagnostic context from cluster state, job runs, events, and logs.
4. Correlate failure signals against recent changes, policies, and Spark configuration.
5. Return root cause, confidence level, and the safest next remediation step.

Canonical procedure reference: [cluster-diagnostics.md](../databricks-devops/modules/cluster-diagnostics.md)

## Inputs

- Environment (`DEV`, `UAT`, or read-only `PROD`)
- Workspace host or profile name
- Cluster ID, job ID, or run ID
- Optional error message, stack trace, or timeframe

## Outputs

- Root cause summary
- Evidence gathered (cluster state, run output, logs, events)
- Recommended remediation steps
- Any follow-up validation to run after remediation

## Guardrails

- Never perform write or termination actions in PROD
- Require explicit confirmation before any restart, policy change, or config edit
- Never expose tokens, secrets, or credentials in output
- Prefer evidence-backed diagnosis over speculative fixes

Full safety policy: [safety-guardrails.md](../databricks-devops/modules/safety-guardrails.md)