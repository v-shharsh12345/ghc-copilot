$ErrorActionPreference = "Stop"
$token = az account get-access-token --resource "https://database.windows.net/" --query accessToken -o tsv

$server = "x6eps4xrq2xudenlfv6naeo3i4-22ajhqvkwtjehg7kepm6sack7u.msit-datawarehouse.fabric.microsoft.com"
$db = "POSOT_Azure"

function Q { param($sql)
  $conn = New-Object System.Data.SqlClient.SqlConnection
  $conn.ConnectionString = "Server=tcp:$server,1433;Database=$db;Encrypt=True;TrustServerCertificate=False;Connection Timeout=60;"
  $conn.AccessToken = $token; $conn.Open()
  $cmd = $conn.CreateCommand(); $cmd.CommandText = $sql; $cmd.CommandTimeout = 120
  $da = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
  $dt = New-Object System.Data.DataTable; [void]$da.Fill($dt); $conn.Close(); return ,$dt
}

Write-Host "-- Tables in AzureGold2026061501:"
$dt = Q "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='AzureGold2026061501' ORDER BY TABLE_NAME"
foreach ($r in $dt.Rows) { Write-Host ("   " + $r["TABLE_NAME"]) }

Write-Host "`n-- Any table LIKE %IntegrationTime% or %DimTime% or Dim%Time anywhere:"
$dt2 = Q "SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE '%Time%' ORDER BY TABLE_SCHEMA, TABLE_NAME"
foreach ($r in $dt2.Rows) { Write-Host ("   {0}.{1}" -f $r["TABLE_SCHEMA"], $r["TABLE_NAME"]) }

Write-Host "`n-- Any table LIKE %FactAzureConsumption% anywhere:"
$dt3 = Q "SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE '%FactAzureConsumption%' ORDER BY TABLE_SCHEMA, TABLE_NAME"
foreach ($r in $dt3.Rows) { Write-Host ("   {0}.{1}" -f $r["TABLE_SCHEMA"], $r["TABLE_NAME"]) }
