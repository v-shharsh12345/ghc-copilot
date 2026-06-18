$ErrorActionPreference = "Stop"

$token = az account get-access-token --resource "https://database.windows.net/" --query accessToken -o tsv

$sources = @(
  @{ name = "Source1"; server = "x6eps4xrq2xudenlfv6naeo3i4-wkxkhwrfvh7exepkpoy75r6w7a.msit-datawarehouse.fabric.microsoft.com"; db = "POSOT_CSP" },
  @{ name = "Source2"; server = "x6eps4xrq2xudenlfv6naeo3i4-c5omxo36ksuujozjb4y7d57ula.msit-datawarehouse.fabric.microsoft.com"; db = "GPSMart" }
)

function Invoke-FabricQuery {
  param($server, $db, $token, $sql)
  $conn = New-Object System.Data.SqlClient.SqlConnection
  $conn.ConnectionString = "Server=tcp:$server,1433;Database=$db;Encrypt=True;TrustServerCertificate=False;Connection Timeout=60;"
  $conn.AccessToken = $token
  $conn.Open()
  $cmd = $conn.CreateCommand()
  $cmd.CommandText = $sql
  $cmd.CommandTimeout = 120
  $da = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
  $dt = New-Object System.Data.DataTable
  [void]$da.Fill($dt)
  $conn.Close()
  return ,$dt
}

foreach ($s in $sources) {
  Write-Host "================ $($s.name) :: $($s.db) ================"

  $sql = @"
SELECT TABLE_SCHEMA + '.' + TABLE_NAME AS FullName
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE '%FactMarket%'
ORDER BY TABLE_SCHEMA, TABLE_NAME
"@
  $dt = Invoke-FabricQuery -server $s.server -db $s.db -token $token -sql $sql
  Write-Host ("-- Tables LIKE %FactMarket% (count={0}):" -f $dt.Rows.Count)
  foreach ($r in $dt.Rows) { Write-Host ("   " + $r["FullName"]) }

  $sql2 = "SELECT DISTINCT TABLE_SCHEMA AS S FROM INFORMATION_SCHEMA.TABLES ORDER BY TABLE_SCHEMA"
  $dt2 = Invoke-FabricQuery -server $s.server -db $s.db -token $token -sql $sql2
  Write-Host ("-- All schemas (count={0}):" -f $dt2.Rows.Count)
  foreach ($r in $dt2.Rows) { Write-Host ("   " + $r["S"]) }
}
