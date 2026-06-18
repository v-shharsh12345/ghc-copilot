$ErrorActionPreference = "Stop"

$tok = az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv
$h = @{ Authorization = "Bearer $tok" }

$sources = @(
  @{ name = "Source1"; ws = "daa3aeb2-a925-4bfe-91ea-7bb1fec7d6f8"; item = "4516a6a2-ba8f-4281-8bdc-10af36c22d32" },
  @{ name = "Source2"; ws = "bbcb5c17-547e-44a9-bb29-0f31f1f7f458"; item = "7f904f4d-ec33-4d14-82e4-27ccaacd6a0a" }
)

foreach ($s in $sources) {
  Write-Host "=== $($s.name) ==="
  $items = Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/workspaces/$($s.ws)/items" -Headers $h
  $it = $items.value | Where-Object { $_.id -eq $s.item }
  if ($it) {
    Write-Host ("displayName: {0}" -f $it.displayName)
    Write-Host ("type:        {0}" -f $it.type)
    Write-Host ("id:          {0}" -f $it.id)
  } else {
    Write-Host "Item not found in items list. Type may be mirroredWarehouse."
  }
}
