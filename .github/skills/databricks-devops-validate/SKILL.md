---
name: databricks-devops-validate
description: Run cross-environment deployment readiness checks, configuration drift detection, and PASS/WARN/FAIL validation reporting.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2025-07-21 | 1.0 | Self-contained capability skill for Databricks cross-environment validation. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `validate`, `compare`, `diff`, `drift`, `readiness`, `pre-deploy` |
| Weight | 0.9 |
| Minimum Confidence | 0.45 |

## Scope

- Compare cluster configs, job definitions, and notebook inventories across environments
- Detect configuration drift between DEV/UAT/PROD
- Run pre-deployment readiness checks
- Produce PASS/WARN/FAIL validation reports

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `databricks-api` | Fetch resource definitions from multiple environments |
| Secondary | `databricks-cli` | Export/compare workspace contents |
| Guidance | `context7-guidance` | Validation patterns and best practices |

## Procedure

1. Resolve source and target environments from [workspace-catalog.yaml](../databricks-devops/config/workspace-catalog.yaml).
2. Collect resource definitions from both environments.
3. Compare properties and detect differences.
4. Classify differences by severity (ERROR / WARN / INFO).
5. Produce PASS/WARN/FAIL summary table.

Canonical procedure reference: [validate.md](../databricks-devops/modules/validate.md)

## Inputs

- Source environment (e.g., `DEV`)
- Target environment (e.g., `UAT` or `PROD`)
- Scope (all resources, specific resource type, or specific resource ID)

## Outputs

- Comparison table with differences
- Severity classification per difference
- Overall PASS/WARN/FAIL verdict
- Recommended actions for WARN/FAIL items

## Guardrails

- Validation is read-only — no mutations in any environment
- Require both source and target environments to be resolved before comparison
- Flag any PROD-specific differences as expected overrides unless proven otherwise

Full safety policy: [safety-guardrails.md](../databricks-devops/modules/safety-guardrails.md)
