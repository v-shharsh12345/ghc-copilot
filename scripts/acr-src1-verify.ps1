$ErrorActionPreference = "Stop"
$token = az account get-access-token --resource "https://database.windows.net/" --query accessToken -o tsv

function Q { param($server,$db,$sql)
  $conn = New-Object System.Data.SqlClient.SqlConnection
  $conn.ConnectionString = "Server=tcp:$server,1433;Database=$db;Encrypt=True;TrustServerCertificate=False;Connection Timeout=60;"
  $conn.AccessToken = $token; $conn.Open()
  $cmd = $conn.CreateCommand(); $cmd.CommandText = $sql; $cmd.CommandTimeout = 120
  $da = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
  $dt = New-Object System.Data.DataTable; [void]$da.Fill($dt); $conn.Close(); return ,$dt
}

$azServer = "x6eps4xrq2xudenlfv6naeo3i4-22ajhqvkwtjehg7kepm6sack7u.msit-datawarehouse.fabric.microsoft.com"
$intServer = "x6eps4xrq2xudenlfv6naeo3i4-gs7rn6r7m2oetco33xb7dwa6o4.msit-datawarehouse.fabric.microsoft.com"

Write-Host "== POSOT_Azure: Reporting schema - target tables =="
$dt = Q $azServer "POSOT_Azure" "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='Reporting' AND TABLE_NAME IN ('FactAzureConsumption_Reporting','MapAzureAssociationPartnerPPR') ORDER BY TABLE_NAME"
foreach ($r in $dt.Rows) { Write-Host ("   Reporting." + $r["TABLE_NAME"]) }

Write-Host "`n== POSOT_Integration (GPS_Integration_Prod_Processing): DimIntegrationTime locations =="
$dt2 = Q $intServer "POSOT_Integration" "SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='DimIntegrationTime' ORDER BY TABLE_SCHEMA"
foreach ($r in $dt2.Rows) { Write-Host ("   {0}.{1}" -f $r["TABLE_SCHEMA"], $r["TABLE_NAME"]) }

Write-Host "`n== DimIntegrationTime columns (first matching schema) =="
if ($dt2.Rows.Count -gt 0) {
  $sch = $dt2.Rows[0]["TABLE_SCHEMA"]
  $dt3 = Q $intServer "POSOT_Integration" "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='$sch' AND TABLE_NAME='DimIntegrationTime' AND COLUMN_NAME IN ('FiscalMonthID','FiscalMonthName') ORDER BY COLUMN_NAME"
  foreach ($r in $dt3.Rows) { Write-Host ("   {0} ({1})" -f $r["COLUMN_NAME"], $r["DATA_TYPE"]) }
}

Write-Host "`n== POSOT_Integration: all gold-like schemas =="
$dt4 = Q $intServer "POSOT_Integration" "SELECT DISTINCT TABLE_SCHEMA AS S FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA LIKE '%Gold%' OR TABLE_SCHEMA LIKE '%Integration%' ORDER BY TABLE_SCHEMA"
foreach ($r in $dt4.Rows) { Write-Host ("   " + $r["S"]) }
