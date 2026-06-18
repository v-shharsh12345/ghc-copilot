```skill
---
name: copilotstudio-devops-develop
description: Create, update, and manage Copilot Studio agent components — topics, knowledge sources, actions, and connectors — in non-PROD environments via Dataverse API and PAC CLI.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-23 | 1.0 | Self-contained capability skill for Copilot Studio agent development operations. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `create`, `update`, `develop`, `build`, `topic`, `knowledge`, `action`, `connector`, `plugin`, `modify agent` |
| Weight | 1.0 |
| Minimum Confidence | 0.45 |

## Scope

- Create new topics for an agent
- Update existing topic content and trigger phrases
- Add/update knowledge sources
- Configure actions and connectors
- Manage agent settings and configurations
- Publish agent changes in DEV/UAT

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `dataverse-api` | Direct component CRUD via Dataverse Web API |
| Secondary | `pac-cli` | Solution-based component management |
| Guidance | `context7-guidance` | Implementation patterns when engines are unavailable |

## Procedure

1. Resolve environment and agent from [environment-catalog.yaml](../copilotstudio-devops/config/environment-catalog.yaml).
2. Block operation if target is PROD and request is a write.
3. Verify authentication.
4. Identify the target component (topic, knowledge source, action).
5. Apply create/update operation via preferred engine.
6. Verify the change via Dataverse query.
7. Advise on publishing if needed.

Canonical procedure reference: [develop.md](../copilotstudio-devops/modules/develop.md)

## Inputs

- **Copilot Studio URL** (e.g., `https://copilotstudio.preview.microsoft.com/environments/{ENV_ID}/bots/{BOT_ID}/overview`) — agent parses ENV_ID and BOT_ID automatically
- OR **Environment ID** (raw GUID) + **Bot ID** (raw GUID)
- Must be non-PROD environment (PROD writes blocked)
- Component type (topic, knowledge, action, connector)
- Component payload (content, trigger phrases, configuration)

## Outputs

- Created/updated component IDs
- Verification results
- Publish recommendation (if changes need publishing)

## Guardrails

- Never perform write operations in PROD
- Require explicit environment confirmation before any write
- Topic modifications should preserve existing trigger phrases unless explicitly replacing
- Knowledge source additions must specify source type and URL/content
- Always recommend publishing after changes for them to take effect

Full safety policy: [safety-guardrails.md](../copilotstudio-devops/modules/safety-guardrails.md)
```