---
name: fabric-devops-validate
description: Run cross-environment deployment readiness checks, metadata drift detection, and PASS/WARN/FAIL validation reporting.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-18 | 1.0 | Self-contained capability skill for deployment validation. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `validate`, `compare`, `post deployment`, `verification`, `prod check`, `metadata drift`, `broken object validation` |
| Weight | 0.95 |
| Minimum Confidence | 0.45 |

## Ambiguity Rules

- When prompt contains `schema drift`, `row count`, `metric variance`, `freshness`, or `dataset` → prefer `fabric-devops-semantic-model-testing` instead
- When prompt contains `lineage`, `upstream`, `downstream`, `impact`, `pbir`, or `tmdl` → prefer `fabric-devops-analyze-lineage` instead

## Scope

- Pre- and post-deployment validation across DEV/UAT/PROD
- Metadata drift and broken object detection
- Item inventory parity and definition comparison
- PASS/WARN/FAIL status with actionable next steps

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `fabric-sempy` | Metadata parity, broken object detection (semantic-link-labs) |
| Secondary | `fabric-api` | Item inventory comparison, definition retrieval |
| Operational | `fabric-cli` | Scripted validation flows |
| Guidance | `context7-guidance` | Advisory when tooling is unavailable |

## Procedure

1. Resolve environments and workspace from [workspace-catalog.yaml](../fabric-devops/config/workspace-catalog.yaml).
2. Compare item inventory by name and type across environments.
3. Compare definitions and key bindings.
4. Run metadata parity checks for report and semantic model objects.
5. Validate semantic model compatibility and freshness indicators.
6. Summarize mismatches by severity (PASS / WARN / FAIL).

Canonical procedure reference: [validate.md](../fabric-devops/modules/validate.md)

## Inputs

- Source and target environments
- Item set (reports / semantic models / notebooks / pipelines)
- Validation depth (`quick` or `full`)

## Outputs

- Validation matrix
- PASS / WARN / FAIL status
- Metadata parity summary (broken objects, missing mappings, dependency impact)
- Required fixes before promotion

## Guardrails

- PROD operations are read-only
- Route schema/data parity scenarios to `fabric-devops-semantic-model-testing` when applicable

Full safety policy: [safety-guardrails.md](../fabric-devops/modules/safety-guardrails.md)
