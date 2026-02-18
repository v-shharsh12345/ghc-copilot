# UI/UX Changes Module

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-17 | 1.2 | Added rapid iteration loop for UAT server-side UX remediation, with explicit "what worked" and "what did not work" guidance from live report-definition workflows. |
| 2026-02-17 | 1.1 | Updated to API-first workflow for report UI/UX edits using Fabric item definition round-trip (`getDefinition` → PBIR patch → `updateDefinition`) and clarified Power BI API limits for per-visual/page edits. |
| 2026-02-17 | 1.0 | Initial UI/UX changes module — PBIR-native report formatting, spacing, font consistency, readability, and design-system enforcement. |

## Goal

Apply consistent, standards-driven UI/UX improvements to Power BI reports by manipulating PBIR definition files (visual.json, page.json, report.json, theme JSON) through an API-first definition round-trip. All changes are deterministic, auditable, and committed via the existing Git-based PBIP workflow.

## Scope

- **In scope**: Font consistency, spacing/alignment, color palette adherence, padding/margins, border standardization, title formatting, visual sizing, slicer styling, card layout, readability improvements, accessibility compliance, theme enforcement.
- **Out of scope**: Data model changes, DAX measures, data source modifications, semantic model schema changes. Those belong to `develop.md` or `analyze-lineage.md`.

## PBIR File Anatomy (Reference)

Understanding where each UI/UX property lives in the PBIR folder structure is critical for targeted changes.

```
ReportName.Report/
├── definition.pbir                          # Semantic model binding (byPath or byConnection)
├── definition/
│   ├── report.json                          # Report-level: theme, filters, annotations
│   ├── version.json                         # PBIR format version
│   ├── pages/
│   │   ├── pages.json                       # Page order and active page
│   │   ├── {pageId}/
│   │   │   ├── page.json                    # Page: displayName, height, width, displayOption, background, objects
│   │   │   └── visuals/
│   │   │       └── {visualId}/
│   │   │           └── visual.json          # Visual: position, visualType, query, objects (font, color, border, padding)
├── StaticResources/
│   ├── RegisteredResources/                 # Custom images, SVGs
│   └── SharedResources/
│       └── BaseThemes/
│           └── {ThemeName}.json             # Theme: dataColors, textClasses, visualStyles, foreground, background
```

### Key Files for UI/UX Manipulation

| File | UI/UX Properties Controlled |
| --- | --- |
| `report.json` | Theme binding (themeCollection.baseTheme), report-level filters, annotations |
| `page.json` | Page dimensions (height, width), displayOption (FitToWidth/FitToPage), background color/transparency |
| `visual.json` | Position (x, y, z, height, width), visual type, font/color/border/padding in `visual.objects`, title properties |
| `{Theme}.json` | Global: dataColors, textClasses (callout/title/header/label font+size+color), visualStyles defaults |

## Design System Standards

### Font Stack

| Role | Font Face | Size (pt) | Weight | Color |
| --- | --- | --- | --- | --- |
| Page Title / Section Header | Segoe UI Semibold | 14–16 | Semibold (600) | `#252423` |
| Visual Title | Segoe UI Semibold | 10–12 | Semibold (600) | `#252423` |
| KPI Callout Value | DIN | 28–45 | Regular (400) | `#252423` |
| Axis Labels | Segoe UI | 9–10 | Regular (400) | `#605E5C` |
| Data Labels | Segoe UI | 8–9 | Regular (400) | `#605E5C` |
| Slicer Text | Segoe UI | 10 | Regular (400) | `#252423` |
| Tooltips | Segoe UI | 9 | Regular (400) | `#252423` |
| Legend | Segoe UI | 9–10 | Regular (400) | `#605E5C` |

### Spacing & Layout Grid

| Property | Standard Value | Notes |
| --- | --- | --- |
| Page width | 1280 or 1600px | Use 1600 for FitToWidth scrollable pages |
| Visual horizontal gap | 10–16px | Consistent between adjacent visuals |
| Visual vertical gap | 10–16px | Consistent between visual rows |
| Page margin (left/right) | 16–24px | Breathing room from page edge |
| Page margin (top) | 50–80px | Room for title bar / navigation |
| Visual inner padding | 8–12px | cellPadding in card/layout objects |
| Slicer row height | 24–32px | Comfortable touch target |
| Card corner radius | 6–10px | `rectangleRoundedCurve` in shapeCustomRectangle |

### Color Palette

| Role | Hex | Used For |
| --- | --- | --- |
| Primary Brand | `#118DFF` | Primary data series, highlights, links |
| Secondary Brand | `#12239E` | Secondary data series |
| Accent Warm | `#E66C37` | Accent data series |
| Good / Positive | `#1AAB40` | Status indicators |
| Neutral / Warning | `#D9B300` | Caution indicators |
| Bad / Negative | `#D64554` | Error / negative indicators |
| Text Primary | `#252423` | Headings, body text |
| Text Secondary | `#605E5C` | Labels, axis text |
| Text Tertiary | `#B3B0AD` | Disabled, placeholder |
| Background | `#FFFFFF` | Visual/card background |
| Background Light | `#F3F2F1` | Page background, alternate rows |
| Border | `#B3B0AD` | Subtle visual borders |

### Accessibility Requirements

- Minimum contrast ratio: 4.5:1 for normal text, 3:1 for large text (WCAG AA)
- Never use color alone to convey meaning — pair with shape, text, or icon
- All interactive elements must have a minimum touch target of 24×24px
- Alt text should be set on decorative visuals where applicable

## Inputs

- **Report name** or **report path** (PBIP folder path or Fabric workspace report name)
- **Environment**: DEV / UAT (write), PROD (read-only audit)
- **Change scope**: One of:
  - `audit` — scan and report inconsistencies (no modifications)
  - `fix-fonts` — standardize fonts across all visuals
  - `fix-spacing` — normalize visual positions and gaps
  - `fix-colors` — enforce palette adherence
  - `fix-all` — apply all fixes
  - `apply-theme` — deploy a custom theme JSON
  - `custom` — apply user-specified property changes to targeted visuals
- **Target pages** (optional): Specific page IDs or display names. Default: all pages.
- **Target visuals** (optional): Specific visual IDs or types. Default: all visuals.
- **Dry run** (optional): If true, output a change plan without modifying files. Default: false.

## Preferred Route

- Primary: **Fabric API definition round-trip**:
  - `POST /v1/workspaces/{workspaceId}/items/{itemId}/getDefinition`
  - Patch PBIR `definition.parts` payloads
  - `POST /v1/workspaces/{workspaceId}/items/{itemId}/updateDefinition`
- Secondary: **Direct PBIR file manipulation** (JSON read/edit/write on `.Report/definition/` files in the PBIP repo)
- Analytical support: **Fabric SemPy** (`sempy_labs.report.ReportWrapper`) — audit/discovery (list_visuals, list_pages, list_visual_objects, BPA)
- Complementary only: **Power BI REST API** (`UpdateReportContent`) for report-level content replacement, not granular per-visual/page style edits
- Guidance fallback: **Context7** (`io.github.upstash/context7`) — for PBIR schema reference, theme property discovery

## Rapid Iteration Loop (Server-Side UAT)

Use this loop when the user asks to "quickly iterate", "fix on the fly", or "find and patch UX issues fast".

```
1. Discover report IDs in target workspace (UAT only for write operations).
2. Pull full definition via getDefinition (capture operation status + parts count).
3. Run metadata UX audit and classify: hard-fail vs soft-warning.
4. Patch only deterministic properties in-memory (minimal blast radius).
5. Push via updateDefinition and wait for LRO success.
6. Re-fetch definition and re-run the same audit rubric.
7. Report delta: before vs after PASS/WARN/FAIL and residual risk.
```

### What Worked (Keep)

- API-first PBIR round-trip (`getDefinition` → patch → `updateDefinition`) is reliable for page/visual styling updates.
- Updating only targeted parts while preserving all untouched payloads reduces drift and regression risk.
- Re-fetching definition after update catches persistence/serialization issues immediately.
- Two-level result reporting works best:
  - Raw metadata audit score
  - Refined practical score (excluding intentional design exceptions and metadata-blind checks)
- Minimal-change batches (fonts/spacing/colors/titles/slicers) converge faster than broad all-file rewrites.

### What Did Not Work (Avoid)

- Using Power BI REST as primary path for per-visual/per-page styling edits.
- Treating all non-token colors as hard failures without an approved exception list.
- Declaring accessibility failures solely from metadata where text/background linkage is ambiguous.
- Patching every visual/theme value indiscriminately in one pass (high regression risk).
- Skipping post-update re-fetch validation.

### Fast Decision Rules

- **FAIL** only for deterministic issues:
  - invalid JSON/schema
  - overlapping visuals
  - unreadable font sizes (< 8pt)
  - clear WCAG violation where both text and background are deterministically known
- **WARN** for uncertain or policy-dependent issues:
  - non-token brand colors
  - metadata-limited contrast checks
  - intentional header/navigation overlays

### Quick Patch Priority (order matters)

1. Font family/size normalization
2. Gross spacing and overlap fixes
3. Title hierarchy consistency
4. Slicer and card padding consistency
5. Color token normalization (only safe mappings)

### Output Contract for Fast Iteration Runs

- Workspace/report identifiers
- Operation IDs for `getDefinition`/`updateDefinition`
- Parts retrieved/modified count
- Before/after PASS/WARN/FAIL
- Residual risks requiring explicit sign-off

## Procedure

### Phase 1 — Report Discovery & Audit

#### 1a. Fabric API Path (default for remote report updates)

```
1. Resolve target report itemId and workspaceId.
2. Call:
  POST /v1/workspaces/{workspaceId}/items/{itemId}/getDefinition
3. If response is 202, poll operation endpoint until complete.
4. Decode base64 payload for relevant `definition.parts`.
5. Build a path-indexed in-memory map for deterministic patching.
```

Typical part paths for UI/UX changes:

```
definition/report.json
definition/pages/pages.json
definition/pages/{pageId}/page.json
definition/pages/{pageId}/visuals/{visualId}/visual.json
StaticResources/SharedResources/BaseThemes/{theme}.json
```

#### 1b. Local PBIP Path (preferred when repo source exists)

If the report exists as a PBIP folder in the repo:

```
1. Locate the .Report/ folder (e.g., "Activities Utilization - ROB.Report/")
2. Read definition/report.json → extract theme binding, report-level filters
3. Read definition/pages/pages.json → extract page order
4. For each page in pageOrder:
   a. Read pages/{pageId}/page.json → extract displayName, height, width, displayOption, background
   b. List pages/{pageId}/visuals/*/visual.json → inventory all visuals
   c. For each visual.json → extract position, visualType, objects (font, color, border, spacing)
5. Read StaticResources/SharedResources/BaseThemes/{theme}.json → extract design tokens
```

#### 1c. Fabric API Payload Reference

```python
# Get report definition from Fabric item APIs
import requests

response = requests.post(
  f"https://api.fabric.microsoft.com/v1/workspaces/{workspace_id}/items/{item_id}/getDefinition",
    headers={"Authorization": f"Bearer {token}"}
)
report_definition = response.json()
# Parse the embedded report.json, pages, visuals from the definition payload
```

#### 1d. SemPy Audit Path (for metadata-level scanning)

```python
from sempy_labs.report import ReportWrapper

rpt = ReportWrapper(report=report_name, workspace=workspace_name)
df_pages = rpt.list_pages()              # Page inventory
df_visuals = rpt.list_visuals()          # Visual inventory with types, page assignment
df_objects = rpt.list_visual_objects()   # Visual-level object bindings
df_filters = rpt.list_report_filters()  # Report/page filters

# Run report BPA for design issues
df_bpa = rpt.run_report_bpa()           # Best Practice Analyzer findings
```

### Phase 2 — Consistency Analysis

Scan all visuals and pages against the Design System Standards defined above.

#### 2a. Font Consistency Check

```
For each visual.json:
  Extract objects that contain font properties:
    - "title" → fontFamily, fontSize, fontColor
    - "labels" → fontFamily, fontSize, fontColor
    - "categoryAxis" → fontFamily, fontSize, labelColor
    - "valueAxis" → fontFamily, fontSize, labelColor
    - "legend" → fontFamily, fontSize, fontColor
    - "calloutValue" → fontFamily, fontSize, fontColor
    - "layout" → calloutSize (for cardVisual)
  
  Compare against Design System Standards font table.
  Flag any deviation as:
    WARN: font differs from standard but is readable
    FAIL: font is missing, unreadable font size (<8pt), or non-standard font face
```

#### 2b. Spacing & Alignment Check

```
For each page:
  Collect all visual positions: {x, y, width, height}
  
  Check horizontal alignment:
    - Group visuals by approximate y-position (±5px tolerance)
    - Within each row, check gaps between adjacent visuals (x + width of left vs x of right)
    - Flag inconsistent gaps as WARN
  
  Check vertical alignment:
    - Group visuals by approximate x-position (±5px tolerance)
    - Within each column, check gaps between stacked visuals (y + height of top vs y of bottom)
    - Flag inconsistent gaps as WARN
  
  Check page margins:
    - Min x across all visuals should be ≥ 16px
    - Max (x + width) should be ≤ (page width - 16px)
    - Min y should be ≥ 50px (allow for nav bar)
  
  Check visual overlap:
    - If any two visuals' bounding boxes intersect (excluding z-order stacking by design), flag as FAIL
```

#### 2c. Color Palette Adherence

```
For each visual.json:
  Extract all color values from objects:
    - background.color, border.color, fontColor, fill.color
    - Any hex value in Literal expressions
  
  Compare against the approved Color Palette.
  Flag non-palette colors as WARN (cosmetic) or FAIL (accessibility violation).
  
  Run contrast check:
    - For each text color + background color pair, compute contrast ratio
    - Flag < 4.5:1 for normal text as FAIL (WCAG AA violation)
    - Flag < 3:1 for large text (>18pt or >14pt bold) as FAIL
```

#### 2d. Visual Title Consistency

```
For each visual.json:
  Check if title object exists and is visible (show: true/false)
  If visible:
    - Check fontFamily matches "Segoe UI Semibold"
    - Check fontSize is 10–12pt
    - Check title text alignment is consistent across page
```

### Phase 3 — Generate Change Plan

Produce a structured change plan before applying any modifications.

```
Change Plan Summary:
━━━━━━━━━━━━━━━━━━━
Report: Activities Utilization - ROB
Scope: fix-all
Pages affected: 3 of 5
Visuals affected: 47 of 128
Dry run: false

Changes by category:
  Font fixes:        23 visuals (title font → Segoe UI Semibold 11pt)
  Spacing fixes:     12 visuals (horizontal gap normalized to 12px)
  Color fixes:        8 visuals (non-palette color → nearest palette match)
  Border fixes:       4 visuals (border width → 1px, color → #B3B0AD)

Files to modify:
  definition/pages/dbd57f1048401ec5d518/visuals/0f515100a8935d707bc8/visual.json
  definition/pages/dbd57f1048401ec5d518/visuals/ea52632f85d08e181502/visual.json
  ... (full list)
```

### Phase 4 — Apply Changes

#### 4.0 Definition Round-Trip (API-first write path)

```
1. Start from `definition.parts` returned by getDefinition.
2. Decode targeted part payloads (base64 -> JSON).
3. Apply deterministic patches (fonts, spacing, colors, titles, borders).
4. Re-encode modified JSON payloads to base64.
5. Submit full definition using:
  POST /v1/workspaces/{workspaceId}/items/{itemId}/updateDefinition
6. If update returns 202, poll operation endpoint until success.
```

Notes:
- Keep non-targeted parts unchanged to avoid drift.
- Preserve `definition.pbir` and `.platform` unless explicitly requested.
- If sensitivity label restrictions or unsupported item errors occur, fall back to local PBIP workflow.

#### 4a. Font Standardization (visual.json manipulation)

For each targeted visual.json, update the `objects` section:

```json
// BEFORE: Inconsistent title font
"title": [{
  "properties": {
    "fontFamily": { "expr": { "Literal": { "Value": "'Arial'" } } },
    "fontSize": { "expr": { "Literal": { "Value": "14D" } } }
  }
}]

// AFTER: Standardized title font
"title": [{
  "properties": {
    "fontFamily": { "expr": { "Literal": { "Value": "'Segoe UI Semibold'" } } },
    "fontSize": { "expr": { "Literal": { "Value": "11D" } } },
    "fontColor": { "solid": { "color": { "expr": { "Literal": { "Value": "'#252423'" } } } } }
  }
}]
```

**PBIR Property Value Syntax**:
- Decimal/float values: suffix `D` (e.g., `"11D"` for font size 11pt)
- Integer/long values: suffix `L` (e.g., `"8L"` for 8px padding)
- String values: wrapped in single quotes inside double quotes (e.g., `"'Segoe UI Semibold'"`)
- Boolean values: `"true"` or `"false"` (string)
- Color values: hex in single quotes (e.g., `"'#252423'"`)

#### 4b. Spacing Normalization (visual.json position manipulation)

```json
// Normalize visual positions to align to grid
// Target: 12px gaps between horizontally adjacent visuals

// BEFORE
"position": {
  "x": 247.5,
  "y": 229.77,
  "z": 17000,
  "height": 120,
  "width": 440,
  "tabOrder": 24000
}

// AFTER (snapped to consistent grid)
"position": {
  "x": 248,
  "y": 230,
  "z": 17000,
  "height": 120,
  "width": 440,
  "tabOrder": 24000
}
```

Spacing normalization algorithm:
```
1. Group visuals by row (cluster by y-center ±10px)
2. Sort each row by x-position
3. For each adjacent pair in row:
   gap = next.x - (current.x + current.width)
   if gap != targetGap (12px):
     adjust next.x = current.x + current.width + targetGap
     cascade adjustment to all subsequent visuals in row
4. Group visuals by column (cluster by x-center ±10px)
5. Sort each column by y-position
6. Apply same gap normalization vertically
7. Snap all x, y values to nearest integer (avoid sub-pixel rendering)
```

#### 4c. Color Palette Enforcement

```json
// BEFORE: Non-standard color
"fontColor": {
  "solid": {
    "color": { "expr": { "Literal": { "Value": "'#333333'" } } }
  }
}

// AFTER: Nearest palette match
"fontColor": {
  "solid": {
    "color": { "expr": { "Literal": { "Value": "'#252423'" } } }
  }
}
```

Color mapping strategy:
```
1. Extract all unique colors from all visuals
2. For each non-palette color, find nearest palette match by:
   a. Calculate CIE76 color distance to each palette color
   b. Select minimum distance match
   c. If distance > threshold (30), flag for manual review instead of auto-fix
3. Apply mapped colors to visual.json objects
```

#### 4d. Border & Background Standardization

```json
// Standard visual border
"border": [{
  "properties": {
    "show": { "expr": { "Literal": { "Value": "false" } } }
  }
}],
"background": [{
  "properties": {
    "show": { "expr": { "Literal": { "Value": "true" } } },
    "color": { "solid": { "color": { "expr": { "Literal": { "Value": "'#FFFFFF'" } } } } },
    "transparency": { "expr": { "Literal": { "Value": "0D" } } }
  }
}],
"visualContainerShadow": [{
  "properties": {
    "show": { "expr": { "Literal": { "Value": "false" } } }
  }
}]
```

#### 4e. Theme Deployment (report.json + theme file)

To apply a custom theme across the entire report:

```json
// In report.json → themeCollection
"themeCollection": {
  "baseTheme": {
    "name": "CY24SU10",
    "reportVersionAtImport": {
      "visual": "1.8.95",
      "report": "2.0.95",
      "page": "1.3.95"
    },
    "type": "SharedResources"
  },
  "customTheme": {
    "name": "GPS_Incentive_Custom",
    "reportVersionAtImport": {
      "visual": "1.8.95",
      "report": "2.0.95",
      "page": "1.3.95"
    },
    "type": "RegisteredResources"
  }
}
```

Custom theme file goes in `StaticResources/RegisteredResources/{name}.json` and follows the same schema as base themes.

### Phase 5 — Validation

After applying changes:

```
1. Parse all modified visual.json files to verify valid JSON
2. Verify all $schema references are intact
3. Run font consistency check → expect 0 FAIL / 0 WARN
4. Run spacing check → expect 0 FAIL, minimal WARN
5. Run color palette check → expect 0 FAIL
6. Run contrast ratio check → expect 0 FAIL (WCAG AA)
7. If Fabric API available: upload modified definition and verify render (optional)
```

## Slicer Styling Standards

Slicers require special handling as they have unique formatting objects:

```json
// Standard dropdown slicer styling
"selection": [{
  "properties": {
    "selectAllCheckboxEnabled": { "expr": { "Literal": { "Value": "true" } } },
    "singleSelect": { "expr": { "Literal": { "Value": "false" } } }
  }
}],
"items": [{
  "properties": {
    "fontFamily": { "expr": { "Literal": { "Value": "'Segoe UI'" } } },
    "fontSize": { "expr": { "Literal": { "Value": "10D" } } },
    "fontColor": { "solid": { "color": { "expr": { "Literal": { "Value": "'#252423'" } } } } },
    "background": { "solid": { "color": { "expr": { "Literal": { "Value": "'#FFFFFF'" } } } } }
  }
}],
"header": [{
  "properties": {
    "fontFamily": { "expr": { "Literal": { "Value": "'Segoe UI Semibold'" } } },
    "fontSize": { "expr": { "Literal": { "Value": "10D" } } },
    "fontColor": { "solid": { "color": { "expr": { "Literal": { "Value": "'#252423'" } } } } }
  }
}]
```

## Card Visual Styling Standards

Card/KPI visuals have layout-specific objects:

```json
// Standard card visual layout
"layout": [{
  "properties": {
    "autoGrid": { "expr": { "Literal": { "Value": "false" } } },
    "orientation": { "expr": { "Literal": { "Value": "2D" } } },
    "calloutSize": { "expr": { "Literal": { "Value": "36D" } } },
    "cellPadding": { "expr": { "Literal": { "Value": "10L" } } },
    "style": { "expr": { "Literal": { "Value": "'Cards'" } } },
    "maxTiles": { "expr": { "Literal": { "Value": "2L" } } }
  }
}],
"shapeCustomRectangle": [{
  "properties": {
    "tileShape": { "expr": { "Literal": { "Value": "'rectangleRoundedByPixel'" } } },
    "rectangleRoundedCurve": { "expr": { "Literal": { "Value": "8L" } } }
  }
}],
"accentBar": [{
  "properties": {
    "show": { "expr": { "Literal": { "Value": "false" } } }
  },
  "selector": { "id": "default" }
}]
```

## Table / Matrix Visual Styling Standards

```json
// Standard table formatting
"grid": [{
  "properties": {
    "gridVertical": { "expr": { "Literal": { "Value": "false" } } },
    "gridHorizontal": { "expr": { "Literal": { "Value": "true" } } },
    "gridHorizontalColor": { "solid": { "color": { "expr": { "Literal": { "Value": "'#F3F2F1'" } } } } },
    "gridHorizontalWeight": { "expr": { "Literal": { "Value": "1D" } } },
    "rowPadding": { "expr": { "Literal": { "Value": "4D" } } },
    "textSize": { "expr": { "Literal": { "Value": "9D" } } }
  }
}],
"columnHeaders": [{
  "properties": {
    "fontFamily": { "expr": { "Literal": { "Value": "'Segoe UI Semibold'" } } },
    "fontSize": { "expr": { "Literal": { "Value": "9D" } } },
    "fontColor": { "solid": { "color": { "expr": { "Literal": { "Value": "'#252423'" } } } } },
    "backColor": { "solid": { "color": { "expr": { "Literal": { "Value": "'#F3F2F1'" } } } } }
  }
}],
"values": [{
  "properties": {
    "fontFamily": { "expr": { "Literal": { "Value": "'Segoe UI'" } } },
    "fontSize": { "expr": { "Literal": { "Value": "9D" } } },
    "fontColor": { "solid": { "color": { "expr": { "Literal": { "Value": "'#252423'" } } } } }
  }
}]
```

## Batch Processing Pattern

For applying UI/UX changes across multiple reports at scale:

```
1. Enumerate all .Report/ folders in the PBIP repo
2. For each report:
   a. Run Phase 1 (audit) → collect findings
   b. Run Phase 2 (consistency analysis) → generate deviation report
3. Aggregate findings across reports into a single dashboard
4. Prioritize by severity: FAIL (accessibility) → FAIL (consistency) → WARN
5. For each report (starting with highest-priority):
   a. Generate change plan (Phase 3)
   b. Apply changes (Phase 4) — only in DEV/UAT
   c. Validate (Phase 5)
   d. Commit to Git branch
6. Create PR with change summary for review
```

## Safety Notes

- **Read-only in PROD**: Audit and analysis only. No file modifications.
- **Write in DEV/UAT only**: All visual.json, page.json, theme modifications execute only against DEV/UAT environments.
- **Dry run default**: When invoked without explicit `dry_run: false`, produce a change plan only.
- **API boundary**: Use Fabric item definition APIs for granular page/visual UI changes.
- **Power BI API boundary**: Do not use Power BI REST API as the primary surface for per-visual/page styling updates.
- **JSON validation**: After every modification, validate the file parses as valid JSON and `$schema` reference is intact.
- **Git safety**: All changes committed to a feature branch, never directly to main.
- **Backup**: Before first modification in a session, snapshot the current state of affected files.

## Outputs

- **Audit report**: Table of all visual/page findings with severity (PASS/WARN/FAIL)
- **Change plan**: Detailed list of file paths, property paths, old values, new values
- **Modified files**: Updated visual.json / page.json / report.json / theme JSON files
- **Validation summary**: Post-change compliance check results
- **Accessibility report**: WCAG AA contrast ratio results for all text/background pairs
- **Next step**: Recommendation (review PR / promote to UAT / run visual regression test)
