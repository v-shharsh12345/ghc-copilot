$ErrorActionPreference = "Stop"

$tok = az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv
$h = @{ Authorization = "Bearer $tok" }
$ws = "c29380d6-b4aa-43d2-9bea-23d9e9004afd"
$nb = "691c0894-31e7-49fa-a936-55501e641893"

$urls = @(
  "https://api.fabric.microsoft.com/v1/workspaces/$ws/notebooks/$nb",
  "https://api.fabric.microsoft.com/v1/workspaces/$ws/items/$nb",
  "https://api.fabric.microsoft.com/v1/workspaces/$ws/notebooks/$nb/getDefinition",
  "https://api.fabric.microsoft.com/v1/workspaces/$ws/items/$nb/getDefinition"
)

foreach ($u in $urls) {
  Write-Host "=== $u ==="
  try {
    $r = Invoke-RestMethod -Uri $u -Headers $h -Method Get
    $json = $r | ConvertTo-Json -Depth 10
    $out = "scripts\\api-" + (($u -replace 'https://api.fabric.microsoft.com/v1/','') -replace '[^a-zA-Z0-9\-]','_') + ".json"
    Set-Content -Path $out -Value $json -Encoding UTF8
    Write-Host "OK -> $out"
  } catch {
    Write-Host ("ERROR: " + $_.Exception.Message)
    if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream()) {
      $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
      $body = $sr.ReadToEnd()
      $sr.Close()
      Write-Host $body
    }
  }
}
