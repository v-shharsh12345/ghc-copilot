$ErrorActionPreference = "Stop"

# Ensure ImportExcel
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
  Write-Host "Installing ImportExcel..."
  Install-Module ImportExcel -Scope CurrentUser -Force -AllowClobber
}
Import-Module ImportExcel

$sqlTok = az account get-access-token --resource "https://database.windows.net/" --query accessToken -o tsv
if (-not $sqlTok) { throw "Could not get Azure access token. Run 'az login' first." }

function Invoke-FabricQuery {
  param($server, $db, $token, $sql)
  $conn = New-Object System.Data.SqlClient.SqlConnection
  $conn.ConnectionString = "Server=tcp:$server,1433;Database=$db;Encrypt=True;TrustServerCertificate=False;Connection Timeout=120;"
  $conn.AccessToken = $token
  $conn.Open()
  $cmd = $conn.CreateCommand(); $cmd.CommandText = $sql; $cmd.CommandTimeout = 600
  $da = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
  $dt = New-Object System.Data.DataTable; [void]$da.Fill($dt); $conn.Close()
  return ,$dt
}

# Endpoints
$salesServer = "x6eps4xrq2xudenlfv6naeo3i4-wkxkhwrfvh7exepkpoy75r6w7a.msit-datawarehouse.fabric.microsoft.com"
$salesDb     = "POSOT_Sales"
$pprServer   = "x6eps4xrq2xudenlfv6naeo3i4-gs7rn6r7m2oetco33xb7dwa6o4.msit-datawarehouse.fabric.microsoft.com"
$pprDb       = "PPR Warehouse"
# DimIntegrationTime lives in POSOT_Integration (integration workspace), NOT in Sales.
$intServer   = "x6eps4xrq2xudenlfv6naeo3i4-gs7rn6r7m2oetco33xb7dwa6o4.msit-datawarehouse.fabric.microsoft.com"
$intDb       = "POSOT_Integration"

# Resolve latest SalesGold schema (FactSales + Map_Partner_Association_Sales + DimPartnerAssociation)
$schemaSql = @"
SELECT s.name AS SchemaName
FROM sys.schemas s
WHERE s.name LIKE 'SalesGold20%'
  AND EXISTS (SELECT 1 FROM sys.tables t WHERE t.schema_id = s.schema_id AND t.name = 'FactSales')
  AND EXISTS (SELECT 1 FROM sys.tables t WHERE t.schema_id = s.schema_id AND t.name = 'Map_Partner_Association_Sales')
  AND EXISTS (SELECT 1 FROM sys.tables t WHERE t.schema_id = s.schema_id AND t.name = 'DimPartnerAssociation')
ORDER BY s.name DESC
"@
$schemaDt = Invoke-FabricQuery -server $salesServer -db $salesDb -token $sqlTok -sql $schemaSql
if ($schemaDt.Rows.Count -eq 0) { throw "No SalesGold schema with required tables found." }
$salesSchema = [string]$schemaDt.Rows[0]["SchemaName"]
Write-Host "Resolved latest SalesGold schema: $salesSchema"

# Resolve latest IntegrationGold schema holding DimIntegrationTime
$intSchemaSql = @"
SELECT s.name AS SchemaName
FROM sys.schemas s
WHERE s.name LIKE 'IntegrationGold20%'
  AND EXISTS (SELECT 1 FROM sys.tables t WHERE t.schema_id = s.schema_id AND t.name = 'DimIntegrationTime')
ORDER BY s.name DESC
"@
$intSchemaDt = Invoke-FabricQuery -server $intServer -db $intDb -token $sqlTok -sql $intSchemaSql
if ($intSchemaDt.Rows.Count -eq 0) { throw "No IntegrationGold schema with DimIntegrationTime found." }
$intSchema = [string]$intSchemaDt.Rows[0]["SchemaName"]
Write-Host "Resolved latest IntegrationGold schema: $intSchema"

# Fetch DimIntegrationTime (FiscalMonthID -> FiscalMonthName) from POSOT_Integration once; join in-memory.
$ditSql = "SELECT DISTINCT FiscalMonthID, FiscalMonthName FROM [$intSchema].[DimIntegrationTime] WHERE FiscalMonthID IS NOT NULL"
$ditDt = Invoke-FabricQuery -server $intServer -db $intDb -token $sqlTok -sql $ditSql
$dit = @{}
foreach ($r in $ditDt.Rows) { $dit[[int]$r["FiscalMonthID"]] = [string]$r["FiscalMonthName"] }
Write-Host "DimIntegrationTime rows (integration): $($ditDt.Rows.Count)"

# =====================================================================
# QUERY 1: PPR Warehouse based on Fiscalmonth(Sales)
# PPR side: uses [PPR Warehouse].[Gold].[DimIntegrationTime] (notebook verbatim).
# =====================================================================
$pprFmSql = @"
with cte as (
    SELECT Distinct A.AssociationID
    FROM  [PPR Warehouse].[Gold].[Map_Partner_Association_Sales] A
    inner join [PPR Warehouse].[Gold].[DimPartnerAssociation] M
    on M.AssociationID = A.AssociationID
)
SELECT F.FiscalMonthID, T.FiscalMonthName, SUM(F.SoldSeatsRevenue) AS TotalSoldSeatsRevenue
FROM [PPR Warehouse].[Gold].[FactSalesPPR] F
inner JOIN [PPR Warehouse].[Gold].[DimIntegrationTime] T ON T.FiscalMonthID = F.FiscalMonthID
inner join cte c on c.AssociationID = F.AssociationID
GROUP BY F.FiscalMonthID, T.FiscalMonthName
ORDER BY F.FiscalMonthID
"@

# Sales side: SAME query, only schema swapped. FactSalesPPR -> FactSales (PPR fact absent in Sales).
# DimIntegrationTime taken from POSOT_Integration (joined in-memory below), NOT DimSalesTime.
$salesFmSql = @"
with cte as (
    SELECT Distinct A.AssociationID
    FROM  [$salesSchema].[Map_Partner_Association_Sales] A
    inner join [$salesSchema].[DimPartnerAssociation] M
    on M.AssociationID = A.AssociationID
)
SELECT F.FiscalMonthID, SUM(F.SoldSeatsRevenue) AS TotalSoldSeatsRevenue
FROM [$salesSchema].[FactSales] F
inner join cte c on c.AssociationID = F.AssociationID
GROUP BY F.FiscalMonthID
ORDER BY F.FiscalMonthID
"@

# =====================================================================
# QUERY 2: PPR Warehouse based on Association Type(Sales)
# DimIntegrationTime here is a LEFT JOIN not used in output/filter (no-op on the
# AssociationName grouped sum when FiscalMonthID is unique in the time dim).
# =====================================================================
$pprAtSql = @"
with cte as (
    SELECT Distinct A.AssociationID, A.AssociationName
    FROM  [PPR Warehouse].[Gold].[Map_Partner_Association_Sales] A
)
SELECT M.AssociationName, SUM(SoldSeatsRevenue) AS BilledRevenue
FROM [PPR Warehouse].[Gold].[FactSalesPPR] AS FAC
Inner join cte M on M.AssociationID = FAC.AssociationID
LEFT JOIN [PPR Warehouse].[Gold].[DimIntegrationTime] DT ON FAC.FiscalMonthID = DT.FiscalMonthID
GROUP BY M.AssociationName
"@

$salesAtSql = @"
with cte as (
    SELECT Distinct A.AssociationID, A.AssociationName
    FROM  [$salesSchema].[Map_Partner_Association_Sales] A
)
SELECT M.AssociationName, SUM(SoldSeatsRevenue) AS BilledRevenue
FROM [$salesSchema].[FactSales] AS FAC
Inner join cte M on M.AssociationID = FAC.AssociationID
GROUP BY M.AssociationName
"@

$runUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")

# ---------------- Run FiscalMonth comparison ----------------
Write-Host "`n=== Q1 PPR (by FiscalMonth) ==="
$pprFm = Invoke-FabricQuery -server $pprServer -db $pprDb -token $sqlTok -sql $pprFmSql
Write-Host "  PPR rows: $($pprFm.Rows.Count)"
Write-Host "=== Q1 Sales (same query, schema-swapped; time from POSOT_Integration) ==="
$salesFm = Invoke-FabricQuery -server $salesServer -db $salesDb -token $sqlTok -sql $salesFmSql
Write-Host "  Sales rows (pre time-join): $($salesFm.Rows.Count)"

$pprH = @{}; $names = @{}
foreach ($r in $pprFm.Rows) { $fm = [int]$r["FiscalMonthID"]; $pprH[$fm] = [decimal]$r["TotalSoldSeatsRevenue"]; $names[$fm] = [string]$r["FiscalMonthName"] }

# Sales: INNER JOIN with DimIntegrationTime (integration) -> keep only FMs present in DimIntegrationTime.
$salH = @{}
foreach ($r in $salesFm.Rows) {
  $fm = [int]$r["FiscalMonthID"]
  if ($dit.ContainsKey($fm)) {
    $salH[$fm] = [decimal]$r["TotalSoldSeatsRevenue"]
    if (-not $names.ContainsKey($fm)) { $names[$fm] = $dit[$fm] }
  }
}

$fmResults = [System.Collections.Generic.List[object]]::new()
foreach ($fm in (($pprH.Keys + $salH.Keys) | Sort-Object -Unique)) {
  $p = if ($pprH.ContainsKey($fm)) { $pprH[$fm] } else { $null }
  $s = if ($salH.ContainsKey($fm)) { $salH[$fm] } else { $null }
  $pct = $null
  if ($p -ne $null -and $s -ne $null) { if ($s -eq 0) { $pct = if ($p -eq 0) { 0.0 } else { $null } } else { $pct = [double](($p - $s) / $s) } }
  $fmResults.Add([pscustomobject][ordered]@{
    FiscalMonthID = $fm; FiscalMonthName = $names[$fm]
    PPR_TotalSoldSeatsRevenue = $p; Sales_TotalSoldSeatsRevenue = $s; PctDiff = $pct
    PPR_Source = "PPR Warehouse.Gold.FactSalesPPR + Gold.DimIntegrationTime"
    Sales_Source = "POSOT_Sales.$salesSchema.FactSales + POSOT_Integration.$intSchema.DimIntegrationTime"
    QueryRunUTC = $runUtc
  })
}

# ---------------- Run AssociationType comparison ----------------
Write-Host "`n=== Q2 PPR (by AssociationType) ==="
$pprAt = Invoke-FabricQuery -server $pprServer -db $pprDb -token $sqlTok -sql $pprAtSql
Write-Host "  PPR rows: $($pprAt.Rows.Count)"
Write-Host "=== Q2 Sales (same query, schema-swapped) ==="
$salesAt = Invoke-FabricQuery -server $salesServer -db $salesDb -token $sqlTok -sql $salesAtSql
Write-Host "  Sales rows: $($salesAt.Rows.Count)"

$pprA = @{}
foreach ($r in $pprAt.Rows) { $k = [string]$r["AssociationName"]; $pprA[$k] = [decimal]$r["BilledRevenue"] }
$salA = @{}
foreach ($r in $salesAt.Rows) { $k = [string]$r["AssociationName"]; $salA[$k] = [decimal]$r["BilledRevenue"] }

$atResults = [System.Collections.Generic.List[object]]::new()
foreach ($k in (($pprA.Keys + $salA.Keys) | Sort-Object -Unique)) {
  $p = if ($pprA.ContainsKey($k)) { $pprA[$k] } else { $null }
  $s = if ($salA.ContainsKey($k)) { $salA[$k] } else { $null }
  $pct = $null
  if ($p -ne $null -and $s -ne $null) { if ($s -eq 0) { $pct = if ($p -eq 0) { 0.0 } else { $null } } else { $pct = [double](($p - $s) / $s) } }
  $atResults.Add([pscustomobject][ordered]@{
    AssociationName = $k
    PPR_BilledRevenue = $p; Sales_BilledRevenue = $s; PctDiff = $pct
    PPR_Source = "PPR Warehouse.Gold.FactSalesPPR"; Sales_Source = "POSOT_Sales.$salesSchema.FactSales"; QueryRunUTC = $runUtc
  })
}

# ---------------- CSV ----------------
$fmResults | Export-Csv -Path "scripts\ppr-vs-sales-fiscalmonth.csv" -NoTypeInformation -Encoding UTF8
$atResults | Export-Csv -Path "scripts\ppr-vs-sales-associationtype.csv" -NoTypeInformation -Encoding UTF8
Write-Host "`nSaved CSV: scripts\ppr-vs-sales-fiscalmonth.csv, scripts\ppr-vs-sales-associationtype.csv"

# ---------------- Excel (two sheets) -> local Downloads (non-OneDrive) ----------------
$outDir = Join-Path $env:USERPROFILE "Downloads"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$xlsx = Join-Path $outDir "PPRWarehouse_vs_Sales_Validation_$stamp.xlsx"

$pkg = $fmResults | Export-Excel -Path $xlsx -WorksheetName "By FiscalMonth" -AutoSize -BoldTopRow -FreezeTopRow -PassThru
$ws1 = $pkg.Workbook.Worksheets["By FiscalMonth"]
$last1 = $fmResults.Count + 1
$ws1.Cells["E2:E$last1"].Style.Numberformat.Format = "0.00%"
$ws1.Cells["C2:D$last1"].Style.Numberformat.Format = "#,##0.00"
for ($i = 0; $i -lt $fmResults.Count; $i++) { $row = $i + 2; $v = $fmResults[$i].PctDiff
  if ($v -ne $null -and [math]::Abs([double]$v) -gt 0.0001) { $ws1.Cells["E$row"].Style.Font.Bold = $true; $ws1.Cells["E$row"].Style.Font.Color.SetColor([System.Drawing.Color]::Red) } }
Close-ExcelPackage $pkg

$pkg2 = $atResults | Export-Excel -Path $xlsx -WorksheetName "By AssociationType" -AutoSize -BoldTopRow -FreezeTopRow -PassThru
$ws2 = $pkg2.Workbook.Worksheets["By AssociationType"]
$last2 = $atResults.Count + 1
$ws2.Cells["D2:D$last2"].Style.Numberformat.Format = "0.00%"
$ws2.Cells["B2:C$last2"].Style.Numberformat.Format = "#,##0.00"
for ($i = 0; $i -lt $atResults.Count; $i++) { $row = $i + 2; $v = $atResults[$i].PctDiff
  if ($v -ne $null -and [math]::Abs([double]$v) -gt 0.0001) { $ws2.Cells["D$row"].Style.Font.Bold = $true; $ws2.Cells["D$row"].Style.Font.Color.SetColor([System.Drawing.Color]::Red) } }
Close-ExcelPackage $pkg2
Write-Host "Saved Excel: $xlsx"

# ---------------- Summary ----------------
Write-Host "`n=== Q1 By FiscalMonth (PPR vs Sales; time dim from POSOT_Integration) ==="
$fmResults | Format-Table FiscalMonthID, FiscalMonthName, PPR_TotalSoldSeatsRevenue, Sales_TotalSoldSeatsRevenue, @{N='PctDiff';E={ if ($_.PctDiff -ne $null) { '{0:P2}' -f $_.PctDiff } else { 'n/a' } }} -AutoSize | Out-String -Width 200 | Write-Host
Write-Host "`n=== Q2 By AssociationType ==="
$atResults | Format-Table AssociationName, PPR_BilledRevenue, Sales_BilledRevenue, @{N='PctDiff';E={ if ($_.PctDiff -ne $null) { '{0:P2}' -f $_.PctDiff } else { 'n/a' } }} -AutoSize | Out-String -Width 200 | Write-Host
Start-Process $xlsx
Write-Host "DONE"
