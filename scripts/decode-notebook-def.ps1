$ErrorActionPreference = "Stop"

$tok = az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv
$h = @{ Authorization = "Bearer $tok" }
$url = "https://df-msit-scus-redirect.analysis.windows.net/v1/operations/0de0ddfb-b2a4-4599-a3e0-1472caa48fa1/result"

$r = Invoke-RestMethod -Uri $url -Method Get -Headers $h
$parts = $r.definition.parts

foreach ($p in $parts) {
  $path = [string]$p.path
  $payload = [string]$p.payload
  $bytes = [Convert]::FromBase64String($payload)
  $text = [System.Text.Encoding]::UTF8.GetString($bytes)

  $safe = $path -replace "[\\/:*?\""<>|]","_"
  $out = "scripts\\decoded-" + $safe
  Set-Content -Path $out -Value $text -Encoding UTF8
  Write-Host "Decoded: $out"
}
