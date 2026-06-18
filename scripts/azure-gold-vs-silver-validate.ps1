$ErrorActionPreference = "Stop"
if (-not (Get-Module -ListAvailable -Name ImportExcel)) { Install-Module ImportExcel -Scope CurrentUser -Force -AllowClobber }
Import-Module ImportExcel

# Billing month to validate (notebook 'Update this' value). Edit to change month.
$Month = 20250701

$tok = az account get-access-token --resource "https://database.windows.net/" --query accessToken -o tsv
if (-not $tok) { throw "Run 'az login' first." }

$server = "x6eps4xrq2xudenlfv6naeo3i4-22ajhqvkwtjehg7kepm6sack7u.msit-datawarehouse.fabric.microsoft.com"
$db = "POSOT_Azure"

function Invoke-Q($sql){
  $conn = New-Object System.Data.SqlClient.SqlConnection
  $conn.ConnectionString = "Server=tcp:$server,1433;Database=$db;Encrypt=True;TrustServerCertificate=False;Connection Timeout=120;"
  $conn.AccessToken = $tok; $conn.Open()
  $cmd = $conn.CreateCommand(); $cmd.CommandText = $sql; $cmd.CommandTimeout = 900
  $da = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
  $dt = New-Object System.Data.DataTable; [void]$da.Fill($dt); $conn.Close(); return ,$dt
}

# Normalize AssociationType per standing rule: 'CSP Tier 1'->'CSP Tier1', 'CSP Tier 2'->'CSP Tier2'
function Normalize-Assoc($v){
  if ($null -eq $v) { return $v }
  $x = $v.Trim()
  if ($x -eq 'CSP Tier 1') { return 'CSP Tier1' }
  if ($x -eq 'CSP Tier 2') { return 'CSP Tier2' }
  return $x
}

# Standing rule: always exclude these AssociationType values
$excludeAssoc = @('TPOR-DIR','TPOR-IND','TPOR-SOA')

# Resolve latest AzureGold schema with the 3 Gold tables
$gs = Invoke-Q @"
SELECT TOP 1 s.name AS SchemaName
FROM sys.schemas s
WHERE s.name LIKE 'AzureGold20%'
  AND EXISTS(SELECT 1 FROM sys.tables t WHERE t.schema_id=s.schema_id AND t.name='FactAzureConsumption')
  AND EXISTS(SELECT 1 FROM sys.tables t WHERE t.schema_id=s.schema_id AND t.name='MapAzureAssociationPartner')
  AND EXISTS(SELECT 1 FROM sys.tables t WHERE t.schema_id=s.schema_id AND t.name='DimAzureAssociationType')
ORDER BY s.name DESC
"@
$goldSchema = [string]$gs.Rows[0]["SchemaName"]
Write-Host "Latest Azure Gold schema: $goldSchema"
Write-Host "Validating BillingMonthID / DIM_DateId = $Month"

# ----- Azure Gold (notebook query, latest schema) -----
$goldSql = @"
WITH CTE AS (
    SELECT MAP.ConsumptionID, DA.AssociationType, MAX(PercentAllocation) AS PercentAllocation
    FROM [$goldSchema].[MapAzureAssociationPartner] MAP
    INNER JOIN [$goldSchema].[DimAzureAssociationType] DA ON MAP.AssociationTypeID = DA.AssociationTypeID
    GROUP BY MAP.ConsumptionID, DA.AssociationType
)
SELECT map.AssociationType,
       SUM(CAST(acr.BilledConsumption AS decimal(18,2)) * map.PercentAllocation) AS ACR
FROM [$goldSchema].[FactAzureConsumption] acr
INNER JOIN CTE map ON map.ConsumptionID = acr.ConsumptionID
WHERE acr.BillingMonthID = $Month
GROUP BY map.AssociationType
ORDER BY map.AssociationType
"@

# ----- Azure Silver (notebook query; temp MartMap rewritten as CTE; ifnull->ISNULL; DIM_DateId exact case) -----
$silverSql = @"
WITH MartMap AS (
    SELECT AssociationType, FACT_AzureConsumedRevenuePartnerUniqueId,
           MAX(ISNULL(PercentAllocation, 0)) AS percentallocation
    FROM [Silver].[SL_Fact_PartnerAssociation]
    GROUP BY AssociationType, FACT_AzureConsumedRevenuePartnerUniqueId
)
SELECT B.AssociationType AS AssociationType,
       SUM(CAST(A.AzureConsumedRevenueCD AS decimal(18,2)) * B.percentallocation) AS Revenue
FROM [Silver].[SL_FactAzureConsumedRevenue] A
INNER JOIN MartMap B ON A.FACT_AzureConsumedRevenuePartnerUniqueId = B.FACT_AzureConsumedRevenuePartnerUniqueId
WHERE A.DIM_DateId = $Month
GROUP BY B.AssociationType
ORDER BY B.AssociationType
"@

Write-Host "`nRunning Azure Gold query..."
$gold = Invoke-Q $goldSql
Write-Host "  Gold rows: $($gold.Rows.Count)"
Write-Host "Running Azure Silver query..."
$silver = Invoke-Q $silverSql
Write-Host "  Silver rows: $($silver.Rows.Count)"

$gH = @{}; foreach ($r in $gold.Rows)   { $gH[(Normalize-Assoc ([string]$r["AssociationType"]))] = [decimal]$r["ACR"] }
$sH = @{}; foreach ($r in $silver.Rows) { $sH[(Normalize-Assoc ([string]$r["AssociationType"]))] = [decimal]$r["Revenue"] }

$runUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
$results = [System.Collections.Generic.List[object]]::new()
foreach ($k in (($gH.Keys + $sH.Keys) | Sort-Object -Unique)) {
  if ($excludeAssoc -contains $k) { continue }
  $g = if ($gH.ContainsKey($k)) { $gH[$k] } else { $null }
  $s = if ($sH.ContainsKey($k)) { $sH[$k] } else { $null }
  $pct = $null
  if ($g -ne $null -and $s -ne $null) { if ($s -eq 0) { $pct = if ($g -eq 0) { 0.0 } else { $null } } else { $pct = [double](($g - $s) / $s) } }
  $results.Add([pscustomobject][ordered]@{
    AssociationType = $k
    Gold_ACR = $g
    Silver_Revenue = $s
    PctDiff = $pct
    Gold_Source = "POSOT_Azure.$goldSchema.FactAzureConsumption"
    Silver_Source = "POSOT_Azure.Silver.SL_FactAzureConsumedRevenue"
    BillingMonthID = $Month
    QueryRunUTC = $runUtc
  })
}

$results | Export-Csv -Path "scripts\azure-gold-vs-silver.csv" -NoTypeInformation -Encoding UTF8

$outDir = Join-Path $env:USERPROFILE "Downloads"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$xlsx = Join-Path $outDir "Azure_Gold_vs_Silver_$($Month)_$stamp.xlsx"
$pkg = $results | Export-Excel -Path $xlsx -WorksheetName "Gold vs Silver" -AutoSize -BoldTopRow -FreezeTopRow -PassThru
$ws = $pkg.Workbook.Worksheets["Gold vs Silver"]
$last = $results.Count + 1
$ws.Cells["D2:D$last"].Style.Numberformat.Format = "0.00%"
$ws.Cells["B2:C$last"].Style.Numberformat.Format = "#,##0.00"
for ($i = 0; $i -lt $results.Count; $i++) { $row = $i + 2; $v = $results[$i].PctDiff
  if ($v -ne $null -and [math]::Abs([double]$v) -gt 0.0001) { $ws.Cells["D$row"].Style.Font.Bold = $true; $ws.Cells["D$row"].Style.Font.Color.SetColor([System.Drawing.Color]::Red) } }
Close-ExcelPackage $pkg
Write-Host "Saved Excel: $xlsx"

Write-Host "`n=== Azure Gold vs Silver (BillingMonthID=$Month) ==="
$results | Format-Table AssociationType, Gold_ACR, Silver_Revenue, @{N='PctDiff';E={ if ($_.PctDiff -ne $null) { '{0:P2}' -f $_.PctDiff } else { 'n/a' } }} -AutoSize | Out-String -Width 200 | Write-Host
Start-Process $xlsx
Write-Host "DONE"
