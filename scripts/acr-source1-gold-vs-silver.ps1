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

$sourceServer = "x6eps4xrq2xudenlfv6naeo3i4-22ajhqvkwtjehg7kepm6sack7u.msit-datawarehouse.fabric.microsoft.com"
$sourceDb = "POSOT_Azure"

# Latest gold schema with map table
$dtGold = Invoke-FabricQuery -server $sourceServer -db $sourceDb -sql @"
SELECT DISTINCT TABLE_SCHEMA
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA LIKE 'AzureGold20%'
  AND TABLE_NAME = 'MapAzureAssociationPartnerPPR'
ORDER BY TABLE_SCHEMA DESC
"@
if ($dtGold.Rows.Count -lt 1) { throw "No AzureGold schema with MapAzureAssociationPartnerPPR found." }
$goldSchema = [string]$dtGold.Rows[0]["TABLE_SCHEMA"]

# Pick Silver schema with map table; prefer dated AzureSilver, else AzureSilver, else latest lexicographically
$dtSilver = Invoke-FabricQuery -server $sourceServer -db $sourceDb -sql @"
SELECT DISTINCT TABLE_SCHEMA
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'MapAzureAssociationPartnerPPR'
  AND (TABLE_SCHEMA LIKE 'AzureSilver%' OR TABLE_SCHEMA LIKE '%Silver%')
ORDER BY TABLE_SCHEMA DESC
"@
if ($dtSilver.Rows.Count -lt 1) {
  throw "No Silver schema containing MapAzureAssociationPartnerPPR found in POSOT_Azure."
}
$silverSchema = [string]$dtSilver.Rows[0]["TABLE_SCHEMA"]

Write-Host "Using Gold schema:   $goldSchema"
Write-Host "Using Silver schema: $silverSchema"

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
  return Invoke-FabricQuery -server $sourceServer -db $sourceDb -sql $sql
}

$dtGoldAcr = Get-AcrByMonth -mapSchema $goldSchema
$dtSilverAcr = Get-AcrByMonth -mapSchema $silverSchema

$goldMap = @{}
foreach ($r in $dtGoldAcr.Rows) { $goldMap[[int]$r["FiscalMonthID"]] = [double]$r["ACR"] }

$silverMap = @{}
foreach ($r in $dtSilverAcr.Rows) { $silverMap[[int]$r["FiscalMonthID"]] = [double]$r["ACR"] }

# Fiscal month names from Source1 if possible; fallback to blank
$timeMap = @{}
$dtTime = Invoke-FabricQuery -server $sourceServer -db $sourceDb -sql @"
SELECT TOP 500 FiscalMonthID, FiscalMonthName
FROM Silver.Sales_DimTime
"@
foreach ($r in $dtTime.Rows) {
  if ($r["FiscalMonthID"] -isnot [DBNull]) { $timeMap[[int]$r["FiscalMonthID"]] = [string]$r["FiscalMonthName"] }
}

$months = @($goldMap.Keys + $silverMap.Keys | Sort-Object -Unique)
$out = foreach ($m in $months) {
  $g = if ($goldMap.ContainsKey($m)) { $goldMap[$m] } else { $null }
  $s = if ($silverMap.ContainsKey($m)) { $silverMap[$m] } else { $null }
  [PSCustomObject]@{
    FiscalMonthID = $m
    FiscalMonthName = $(if ($timeMap.ContainsKey($m)) { $timeMap[$m] } else { "" })
    ACR_LatestGold = $g
    ACR_Silver = $s
    Difference_GoldMinusSilver = if ($null -ne $g -and $null -ne $s) { $g - $s } else { $null }
    GoldSchema = $goldSchema
    SilverSchema = $silverSchema
  }
}

$out | Export-Csv "scripts\acr-source1-gold-vs-silver.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Saved CSV: scripts\\acr-source1-gold-vs-silver.csv"
$out | Format-Table -AutoSize

# Excel export
$excelPath = (Resolve-Path ".").Path + "\ACR_Source1_Gold_vs_Silver.xlsx"
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$wb = $excel.Workbooks.Add()
$ws = $wb.Worksheets.Item(1)
$ws.Name = "Gold vs Silver"

$ws.Cells.Item(1,1).Value2 = "Source1 ACR Comparison: Latest Gold vs Silver"
$ws.Range("A1:G1").Merge() | Out-Null
$ws.Range("A1:G1").Font.Bold = $true
$ws.Range("A1:G1").Font.Size = 13
$ws.Range("A1:G1").HorizontalAlignment = -4108

$headers = @("FiscalMonthID","FiscalMonthName","ACR Latest Gold","ACR Silver","Difference (Gold-Silver)","Gold Schema","Silver Schema")
for ($i=0; $i -lt $headers.Count; $i++) {
  $cell = $ws.Cells.Item(3, $i+1)
  $cell.Value2 = $headers[$i]
  $cell.Font.Bold = $true
  $cell.Interior.Color = 0xD9D9D9
  $cell.Borders.LineStyle = 1
}

$row = 4
foreach ($d in $out) {
  $ws.Cells.Item($row,1).Value2 = [double]$d.FiscalMonthID
  $ws.Cells.Item($row,2).Value2 = [string]$d.FiscalMonthName
  if ($null -ne $d.ACR_LatestGold) { $ws.Cells.Item($row,3).Value2 = [double]$d.ACR_LatestGold }
  if ($null -ne $d.ACR_Silver) { $ws.Cells.Item($row,4).Value2 = [double]$d.ACR_Silver }
  if ($null -ne $d.Difference_GoldMinusSilver) { $ws.Cells.Item($row,5).Value2 = [double]$d.Difference_GoldMinusSilver }
  $ws.Cells.Item($row,6).Value2 = [string]$d.GoldSchema
  $ws.Cells.Item($row,7).Value2 = [string]$d.SilverSchema

  $ws.Cells.Item($row,3).NumberFormat = "#,##0.00"
  $ws.Cells.Item($row,4).NumberFormat = "#,##0.00"
  $ws.Cells.Item($row,5).NumberFormat = "#,##0.00"

  for ($c=1; $c -le 7; $c++) { $ws.Cells.Item($row,$c).Borders.LineStyle = 1 }
  $row++
}

$ws.Columns.Item("A:G").EntireColumn.AutoFit() | Out-Null
if (Test-Path $excelPath) { Remove-Item $excelPath -Force }
$wb.SaveAs($excelPath, 51)
$wb.Close($false)
$excel.Quit()
foreach ($o in @($ws,$wb,$excel)) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($o) | Out-Null }
[GC]::Collect(); [GC]::WaitForPendingFinalizers()

$desktopPath = [Environment]::GetFolderPath("Desktop") + "\ACR_Source1_Gold_vs_Silver.xlsx"
Copy-Item $excelPath $desktopPath -Force

Write-Host "Excel written: $excelPath"
Write-Host "Copied to: $desktopPath"
