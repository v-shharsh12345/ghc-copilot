```skill
---
name: copilotstudio-devops-inventory
description: List, inspect, and monitor Copilot Studio agents and their components — topics, knowledge sources, actions, analytics, and publish status — via Dataverse Web API.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-23 | 1.0 | Self-contained capability skill for Copilot Studio agent inventory and monitoring. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `list agents`, `inventory`, `topics`, `status`, `health`, `published`, `bot metadata`, `analytics`, `knowledge sources`, `actions` |
| Weight | 1.0 |
| Minimum Confidence | 0.45 |

## Scope

- List all agents in a Power Platform environment
- View agent metadata (name, status, topics, knowledge sources, actions)
- Check publish status and last modified dates
- View conversation analytics and transcripts
- Inspect agent components (bot, botcomponent Dataverse tables)

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `pac-cli` | `pac copilot list`, `pac copilot status`, `pac copilot extract-template`, `pac solution list` (PROVEN) |
| Secondary | `dataverse-api` | Query bot/botcomponent entities for detailed metadata |
| Guidance | `context7-guidance` | Implementation patterns when engines are unavailable |

## Procedure

1. Resolve environment from [environment-catalog.yaml](../copilotstudio-devops/config/environment-catalog.yaml).
2. Verify authentication (Azure CLI or PAC CLI auth profile).
3. Query Dataverse `bots` entity to list all agents.
4. For detailed inspection, query `botcomponents` filtered by parent bot.
5. Format results as inventory table.
6. Return summary with component counts and status.

Canonical procedure reference: [inventory.md](../copilotstudio-devops/modules/inventory.md)

## Inputs

- **Copilot Studio URL** (e.g., `https://copilotstudio.preview.microsoft.com/environments/{ENV_ID}/bots/{BOT_ID}/overview`) — agent parses ENV_ID and BOT_ID automatically
- OR **Environment ID** (raw GUID) + optional **Bot ID** (raw GUID)
- Agent filter (optional — name, schema name, or bot ID)
- Detail level (`summary` or `detailed`)

## Outputs

- Agent list with: Name, Schema Name, Status, Topic Count, Last Modified
- Component breakdown (if detailed): Topics, Knowledge Sources, Actions, Connectors
- Analytics summary (if available): Conversations, Escalations, Resolution Rate

## Guardrails

- Read-only operation — no writes allowed
- Never expose internal bot IDs in user-facing output unless explicitly requested
- Query results may be large — paginate and summarize

Full safety policy: [safety-guardrails.md](../copilotstudio-devops/modules/safety-guardrails.md)
```