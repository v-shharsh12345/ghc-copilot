# Semantic Model Testing

Run repeatable semantic model comparison checks across DEV, UAT, and PROD as part of Fabric lifecycle validation.

## Scope

- Schema drift detection (tables, columns, measures, relationships)
- Row count variance checks
- Key metric variance checks
- Data freshness alignment checks
- PASS/WARN/FAIL reporting for release readiness

## Primary Inputs

1. Dataset name (required)
2. Environment pair or triad (DEV/UAT/PROD)
3. Optional thresholds override

## Data Sources

- Dataset mapping catalog: `../../compare-semantic-models/dataset-catalog.yaml`
- Reusable query templates: `../../compare-semantic-models/comparison-queries.md`

## Execution Steps

1. Resolve dataset IDs from `dataset-catalog.yaml` for requested environments.
2. Fetch semantic model schemas with `powerbi-remote/GetSemanticModelSchema`.
3. Diff schema objects by environment and classify drift severity.
4. Execute row-count queries for key fact tables.
5. Execute key metric queries using configured/derived measures.
6. Execute freshness queries (max date / refresh indicators).
7. Score checks and produce consolidated PASS/WARN/FAIL output.

## Default Thresholds

| Check | Warn | Fail |
| --- | --- | --- |
| Row count variance | >5% | >20% |
| Metric variance | >0.1% | >1% |
| Freshness lag | >1 day | >3 days |

## Routing Notes

- Prefer this module when prompts mention: schema drift, row count mismatch, metric mismatch, freshness lag, or environment comparison.
- For broader release checks, combine with `validate.md` and return one summary.

## Output Contract

Return:

1. Dataset and environment scope
2. Schema comparison findings
3. Data quality findings (row counts/metrics/freshness)
4. Overall status (PASS/WARN/FAIL)
5. Promotion recommendation (go/no-go + follow-up actions)

