#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Scaffold a new Power BI report build script for any semantic model.

.DESCRIPTION
    Discovers workspace + semantic model, inspects schema via DAX, then generates
    a ready-to-run PowerShell script with visual builders and a layout blueprint.

.PARAMETER WorkspaceName
    Display name of the Fabric workspace (partial match OK).

.PARAMETER ModelName
    Display name of the semantic model (partial match OK).

.PARAMETER OutputPath
    Path to write the generated build script. Default: ./build-report.ps1

.PARAMETER ReportName
    Display name for the new report. Default: "Auto-Generated Report"

.EXAMPLE
    .\scaffold-report.ps1 -WorkspaceName "GPS Investments" -ModelName "UserQueryLogs" -OutputPath "./my-report.ps1"
#>
param(
    [Parameter(Mandatory)][string]$WorkspaceName,
    [Parameter(Mandatory)][string]$ModelName,
    [string]$OutputPath = "./build-report.ps1",
    [string]$ReportName = "Auto-Generated Report"
)

$ErrorActionPreference = "Stop"
$token = (az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv)
$headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }

# ─── Find workspace ──────────────────────────────────────────────────────────
Write-Host "Finding workspace matching '$WorkspaceName'..."
$workspaces = (Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/workspaces" -Headers $headers).value
$ws = $workspaces | Where-Object { $_.displayName -like "*$WorkspaceName*" } | Select-Object -First 1
if (-not $ws) { throw "Workspace not found matching '$WorkspaceName'" }
Write-Host "  Found: $($ws.displayName) [$($ws.id)]"

# ─── Find semantic model ─────────────────────────────────────────────────────
Write-Host "Finding semantic model matching '$ModelName'..."
$models = (Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/workspaces/$($ws.id)/semanticModels" -Headers $headers).value
$model = $models | Where-Object { $_.displayName -like "*$ModelName*" } | Select-Object -First 1
if (-not $model) { throw "Semantic model not found matching '$ModelName'" }
Write-Host "  Found: $($model.displayName) [$($model.id)]"

# ─── Discover schema via DAX ─────────────────────────────────────────────────
Write-Host "Querying schema..."
$daxUri = "https://api.fabric.microsoft.com/v1/workspaces/$($ws.id)/semanticModels/$($model.id)/executeQueries"

# Get tables
$tablesResp = Invoke-RestMethod -Uri $daxUri -Headers $headers -Method POST -Body (@{
    queries = @(@{ query = "EVALUATE INFO.TABLES()" })
} | ConvertTo-Json -Depth 5)
$tables = $tablesResp.results[0].tables[0].rows | Where-Object { -not $_.'[IsHidden]' }

# Get columns
$colsResp = Invoke-RestMethod -Uri $daxUri -Headers $headers -Method POST -Body (@{
    queries = @(@{ query = "EVALUATE INFO.COLUMNS()" })
} | ConvertTo-Json -Depth 5)
$columns = $colsResp.results[0].tables[0].rows

# Get measures
$measResp = Invoke-RestMethod -Uri $daxUri -Headers $headers -Method POST -Body (@{
    queries = @(@{ query = "EVALUATE INFO.MEASURES()" })
} | ConvertTo-Json -Depth 5)
$measures = $measResp.results[0].tables[0].rows

Write-Host "  Tables: $($tables.Count)"
Write-Host "  Columns: $($columns.Count)"
Write-Host "  Measures: $($measures.Count)"

# Pick primary table (largest or first non-hidden)
$primaryTable = ($tables | Select-Object -First 1).'[Name]'
$tableCols = $columns | Where-Object { $_.'[TableID]' -eq ($tables | Select-Object -First 1).'[ID]' }
$measureNames = $measures | ForEach-Object { $_.'[Name]' }

# ─── Generate script ─────────────────────────────────────────────────────────
Write-Host "Generating build script at $OutputPath..."

$connStr = "Data Source=\`"powerbi://api.powerbi.com/v1.0/myorg/$($ws.displayName)\`";initial catalog=$($model.displayName);integrated security=ClaimsToken;semanticmodelid=$($model.id)"

$script = @"
###############################################################################
# Auto-generated report build script
# Workspace: $($ws.displayName) [$($ws.id)]
# Model:     $($model.displayName) [$($model.id)]
# Table:     $primaryTable
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm")
###############################################################################

`$ErrorActionPreference = "Stop"
`$token = (az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv)
`$headers = @{ "Authorization" = "Bearer `$token"; "Content-Type" = "application/json" }
`$wsId = "$($ws.id)"
# `$reportId = "<report-id>"  # Uncomment after first creation

function VID { -join ((48..57)+(97..102) | Get-Random -Count 20 | ForEach-Object{[char]`$_}) }
function B64(`$obj) { `$json = `$obj | ConvertTo-Json -Depth 30 -Compress; [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(`$json)) }
function AddVisual(`$pageId, `$vo) { [void]`$script:allParts.Add(@{ path="definition/pages/`$pageId/visuals/`$(`$vo.vid)/visual.json"; payload=(B64 `$vo.json); payloadType="InlineBase64" }) }

# ── Visual builders (Entity = "$primaryTable") ──
# TODO: Paste MakeCard, MakeSlicer, MakeHeader, MakeBarChart, MakeColumnChart,
#       MakeLineChart, MakeDonut from references/visual-builders.md
#       Replace <TABLE> with "$primaryTable"

# ── Available Measures ──
$(($measureNames | ForEach-Object { "# - $_" }) -join "`n")

# ── Available Columns ──
$(($tableCols | ForEach-Object { "# - $($_.'[ExplicitName]') ($($_.'[ExplicitDataType]'))" }) -join "`n")

# ── Build Parts ──
`$allParts = [System.Collections.ArrayList]::new()
`$p1 = "a1b2c3d4e5f6a7b8c9d0"

# Structural
`$pbir = @{ '`$schema'="https://developer.microsoft.com/json-schemas/fabric/item/report/definitionProperties/2.0.0/schema.json"; version="4.0"; datasetReference=@{ byConnection=@{ connectionString="$connStr" } } }
[void]`$allParts.Add(@{ path="definition.pbir"; payload=(B64 `$pbir); payloadType="InlineBase64" })
[void]`$allParts.Add(@{ path="definition/version.json"; payload=(B64 @{ '`$schema'="https://developer.microsoft.com/json-schemas/fabric/item/report/definition/versionMetadata/1.0.0/schema.json"; version="2.0.0" }); payloadType="InlineBase64" })
[void]`$allParts.Add(@{ path="definition/report.json"; payload=(B64 @{ '`$schema'="https://developer.microsoft.com/json-schemas/fabric/item/report/definition/report/3.2.0/schema.json"; themeCollection=@{ baseTheme=@{ name="CY25SU12"; reportVersionAtImport=@{ visual="2.5.0"; report="3.1.0"; page="2.3.0" }; type="SharedResources" } } }); payloadType="InlineBase64" })
[void]`$allParts.Add(@{ path="definition/pages/pages.json"; payload=(B64 @{ '`$schema'="https://developer.microsoft.com/json-schemas/fabric/item/report/definition/pagesMetadata/1.0.0/schema.json"; pageOrder=@(`$p1); activePageName=`$p1 }); payloadType="InlineBase64" })

# Page 1
`$p1Obj = @{ '`$schema'="https://developer.microsoft.com/json-schemas/fabric/item/report/definition/page/2.1.0/schema.json"; name=`$p1; displayName="Overview"; displayOption="FitToWidth"; height=890; width=1280 }
[void]`$allParts.Add(@{ path="definition/pages/`$p1/page.json"; payload=(B64 `$p1Obj); payloadType="InlineBase64" })

# TODO: Add visuals here using AddVisual `$p1 (MakeCard ...)
# Layout:
#   y=0    h=40  : Header
#   y=46   h=90  : Slicers + accent cards
#   y=142  h=110 : Primary KPI row
#   y=258  h=310 : Charts
#   y=574  h=90  : Secondary KPIs
#   y=670  h=210 : Trend chart

Write-Host "Total parts: `$(`$allParts.Count)"
`$body = @{ definition=@{ parts=`$allParts } } | ConvertTo-Json -Depth 30

# CREATE new report (first run)
`$createBody = @{ displayName="$ReportName"; definition=@{ parts=`$allParts } } | ConvertTo-Json -Depth 30
`$resp = Invoke-WebRequest -Uri "https://api.fabric.microsoft.com/v1/workspaces/`$wsId/reports" -Headers `$headers -Method POST -Body `$createBody -UseBasicParsing
Write-Host "Status: `$(`$resp.StatusCode)"

# UPDATE existing report (subsequent runs — uncomment and set `$reportId)
# `$resp = Invoke-WebRequest -Uri "https://api.fabric.microsoft.com/v1/workspaces/`$wsId/reports/`$reportId/updateDefinition" -Headers `$headers -Method POST -Body `$body -UseBasicParsing

if (`$resp.StatusCode -eq 202) {
    `$op = `$resp.Headers["Location"] | Select-Object -First 1
    Write-Host "Polling..."
    do { Start-Sleep 15; `$poll = (Invoke-WebRequest -Uri `$op -Headers `$headers -Method GET -UseBasicParsing).Content | ConvertFrom-Json; Write-Host "Status: `$(`$poll.status)" } while (`$poll.status -notin @("Succeeded","Failed"))
}
"@

$script | Out-File $OutputPath -Encoding UTF8
Write-Host "`nDone! Edit $OutputPath to add visuals, then run it."
Write-Host "Measures found: $($measureNames -join ', ')"
