# SSAS Query Patterns Module

Reusable PowerShell templates for querying SSAS/AAS tabular models via `Invoke-ASCmd`.

> **Convention:** All queries use `Import-Module SqlServer` and `Invoke-ASCmd`.
> Replace `<SERVER>` and `<DATABASE>` with values from [ssas-catalog.yaml](../config/ssas-catalog.yaml).

---

## Schema Discovery

### List Databases

```powershell
Import-Module SqlServer
$result = Invoke-ASCmd -Server "<SERVER>" -Query @"
<Discover xmlns='urn:schemas-microsoft-com:xml-analysis'>
  <RequestType>DBSCHEMA_CATALOGS</RequestType>
  <Restrictions />
  <Properties />
</Discover>
"@
[xml]$xml = $result
$xml.GetElementsByTagName("row") | ForEach-Object { $_.CATALOG_NAME }
```

### List Tables

```powershell
$result = Invoke-ASCmd -Server "<SERVER>" -Database "<DATABASE>" -Query @"
SELECT [DIMENSION_UNIQUE_NAME]
FROM `$SYSTEM.MDSCHEMA_DIMENSIONS
WHERE [CUBE_NAME] = 'Model'
  AND [DIMENSION_UNIQUE_NAME] <> '[Measures]'
ORDER BY [DIMENSION_UNIQUE_NAME]
"@
[xml]$xml = $result
$xml.GetElementsByTagName("row") | ForEach-Object { $_.DIMENSION_UNIQUE_NAME }
```

### List Columns for a Table

```powershell
$tableName = "Account Information"
$result = Invoke-ASCmd -Server "<SERVER>" -Database "<DATABASE>" -Query @"
SELECT [HIERARCHY_UNIQUE_NAME], [HIERARCHY_CAPTION], [DEFAULT_MEMBER]
FROM `$SYSTEM.MDSCHEMA_HIERARCHIES
WHERE [CUBE_NAME] = 'Model'
  AND [DIMENSION_UNIQUE_NAME] = '[$tableName]'
ORDER BY [HIERARCHY_CAPTION]
"@
[xml]$xml = $result
$xml.GetElementsByTagName("row") | ForEach-Object {
    Write-Output "$($_.HIERARCHY_CAPTION)"
}
```

### List All Measures

```powershell
$result = Invoke-ASCmd -Server "<SERVER>" -Database "<DATABASE>" -Query @"
SELECT [MEASURE_NAME], [MEASURE_UNIQUE_NAME], [DATA_TYPE], [EXPRESSION]
FROM `$SYSTEM.MDSCHEMA_MEASURES
WHERE [CUBE_NAME] = 'Model'
ORDER BY [MEASURE_NAME]
"@
[xml]$xml = $result
$xml.GetElementsByTagName("row") | ForEach-Object {
    Write-Output "$($_.MEASURE_NAME) | Type: $($_.DATA_TYPE)"
}
```

### List Relationships (Measure Group Dimensions)

```powershell
$result = Invoke-ASCmd -Server "<SERVER>" -Database "<DATABASE>" -Query @"
SELECT [MEASUREGROUP_NAME], [DIMENSION_UNIQUE_NAME], [DIMENSION_GRANULARITY]
FROM `$SYSTEM.MDSCHEMA_MEASUREGROUP_DIMENSIONS
WHERE [CUBE_NAME] = 'Model'
ORDER BY [MEASUREGROUP_NAME], [DIMENSION_UNIQUE_NAME]
"@
[xml]$xml = $result
$xml.GetElementsByTagName("row") | ForEach-Object {
    Write-Output "$($_.MEASUREGROUP_NAME) -> $($_.DIMENSION_UNIQUE_NAME)"
}
```

---

## DAX Queries

### Row Counts

```powershell
$dax = @"
EVALUATE
UNION(
    ROW("Table", "Table1", "Rows", COUNTROWS('Table1')),
    ROW("Table", "Table2", "Rows", COUNTROWS('Table2'))
)
"@
$result = Invoke-ASCmd -Server "<SERVER>" -Database "<DATABASE>" -Query $dax
[xml]$xml = $result
$xml.GetElementsByTagName("row") | ForEach-Object {
    Write-Output "$($_.Table) : $($_.Rows)"
}
```

### Key Metrics

```powershell
$dax = @"
EVALUATE
ROW(
    "Metric1_Value", [Metric1],
    "Metric2_Value", [Metric2]
)
"@
$result = Invoke-ASCmd -Server "<SERVER>" -Database "<DATABASE>" -Query $dax
[xml]$xml = $result
$xml.GetElementsByTagName("row")
```

### Data Freshness

```powershell
$dax = @"
EVALUATE
ROW(
    "MaxCalendarDate", MAX('Calendar'[Date])
)
"@
$result = Invoke-ASCmd -Server "<SERVER>" -Database "<DATABASE>" -Query $dax
[xml]$xml = $result
$xml.GetElementsByTagName("row") | ForEach-Object { $_.MaxCalendarDate }
```

### Distinct Key Counts

```powershell
$dax = @"
EVALUATE
UNION(
    ROW("Dimension", "Dim1", "Keys", DISTINCTCOUNT('Dim1'[KeyColumn])),
    ROW("Dimension", "Dim2", "Keys", DISTINCTCOUNT('Dim2'[KeyColumn]))
)
"@
$result = Invoke-ASCmd -Server "<SERVER>" -Database "<DATABASE>" -Query $dax
[xml]$xml = $result
$xml.GetElementsByTagName("row") | ForEach-Object {
    Write-Output "$($_.Dimension) : $($_.Keys) distinct keys"
}
```

---

## XML Response Parsing

`Invoke-ASCmd` returns XML. Standard parsing pattern:

```powershell
# Cast to XML
[xml]$xml = $result

# Extract rows
$rows = $xml.GetElementsByTagName("row")

# Access fields by element name (matches the column alias in DAX or the schema field name)
foreach ($row in $rows) {
    $row.FieldName
}
```

For DAX `EVALUATE` results, the field names match the aliases in `ROW()` calls:
- `ROW("Table", "Foo", "Rows", 100)` → `$row.Table`, `$row.Rows`

For schema rowset queries (`$SYSTEM.*`), field names match the column names in the DMV:
- `DIMENSION_UNIQUE_NAME`, `MEASURE_NAME`, `HIERARCHY_CAPTION`, etc.

---

## Cross-Platform: SSAS vs Fabric Side-by-Side

To compare an SSAS model against a Fabric semantic model:

### Step 1: Extract SSAS schema (PowerShell)
Run the "List Tables" and "List Columns" patterns above.

### Step 2: Extract Fabric schema (powerbi-remote)
```
mcp_powerbi-remot_GetSemanticModelSchema(artifactId="<datasetId>")
```

### Step 3: Compare
- Normalize table names (strip brackets, case-insensitive)
- Diff table lists, column lists, measure lists
- Run matching DAX on both and compare values

### Step 4: Report
Use unified PASS/WARN/FAIL format from [comparison-queries.md](../../compare-semantic-models/comparison-queries.md).
