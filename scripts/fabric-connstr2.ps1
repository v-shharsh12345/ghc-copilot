$ErrorActionPreference = "Stop"

$tok = az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv
$h = @{ Authorization = "Bearer $tok" }

$sources = @(
  @{ name = "Source1"; ws = "daa3aeb2-a925-4bfe-91ea-7bb1fec7d6f8"; item = "4516a6a2-ba8f-4281-8bdc-10af36c22d32" },
  @{ name = "Source2"; ws = "bbcb5c17-547e-44a9-bb29-0f31f1f7f458"; item = "7f904f4d-ec33-4d14-82e4-27ccaacd6a0a" }
)

$types = @("lakehouses","warehouses","mirroredDatabases","mirroredWarehouses")

foreach ($s in $sources) {
  Write-Host "================ $($s.name) ($($s.ws)) ================"
  foreach ($t in $types) {
    try {
      $r = Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/workspaces/$($s.ws)/$t" -Headers $h
      foreach ($i in $r.value) {
        $cs = $null
        if ($i.properties.connectionString) { $cs = $i.properties.connectionString }
        elseif ($i.properties.sqlEndpointProperties.connectionString) { $cs = $i.properties.sqlEndpointProperties.connectionString }
        $epId = $i.properties.sqlEndpointProperties.id
        Write-Host ("[{0}] name={1} id={2} sqlEpId={3} conn={4}" -f $t, $i.displayName, $i.id, $epId, $cs)
      }
    } catch {
      Write-Host ("[{0}] error: {1}" -f $t, $_.Exception.Message)
    }
  }
}
