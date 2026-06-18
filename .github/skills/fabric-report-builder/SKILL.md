---
name: fabric-report-builder
description: >
  Build, deploy, and iterate Power BI reports entirely via code using Fabric REST API + PowerShell + PBIR JSON.
  No Power BI Desktop required. Covers end-to-end: data source discovery, semantic model inspection,
  DAX measure creation, PBIR visual JSON construction, API deployment, and Playwright visual verification.
  Use when user says "create Power BI report", "build dashboard", "deploy report via API",
  "build PBIR report", "create visuals programmatically", "report from semantic model",
  "automate Power BI", or needs to create/modify/redeploy any Power BI report without Desktop.
---

# Fabric Report Builder

Build and deploy Power BI reports entirely through code — no Power BI Desktop needed.

## Architecture

```
Data Source (any) → Semantic Model (lakehouse/dataset) → PBIR Report JSON → Fabric REST API → Deployed Report → Playwright Verify
```

## End-to-End Workflow

### Phase 1: Discover the Data Source

Identify what data the report will visualize. The data can live anywhere — the report connects to a **semantic model**, not raw data.

```powershell
# Auth (reused in every phase)
$token = (az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv)
$headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }
```

**Find workspaces:**
```powershell
(Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/workspaces" -Headers $headers).value |
  Select-Object id, displayName | Format-Table
```

**Find semantic models in a workspace:**
```powershell
$wsId = "<workspace-id>"
(Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/semanticModels" -Headers $headers).value |
  Select-Object id, displayName | Format-Table
```

**Query the semantic model to understand its schema:**
```powershell
$modelId = "<semantic-model-id>"
$daxBody = @{ queries = @(@{ query = "EVALUATE INFO.TABLES()" }) } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/semanticModels/$modelId/executeQueries" `
  -Headers $headers -Method POST -Body $daxBody
```

Useful DAX discovery queries:
- `EVALUATE INFO.TABLES()` — list all tables
- `EVALUATE INFO.COLUMNS()` — list all columns with types
- `EVALUATE INFO.MEASURES()` — list existing measures
- `EVALUATE TOPN(5, 'TableName')` — sample rows
- `EVALUATE { COUNTROWS('TableName') }` — row count

### Phase 2: Create/Inspect the Semantic Model

If a semantic model already exists, inspect it. If not, create one from a lakehouse or other source via the Fabric portal or API.

**Connection string format** (needed for the report):
```
Data Source="powerbi://api.powerbi.com/v1.0/myorg/<WorkspaceName>";
initial catalog=<ModelName>;
integrated security=ClaimsToken;
semanticmodelid=<model-id>
```

**Add DAX measures** via `executeQueries` or the Fabric portal:
```powershell
# Example: add a measure via XMLA (requires XMLA endpoint enabled)
# Or create measures in the Fabric portal UI under the semantic model
```

Key DAX patterns for analytics reports:
```dax
-- Unique count
Unique Users = DISTINCTCOUNT('Table'[UserColumn])

-- Ratio
Queries per User = DIVIDE([Total Queries], [Unique Users], 0)

-- Percentage
Retention Rate % = DIVIDE([Returning Users], [Unique Users], 0) * 100

-- Time intelligence
Queries Last 7 Days = CALCULATE([Total Queries], DATESINPERIOD('Table'[DateColumn], MAX('Table'[DateColumn]), -7, DAY))

-- ROI / Hours Saved
Hours Saved = DIVIDE([Total Queries] * <MinutesSavedPerQuery>, 60, 0)

-- Calculated column (category classification)
Query Category = SWITCH(TRUE(),
    CONTAINSSTRING([TextField], "keyword1"), "Category A",
    CONTAINSSTRING([TextField], "keyword2"), "Category B",
    "Other"
)
```

### Phase 3: Build the PBIR Report Definition

A PBIR report is a collection of JSON files, each Base64-encoded and sent as "parts" to the API.

#### 3.1 Structural Parts (always required)

```
definition.pbir                          → connection to semantic model
definition/version.json                  → schema version
definition/report.json                   → theme config
definition/pages/pages.json              → page order + active page
definition/pages/{pageId}/page.json      → page size, display mode
definition/pages/{pageId}/visuals/{vid}/visual.json  → each visual
StaticResources/SharedResources/BaseThemes/<theme>.json  → theme file (optional)
```

#### 3.2 PowerShell Helpers

```powershell
# Generate random visual IDs
function VID { -join ((48..57)+(97..102) | Get-Random -Count 20 | ForEach-Object{[char]$_}) }

# Base64-encode any object
function B64($obj) {
    $json = $obj | ConvertTo-Json -Depth 30 -Compress
    [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($json))
}

# Add a visual part to the parts array
function AddVisual($pageId, $vo) {
    [void]$script:allParts.Add(@{
        path="definition/pages/$pageId/visuals/$($vo.vid)/visual.json"
        payload=(B64 $vo.json)
        payloadType="InlineBase64"
    })
}
```

#### 3.3 definition.pbir

```powershell
$pbir = @{
    '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definitionProperties/2.0.0/schema.json"
    version   = "4.0"
    datasetReference = @{ byConnection = @{
        connectionString = "Data Source=`"powerbi://api.powerbi.com/v1.0/myorg/<WorkspaceName>`";initial catalog=<ModelName>;integrated security=ClaimsToken;semanticmodelid=<model-id>"
    }}
}
```

#### 3.4 Page Definition

```powershell
$pageObj = @{
    '$schema'     = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/page/2.1.0/schema.json"
    name          = "<pageId>"           # unique hex string
    displayName   = "Executive Summary"
    displayOption = "FitToWidth"         # FitToWidth allows scroll, FitToPage scales down
    height        = 890                  # use 860-900 for FitToWidth (avoids cramming into 720)
    width         = 1280
}
```

#### 3.5 Visual JSON Schema (v2.7.0)

Every visual follows this structure:

```json
{
    "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.7.0/schema.json",
    "name": "<visual-id>",
    "position": { "x": 10, "y": 100, "z": 1000, "height": 110, "width": 250, "tabOrder": 1000 },
    "visual": {
        "visualType": "<type>",
        "query": { "queryState": { ... } },
        "objects": { ... },
        "visualContainerObjects": { ... }
    }
}
```

**Visual types:** `cardVisual`, `slicer`, `textbox`, `clusteredBarChart`, `clusteredColumnChart`, `lineChart`, `donutChart`, `pieChart`, `tableEx`, `pivotTable`

### Phase 4: Visual Builder Functions

Reusable PowerShell functions for common visual types. Adapt `Entity` to match your semantic model table name.

> **CRITICAL SIZING RULES** (learned from production iterations):
> - Card visuals need **minimum 90px height** for value + label to show without clipping
> - Slicer visuals need **minimum 80-90px height** for title + dropdown
> - Use **0px top padding** on accent cards to maximize vertical space
> - Font 16D for small cards, 20-22D for medium, 26D for large hero cards
> - Always use `FitToWidth` with height 860-900 — never 720 (causes cramming)
> - Leave **6px vertical gap** between visual rows minimum

#### Card Visual

```powershell
function MakeCard($measure, $x, $y, $w, $h, $z, $fontSize, $bgColor, $borderColor, $fontColor) {
    if (-not $fontSize)    { $fontSize    = "22D" }
    if (-not $bgColor)     { $bgColor     = "'#FFFFFF'" }
    if (-not $borderColor) { $borderColor = "'#E0E0E0'" }
    if (-not $fontColor)   { $fontColor   = "'#333333'" }
    $v = VID
    return @{ vid=$v; json=@{
        '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.7.0/schema.json"
        name = $v
        position = @{ x=$x; y=$y; z=$z; height=$h; width=$w; tabOrder=$z }
        visual = @{
            visualType = "cardVisual"
            query = @{ queryState = @{ Data = @{ projections = @(@{
                field = @{ Measure = @{ Expression = @{ SourceRef = @{ Entity = "<TABLE>" } }; Property = $measure } }
                queryRef = "<TABLE>.$measure"; nativeQueryRef = $measure
            }) } } }
            objects = @{
                value = @(@{ properties = @{
                    fontFamily = @{ expr = @{ Literal = @{ Value = "'''Segoe UI Semibold'''" } } }
                    fontSize   = @{ expr = @{ Literal = @{ Value = $fontSize } } }
                    fontColor  = @{ solid = @{ color = @{ expr = @{ Literal = @{ Value = $fontColor } } } } }
                }; selector = @{ id = "default" } })
                label = @(@{ properties = @{
                    show      = @{ expr = @{ Literal = @{ Value = "true" } } }
                    fontSize  = @{ expr = @{ Literal = @{ Value = "11D" } } }
                }; selector = @{ id = "default" } })
            }
            visualContainerObjects = @{
                border     = @(@{ properties = @{ show = @{ expr = @{ Literal = @{ Value = "true" } } }; color = @{ solid = @{ color = @{ expr = @{ Literal = @{ Value = $borderColor } } } } }; radius = @{ expr = @{ Literal = @{ Value = "8D" } } } } })
                background = @(@{ properties = @{ show = @{ expr = @{ Literal = @{ Value = "true" } } }; color = @{ solid = @{ color = @{ expr = @{ Literal = @{ Value = $bgColor } } } } } } })
                padding    = @(@{ properties = @{ top = @{ expr = @{ Literal = @{ Value = "0D" } } }; left = @{ expr = @{ Literal = @{ Value = "8D" } } } } })
            }
        }
    }}
}
```

#### Slicer (Dropdown)

```powershell
function MakeSlicer($column, $title, $x, $y, $w, $h, $z) {
    $v = VID
    return @{ vid=$v; json=@{
        '$schema' = "...visualContainer/2.7.0/schema.json"
        name=$v; position=@{ x=$x; y=$y; z=$z; height=$h; width=$w; tabOrder=$z }
        visual = @{
            visualType = "slicer"
            query = @{ queryState = @{ Values = @{ projections = @(@{
                field = @{ Column = @{ Expression = @{ SourceRef = @{ Entity = "<TABLE>" } }; Property = $column } }
                queryRef = "<TABLE>.$column"; nativeQueryRef = $column
            }) } } }
            objects = @{ data = @(@{ properties = @{ mode = @{ expr = @{ Literal = @{ Value = "'Dropdown'" } } } } }) }
            visualContainerObjects = @{
                title = @(@{ properties = @{ show = @{ expr = @{ Literal = @{ Value = "true" } } }; text = @{ expr = @{ Literal = @{ Value = "'$title'" } } } } })
                border = @(@{ properties = @{ show = @{ expr = @{ Literal = @{ Value = "true" } } }; radius = @{ expr = @{ Literal = @{ Value = "6D" } } } } })
            }
        }
    }}
}
```

#### Bar Chart, Column Chart, Line Chart, Donut Chart

See `references/visual-builders.md` for full implementations of `MakeBarChart`, `MakeColumnChart`, `MakeLineChart`, `MakeDonut`, `MakeHeader` (textbox).

### Phase 5: Layout Blueprint

Design the layout BEFORE writing code. Use this template:

```
Canvas: 1280 x 890 (FitToWidth)
──────────────────────────────────────────────
y=0    h=40  : Header bar (dark bg, white text)
y=46   h=90  : Slicer(s) + accent KPI cards
y=142  h=110 : Primary KPI row (4-6 cards)
y=258  h=310 : Charts row (bar/column left + donut/pie right)
y=574  h=90  : Secondary KPI row (6 cards)
y=670  h=210 : Trend line chart (full width)
──────────────────────────────────────────────
```

**Rules:**
- Each row's y = previous row's y + h + gap (6px min)
- Cards: min 90px tall, 200-250px wide
- Charts: min 250px tall, 300px+ wide
- Full-width elements: x=10, w=1260
- Half-width: left x=10 w=620, right x=640 w=630

### Phase 6: Deploy via Fabric REST API

```powershell
# Assemble parts array
$allParts = [System.Collections.ArrayList]::new()
[void]$allParts.Add(@{ path="definition.pbir"; payload=(B64 $pbir); payloadType="InlineBase64" })
# ... add all page + visual parts ...

# Build payload
$body = @{ definition = @{ parts = $allParts } } | ConvertTo-Json -Depth 30

# Create new report
$uri = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/reports"
$createBody = @{ displayName = "My Report"; definition = @{ parts = $allParts } } | ConvertTo-Json -Depth 30
$resp = Invoke-WebRequest -Uri $uri -Headers $headers -Method POST -Body $createBody -UseBasicParsing

# OR update existing report
$uri = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/reports/$reportId/updateDefinition"
$resp = Invoke-WebRequest -Uri $uri -Headers $headers -Method POST -Body $body -UseBasicParsing

# Poll for completion (API returns 202)
if ($resp.StatusCode -eq 202) {
    $op = $resp.Headers["Location"] | Select-Object -First 1
    do {
        Start-Sleep -Seconds 15
        $poll = (Invoke-WebRequest -Uri $op -Headers $headers -Method GET -UseBasicParsing).Content | ConvertFrom-Json
        Write-Host "Status: $($poll.status)"
    } while ($poll.status -notin @("Succeeded","Failed"))

    if ($poll.status -eq "Failed") { throw "Deploy failed: $($poll.error | ConvertTo-Json)" }
}
```

### Phase 7: Verify with Playwright MCP

After deployment, use Playwright to visually verify the report renders correctly.

```
1. mcp_playwright_browser_navigate → report URL
2. mcp_playwright_browser_click   → sign in (pick account)
3. mcp_playwright_browser_wait_for → wait 15-20s for render
4. mcp_playwright_browser_take_screenshot → capture page
5. Inspect screenshot for:
   - Card values and labels fully visible (not clipped)
   - Charts rendering with data (not empty)
   - No overlapping visuals
   - Slicer dropdowns functional
6. Click each page tab → screenshot each
7. If issues found → adjust positions/heights → redeploy → re-verify
```

**Common Playwright issues:**
- Report requires auth → click the correct account button
- "Visuals are loading..." → wait longer (20-30s)
- Screenshot at 43% zoom → use `fullPage: true` for complete capture

### Phase 8: Iteration Checklist

When visuals are broken, check in this order:

| Symptom | Fix |
|---------|-----|
| Card label clipped | Increase card height (min 90px), reduce fontSize, set padding top=0D |
| Visuals overlapping | Check y-coordinates: next_row_y >= prev_row_y + prev_row_h + 6 |
| Slicer value not showing | Increase slicer height to 90px |
| Chart empty | Verify Entity name matches semantic model table exactly |
| Donut behind bar chart | Ensure different x positions and same z-order range |
| Everything cramped | Switch displayOption to "FitToWidth", increase page height to 890 |
| Title text invisible | Check fontColor vs background color contrast |
| "displayTitle" eating space | Remove displayTitle param, let cardVisual label show naturally |

## Quick-Start Template

For a new report, copy and adapt this sequence:

1. `az account get-access-token --resource "https://api.fabric.microsoft.com"` — auth
2. Discover workspace + semantic model IDs (Phase 1)
3. Run sample DAX queries to understand the data shape
4. Design layout blueprint on paper/comments (Phase 5)
5. Write PowerShell script using MakeCard/MakeSlicer/MakeBarChart helpers (Phase 4)
6. Replace `<TABLE>` with actual entity name in all visual functions
7. Deploy via `updateDefinition` API (Phase 6)
8. Verify with Playwright MCP (Phase 7)
9. Iterate: fix heights/positions, redeploy, re-verify (Phase 8)

## API Reference

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v1/workspaces` | GET | List workspaces |
| `/v1/workspaces/{id}/semanticModels` | GET | List semantic models |
| `/v1/workspaces/{id}/semanticModels/{id}/executeQueries` | POST | Run DAX queries |
| `/v1/workspaces/{id}/reports` | POST | Create new report |
| `/v1/workspaces/{id}/reports/{id}/getDefinition` | POST | Download report PBIR |
| `/v1/workspaces/{id}/reports/{id}/updateDefinition` | POST | Upload/replace report PBIR |

## PBIR Schema Versions

| Part | Schema |
|------|--------|
| definition.pbir | `definitionProperties/2.0.0` |
| version.json | `versionMetadata/1.0.0` |
| report.json | `report/3.2.0` |
| page.json | `page/2.1.0` |
| visual.json | `visualContainer/2.7.0` |
| pages.json | `pagesMetadata/1.0.0` |
