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

# Resolve latest + previous AzureGold schemas with the 3 Gold tables
$gs = Invoke-Q @"
SELECT TOP 2 s.name AS SchemaName
FROM sys.schemas s
WHERE s.name LIKE 'AzureGold20%'
  AND EXISTS(SELECT 1 FROM sys.tables t WHERE t.schema_id=s.schema_id AND t.name='FactAzureConsumption')
  AND EXISTS(SELECT 1 FROM sys.tables t WHERE t.schema_id=s.schema_id AND t.name='MapAzureAssociationPartner')
  AND EXISTS(SELECT 1 FROM sys.tables t WHERE t.schema_id=s.schema_id AND t.name='DimAzureAssociationType')
ORDER BY s.name DESC
"@
if ($gs.Rows.Count -lt 2) { throw "Need at least 2 AzureGold schemas with required tables." }
$latestSchema   = [string]$gs.Rows[0]["SchemaName"]
$previousSchema = [string]$gs.Rows[1]["SchemaName"]
Write-Host "Latest Azure Gold schema:   $latestSchema"
Write-Host "Previous Azure Gold schema: $previousSchema"
Write-Host "Validating BillingMonthID = $Month"

function Get-GoldByAssoc($schema){
  $sql = @"
WITH CTE AS (
    SELECT MAP.ConsumptionID, DA.AssociationType, MAX(PercentAllocation) AS PercentAllocation
    FROM [$schema].[MapAzureAssociationPartner] MAP
    INNER JOIN [$schema].[DimAzureAssociationType] DA ON MAP.AssociationTypeID = DA.AssociationTypeID
    GROUP BY MAP.ConsumptionID, DA.AssociationType
)
SELECT map.AssociationType,
       SUM(CAST(acr.BilledConsumption AS decimal(18,2)) * map.PercentAllocation) AS ACR
FROM [$schema].[FactAzureConsumption] acr
INNER JOIN CTE map ON map.ConsumptionID = acr.ConsumptionID
WHERE acr.BillingMonthID = $Month
GROUP BY map.AssociationType
ORDER BY map.AssociationType
"@
  return Invoke-Q $sql
}

Write-Host "`nRunning Latest Gold query..."
$latest = Get-GoldByAssoc $latestSchema
Write-Host "  Latest rows: $($latest.Rows.Count)"
Write-Host "Running Previous Gold query..."
$previous = Get-GoldByAssoc $previousSchema
Write-Host "  Previous rows: $($previous.Rows.Count)"

$lH = @{}; foreach ($r in $latest.Rows)   { $lH[(Normalize-Assoc ([string]$r["AssociationType"]))] = [decimal]$r["ACR"] }
$pH = @{}; foreach ($r in $previous.Rows) { $pH[(Normalize-Assoc ([string]$r["AssociationType"]))] = [decimal]$r["ACR"] }

$runUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
$results = [System.Collections.Generic.List[object]]::new()
foreach ($k in (($lH.Keys + $pH.Keys) | Sort-Object -Unique)) {
  if ($excludeAssoc -contains $k) { continue }
  $l = if ($lH.ContainsKey($k)) { $lH[$k] } else { $null }
  $p = if ($pH.ContainsKey($k)) { $pH[$k] } else { $null }
  $pct = $null
  if ($l -ne $null -and $p -ne $null) { if ($p -eq 0) { $pct = if ($l -eq 0) { 0.0 } else { $null } } else { $pct = [double](($l - $p) / $p) } }
  $results.Add([pscustomobject][ordered]@{
    AssociationType = $k
    LatestGold_ACR = $l
    PreviousGold_ACR = $p
    PctDiff = $pct
    LatestGold_Schema = $latestSchema
    PreviousGold_Schema = $previousSchema
    BillingMonthID = $Month
    QueryRunUTC = $runUtc
  })
}

$results | Export-Csv -Path "scripts\azure-latest-vs-previous-gold.csv" -NoTypeInformation -Encoding UTF8

$outDir = Join-Path $env:USERPROFILE "Downloads"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$xlsx = Join-Path $outDir "Azure_LatestGold_vs_PreviousGold_$($Month)_$stamp.xlsx"
$pkg = $results | Export-Excel -Path $xlsx -WorksheetName "Latest vs Previous Gold" -AutoSize -BoldTopRow -FreezeTopRow -PassThru
$ws = $pkg.Workbook.Worksheets["Latest vs Previous Gold"]
$last = $results.Count + 1
$ws.Cells["D2:D$last"].Style.Numberformat.Format = "0.00%"
$ws.Cells["B2:C$last"].Style.Numberformat.Format = "#,##0.00"
for ($i = 0; $i -lt $results.Count; $i++) { $row = $i + 2; $v = $results[$i].PctDiff
  if ($v -ne $null -and [math]::Abs([double]$v) -gt 0.0001) { $ws.Cells["D$row"].Style.Font.Bold = $true; $ws.Cells["D$row"].Style.Font.Color.SetColor([System.Drawing.Color]::Red) } }
Close-ExcelPackage $pkg
Write-Host "Saved Excel: $xlsx"

Write-Host "`n=== Azure Latest Gold vs Previous Gold (BillingMonthID=$Month) ==="
$results | Format-Table AssociationType, LatestGold_ACR, PreviousGold_ACR, @{N='PctDiff';E={ if ($_.PctDiff -ne $null) { '{0:P2}' -f $_.PctDiff } else { 'n/a' } }} -AutoSize | Out-String -Width 200 | Write-Host
Start-Process $xlsx
Write-Host "DONE"
