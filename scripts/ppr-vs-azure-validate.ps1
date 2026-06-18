$ErrorActionPreference = "Stop"
if (-not (Get-Module -ListAvailable -Name ImportExcel)) { Install-Module ImportExcel -Scope CurrentUser -Force -AllowClobber }
Import-Module ImportExcel

$tok = az account get-access-token --resource "https://database.windows.net/" --query accessToken -o tsv
if (-not $tok) { throw "Run 'az login' first." }

# Endpoints
$pprServer = "x6eps4xrq2xudenlfv6naeo3i4-gs7rn6r7m2oetco33xb7dwa6o4.msit-datawarehouse.fabric.microsoft.com"
$pprDb     = "PPR Warehouse"
$azServer  = "x6eps4xrq2xudenlfv6naeo3i4-22ajhqvkwtjehg7kepm6sack7u.msit-datawarehouse.fabric.microsoft.com"
$azDb      = "POSOT_Azure"
# DimIntegrationTime lives in POSOT_Integration (integration workspace).
$intServer = "x6eps4xrq2xudenlfv6naeo3i4-gs7rn6r7m2oetco33xb7dwa6o4.msit-datawarehouse.fabric.microsoft.com"
$intDb     = "POSOT_Integration"

function Invoke-Q($server,$db,$sql){
  $conn = New-Object System.Data.SqlClient.SqlConnection
  $conn.ConnectionString = "Server=tcp:$server,1433;Database=$db;Encrypt=True;TrustServerCertificate=False;Connection Timeout=120;"
  $conn.AccessToken = $tok; $conn.Open()
  $cmd = $conn.CreateCommand(); $cmd.CommandText = $sql; $cmd.CommandTimeout = 1800
  $da = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
  $dt = New-Object System.Data.DataTable; [void]$da.Fill($dt); $conn.Close(); return ,$dt
}

# Standing rules
function Normalize-Assoc($v){
  if ($null -eq $v) { return $v }
  $x = $v.Trim()
  if ($x -eq 'CSP Tier 1') { return 'CSP Tier1' }
  if ($x -eq 'CSP Tier 2') { return 'CSP Tier2' }
  return $x
}
$excludeAssoc = @('TPOR-DIR','TPOR-IND','TPOR-SOA')

# Resolve latest AzureGold schema with required tables
$azSchemaDt = Invoke-Q $azServer $azDb @"
SELECT TOP 1 s.name AS SchemaName
FROM sys.schemas s
WHERE s.name LIKE 'AzureGold20%'
  AND EXISTS(SELECT 1 FROM sys.tables t WHERE t.schema_id=s.schema_id AND t.name='FactAzureConsumption')
  AND EXISTS(SELECT 1 FROM sys.tables t WHERE t.schema_id=s.schema_id AND t.name='MapAzureAssociationPartner')
  AND EXISTS(SELECT 1 FROM sys.tables t WHERE t.schema_id=s.schema_id AND t.name='DimAzureAssociationType')
ORDER BY s.name DESC
"@
$azSchema = [string]$azSchemaDt.Rows[0]["SchemaName"]
Write-Host "Latest Azure Gold schema: $azSchema"

# Resolve latest IntegrationGold schema holding DimIntegrationTime
$intSchemaDt = Invoke-Q $intServer $intDb @"
SELECT TOP 1 s.name AS SchemaName
FROM sys.schemas s
WHERE s.name LIKE 'IntegrationGold20%'
  AND EXISTS(SELECT 1 FROM sys.tables t WHERE t.schema_id=s.schema_id AND t.name='DimIntegrationTime')
ORDER BY s.name DESC
"@
$intSchema = [string]$intSchemaDt.Rows[0]["SchemaName"]
Write-Host "Latest IntegrationGold schema: $intSchema"

# DimIntegrationTime (FiscalMonthID -> FiscalMonthName) for Azure-side in-memory join
$ditDt = Invoke-Q $intServer $intDb "SELECT DISTINCT FiscalMonthID, FiscalMonthName FROM [$intSchema].[DimIntegrationTime] WHERE FiscalMonthID IS NOT NULL"
$dit = @{}
foreach ($r in $ditDt.Rows) { $dit[[int]$r["FiscalMonthID"]] = [string]$r["FiscalMonthName"] }
Write-Host "DimIntegrationTime rows (integration): $($ditDt.Rows.Count)"

# ============================================================
# QUERY 1: PPR Warehouse based on Fiscalmonth(Azure) - notebook verbatim (PPR side)
# ============================================================
$pprFmSql = @"
WITH CTE AS (
    SELECT A.ConsumptionID, MAX(PercentAllocation) AS PercentAllocation
    FROM [PPR Warehouse].[Gold].[MapAzureAssociationPartnerPPR] A
    GROUP BY ConsumptionID
)
SELECT FAC.FiscalMonthID, T.FiscalMonthName, SUM(FAC.BilledConsumption * C.PercentAllocation) AS ACR
FROM [PPR Warehouse].[Gold].[FactAzureConsumption_Reporting] AS FAC
left JOIN CTE C ON C.ConsumptionID = FAC.ConsumptionID
left JOIN [PPR Warehouse].[Gold].[DimIntegrationTime] T ON T.FiscalMonthID = FAC.FiscalMonthID
GROUP BY FAC.FiscalMonthID, T.FiscalMonthName
ORDER BY FAC.FiscalMonthID
"@

# Azure side: SAME query, schema-swapped. Time dim from POSOT_Integration (in-memory).
$azFmSql = @"
WITH CTE AS (
    SELECT A.ConsumptionID, MAX(PercentAllocation) AS PercentAllocation
    FROM [$azSchema].[MapAzureAssociationPartner] A
    GROUP BY ConsumptionID
)
SELECT FAC.FiscalMonthID, SUM(FAC.BilledConsumption * C.PercentAllocation) AS ACR
FROM [$azSchema].[FactAzureConsumption] AS FAC
left JOIN CTE C ON C.ConsumptionID = FAC.ConsumptionID
GROUP BY FAC.FiscalMonthID
ORDER BY FAC.FiscalMonthID
"@

# ============================================================
# QUERY 2: PPR Warehouse based on Association Type(Azure) - notebook verbatim (PPR side)
# ============================================================
$pprAtSql = @"
WITH CTE AS (
    SELECT A.ConsumptionID, B.AssociationType, MAX(PercentAllocation) AS PercentAllocation
    FROM [PPR Warehouse].[Gold].[MapAzureAssociationPartnerPPR] A
    INNER JOIN [PPR Warehouse].[Gold].[DimPartnerAssociationType] B ON A.AssociationTypeID = B.AssociationTypeID
    GROUP BY ConsumptionID, B.AssociationType
)
SELECT F.AssociationType, SUM(FAC.BilledConsumption * F.PercentAllocation) AS ACR
FROM [PPR Warehouse].[Gold].[FactAzureConsumption_Reporting] AS FAC
INNER JOIN CTE AS F ON F.ConsumptionID = FAC.ConsumptionID
GROUP BY F.AssociationType
"@

# Azure side: SAME query, schema-swapped.
$azAtSql = @"
WITH CTE AS (
    SELECT A.ConsumptionID, B.AssociationType, MAX(PercentAllocation) AS PercentAllocation
    FROM [$azSchema].[MapAzureAssociationPartner] A
    INNER JOIN [$azSchema].[DimAzureAssociationType] B ON A.AssociationTypeID = B.AssociationTypeID
    GROUP BY ConsumptionID, B.AssociationType
)
SELECT F.AssociationType, SUM(FAC.BilledConsumption * F.PercentAllocation) AS ACR
FROM [$azSchema].[FactAzureConsumption] AS FAC
INNER JOIN CTE AS F ON F.ConsumptionID = FAC.ConsumptionID
GROUP BY F.AssociationType
"@

$runUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")

# ---------------- Q1 FiscalMonth ----------------
Write-Host "`n=== Q1 PPR (by FiscalMonth) ==="
$pprFm = Invoke-Q $pprServer $pprDb $pprFmSql
Write-Host "  PPR rows: $($pprFm.Rows.Count)"
Write-Host "=== Q1 Azure (same query, schema-swapped) ==="
$azFm = Invoke-Q $azServer $azDb $azFmSql
Write-Host "  Azure rows: $($azFm.Rows.Count)"

$pprH = @{}; $names = @{}
foreach ($r in $pprFm.Rows) { if ($r["FiscalMonthID"] -isnot [DBNull]) { $fm=[int]$r["FiscalMonthID"]; $pprH[$fm]=[decimal]$r["ACR"]; $names[$fm]=[string]$r["FiscalMonthName"] } }
$azH = @{}
foreach ($r in $azFm.Rows) { if ($r["FiscalMonthID"] -isnot [DBNull]) { $fm=[int]$r["FiscalMonthID"]; $azH[$fm]=[decimal]$r["ACR"]; if (-not $names.ContainsKey($fm) -and $dit.ContainsKey($fm)) { $names[$fm]=$dit[$fm] } } }

$fmResults = [System.Collections.Generic.List[object]]::new()
foreach ($fm in (($pprH.Keys + $azH.Keys) | Sort-Object -Unique)) {
  $p = if ($pprH.ContainsKey($fm)) { $pprH[$fm] } else { $null }
  $a = if ($azH.ContainsKey($fm)) { $azH[$fm] } else { $null }
  $pct = $null
  if ($p -ne $null -and $a -ne $null) { if ($a -eq 0) { $pct = if ($p -eq 0) { 0.0 } else { $null } } else { $pct = [double](($p - $a) / $a) } }
  $fmResults.Add([pscustomobject][ordered]@{
    FiscalMonthID = $fm; FiscalMonthName = $(if ($names.ContainsKey($fm)) { $names[$fm] } else { $dit[$fm] })
    PPR_ACR = $p; Azure_ACR = $a; PctDiff = $pct
    PPR_Source = "PPR Warehouse.Gold.FactAzureConsumption_Reporting"
    Azure_Source = "POSOT_Azure.$azSchema.FactAzureConsumption"; QueryRunUTC = $runUtc
  })
}

# ---------------- Q2 AssociationType ----------------
Write-Host "`n=== Q2 PPR (by AssociationType) ==="
$pprAt = Invoke-Q $pprServer $pprDb $pprAtSql
Write-Host "  PPR rows: $($pprAt.Rows.Count)"
Write-Host "=== Q2 Azure (same query, schema-swapped) ==="
$azAt = Invoke-Q $azServer $azDb $azAtSql
Write-Host "  Azure rows: $($azAt.Rows.Count)"

$pprA = @{}
foreach ($r in $pprAt.Rows) { $k = Normalize-Assoc ([string]$r["AssociationType"]); if ($pprA.ContainsKey($k)) { $pprA[$k] += [decimal]$r["ACR"] } else { $pprA[$k] = [decimal]$r["ACR"] } }
$azA = @{}
foreach ($r in $azAt.Rows) { $k = Normalize-Assoc ([string]$r["AssociationType"]); if ($azA.ContainsKey($k)) { $azA[$k] += [decimal]$r["ACR"] } else { $azA[$k] = [decimal]$r["ACR"] } }

$atResults = [System.Collections.Generic.List[object]]::new()
foreach ($k in (($pprA.Keys + $azA.Keys) | Sort-Object -Unique)) {
  if ($excludeAssoc -contains $k) { continue }
  $p = if ($pprA.ContainsKey($k)) { $pprA[$k] } else { $null }
  $a = if ($azA.ContainsKey($k)) { $azA[$k] } else { $null }
  $pct = $null
  if ($p -ne $null -and $a -ne $null) { if ($a -eq 0) { $pct = if ($p -eq 0) { 0.0 } else { $null } } else { $pct = [double](($p - $a) / $a) } }
  $atResults.Add([pscustomobject][ordered]@{
    AssociationType = $k
    PPR_ACR = $p; Azure_ACR = $a; PctDiff = $pct
    PPR_Source = "PPR Warehouse.Gold.FactAzureConsumption_Reporting"
    Azure_Source = "POSOT_Azure.$azSchema.FactAzureConsumption"; QueryRunUTC = $runUtc
  })
}

# ---------------- CSV ----------------
$fmResults | Export-Csv -Path "scripts\ppr-vs-azure-fiscalmonth.csv" -NoTypeInformation -Encoding UTF8
$atResults | Export-Csv -Path "scripts\ppr-vs-azure-associationtype.csv" -NoTypeInformation -Encoding UTF8

# ---------------- Excel (two sheets) -> local Downloads ----------------
$outDir = Join-Path $env:USERPROFILE "Downloads"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$xlsx = Join-Path $outDir "PPRWarehouse_vs_Azure_Validation_$stamp.xlsx"

$pkg = $fmResults | Export-Excel -Path $xlsx -WorksheetName "By FiscalMonth" -AutoSize -BoldTopRow -FreezeTopRow -PassThru
$ws1 = $pkg.Workbook.Worksheets["By FiscalMonth"]; $l1 = $fmResults.Count + 1
$ws1.Cells["E2:E$l1"].Style.Numberformat.Format = "0.00%"
$ws1.Cells["C2:D$l1"].Style.Numberformat.Format = "#,##0.00"
for ($i=0; $i -lt $fmResults.Count; $i++){ $row=$i+2; $v=$fmResults[$i].PctDiff; if ($v -ne $null -and [math]::Abs([double]$v) -gt 0.0001){ $ws1.Cells["E$row"].Style.Font.Bold=$true; $ws1.Cells["E$row"].Style.Font.Color.SetColor([System.Drawing.Color]::Red) } }
Close-ExcelPackage $pkg

$pkg2 = $atResults | Export-Excel -Path $xlsx -WorksheetName "By AssociationType" -AutoSize -BoldTopRow -FreezeTopRow -PassThru
$ws2 = $pkg2.Workbook.Worksheets["By AssociationType"]; $l2 = $atResults.Count + 1
$ws2.Cells["D2:D$l2"].Style.Numberformat.Format = "0.00%"
$ws2.Cells["B2:C$l2"].Style.Numberformat.Format = "#,##0.00"
for ($i=0; $i -lt $atResults.Count; $i++){ $row=$i+2; $v=$atResults[$i].PctDiff; if ($v -ne $null -and [math]::Abs([double]$v) -gt 0.0001){ $ws2.Cells["D$row"].Style.Font.Bold=$true; $ws2.Cells["D$row"].Style.Font.Color.SetColor([System.Drawing.Color]::Red) } }
Close-ExcelPackage $pkg2
Write-Host "Saved Excel: $xlsx"

# ---------------- Summary ----------------
Write-Host "`n=== Q1 By FiscalMonth (PPR vs Azure) ==="
$fmResults | Format-Table FiscalMonthID, FiscalMonthName, PPR_ACR, Azure_ACR, @{N='PctDiff';E={ if ($_.PctDiff -ne $null){ '{0:P2}' -f $_.PctDiff } else { 'n/a' } }} -AutoSize | Out-String -Width 200 | Write-Host
Write-Host "`n=== Q2 By AssociationType (PPR vs Azure) ==="
$atResults | Format-Table AssociationType, PPR_ACR, Azure_ACR, @{N='PctDiff';E={ if ($_.PctDiff -ne $null){ '{0:P2}' -f $_.PctDiff } else { 'n/a' } }} -AutoSize | Out-String -Width 200 | Write-Host
Start-Process $xlsx
Write-Host "DONE"
