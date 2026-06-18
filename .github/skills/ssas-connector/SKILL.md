---
name: ssas-connector
description: 'Connect to on-prem SQL Server Analysis Services (SSAS) or Azure Analysis Services (AAS) tabular models to discover schema, execute DAX queries, and support cross-platform semantic validation.'
---

# SSAS / AAS Connector Skill

Connect to on-prem SSAS and Azure AAS tabular models using the PowerShell `SqlServer` module (`Invoke-ASCmd`). Supports schema discovery, DAX query execution, and cross-platform comparison with Fabric semantic models.

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-25 | 1.0 | Initial skill — schema discovery, DAX execution, cross-platform comparison support. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `SSAS`, `AAS`, `on-prem cube`, `tabular model`, `analysis services`, `WCSAS`, `XMLA`, `Invoke-ASCmd`, `cube tables`, `cube measures`, `cube schema` |
| Weight | 1.0 |
| Minimum Confidence | 0.45 |

## When to Use

- Discover tables, columns, measures, and relationships in an on-prem SSAS / AAS tabular model
- Execute DAX queries against SSAS / AAS
- Compare an SSAS/AAS model schema or data against a Fabric semantic model (cross-platform validation)
- Audit a tabular model's structure before migration to Fabric

## Prerequisites

- PowerShell module `SqlServer` installed (`Import-Module SqlServer`)
- Network connectivity to the SSAS server hostname
- Windows authentication or token-based access to the target database
- Server and database names (see [ssas-catalog.yaml](config/ssas-catalog.yaml))

---

## Connection Pattern

All queries go through `Invoke-ASCmd` from the `SqlServer` PowerShell module. The agent runs these commands in the terminal.

### Basic Connection Test

```powershell
Import-Module SqlServer
$result = Invoke-ASCmd -Server "<HOSTNAME>" -Database "<DATABASE>" -Query "<Discover xmlns='urn:schemas-microsoft-com:xml-analysis'><RequestType>DBSCHEMA_CATALOGS</RequestType><Restrictions /><Properties /></Discover>"
[xml]$xml = $result
$xml.GetElementsByTagName("row") | ForEach-Object { $_.CATALOG_NAME }
```

### DAX Query Execution

```powershell
Import-Module SqlServer
$dax = @"
EVALUATE ROW("Test", 1)
"@
$result = Invoke-ASCmd -Server "<HOSTNAME>" -Database "<DATABASE>" -Query $dax
[xml]$xml = $result
$xml.GetElementsByTagName("row")
```

---

## Schema Discovery Procedures

### 1. List All Databases on a Server

```powershell
Import-Module SqlServer
$result = Invoke-ASCmd -Server "<HOSTNAME>" -Query "<Discover xmlns='urn:schemas-microsoft-com:xml-analysis'><RequestType>DBSCHEMA_CATALOGS</RequestType><Restrictions /><Properties /></Discover>"
[xml]$xml = $result
$xml.GetElementsByTagName("row") | ForEach-Object { $_.CATALOG_NAME }
```

### 2. List All Tables (Dimensions)

```powershell
$result = Invoke-ASCmd -Server "<HOSTNAME>" -Database "<DATABASE>" -Query "SELECT [DIMENSION_UNIQUE_NAME] FROM `$SYSTEM.MDSCHEMA_DIMENSIONS WHERE [CUBE_NAME] = 'Model' AND [DIMENSION_UNIQUE_NAME] <> '[Measures]' ORDER BY [DIMENSION_UNIQUE_NAME]"
[xml]$xml = $result
$xml.GetElementsByTagName("row") | ForEach-Object { $_.DIMENSION_UNIQUE_NAME }
```

### 3. List All Columns for a Table

```powershell
$result = Invoke-ASCmd -Server "<HOSTNAME>" -Database "<DATABASE>" -Query "SELECT [HIERARCHY_UNIQUE_NAME], [HIERARCHY_CAPTION] FROM `$SYSTEM.MDSCHEMA_HIERARCHIES WHERE [CUBE_NAME] = 'Model' AND [DIMENSION_UNIQUE_NAME] = '[TableName]' ORDER BY [HIERARCHY_CAPTION]"
[xml]$xml = $result
$xml.GetElementsByTagName("row") | ForEach-Object { $_.HIERARCHY_CAPTION }
```

### 4. List All Measures

```powershell
$result = Invoke-ASCmd -Server "<HOSTNAME>" -Database "<DATABASE>" -Query "SELECT [MEASURE_NAME], [MEASURE_UNIQUE_NAME], [DATA_TYPE], [EXPRESSION] FROM `$SYSTEM.MDSCHEMA_MEASURES WHERE [CUBE_NAME] = 'Model' ORDER BY [MEASURE_NAME]"
[xml]$xml = $result
$xml.GetElementsByTagName("row") | ForEach-Object { Write-Output "$($_.MEASURE_NAME) | $($_.DATA_TYPE)" }
```

### 5. List All Relationships

```powershell
$result = Invoke-ASCmd -Server "<HOSTNAME>" -Database "<DATABASE>" -Query "SELECT [DIMENSION_UNIQUE_NAME], [MEASUREGROUP_NAME] FROM `$SYSTEM.MDSCHEMA_MEASUREGROUP_DIMENSIONS WHERE [CUBE_NAME] = 'Model' ORDER BY [MEASUREGROUP_NAME], [DIMENSION_UNIQUE_NAME]"
[xml]$xml = $result
$xml.GetElementsByTagName("row") | ForEach-Object { Write-Output "$($_.MEASUREGROUP_NAME) -> $($_.DIMENSION_UNIQUE_NAME)" }
```

### 6. Row Counts via DAX

```powershell
$dax = @"
EVALUATE
UNION(
    ROW("Table", "TableName1", "Rows", COUNTROWS('TableName1')),
    ROW("Table", "TableName2", "Rows", COUNTROWS('TableName2'))
)
"@
$result = Invoke-ASCmd -Server "<HOSTNAME>" -Database "<DATABASE>" -Query $dax
[xml]$xml = $result
$xml.GetElementsByTagName("row") | ForEach-Object {
    Write-Output "$($_.Table) : $($_.Rows)"
}
```

### 7. Key Metrics via DAX

```powershell
$dax = @"
EVALUATE
ROW(
    "Metric1", [Measure Name 1],
    "Metric2", [Measure Name 2]
)
"@
$result = Invoke-ASCmd -Server "<HOSTNAME>" -Database "<DATABASE>" -Query $dax
```

### 8. Data Freshness via DAX

```powershell
$dax = @"
EVALUATE
ROW(
    "MaxDate", MAX('Calendar'[Date])
)
"@
$result = Invoke-ASCmd -Server "<HOSTNAME>" -Database "<DATABASE>" -Query $dax
```

---

## Cross-Platform Comparison Workflow

When comparing an SSAS/AAS model against a Fabric semantic model:

```
┌─────────────────────────────────────────────────────────────────┐
│       CROSS-PLATFORM COMPARISON WORKFLOW                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  INPUT: SSAS server/db + Fabric dataset name/environment        │
│                                                                 │
│  1. RESOLVE TARGETS                                             │
│     ├─ SSAS: Lookup server/db from ssas-catalog.yaml            │
│     └─ Fabric: Lookup datasetId from dataset-catalog.yaml       │
│                                                                 │
│  2. SCHEMA EXTRACTION (parallel)                                │
│     ├─ SSAS: Run schema discovery procedures (§ above)          │
│     └─ Fabric: GetSemanticModelSchema via powerbi-remote        │
│                                                                 │
│  3. SCHEMA DIFF                                                 │
│     ├─ Compare table names (normalize bracket notation)         │
│     ├─ Compare column names per table                           │
│     ├─ Compare measure names and expressions                    │
│     └─ Flag: Added / Removed / Renamed / Type-changed           │
│                                                                 │
│  4. DATA COMPARISON (parallel)                                  │
│     ├─ SSAS: Execute DAX row counts + metrics via Invoke-ASCmd  │
│     └─ Fabric: Execute same DAX via powerbi-remote              │
│                                                                 │
│  5. FRESHNESS COMPARISON                                        │
│     ├─ SSAS: Query MAX dates via DAX                            │
│     └─ Fabric: Query MAX dates via DAX                          │
│                                                                 │
│  6. OUTPUT REPORT                                               │
│     └─ Unified PASS/WARN/FAIL table (same thresholds as        │
│        fabric-devops-semantic-model-testing)                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Normalization Rules

When comparing SSAS ↔ Fabric schemas, normalize names:
- Strip brackets: `[Account Information]` → `Account Information`
- Case-insensitive comparison
- Ignore system/internal tables (e.g., `[Measures]`, `[Data Dictionary]`)

---

## Thresholds

Same thresholds as [fabric-devops-semantic-model-testing](../fabric-devops-semantic-model-testing/SKILL.md):

| Check | OK | WARN | FAIL |
|-------|-----|------|------|
| Row Count Variance | ≤5% | 5-20% | >20% |
| Metric Variance | ≤0.1% | 0.1-1% | >1% |
| Freshness Gap | Same day | 1-2 days | >3 days |
| Missing Schema Objects | 0 | New in source | Missing in target |

---

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `powershell-ssas` | Schema discovery and DAX via `Invoke-ASCmd` (SqlServer module) |
| Secondary | `powerbi-remote` | Fabric-side schema and DAX for cross-platform comparison |
| Guidance | `context7-guidance` | Advisory when tooling is unavailable |

---

## Inputs

- Server hostname (required)
- Database name (required, or discover from server)
- Query type: `schema` | `tables` | `columns` | `measures` | `relationships` | `dax` | `compare`
- For comparison: Fabric dataset name + environment

## Outputs

- Table/column/measure/relationship listings
- DAX query results
- Cross-platform comparison report (PASS/WARN/FAIL)

## Guardrails

- SSAS connections are **read-only** — no write/process commands
- Never send `ALTER`, `CREATE`, `DELETE`, `Process` XMLA commands
- Only `Discover` and `EVALUATE` (DAX) operations are permitted
- For cross-platform comparison, PROD Fabric side is also read-only per [safety-guardrails.md](../fabric-devops/modules/safety-guardrails.md)

## Files

| File | Purpose |
|------|---------|
| [config/ssas-catalog.yaml](config/ssas-catalog.yaml) | Server/database registry |
| [modules/query-patterns.md](modules/query-patterns.md) | Reusable PowerShell query templates |
