---
name: fabric-devops-release-promote
description: Promote Fabric items between lifecycle stages (DEV → UAT → PROD) using deployment pipelines with pre-flight validation and post-deployment verification.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-18 | 1.0 | Self-contained capability skill for release promotion across deployment stages. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `promote`, `release`, `deploy`, `dev to uat`, `uat to prod`, `deployment pipeline`, `stage`, `push to production`, `move to uat`, `lifecycle promotion` |
| Weight | 1.0 |
| Minimum Confidence | 0.6 |

## Scope

- Promote items through Fabric deployment pipeline stages
- Run pre-flight validation before each promotion
- Execute post-deployment verification after each promotion
- Enforce PROD write-protection guardrail (requires explicit user confirmation)

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `fabric-api` | Deployment pipeline API, item deployment |
| Secondary | `fabric-cli` | Scripted deployment flows |
| Guidance | `context7-guidance` | Lifecycle best-practice guidance |

## Procedure

### Phase 1 — Pre-flight
1. Identify source and target stages from user request.
2. Resolve workspace IDs from [workspace-catalog.yaml](../fabric-devops/config/workspace-catalog.yaml).
3. Run pre-deployment validation on items in scope (invoke [validate](../fabric-devops-validate/SKILL.md) checks).
4. If any validation fails with severity ≥ ERROR, halt promotion and report.

### Phase 2 — Promotion
5. Enumerate items to promote (all or filtered by type/name).
6. Execute deployment pipeline stage transition via Fabric API.
7. Wait for deployment completion and capture result status.

### Phase 3 — Post-deployment Verification
8. Re-run validation in target environment to confirm deployment integrity.
9. For semantic model promotions, invoke [semantic-model-testing](../fabric-devops-semantic-model-testing/SKILL.md) with default thresholds.
10. Produce deployment summary: items promoted, status, and any post-deploy warnings.

Canonical procedure reference: [release-promote.md](../fabric-devops/modules/release-promote.md)

## Inputs

- Source stage: `DEV` or `UAT`
- Target stage: `UAT` or `PROD`
- Items: all, or filtered by type/name
- Skip pre-flight: `false` (default)

## Outputs

- Pre-flight validation report
- Deployment result (SUCCESS / PARTIAL / FAILED)
- Post-deployment verification summary
- Item-level promotion status table

## Guardrails

- PROD promotion requires explicit user confirmation before execution
- Pre-flight validation runs automatically unless explicitly skipped
- If pre-flight reveals ERROR-level issues, promotion is blocked
- Post-deployment verification is always executed (cannot be skipped)
- Rollback guidance is provided on PARTIAL or FAILED outcomes

Full safety policy: [safety-guardrails.md](../fabric-devops/modules/safety-guardrails.md)
