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

$server = "x6eps4xrq2xudenlfv6naeo3i4-22ajhqvkwtjehg7kepm6sack7u.msit-datawarehouse.fabric.microsoft.com"
$db = "POSOT_Azure"

# 1) Latest gold schema for notebook gold query tables
$dtSchemas = Invoke-FabricQuery -server $server -db $db -sql @"
SELECT DISTINCT TABLE_SCHEMA
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA LIKE 'AzureGold20%'
  AND TABLE_NAME IN ('MapAzureAssociationPartner','DimAzureAssociationType','FactAzureConsumption')
GROUP BY TABLE_SCHEMA
HAVING COUNT(DISTINCT TABLE_NAME) = 3
ORDER BY TABLE_SCHEMA DESC
"@
if ($dtSchemas.Rows.Count -lt 1) { throw "No eligible latest AzureGold schema found for notebook gold query tables." }
$goldSchema = [string]$dtSchemas.Rows[0]["TABLE_SCHEMA"]

# 2) Month id from notebook query (fallback: latest common month if no data)
$monthId = 20250701

function Get-ComparisonRows {
  param($schema, $billingMonth)

  $goldSql = @"
WITH CTE AS (
    SELECT MAP.ConsumptionID,
           DA.AssociationType,
           MAX(MAP.PercentAllocation) AS PercentAllocation
    FROM [$schema].[MapAzureAssociationPartner] MAP
    INNER JOIN [$schema].[DimAzureAssociationType] DA
      ON MAP.AssociationTypeID = DA.AssociationTypeID
    GROUP BY MAP.ConsumptionID, DA.AssociationType
)
SELECT CTE.AssociationType,
       SUM(CAST(ACR.BilledConsumption AS decimal(18,2)) * CTE.PercentAllocation) AS GoldValue
FROM [$schema].[FactAzureConsumption] ACR
INNER JOIN CTE ON CTE.ConsumptionID = ACR.ConsumptionID
WHERE ACR.BillingMonthID = $billingMonth
GROUP BY CTE.AssociationType
"@

  $silverSql = @"
WITH MartMap AS (
    SELECT AssociationType,
           FACT_AzureConsumedRevenuePartnerUniqueId,
           MAX(ISNULL(PercentAllocation,0)) AS PercentAllocation
    FROM [Silver].[SL_Fact_PartnerAssociation]
    GROUP BY AssociationType, FACT_AzureConsumedRevenuePartnerUniqueId
)
SELECT B.AssociationType,
       SUM(CAST(A.AzureConsumedRevenueCD AS decimal(18,2)) * B.PercentAllocation) AS SilverValue
FROM [Silver].[SL_FactAzureConsumedRevenue] A
INNER JOIN MartMap B
  ON A.FACT_AzureConsumedRevenuePartnerUniqueId = B.FACT_AzureConsumedRevenuePartnerUniqueId
WHERE A.[DIM_DateId] = $billingMonth
GROUP BY B.AssociationType
"@

  $dtGold = Invoke-FabricQuery -server $server -db $db -sql $goldSql
  $dtSilver = Invoke-FabricQuery -server $server -db $db -sql $silverSql

  $g = @{}
  foreach ($r in $dtGold.Rows) { $g[[string]$r["AssociationType"]] = [double]$r["GoldValue"] }
  $s = @{}
  foreach ($r in $dtSilver.Rows) { $s[[string]$r["AssociationType"]] = [double]$r["SilverValue"] }

  $keys = @($g.Keys + $s.Keys | Sort-Object -Unique)
  $rows = foreach ($k in $keys) {
    $gv = if ($g.ContainsKey($k)) { $g[$k] } else { $null }
    $sv = if ($s.ContainsKey($k)) { $s[$k] } else { $null }
    [PSCustomObject]@{
      BillingMonthID = $billingMonth
      AssociationType = $k
      GoldValue = $gv
      SilverValue = $sv
      Difference_GoldMinusSilver = if ($null -ne $gv -and $null -ne $sv) { $gv - $sv } else { $null }
      GoldSchema = $schema
    }
  }
  return ,$rows
}

$rows = Get-ComparisonRows -schema $goldSchema -billingMonth $monthId

# If notebook month has no rows, use latest common month
if ($rows.Count -eq 0) {
  $dtMonth = Invoke-FabricQuery -server $server -db $db -sql @"
SELECT MAX(BillingMonthID) AS M
FROM [$goldSchema].[FactAzureConsumption]
"@
  $monthId = [int]$dtMonth.Rows[0]["M"]
  $rows = Get-ComparisonRows -schema $goldSchema -billingMonth $monthId
}

$csvPath = "scripts\source1-gold-vs-silver-notebook-query.csv"
$rows | Export-Csv $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "Saved CSV: $csvPath"
Write-Host "Gold schema used: $goldSchema"
Write-Host "BillingMonthID used: $monthId"
$rows | Format-Table -AutoSize

# Excel export
$excelPath = (Resolve-Path ".").Path + "\Source1_Gold_vs_Silver_NotebookQuery.xlsx"
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$wb = $excel.Workbooks.Add()
$ws = $wb.Worksheets.Item(1)
$ws.Name = "Gold vs Silver"

$ws.Cells.Item(1,1).Value2 = "Source1 Gold vs Silver (Notebook Query Logic)"
$ws.Range("A1:F1").Merge() | Out-Null
$ws.Range("A1:F1").Font.Bold = $true
$ws.Range("A1:F1").Font.Size = 13
$ws.Range("A1:F1").HorizontalAlignment = -4108

$headers = @("BillingMonthID","AssociationType","GoldValue","SilverValue","Difference (Gold-Silver)","GoldSchema")
for($i=0; $i -lt $headers.Count; $i++){
  $cell = $ws.Cells.Item(3,$i+1)
  $cell.Value2 = $headers[$i]
  $cell.Font.Bold = $true
  $cell.Interior.Color = 0xD9D9D9
  $cell.Borders.LineStyle = 1
}

$rowN = 4
foreach($r in $rows){
  $ws.Cells.Item($rowN,1).Value2 = [double]$r.BillingMonthID
  $ws.Cells.Item($rowN,2).Value2 = [string]$r.AssociationType
  if($null -ne $r.GoldValue){ $ws.Cells.Item($rowN,3).Value2 = [double]$r.GoldValue }
  if($null -ne $r.SilverValue){ $ws.Cells.Item($rowN,4).Value2 = [double]$r.SilverValue }
  if($null -ne $r.Difference_GoldMinusSilver){ $ws.Cells.Item($rowN,5).Value2 = [double]$r.Difference_GoldMinusSilver }
  $ws.Cells.Item($rowN,6).Value2 = [string]$r.GoldSchema
  $ws.Cells.Item($rowN,3).NumberFormat = "#,##0.00"
  $ws.Cells.Item($rowN,4).NumberFormat = "#,##0.00"
  $ws.Cells.Item($rowN,5).NumberFormat = "#,##0.00"
  for($c=1; $c -le 6; $c++){ $ws.Cells.Item($rowN,$c).Borders.LineStyle = 1 }
  $rowN++
}

$ws.Columns.Item("A:F").EntireColumn.AutoFit() | Out-Null
if(Test-Path $excelPath){ Remove-Item $excelPath -Force }
$wb.SaveAs($excelPath, 51)
$wb.Close($false)
$excel.Quit()
foreach($o in @($ws,$wb,$excel)){ [System.Runtime.InteropServices.Marshal]::ReleaseComObject($o) | Out-Null }
[GC]::Collect(); [GC]::WaitForPendingFinalizers()

$desktopPath = [Environment]::GetFolderPath("Desktop") + "\Source1_Gold_vs_Silver_NotebookQuery.xlsx"
Copy-Item $excelPath $desktopPath -Force
Write-Host "Excel written: $excelPath"
Write-Host "Copied to: $desktopPath"
