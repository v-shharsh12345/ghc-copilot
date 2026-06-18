$ErrorActionPreference = "Stop"

$token = az account get-access-token --resource "https://database.windows.net/" --query accessToken -o tsv

$targets = @(
  @{ name = "Source 1 - POSOT_CSP"; server = "x6eps4xrq2xudenlfv6naeo3i4-wkxkhwrfvh7exepkpoy75r6w7a.msit-datawarehouse.fabric.microsoft.com"; db = "POSOT_CSP"; schema = "CSPGold2026061101"; table = "FactMarketDB" },
  @{ name = "Source 2 - GPSMart";   server = "x6eps4xrq2xudenlfv6naeo3i4-c5omxo36ksuujozjb4y7d57ula.msit-datawarehouse.fabric.microsoft.com"; db = "GPSMart"; schema = "CSPT"; table = "FactMarketDB" }
)

function Invoke-FabricScalar {
  param($server, $db, $token, $sql)
  $conn = New-Object System.Data.SqlClient.SqlConnection
  $conn.ConnectionString = "Server=tcp:$server,1433;Database=$db;Encrypt=True;TrustServerCertificate=False;Connection Timeout=60;"
  $conn.AccessToken = $token
  $conn.Open()
  $cmd = $conn.CreateCommand()
  $cmd.CommandText = $sql
  $cmd.CommandTimeout = 300
  $val = $cmd.ExecuteScalar()
  $conn.Close()
  return $val
}

$results = @()
foreach ($t in $targets) {
  $full = "[$($t.schema)].[$($t.table)]"
  Write-Host "=== $($t.name) :: $full ==="

  # Confirm NCEFlag column exists
  $colSql = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='$($t.schema)' AND TABLE_NAME='$($t.table)' AND COLUMN_NAME='NCEFlag'"
  $hasCol = Invoke-FabricScalar -server $t.server -db $t.db -token $token -sql $colSql
  Write-Host "   NCEFlag column present: $hasCol"

  $cntSql = "SELECT COUNT(*) FROM [$($t.schema)].[$($t.table)] WHERE NCEFlag = 'Yes'"
  $cnt = Invoke-FabricScalar -server $t.server -db $t.db -token $token -sql $cntSql
  Write-Host "   Count(NCEFlag='Yes') = $cnt"

  $results += [PSCustomObject]@{
    Source            = $t.name
    Database          = $t.db
    Schema            = $t.schema
    Table             = $t.table
    FullyQualified    = "[$($t.db)].$full"
    Filter            = "NCEFlag = 'Yes'"
    RecordCount       = [int64]$cnt
    QueryRunUTC       = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
  }
}

$results | Export-Csv -Path "scripts\factmarketdb-nceflag-results.csv" -NoTypeInformation -Encoding UTF8
Write-Host "`nSaved CSV: scripts\factmarketdb-nceflag-results.csv"
$results | Format-Table -AutoSize
