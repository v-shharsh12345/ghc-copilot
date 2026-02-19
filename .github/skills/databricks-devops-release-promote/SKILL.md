---
name: databricks-devops-release-promote
description: Promote Databricks items across DEV/UAT/PROD using Asset Bundles with pre-flight validation and post-deployment verification.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2025-07-21 | 1.0 | Self-contained capability skill for Databricks release and promotion lifecycle. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `deploy`, `promote`, `release`, `bundle`, `CI/CD`, `rollback`, `migrate` |
| Weight | 1.0 |
| Minimum Confidence | 0.50 |

## Scope

- Bundle-based deployments (validate, deploy, run)
- Promotion workflows DEV → UAT → PROD
- Pre-flight validation before deployment
- Post-deployment verification
- Rollback procedures

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `databricks-cli` | Bundle validate/deploy/run commands |
| Secondary | `databricks-api` | Manual export/import of notebooks and jobs |
| Guidance | `context7-guidance` | Bundle config patterns, deployment best practices |

## Procedure

1. Resolve source and target environments from [workspace-catalog.yaml](../databricks-devops/config/workspace-catalog.yaml).
2. Run pre-flight validation (bundle validate, cross-env check via [validate.md](../databricks-devops/modules/validate.md)).
3. Deploy to target environment via `databricks bundle deploy`.
4. Run post-deploy verification (trigger job, check status).
5. Report deployment result as PASS/FAIL with details.

Canonical procedure reference: [release-promote.md](../databricks-devops/modules/release-promote.md)

## Inputs

- Source environment (`DEV` or `UAT`)
- Target environment (`UAT` or `PROD`)
- Bundle target name or resource keys
- Approval confirmation (required for PROD)

## Outputs

- Pre-flight validation result (PASS/FAIL)
- Deployment status
- Post-deploy verification result
- Rollback instructions (if deployment fails)

## Guardrails

- Always run `bundle validate` before `bundle deploy`
- Never deploy to PROD without UAT validation
- PROD deployment requires explicit user approval
- Always have rollback plan documented before PROD deploy
- Prefer bundle-based over manual export/import

Full safety policy: [safety-guardrails.md](../databricks-devops/modules/safety-guardrails.md)
