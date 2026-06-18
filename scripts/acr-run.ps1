$ErrorActionPreference = "Stop"
$token = az account get-access-token --resource "https://database.windows.net/" --query accessToken -o tsv

function Invoke-FabricQuery {
  param($server, $db, $sql)
  $conn = New-Object System.Data.SqlClient.SqlConnection
  $conn.ConnectionString = "Server=tcp:$server,1433;Database=$db;Encrypt=True;TrustServerCertificate=False;Connection Timeout=60;"
  $conn.AccessToken = $token; $conn.Open()
  $cmd = $conn.CreateCommand(); $cmd.CommandText = $sql; $cmd.CommandTimeout = 600
  $da = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
  $dt = New-Object System.Data.DataTable; [void]$da.Fill($dt); $conn.Close(); return ,$dt
}

$azServer  = "x6eps4xrq2xudenlfv6naeo3i4-22ajhqvkwtjehg7kepm6sack7u.msit-datawarehouse.fabric.microsoft.com"
$intServer = "x6eps4xrq2xudenlfv6naeo3i4-gs7rn6r7m2oetco33xb7dwa6o4.msit-datawarehouse.fabric.microsoft.com"
$pprServer = "x6eps4xrq2xudenlfv6naeo3i4-gs7rn6r7m2oetco33xb7dwa6o4.msit-datawarehouse.fabric.microsoft.com"

# ---------- SOURCE 1 ----------
$src1Agg = @"
WITH CTE AS (
    SELECT A.ConsumptionID, MAX(PercentAllocation) AS PercentAllocation
    FROM [AzureGold2026061501].[MapAzureAssociationPartnerPPR] A
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

$src1Time = "SELECT FiscalMonthID, FiscalMonthName FROM [IntegrationGold2026061501].[DimIntegrationTime]"

Write-Host "Running Source 1 aggregation (POSOT_Azure)..."
$dtAgg1 = Invoke-FabricQuery -server $azServer -db "POSOT_Azure" -sql $src1Agg
Write-Host ("   agg rows: {0}" -f $dtAgg1.Rows.Count)

Write-Host "Fetching DimIntegrationTime (POSOT_Integration)..."
$dtTime = Invoke-FabricQuery -server $intServer -db "POSOT_Integration" -sql $src1Time
$timeMap = @{}
foreach ($r in $dtTime.Rows) { if ($r["FiscalMonthID"] -isnot [DBNull]) { $timeMap[[int]$r["FiscalMonthID"]] = [string]$r["FiscalMonthName"] } }
Write-Host ("   time rows: {0}" -f $dtTime.Rows.Count)

$rows1 = foreach ($r in $dtAgg1.Rows) {
  $fm = if ($r["FiscalMonthID"] -is [DBNull]) { $null } else { [int]$r["FiscalMonthID"] }
  $name = if ($fm -ne $null -and $timeMap.ContainsKey($fm)) { $timeMap[$fm] } else { "" }
  [PSCustomObject]@{
    FiscalMonthID   = $fm
    FiscalMonthName = $name
    ACR             = $(if ($r["ACR"] -is [DBNull]) { $null } else { [double]$r["ACR"] })
  }
}

# ---------- SOURCE 2 ----------
$src2Sql = @"
WITH CTE AS (
    SELECT A.ConsumptionID, MAX(PercentAllocation) AS PercentAllocation
    FROM [Gold].[MapAzureAssociationPartnerPPR] A
    GROUP BY A.ConsumptionID
)
SELECT
    FAC.FiscalMonthID,
    T.FiscalMonthName,
    SUM(FAC.BilledConsumption * C.PercentAllocation) AS ACR
FROM [Gold].[FactAzureConsumption_Reporting] AS FAC
LEFT JOIN CTE C ON C.ConsumptionID = FAC.ConsumptionID
LEFT JOIN [Gold].[DimIntegrationTime] T ON T.FiscalMonthID = FAC.FiscalMonthID
GROUP BY FAC.FiscalMonthID, T.FiscalMonthName
ORDER BY FAC.FiscalMonthID
"@

Write-Host "Running Source 2 (PPR Warehouse / Gold)..."
$dt2 = Invoke-FabricQuery -server $pprServer -db "PPR Warehouse" -sql $src2Sql
Write-Host ("   rows: {0}" -f $dt2.Rows.Count)

$rows2 = foreach ($r in $dt2.Rows) {
  [PSCustomObject]@{
    FiscalMonthID   = $(if ($r["FiscalMonthID"] -is [DBNull]) { $null } else { [int]$r["FiscalMonthID"] })
    FiscalMonthName = $(if ($r["FiscalMonthName"] -is [DBNull]) { "" } else { [string]$r["FiscalMonthName"] })
    ACR             = $(if ($r["ACR"] -is [DBNull]) { $null } else { [double]$r["ACR"] })
  }
}

$rows1 | Export-Csv "scripts\acr-src1.csv" -NoTypeInformation -Encoding UTF8
$rows2 | Export-Csv "scripts\acr-src2.csv" -NoTypeInformation -Encoding UTF8

Write-Host "`n===== SOURCE 1 (POSOT_Azure) ====="; $rows1 | Format-Table -AutoSize
Write-Host "`n===== SOURCE 2 (PPR Warehouse) ====="; $rows2 | Format-Table -AutoSize
