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

$tables = @(
  @{s="AzureGold2026061501"; t="FactAzureConsumptionPPR"},
  @{s="AzureGold2026061501"; t="FactAzureConsumption"},
  @{s="AzureGold2026061501"; t="MapAzureAssociationPartnerPPR"},
  @{s="Reporting"; t="FactAzureConsumption_Reporting"}
)
foreach ($tb in $tables) {
  Write-Host ("== {0}.{1} columns ==" -f $tb.s, $tb.t)
  $dt = Q "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='$($tb.s)' AND TABLE_NAME='$($tb.t)' ORDER BY ORDINAL_POSITION"
  foreach ($r in $dt.Rows) { Write-Host ("   {0} ({1})" -f $r["COLUMN_NAME"], $r["DATA_TYPE"]) }
  Write-Host ""
}
