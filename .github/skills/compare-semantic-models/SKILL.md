---
name: semantic-model-comparator
description: 'Compare Fabric semantic models across DEV/UAT/PROD environments for schema drift, data quality, and deployment readiness.'
---

# Semantic Model Comparator Skill

Compare semantic models across environments using `#powerbi-remote` tools. No report parsing required - direct model-to-model comparison.

## When to Use

- Validate data quality before/after deployments
- Detect schema drift between environments
- Compare row counts and key metrics
- Check data freshness alignment
- Identify new features in lower environments pending promotion

## Prerequisites

- `#powerbi-remote` tools authenticated
- Dataset IDs known (see [dataset-catalog.yaml](dataset-catalog.yaml))

---

## Comparison Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│           SEMANTIC MODEL COMPARISON WORKFLOW                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  INPUT: Dataset name + Environments (DEV/UAT/PROD)              │
│                                                                 │
│  1. RESOLVE IDs                                                 │
│     └─ Lookup datasetId per environment from catalog            │
│                                                                 │
│  2. SCHEMA COMPARISON                                           │
│     ├─ GetSemanticModelSchema(ENV_A)                            │
│     ├─ GetSemanticModelSchema(ENV_B)                            │
│     └─ Diff: Tables, Columns, Measures, Relationships           │
│                                                                 │
│  3. ROW COUNT COMPARISON                                        │
│     ├─ Query each environment                                   │
│     └─ Flag variance > 5%                                       │
│                                                                 │
│  4. KEY METRICS COMPARISON                                      │
│     ├─ Identify key measures from schema                        │
│     ├─ Execute on each environment                              │
│     └─ Compare with tolerance (0.1%)                            │
│                                                                 │
│  5. DATA FRESHNESS                                              │
│     ├─ Query MAX dates                                          │
│     └─ Flag if PROD behind by >1 day                            │
│                                                                 │
│  6. OUTPUT REPORT                                               │
│     └─ Summary table with PASS/WARN/FAIL                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Tool Usage Patterns

### 1. Get Schema for Comparison

```
Use: mcp_powerbi-remot_GetSemanticModelSchema
Input: artifactId = "<datasetId>"
Output: Tables, columns, measures, relationships
```

### 2. Generate Comparison Query

```
Use: mcp_powerbi-remot_GenerateQuery
Input: 
  - artifactId = "<datasetId>"
  - userInput = "Count rows in FactClaims table"
  - schemaSelection = { tables: [{ name: "FactClaims", columns: [] }] }
```

### 3. Execute and Compare

```
Use: mcp_powerbi-remot_ExecuteQuery
Input:
  - artifactId = "<datasetId>"
  - daxQuery = "EVALUATE ROW(\"Count\", COUNTROWS('FactClaims'))"
```

---

## Standard Comparison Queries

### Row Counts (All Fact Tables)
```dax
EVALUATE
UNION(
    ROW("Table", "FactClaims", "Rows", COUNTROWS('FactClaims')),
    ROW("Table", "FactEarnings", "Rows", COUNTROWS('FactEarnings')),
    ROW("Table", "FactEngagements", "Rows", COUNTROWS('FactEngagements'))
)
```

### Key Metrics Summary
```dax
EVALUATE
ROW(
    "TotalRevenue", [Total Revenue],
    "TotalClaims", [Total Claims],
    "ActivePartners", [Active Partners]
)
```

### Data Freshness
```dax
EVALUATE
ROW(
    "MaxCalendarDate", MAX('DimDate'[Date]),
    "MaxLoadDate", MAX('FactClaims'[LoadDate])
)
```

### Dimension Coverage
```dax
EVALUATE
UNION(
    ROW("Dimension", "Partner", "DistinctKeys", DISTINCTCOUNT('DimPartner'[PartnerID])),
    ROW("Dimension", "Customer", "DistinctKeys", DISTINCTCOUNT('DimCustomer'[CustomerID])),
    ROW("Dimension", "Geography", "DistinctKeys", DISTINCTCOUNT('DimGeo'[GeoID]))
)
```

---

## Thresholds

| Metric | OK | WARNING | ERROR |
|--------|-----|---------|-------|
| Row Count Variance | ≤5% | 5-20% | >20% |
| Metric Variance | ≤0.1% | 0.1-1% | >1% |
| Data Freshness Gap | Same day | 1-2 days | >3 days |
| Missing Schema Objects | 0 | New in lower | Missing in lower |

---

## Files

| File | Purpose |
|------|---------|
| [dataset-catalog.yaml](dataset-catalog.yaml) | Dataset IDs by environment |
| [comparison-queries.md](comparison-queries.md) | Reusable DAX patterns |
