$ErrorActionPreference = "Stop"
$token = az account get-access-token --resource "https://database.windows.net/" --query accessToken -o tsv

$sources = @(
  @{ name = "Source1-POSOT_Azure"; server = "x6eps4xrq2xudenlfv6naeo3i4-22ajhqvkwtjehg7kepm6sack7u.msit-datawarehouse.fabric.microsoft.com"; db = "POSOT_Azure" },
  @{ name = "Source2-PPR Warehouse"; server = "x6eps4xrq2xudenlfv6naeo3i4-gs7rn6r7m2oetco33xb7dwa6o4.msit-datawarehouse.fabric.microsoft.com"; db = "PPR Warehouse" }
)

function Invoke-FabricQuery {
  param($server, $db, $token, $sql)
  $conn = New-Object System.Data.SqlClient.SqlConnection
  $conn.ConnectionString = "Server=tcp:$server,1433;Database=$db;Encrypt=True;TrustServerCertificate=False;Connection Timeout=60;"
  $conn.AccessToken = $token
  $conn.Open()
  $cmd = $conn.CreateCommand(); $cmd.CommandText = $sql; $cmd.CommandTimeout = 120
  $da = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
  $dt = New-Object System.Data.DataTable; [void]$da.Fill($dt); $conn.Close()
  return ,$dt
}

foreach ($s in $sources) {
  Write-Host "================ $($s.name) :: $($s.db) ================"
  $sql = @"
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN ('MapAzureAssociationPartnerPPR','FactAzureConsumption_Reporting','DimIntegrationTime')
ORDER BY TABLE_SCHEMA, TABLE_NAME
"@
  $dt = Invoke-FabricQuery -server $s.server -db $s.db -token $token -sql $sql
  Write-Host ("-- Matches (count={0}):" -f $dt.Rows.Count)
  foreach ($r in $dt.Rows) { Write-Host ("   {0}.{1}" -f $r["TABLE_SCHEMA"], $r["TABLE_NAME"]) }

  $dt2 = Invoke-FabricQuery -server $s.server -db $s.db -token $token -sql "SELECT DISTINCT TABLE_SCHEMA AS S FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA LIKE '%Gold%' ORDER BY TABLE_SCHEMA"
  Write-Host ("-- Gold-like schemas (count={0}):" -f $dt2.Rows.Count)
  foreach ($r in $dt2.Rows) { Write-Host ("   " + $r["S"]) }
}
