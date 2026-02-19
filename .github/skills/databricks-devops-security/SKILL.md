---
name: databricks-devops-security
description: Manage permissions, secret scopes, cluster policies, tokens, and Unity Catalog grants for Databricks workspaces.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2025-07-21 | 1.0 | Self-contained capability skill for Databricks security and access control. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `permission`, `secret`, `acl`, `policy`, `token`, `grant`, `access`, `security` |
| Weight | 0.9 |
| Minimum Confidence | 0.50 |

## Scope

- View and update object permissions (clusters, jobs, notebooks, warehouses)
- Manage secret scopes and secrets (including Azure Key Vault-backed)
- Create and enforce cluster policies
- Manage personal access tokens
- Administer Unity Catalog grants

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `databricks-api` | Permission CRUD, secret management, token operations |
| Secondary | `databricks-cli` | Secret scope creation, policy listing |
| Tertiary | `databricks-sql` | Unity Catalog GRANT/REVOKE/SHOW operations |
| Guidance | `context7-guidance` | Security best practices, permission models |

## Procedure

1. Resolve environment and workspace from [workspace-catalog.yaml](../databricks-devops/config/workspace-catalog.yaml).
2. Identify target resource and operation.
3. Retrieve current permissions/configuration (read before write).
4. Apply requested change via preferred engine.
5. Verify the change took effect (re-read permissions).
6. Return summary with before/after state.

Canonical procedure reference: [security.md](../databricks-devops/modules/security.md)

## Inputs

- Environment (`DEV`, `UAT`, `PROD` for reads; `DEV`/`UAT` for grants)
- Resource type and ID
- Principal (user, group, or service principal)
- Permission level or grant type

## Outputs

- Current permission state
- Applied changes summary
- Verification result

## Guardrails

- Never remove IS_OWNER from any resource
- Never grant CAN_MANAGE or ALL PRIVILEGES to broad groups without approval
- Never expose secret values in output (values are always `[REDACTED]`)
- Never create tokens without `lifetime_seconds`
- Permission changes in PROD require explicit confirmation

Full safety policy: [safety-guardrails.md](../databricks-devops/modules/safety-guardrails.md)
