```skill
---
name: copilotstudio-devops-validate
description: Cross-environment validation of Copilot Studio agents — compare topic coverage, knowledge sources, actions, and configuration between DEV/UAT/PROD via solution diff and Dataverse queries.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-23 | 1.0 | Self-contained capability skill for cross-environment Copilot Studio agent validation. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `validate`, `compare`, `drift`, `topic diff`, `prod check`, `parity`, `configuration`, `cross-environment`, `code review`, `review agent`, `diff dev prod` |
| Weight | 0.95 |
| Minimum Confidence | 0.45 |

## Scope

- Compare agent topic lists between environments
- Detect knowledge source drift (missing/different sources across envs)
- Compare action/connector configurations
- Validate solution component parity via PAC CLI export + diff
- Identify a configuration drift report with PASS/WARN/FAIL

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `pac-cli` | `pac copilot extract-template` from both envs → YAML diff (PROVEN: extracts full agent config) |
| Secondary | `dataverse-api` | Query both environments and compare component metadata |
| Guidance | `context7-guidance` | Implementation patterns when engines are unavailable |

## Procedure

1. Resolve both source and target environments from [environment-catalog.yaml](../copilotstudio-devops/config/environment-catalog.yaml).
2. Verify authentication for both environments.
3. Query agent components from both environments.
4. Compare: topics, knowledge sources, actions, entities, triggers.
5. Generate drift report with categorized differences.
6. Return PASS/WARN/FAIL verdict based on severity.

Canonical procedure reference: [validate.md](../copilotstudio-devops/modules/validate.md)

## Inputs

- **Source Copilot Studio URL** (e.g., DEV agent URL) — agent parses ENV_ID and BOT_ID automatically
- **Target Copilot Studio URL** (e.g., PROD agent URL) — agent parses ENV_ID and BOT_ID automatically
- OR **Source Environment ID** + **Bot ID** and **Target Environment ID** + **Bot ID**
- Validation scope (optional — `topics`, `knowledge`, `actions`, `all`)

## Outputs

- Drift report: components present in source but missing in target (and vice versa)
- Configuration differences: changed properties between environments
- Validation verdict: PASS (identical), WARN (minor differences), FAIL (critical drift)

## Guardrails

- Read-only operation in both environments
- Never modify either environment as part of validation
- Both environments must be accessible with valid auth

Full safety policy: [safety-guardrails.md](../copilotstudio-devops/modules/safety-guardrails.md)
```