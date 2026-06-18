$ErrorActionPreference = "Stop"

$token = az account get-access-token --resource "https://database.windows.net/" --query accessToken -o tsv

function Invoke-FabricQuery {
  param($server, $db, $sql)
  $conn = New-Object System.Data.SqlClient.SqlConnection
  $conn.ConnectionString = "Server=tcp:$server,1433;Database=$db;Encrypt=True;TrustServerCertificate=False;Connection Timeout=60;"
  $conn.AccessToken = $token
  $conn.Open()
  $cmd = $conn.CreateCommand()
  $cmd.CommandText = $sql
  $cmd.CommandTimeout = 600
  $da = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
  $dt = New-Object System.Data.DataTable
  [void]$da.Fill($dt)
  $conn.Close()
  return ,$dt
}

$azureServer = "x6eps4xrq2xudenlfv6naeo3i4-22ajhqvkwtjehg7kepm6sack7u.msit-datawarehouse.fabric.microsoft.com"
$azureDb = "POSOT_Azure"
$integrationServer = "x6eps4xrq2xudenlfv6naeo3i4-gs7rn6r7m2oetco33xb7dwa6o4.msit-datawarehouse.fabric.microsoft.com"
$integrationDb = "POSOT_Integration"

# Find latest and previous Azure gold schemas
$dtAzureSchemas = Invoke-FabricQuery -server $azureServer -db $azureDb -sql @"
SELECT DISTINCT TABLE_SCHEMA
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA LIKE 'AzureGold20%'
  AND TABLE_NAME = 'MapAzureAssociationPartnerPPR'
ORDER BY TABLE_SCHEMA DESC
"@
if ($dtAzureSchemas.Rows.Count -lt 2) { throw "Need at least two AzureGold schemas with MapAzureAssociationPartnerPPR" }
$azureLatest = [string]$dtAzureSchemas.Rows[0]["TABLE_SCHEMA"]
$azurePrev = [string]$dtAzureSchemas.Rows[1]["TABLE_SCHEMA"]

# Find latest and previous Integration gold schemas for DimIntegrationTime
$dtIntSchemas = Invoke-FabricQuery -server $integrationServer -db $integrationDb -sql @"
SELECT DISTINCT TABLE_SCHEMA
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA LIKE 'IntegrationGold20%'
  AND TABLE_NAME = 'DimIntegrationTime'
ORDER BY TABLE_SCHEMA DESC
"@
if ($dtIntSchemas.Rows.Count -lt 2) { throw "Need at least two IntegrationGold schemas with DimIntegrationTime" }
$intLatest = [string]$dtIntSchemas.Rows[0]["TABLE_SCHEMA"]
$intPrev = [string]$dtIntSchemas.Rows[1]["TABLE_SCHEMA"]

Write-Host "Azure map schemas: latest=$azureLatest, previous=$azurePrev"
Write-Host "Integration time schemas: latest=$intLatest, previous=$intPrev"

# Common query template for Source 1
function Get-AcrByMonth {
  param($mapSchema)

  $sql = @"
WITH CTE AS (
    SELECT A.ConsumptionID, MAX(PercentAllocation) AS PercentAllocation
    FROM [$mapSchema].[MapAzureAssociationPartnerPPR] A
    GROUP BY A.ConsumptionID
)
SELECT
    FAC.FiscalMonthID,
    SUM(FAC.BilledConsumption * C.PercentAllocation) AS ACR
FROM [Reporting].[FactAzureConsumption_Reporting] AS FAC
LEFT JOIN CTE C ON C.ConsumptionID = FAC.ConsumptionID
GROUP BY FAC.FiscalMonthID
ORDER BY FAC.FiscalMonthID
"@
  return Invoke-FabricQuery -server $azureServer -db $azureDb -sql $sql
}

function Get-TimeMap {
  param($timeSchema)
  $dt = Invoke-FabricQuery -server $integrationServer -db $integrationDb -sql "SELECT FiscalMonthID, FiscalMonthName FROM [$timeSchema].[DimIntegrationTime]"
  $map = @{}
  foreach ($r in $dt.Rows) {
    if ($r["FiscalMonthID"] -isnot [DBNull]) {
      $map[[int]$r["FiscalMonthID"]] = [string]$r["FiscalMonthName"]
    }
  }
  return $map
}

$latestAgg = Get-AcrByMonth -mapSchema $azureLatest
$prevAgg = Get-AcrByMonth -mapSchema $azurePrev
$timeLatest = Get-TimeMap -timeSchema $intLatest
$timePrev = Get-TimeMap -timeSchema $intPrev

$latestRows = @{}
foreach ($r in $latestAgg.Rows) {
  $fm = [int]$r["FiscalMonthID"]
  $latestRows[$fm] = [double]$r["ACR"]
}

$prevRows = @{}
foreach ($r in $prevAgg.Rows) {
  $fm = [int]$r["FiscalMonthID"]
  $prevRows[$fm] = [double]$r["ACR"]
}

$allMonths = @($latestRows.Keys + $prevRows.Keys | Sort-Object -Unique)

$out = foreach ($fm in $allMonths) {
  $acrLatest = if ($latestRows.ContainsKey($fm)) { $latestRows[$fm] } else { $null }
  $acrPrev = if ($prevRows.ContainsKey($fm)) { $prevRows[$fm] } else { $null }
  $nameLatest = if ($timeLatest.ContainsKey($fm)) { $timeLatest[$fm] } else { "" }
  $namePrev = if ($timePrev.ContainsKey($fm)) { $timePrev[$fm] } else { "" }
  [PSCustomObject]@{
    FiscalMonthID = $fm
    FiscalMonthName_LatestTime = $nameLatest
    FiscalMonthName_PreviousTime = $namePrev
    ACR_LatestGold = $acrLatest
    ACR_PreviousGold = $acrPrev
    Difference_LatestMinusPrevious = if ($null -ne $acrLatest -and $null -ne $acrPrev) { $acrLatest - $acrPrev } else { $null }
    AzureGold_Latest = $azureLatest
    AzureGold_Previous = $azurePrev
    IntegrationGold_Latest = $intLatest
    IntegrationGold_Previous = $intPrev
  }
}

$out | Export-Csv "scripts\acr-source1-gold-latest-vs-prev.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Saved: scripts\\acr-source1-gold-latest-vs-prev.csv"
$out | Format-Table -AutoSize
