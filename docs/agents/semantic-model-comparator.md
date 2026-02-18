# Semantic Model Comparator Agent

> **File:** `.github/agents/semantic-model-comparator.agent.md`
> **Version:** Deprecated

## Status

This agent is deprecated.

Use the `fabric-devops` agent with `modules/semantic-model-testing.md` for all semantic model comparison workflows.

## Overview

The legacy **Semantic Model Comparator** capability has been moved under `fabric-devops` to keep Fabric engineering and Fabric testing in one operational path.

## What It Compares

| Check | Description |
|-------|-------------|
| **Schema Diff** | New/missing/changed columns, measures, relationships |
| **Row Counts** | Per-table row count variance between environments |
| **Key Metrics** | Aggregated DAX measures compared across environments |
| **Data Freshness** | Last refresh timestamps aligned between environments |

## Thresholds

| Check | Warning | Error |
|-------|---------|-------|
| Row Count Variance | > 5% | > 20% |
| Metric Variance | > 0.1% | > 1% |
| Data Freshness | PROD 1+ day behind | PROD 3+ days behind |
| Schema Drift | New columns in lower env | Missing columns in lower env |

## Configuration

The agent uses two supporting files in the `compare-semantic-models` skill:

- **`dataset-catalog.yaml`** — Maps dataset names to their Fabric dataset IDs across DEV, UAT, and PROD environments
- **`comparison-queries.md`** — Reusable DAX query patterns for row counts, metrics, freshness checks, and key coverage validation

### Adding a New Dataset

Add an entry to `dataset-catalog.yaml`:

```yaml
- name: MyNewDataset
  dev:
    datasetId: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    workspace: "DEV-Workspace-Name"
  uat:
    datasetId: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    workspace: "UAT-Workspace-Name"
  prod:
    datasetId: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    workspace: "PROD-Workspace-Name"
```

## Migration

1. Use `fabric-devops` for semantic model requests.
2. Keep using `compare-semantic-models` skill assets (`dataset-catalog.yaml`, `comparison-queries.md`).
3. Route prompts with terms like "schema drift", "metric variance", "row count variance", or "data freshness" to semantic model testing.

## Example Prompts

```
Compare AzureInvestments DEV vs PROD
Check schema drift for Claims dataset across all environments
Validate row counts for Eligibility DEV vs UAT
Are metrics consistent between UAT and PROD for IncentiveReporting?
```

## Output Format

The agent produces a structured comparison report:

```
## Comparison: AzureInvestments — DEV vs PROD

### Schema Comparison
✅ Tables match (12/12)
⚠️ 2 new columns in DEV not in PROD: [dim_Partner.NewFlag, fact_Claims.AdjustmentType]

### Row Counts
| Table | DEV | PROD | Variance | Status |
|-------|-----|------|----------|--------|
| fact_Claims | 1,245,000 | 1,240,000 | 0.4% | ✅ PASS |
| dim_Partner | 8,500 | 8,200 | 3.7% | ✅ PASS |

### Key Metrics
| Metric | DEV | PROD | Variance | Status |
|--------|-----|------|----------|--------|
| Total Revenue | $12.5M | $12.4M | 0.08% | ✅ PASS |

### Data Freshness
| Environment | Last Refresh | Status |
|-------------|-------------|--------|
| DEV | 2026-02-18 06:00 | ✅ |
| PROD | 2026-02-18 05:30 | ✅ |

**Overall: ✅ PASS (1 warning)**
```
