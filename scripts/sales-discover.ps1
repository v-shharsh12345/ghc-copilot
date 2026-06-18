$ErrorActionPreference = "Stop"

$tok = az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv
$h = @{ Authorization = "Bearer $tok" }

# Find the Sales workspace
$wsName = "GPS_MSSales_Prod_Processing"
$wss = Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/workspaces" -Headers $h -Method Get
$ws = $wss.value | Where-Object { $_.displayName -eq $wsName }
if (-not $ws) { throw "Workspace '$wsName' not found" }
Write-Host "Workspace: $($ws.displayName)  id=$($ws.id)"

# List SQL endpoints in the workspace
Write-Host "`n=== SQL Endpoints ==="
try {
  $eps = Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/workspaces/$($ws.id)/sqlEndpoints" -Headers $h -Method Get
  foreach ($e in $eps.value) {
    Write-Host ("name={0}  id={1}  connStr={2}" -f $e.displayName, $e.id, $e.properties.connectionString)
  }
} catch {
  Write-Host ("sqlEndpoints error: " + $_.Exception.Message)
}

# List lakehouses (each has a SQL endpoint connection string in properties)
Write-Host "`n=== Lakehouses ==="
try {
  $lhs = Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/workspaces/$($ws.id)/lakehouses" -Headers $h -Method Get
  foreach ($l in $lhs.value) {
    Write-Host ("name={0}  id={1}" -f $l.displayName, $l.id)
    if ($l.properties.sqlEndpointProperties) {
      Write-Host ("   connStr={0}  sqlDb={1}" -f $l.properties.sqlEndpointProperties.connectionString, $l.properties.sqlEndpointProperties.id)
    }
  }
} catch {
  Write-Host ("lakehouses error: " + $_.Exception.Message)
}
