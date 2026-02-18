# Compare Semantic Models Skill

## Overview

The **compare-semantic-models** skill compares Fabric semantic models across DEV/UAT/PROD environments for schema drift, data quality differences, and deployment readiness. It uses `#powerbi-remote` tools for direct model-to-model comparison.

This skill is treated as a reusable workflow asset and is executed through the `fabric-devops` semantic model testing module.

## Key Capabilities

| Capability | Description |
|------------|-------------|
| **Schema comparison** | Diff tables, columns, measures, and relationships across environments |
| **Row count validation** | Compare row counts with configurable variance threshold (default 5%) |
| **Key metrics comparison** | Execute and compare key measures with tolerance (0.1%) |
| **Data freshness check** | Verify MAX dates align; flag if PROD behind by >1 day |
| **PASS/WARN/FAIL output** | Summary report with clear status indicators |

## Supported Datasets

Datasets are cataloged in `dataset-catalog.yaml` with environment-specific IDs for:

- Azure Investments Dataset
- Activities Utilization Dataset
- MBR Dataset
- Other datasets defined in the catalog

## Example Invocations

```
"Compare AzureInvestments between DEV and PROD"
"Check schema drift for Activities Utilization across all environments"
"Validate data quality before promoting to PROD"
"Are row counts consistent between UAT and PROD?"
```

## Required MCP Servers

- **Power BI Remote** (`#powerbi-remote`) — Schema queries and DAX execution across environments

## Workflow

1. **Resolve IDs** — Look up `datasetId` per environment from the catalog
2. **Schema comparison** — `GetSemanticModelSchema()` on each environment, then diff
3. **Row count comparison** — Query each environment, flag variance >5%
4. **Key metrics comparison** — Execute key measures, compare with 0.1% tolerance
5. **Data freshness** — Query MAX dates, flag if PROD is behind
6. **Output report** — Summary table with PASS/WARN/FAIL per check

## Supporting Files

| File | Purpose |
|------|---------|
| `dataset-catalog.yaml` | Environment-specific dataset IDs and metadata |
| `comparison-queries.md` | Reusable DAX query templates for comparisons |

## Source File

[.github/skills/compare-semantic-models/SKILL.md](../../.github/skills/compare-semantic-models/SKILL.md)
