---
name: fabric-devops-semantic-model-testing
description: Run repeatable semantic model schema, row-count, metric, and freshness parity checks across DEV/UAT/PROD environments.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-18 | 1.0 | Self-contained capability skill for semantic model testing workflows. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `semantic model`, `semantic models`, `dataset compare`, `model compare`, `schema drift`, `row count variance`, `metric variance`, `data freshness`, `dev vs uat`, `uat vs prod`, `deployment readiness` |
| Weight | 1.1 |
| Minimum Confidence | 0.45 |

## Scope

- Resolve dataset IDs per environment from [dataset-catalog.yaml](../compare-semantic-models/dataset-catalog.yaml)
- Compare schema objects across DEV/UAT/PROD (tables, columns, measures, relationships)
- Run row-count, metric, and freshness parity checks with configurable thresholds
- Produce PASS/WARN/FAIL report for release readiness

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `powerbi-remote` | Schema retrieval, DAX query execution |
| Secondary | `fabric-sempy` | Analytical validation and comparison |
| Guidance | `context7-guidance` | Advisory when tooling is unavailable |

## Default Thresholds

| Check | Warn | Fail |
| --- | --- | --- |
| Row count variance | >5% | >20% |
| Metric variance | >0.1% | >1% |
| Freshness lag | >1 day | >3 days |

## Procedure

1. Resolve dataset IDs from [dataset-catalog.yaml](../compare-semantic-models/dataset-catalog.yaml) for requested environments.
2. Fetch semantic model schemas with `powerbi-remote/GetSemanticModelSchema`.
3. Diff schema objects by environment and classify drift severity.
4. Execute row-count queries for key fact tables.
5. Execute key metric queries using configured/derived measures.
6. Execute freshness queries (max date / refresh indicators).
7. Score checks and produce consolidated PASS/WARN/FAIL output.

Canonical procedure reference: [semantic-model-testing.md](../fabric-devops/modules/semantic-model-testing.md)
Reusable query templates: [comparison-queries.md](../compare-semantic-models/comparison-queries.md)

## Inputs

- Dataset name (required)
- Environment pair or triad (DEV / UAT / PROD)
- Optional thresholds override

## Outputs

- Dataset and environment scope
- Schema comparison findings
- Data quality findings (row counts / metrics / freshness)
- Overall status (PASS / WARN / FAIL)
- Promotion recommendation (go / no-go + follow-up actions)

## Guardrails

- Treat PROD as read-only
- Apply threshold-based PASS/WARN/FAIL output for data-quality checks
- For broader release checks, combine with `fabric-devops-validate` and return one summary

Full safety policy: [safety-guardrails.md](../fabric-devops/modules/safety-guardrails.md)
