---
name: fabric-devops-lakehouse-diagnostics
description: Diagnose lakehouse ingestion failures, trace dependency breakages, and produce root-cause remediation steps.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-18 | 1.0 | Self-contained capability skill for lakehouse failure diagnostics. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `lakehouse`, `table load`, `shortcut`, `failure`, `logs`, `dependency` |
| Weight | 1.0 |
| Minimum Confidence | 0.45 |

## Scope

- Diagnose lakehouse load failures and dependency breakages
- Correlate notebook and pipeline failures with upstream/downstream tables
- Produce root-cause-focused remediation steps with verification guidance

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `fabric-api` | Item metadata, job history, lakehouse entity enumeration |
| Secondary | `fabric-sempy` | Analytical diagnostics, dataframe-based correlation |
| Operational | `fabric-cli` | Scripted diagnostic flows |
| Guidance | `context7-guidance` | Advisory when tooling is unavailable |

## Procedure

1. Resolve workspace from [workspace-catalog.yaml](../fabric-devops/config/workspace-catalog.yaml).
2. Enumerate lakehouse tables and shortcuts.
3. Correlate failures to upstream/downstream notebook and pipeline runs.
4. Check environment-specific dependency references.
5. Identify likely root cause and impact scope.
6. Provide remediation and verification steps.

Canonical procedure reference: [lakehouse-diagnostics.md](../fabric-devops/modules/lakehouse-diagnostics.md)

## Inputs

- Lakehouse / workspace
- Failing pipeline or notebook IDs (optional)
- Suspected table or shortcut path (optional)

## Outputs

- Root-cause hypothesis
- Impacted objects list
- Remediation plan with validation steps

## Guardrails

- Prefer read-only diagnostics first in all environments
- Restrict write/remediation actions to non-PROD with explicit confirmation
- Never apply direct write fixes in PROD

Full safety policy: [safety-guardrails.md](../fabric-devops/modules/safety-guardrails.md)
