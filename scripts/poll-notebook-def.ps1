$ErrorActionPreference = "Stop"

$tok = az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv
$h = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }
$opUrl = "https://df-msit-scus-redirect.analysis.windows.net/v1/operations/0de0ddfb-b2a4-4599-a3e0-1472caa48fa1"

$done = $false
for ($i = 1; $i -le 30; $i++) {
  $r = Invoke-RestMethod -Uri $opUrl -Method Get -Headers $h
  $status = [string]$r.status
  Write-Host "Poll $i status=$status"

  if ($status -eq "Succeeded") {
    $json = $r | ConvertTo-Json -Depth 50
    Set-Content -Path "scripts\notebook-getdef-op.json" -Value $json -Encoding UTF8
    Write-Host "Saved scripts\\notebook-getdef-op.json"
    $done = $true
    break
  }

  if ($status -eq "Failed") {
    throw "Notebook getDefinition operation failed"
  }

}

if (-not $done) {
  Write-Host "Operation not completed in polling window"
}
