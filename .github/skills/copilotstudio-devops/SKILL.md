```skill
---
name: copilotstudio-devops
description: Shared resource layer for Copilot Studio lifecycle skills — provides environment catalog, engine definitions, safety guardrails, and canonical procedure modules.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-23 | 1.0 | Initial shared resource layer for Copilot Studio DevOps capability skills. |

This skill provides **shared resources** consumed by the six capability skills that handle Copilot Studio lifecycle operations. It does not route requests itself — each capability skill declares its own intent scope, engine preference, and procedure.

> ⚠️ **CRITICAL: PRODUCTION ENVIRONMENT PROTECTION**
>
> - ✅ **READ-ONLY operations are allowed** on PROD (list, get, export, evaluate via conversation, compare, analytics)
> - ❌ **WRITE operations are PROHIBITED** on PROD (create, update, delete, import, publish, quarantine)
> - ❌ **NEVER expose client secrets, tokens, or Direct Line secrets** in any output
> - Require explicit confirmation before any write operation in non-PROD

## Capability Skills

Each skill self-declares its intent triggers, engine preference, and guardrails. The agent reads these declarations and dispatches accordingly.

| Skill | Lifecycle Domain | Intent Weight |
| --- | --- | --- |
| [copilotstudio-devops-evaluate](../copilotstudio-devops-evaluate/SKILL.md) | Evaluate/test agent conversations | 1.1 |
| [copilotstudio-devops-inventory](../copilotstudio-devops-inventory/SKILL.md) | Inventory, metadata, health | 1.0 |
| [copilotstudio-devops-validate](../copilotstudio-devops-validate/SKILL.md) | Cross-environment validation | 0.95 |
| [copilotstudio-devops-develop](../copilotstudio-devops-develop/SKILL.md) | Build/update agent components | 1.0 |
| [copilotstudio-devops-release-promote](../copilotstudio-devops-release-promote/SKILL.md) | Lifecycle promotion via solutions | 1.0 |
| [copilotstudio-devops-security](../copilotstudio-devops-security/SKILL.md) | Security, governance, admin ops | 1.0 |

## Shared Resources

| Path | Purpose |
| --- | --- |
| [config/environment-catalog.yaml](config/environment-catalog.yaml) | Central environment/agent metadata (consumed by all skills) |
| [config/execution-router.yaml](config/execution-router.yaml) | Engine definitions and fallback policy |
| [modules/safety-guardrails.md](modules/safety-guardrails.md) | Safety rules and environment protections |

## Procedure Modules

Canonical procedures consumed by capability skills via relative reference:

| Module | Consumed By |
| --- | --- |
| [modules/evaluate.md](modules/evaluate.md) | copilotstudio-devops-evaluate |
| [modules/inventory.md](modules/inventory.md) | copilotstudio-devops-inventory |
| [modules/validate.md](modules/validate.md) | copilotstudio-devops-validate |
| [modules/develop.md](modules/develop.md) | copilotstudio-devops-develop |
| [modules/release-promote.md](modules/release-promote.md) | copilotstudio-devops-release-promote |
| [modules/security.md](modules/security.md) | copilotstudio-devops-security |

## Engine Definitions

Available execution engines (shared across all capability skills). All engines execute via **terminal commands** or **Python scripts** — there are no dedicated MCP server bindings for Copilot Studio.

| Engine | Execution Method | Strength |
| --- | --- | --- |
| `semantic-kernel-cs` | Terminal: `python <script>` (semantic-kernel[copilotstudio]) | Agent invocation, conversational evaluation, response scoring |
| `directline-api` | Terminal: `python <script>` or `curl` | Raw conversation testing, load testing, WebSocket evaluation |
| `dataverse-api` | Terminal: `python <script>` or `curl` | Agent/topic CRUD via Dataverse OData API |
| `powerplatform-api` | Terminal: `curl` or Python `requests` | Admin operations (quarantine, bot management) |
| `pac-cli` | Terminal: `pac <command>` | Solution lifecycle (export, import, deploy pipelines) |
| `context7-guidance` | Context7 MCP (advisory only) | Implementation patterns and best practices |

## Response Contract

For each operation, the executing capability skill returns:

- Scope (environment/agent/components)
- Chosen route (intent + primary engine + fallbacks)
- Actions executed
- Findings (PASS/WARN/FAIL)
- Risk notes (guardrails)
- Next step
- Execution metrics (tool calls, classification hops, engine used)

## Skill Loading Pattern

Skills follow a **fast-header + deferred-body** pattern:

1. **Fast header** (SKILL.md) — Intent triggers, weight, engine preference, guardrails (~50 lines). Loaded during routing to determine which skill matches.
2. **Procedure body** (modules/*.md) — Full step-by-step execution procedure (~100-300 lines). Loaded only AFTER the skill is confirmed as the routing winner.

This deferred loading reduces context window pressure during the scoring phase.
```