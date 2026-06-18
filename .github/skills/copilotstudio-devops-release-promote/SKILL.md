```skill
---
name: copilotstudio-devops-release-promote
description: Promote Copilot Studio agents across environments using solution export/import, PAC CLI, and Power Platform Pipelines — manage ALM lifecycle from DEV to UAT to PROD.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-23 | 1.0 | Self-contained capability skill for Copilot Studio agent lifecycle promotion. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `promote`, `release`, `deploy`, `export`, `import`, `solution`, `pipeline`, `ALM`, `dev to uat`, `uat to prod`, `publish`, `package` |
| Weight | 1.0 |
| Minimum Confidence | 0.45 |

## Scope

- Export agent solutions from source environments
- Import agent solutions to target environments
- Unpack/pack solutions for source control integration
- Trigger Power Platform Pipeline deployments
- Manage solution versioning
- Post-import validation and publishing

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `pac-cli` | Solution export, import, pack, unpack, pipeline deploy |
| Secondary | `dataverse-api` | Solution metadata queries, deployment status checks |
| Guidance | `context7-guidance` | Implementation patterns when engines are unavailable |

## Procedure

1. Resolve source and target environments from [environment-catalog.yaml](../copilotstudio-devops/config/environment-catalog.yaml).
2. Block if target is PROD and source is not UAT (enforce DEV → UAT → PROD).
3. Verify authentication for both environments.
4. Export solution from source.
5. Import solution to target.
6. Verify import succeeded.
7. Guide user to publish the agent in the target environment.

Canonical procedure reference: [release-promote.md](../copilotstudio-devops/modules/release-promote.md)

## Inputs

- **Source Copilot Studio URL** or **Source Environment ID** (e.g., DEV)
- **Target Copilot Studio URL** or **Target Environment ID** (e.g., PROD)
- Solution name containing the agent (auto-discovered via `pac solution list` if not provided)
- Export type (`managed` or `unmanaged`)
- Pipeline name (if using Power Platform Pipelines)

## Outputs

- Export path and solution metadata
- Import result (success/failure with details)
- Post-import verification results
- Next steps (publish, test)

## Guardrails

- Enforce DEV → UAT → PROD promotion order
- Managed solutions required for PROD deployments
- Never deploy unmanaged solutions to PROD
- Require explicit confirmation before import to UAT or PROD
- Always run post-import validation
- Never directly modify components in PROD — solution import only

Full safety policy: [safety-guardrails.md](../copilotstudio-devops/modules/safety-guardrails.md)
```