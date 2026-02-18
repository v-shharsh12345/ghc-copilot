# Comparison Query Patterns

Reusable DAX queries for cross-environment semantic model comparison.

---

## Row Count Queries

### Single Table
```dax
EVALUATE ROW("RowCount", COUNTROWS('TableName'))
```

### Multiple Tables
```dax
EVALUATE
UNION(
    ROW("Table", "FactClaims", "Rows", COUNTROWS('FactClaims')),
    ROW("Table", "FactEarnings", "Rows", COUNTROWS('FactEarnings')),
    ROW("Table", "DimPartner", "Rows", COUNTROWS('DimPartner'))
)
```

### With Filter (Time-scoped)
```dax
EVALUATE
ROW(
    "RowCount",
    CALCULATE(
        COUNTROWS('FactClaims'),
        'DimDate'[FiscalYear] = "FY25"
    )
)
```

---

## Key Metric Queries

### Basic Measures
```dax
EVALUATE
ROW(
    "Metric1", [Total Revenue],
    "Metric2", [Total Claims],
    "Metric3", [Active Partners]
)
```

### With Time Filter
```dax
EVALUATE
CALCULATETABLE(
    ROW(
        "TotalRevenue", [Total Revenue],
        "TotalClaims", [Total Claims]
    ),
    'DimDate'[FiscalQuarter] = "FY25 Q2"
)
```

---

## Data Freshness Queries

### Max Date Check
```dax
EVALUATE
ROW(
    "MaxCalendarDate", MAX('DimDate'[Date]),
    "MaxFactDate", MAX('FactClaims'[ClaimDate]),
    "MaxLoadDate", MAX('FactClaims'[LoadDate])
)
```

### Date Range Coverage
```dax
EVALUATE
ROW(
    "MinDate", MIN('DimDate'[Date]),
    "MaxDate", MAX('DimDate'[Date]),
    "DaysCovered", DATEDIFF(MIN('DimDate'[Date]), MAX('DimDate'[Date]), DAY)
)
```

---

## Dimension Key Coverage

### Distinct Key Counts
```dax
EVALUATE
UNION(
    ROW("Dimension", "Partner", "Keys", DISTINCTCOUNT('DimPartner'[PartnerID])),
    ROW("Dimension", "Customer", "Keys", DISTINCTCOUNT('DimCustomer'[CustomerID])),
    ROW("Dimension", "Geography", "Keys", DISTINCTCOUNT('DimGeo'[GeoID]))
)
```

### Orphan Key Detection
```dax
-- Keys in Fact not in Dimension
EVALUATE
ROW(
    "OrphanPartnerKeys",
    COUNTROWS(
        EXCEPT(
            VALUES('FactClaims'[PartnerID]),
            VALUES('DimPartner'[PartnerID])
        )
    )
)
```

---

## Schema Discovery Helpers

### List All Tables (via schema)
Use `GetSemanticModelSchema` tool - returns all tables with columns.

### Table Column Count
```dax
-- After getting schema, count columns per table
-- This helps identify schema drift
```

---

## Comparison Output Template

After running queries on both environments, format results as:

```markdown
| Metric | ENV_A | ENV_B | Variance | Status |
|--------|-------|-------|----------|--------|
| FactClaims Rows | 100,000 | 99,500 | 0.5% | ✅ OK |
| Total Revenue | $5.2M | $5.1M | 1.9% | ⚠️ WARN |
| Max Date | 2026-01-29 | 2026-01-28 | 1 day | ⚠️ WARN |
```
