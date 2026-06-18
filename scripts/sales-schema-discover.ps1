$ErrorActionPreference = "Stop"
$sqlTok = az account get-access-token --resource "https://database.windows.net/" --query accessToken -o tsv

function Invoke-FabricQuery {
  param($server, $db, $token, $sql)
  $conn = New-Object System.Data.SqlClient.SqlConnection
  $conn.ConnectionString = "Server=tcp:$server,1433;Database=$db;Encrypt=True;TrustServerCertificate=False;Connection Timeout=120;"
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

$salesServer = "x6eps4xrq2xudenlfv6naeo3i4-wkxkhwrfvh7exepkpoy75r6w7a.msit-datawarehouse.fabric.microsoft.com"
$salesDb = "POSOT_Sales"

Write-Host "=== Schemas containing FactSales ==="
$sql = @"
SELECT TABLE_SCHEMA, STRING_AGG(TABLE_NAME, ',') AS tabs
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN ('FactSales','DimBusiness')
GROUP BY TABLE_SCHEMA
ORDER BY TABLE_SCHEMA DESC
"@
$dt = Invoke-FabricQuery -server $salesServer -db $salesDb -token $sqlTok -sql $sql
$dt | Format-Table -AutoSize | Out-String -Width 200 | Write-Host
