```skill
---
name: copilotstudio-devops-evaluate
description: Evaluate and test Copilot Studio agents by invoking them programmatically — score response quality, test topic triggering, benchmark latency, and run regression test suites.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-23 | 1.0 | Self-contained capability skill for Copilot Studio agent evaluation and testing. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `evaluate`, `test`, `invoke`, `conversation`, `score`, `benchmark`, `Direct Line`, `response quality`, `regression`, `test suite` |
| Weight | 1.1 |
| Minimum Confidence | 0.45 |

## Scope

- Invoke a published Copilot Studio agent with test utterances
- Score response quality (relevance, accuracy, completeness)
- Test topic triggering accuracy against expected topics
- Benchmark response latency and throughput
- Run regression test suites across multiple scenarios
- Compare evaluation results across environments (DEV vs PROD)

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `semantic-kernel-cs` | Conversational evaluation via CopilotStudioAgent Python SDK |
| Secondary | `directline-api` | Performance testing, load testing, raw conversation flow |
| Guidance | `context7-guidance` | Implementation patterns when engines are unavailable |

## Procedure

1. Resolve environment and agent from [environment-catalog.yaml](../copilotstudio-devops/config/environment-catalog.yaml).
2. Verify authentication (Entra ID app for SK, or Direct Line token for DL).
3. Prepare test scenarios (user-provided or from test manifest).
4. Invoke agent with test utterances via preferred engine.
5. Collect responses, latency, and metadata.
6. Score responses against expected outcomes.
7. Return evaluation summary with PASS/WARN/FAIL verdicts.

Canonical procedure reference: [evaluate.md](../copilotstudio-devops/modules/evaluate.md)

## Inputs

- **Copilot Studio URL** (e.g., `https://copilotstudio.preview.microsoft.com/environments/{ENV_ID}/bots/{BOT_ID}/overview`) — agent parses ENV_ID and BOT_ID automatically
- OR **Environment ID** (raw GUID) + **Bot ID** (raw GUID)
- Test utterances (list of messages to send)
- Expected outcomes (optional — expected topic, expected response patterns)
- Scoring criteria (optional — relevance, accuracy, latency thresholds)

## Outputs

- Per-utterance results: response text, triggered topic, latency, score
- Aggregate scores: pass rate, average latency, topic accuracy
- Evaluation verdict: PASS/WARN/FAIL
- Regression comparison (if baseline provided)

## Guardrails

- Evaluation is non-destructive but may trigger external connectors
- Warn the user about potential side effects before evaluation
- Never evaluate with real user data containing PII
- PROD evaluation is allowed (read-only conversation) but rate-limit to avoid quota impact
- Log all evaluation runs for audit trail

Full safety policy: [safety-guardrails.md](../copilotstudio-devops/modules/safety-guardrails.md)
```