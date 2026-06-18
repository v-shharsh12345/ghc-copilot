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
  return $dt
}

foreach ($s in $sources) {
  Write-Host "================ $($s.name) :: $($s.db) ================"

  # 1) Schemas containing FactMarketDB
  $sql = @"
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'FactMarketDB'
ORDER BY TABLE_SCHEMA
"@
  $dt = Invoke-FabricQuery -server $s.server -db $s.db -token $token -sql $sql
  Write-Host "-- Schemas containing FactMarketDB:"
  foreach ($r in $dt.Rows) { Write-Host ("   {0}.{1}" -f $r.TABLE_SCHEMA, $r.TABLE_NAME) }
}
