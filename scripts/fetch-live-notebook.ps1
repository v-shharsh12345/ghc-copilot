$ErrorActionPreference = "Stop"

# Acquire Fabric token
$tok = az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv
if (-not $tok) { throw "No Fabric token. Run 'az login' first." }
$h = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }

$ws = "c29380d6-b4aa-43d2-9bea-23d9e9004afd"
$nb = "691c0894-31e7-49fa-a936-55501e641893"

# Kick off getDefinition (LRO)
$defUrl = "https://api.fabric.microsoft.com/v1/workspaces/$ws/notebooks/$nb/getDefinition"
Write-Host "POST $defUrl"
$resp = Invoke-WebRequest -Uri $defUrl -Method Post -Headers $h -Body "{}" -UseBasicParsing
Write-Host "HTTP $($resp.StatusCode)"

$opLocation = $resp.Headers["Location"]
$retryAfter = $resp.Headers["Retry-After"]
Write-Host "Operation-Location: $opLocation"

# Some responses return the definition inline (200) instead of 202
if ($resp.StatusCode -eq 200 -and $resp.Content) {
  $body = $resp.Content | ConvertFrom-Json
  if ($body.definition.parts) {
    $parts = $body.definition.parts
    foreach ($p in $parts) {
      $bytes = [Convert]::FromBase64String([string]$p.payload)
      $text = [System.Text.Encoding]::UTF8.GetString($bytes)
      $safe = ([string]$p.path) -replace "[\\/:*?\""<>|]","_"
      $out = "scripts\live-decoded-$safe"
      Set-Content -Path $out -Value $text -Encoding UTF8
      Write-Host "Decoded inline: $out"
    }
    return
  }
}

if (-not $opLocation) { throw "No Operation-Location header returned; status $($resp.StatusCode)" }

# Poll the operation
$status = "Running"
for ($i = 1; $i -le 40; $i++) {
  Start-Sleep -Milliseconds 1500
  $op = Invoke-RestMethod -Uri $opLocation -Method Get -Headers $h
  $status = [string]$op.status
  Write-Host "Poll $i status=$status"
  if ($status -eq "Succeeded") { break }
  if ($status -eq "Failed") { throw "getDefinition failed: $($op | ConvertTo-Json -Depth 10)" }
}
if ($status -ne "Succeeded") { throw "Operation did not succeed in polling window" }

# Fetch result
$resultUrl = $opLocation.TrimEnd('/') + "/result"
Write-Host "GET $resultUrl"
$res = Invoke-RestMethod -Uri $resultUrl -Method Get -Headers $h
$parts = $res.definition.parts
foreach ($p in $parts) {
  $bytes = [Convert]::FromBase64String([string]$p.payload)
  $text = [System.Text.Encoding]::UTF8.GetString($bytes)
  $safe = ([string]$p.path) -replace "[\\/:*?\""<>|]","_"
  $out = "scripts\live-decoded-$safe"
  Set-Content -Path $out -Value $text -Encoding UTF8
  Write-Host "Decoded: $out"
}
Write-Host "DONE"
