$ErrorActionPreference = "Stop"

$tok = az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv
$h = @{ Authorization = "Bearer $tok" }

$names = @("GPS_Azure_Prod_Processing","GPS_Integration_Prod_Processing")

$ws = Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/workspaces" -Headers $h
foreach ($n in $names) {
  $match = $ws.value | Where-Object { $_.displayName -eq $n }
  if ($match) {
    Write-Host ("WORKSPACE: {0} -> {1}" -f $match.displayName, $match.id)
    foreach ($t in @("lakehouses","warehouses")) {
      try {
        $items = Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/workspaces/$($match.id)/$t" -Headers $h
        foreach ($i in $items.value) {
          $cs = $i.properties.connectionString
          if (-not $cs) { $cs = $i.properties.sqlEndpointProperties.connectionString }
          $epId = $i.properties.sqlEndpointProperties.id
          Write-Host ("   [{0}] name={1} id={2} sqlEpId={3} conn={4}" -f $t, $i.displayName, $i.id, $epId, $cs)
        }
      } catch { Write-Host ("   [{0}] error: {1}" -f $t, $_.Exception.Message) }
    }
  } else {
    Write-Host ("WORKSPACE NOT FOUND: {0}" -f $n)
  }
}
