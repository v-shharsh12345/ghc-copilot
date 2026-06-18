```skill
---
name: copilotstudio-devops-security
description: Manage security, governance, and compliance for Copilot Studio agents — quarantine/unquarantine bots, audit permissions, DLP policy checks, and admin operations via Power Platform API.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-23 | 1.0 | Self-contained capability skill for Copilot Studio agent security and governance. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `quarantine`, `delete`, `DLP`, `permissions`, `security`, `governance`, `compliance`, `audit`, `admin`, `access control`, `unquarantine` |
| Weight | 1.0 |
| Minimum Confidence | 0.45 |

## Scope

- Quarantine non-compliant agents
- Unquarantine agents after remediation
- Delete agents via admin API
- Audit agent permissions and ownership
- Check DLP policy compliance
- Review agent security configurations (auth settings, channel security)

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `powerplatform-api` | Admin operations (quarantine, delete, bot management) |
| Secondary | `dataverse-api` | Permission queries, ownership audit, component inspection |
| Guidance | `context7-guidance` | Governance patterns and compliance guidance |

## Procedure

1. Resolve environment from [environment-catalog.yaml](../copilotstudio-devops/config/environment-catalog.yaml).
2. Verify admin-level authentication (Global Admin, AI Admin, or PP Admin).
3. Identify target agent and operation.
4. For quarantine/delete: require justification and explicit confirmation.
5. Execute admin operation via Power Platform API.
6. Verify result and report status.

Canonical procedure reference: [security.md](../copilotstudio-devops/modules/security.md)

## Inputs

- **Copilot Studio URL** or **Environment ID** (raw GUID) + **Bot ID** (raw GUID)
- Operation (quarantine, unquarantine, delete, audit)
- Justification (required for quarantine/delete)

## Outputs

- Operation result (success/failure)
- Audit report (permissions, config, compliance findings)
- Governance recommendations

## Guardrails

- Admin operations require elevated permissions (see safety-guardrails.md)
- Delete is IRREVERSIBLE — require double confirmation
- Quarantine immediately affects all users — warn before executing
- Never perform admin operations on PROD agents without explicit written justification
- Always log admin actions with timestamp, operator, and justification

Full safety policy: [safety-guardrails.md](../copilotstudio-devops/modules/safety-guardrails.md)
```