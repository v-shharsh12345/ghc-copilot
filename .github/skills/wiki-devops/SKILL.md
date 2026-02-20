---
name: wiki-devops
description: Generate comprehensive, business-context-rich wiki documentation for Power BI reports by combining semantic model analysis, M365 business context, per-visual Playwright screenshots, and ADO wiki publishing.
intent-triggers:
  - wiki
  - document
  - documentation
  - create wiki
  - update wiki
  - report wiki
  - push wiki
  - screenshots
  - business context wiki
min-confidence: 0.6
engine-preference: powerbi-remote + playwright + workiq
---

# Wiki DevOps Skill

## Objective

Produce a publish-ready wiki page for any Power BI report that a non-technical business user can read to fully understand what the report shows, how to use it, and what the numbers mean.

## Intent Scope

This skill activates when the user wants to:
- Create or update wiki documentation for a Power BI report
- Capture per-visual screenshots of report pages
- Enrich existing wiki with business context from M365
- Push wiki content to an Azure DevOps wiki repository

## Dependencies

| Dependency | Purpose |
|-----------|---------|
| `powerbi-remote` MCP | Report metadata, semantic model schema, DAX queries |
| `playwright` MCP | Browser automation for screenshots |
| `workiq` MCP (via chief-of-staff) | M365 business context (meetings, emails, chats) |
| `git` CLI | ADO wiki publishing |

## Procedure

### Phase 1: Discovery

1. Use `DiscoverArtifacts` to find the report and semantic model by name.
2. Use `GetReportMetadata` with the PROD report ID to extract pages, visuals, and bindings.
3. Use `GetSemanticModelSchema` to extract tables, columns, measures, and relationships.

### Phase 2: Context Enrichment

4. Delegate to `chief-of-staff` subagent to gather:
   - Business program overview
   - Domain concepts and terminology
   - Recent discussions about the report (last 4 weeks)
   - Office Hours sessions and stakeholder-specific nuances
   - Pending changes and known limitations

### Phase 3: Visual Capture

5. Navigate Playwright to the PROD report URL.
6. Authenticate if needed (click Microsoft account).
7. For each report page:
   a. Hide sidebar and page pane via JS evaluation.
   b. Map all visuals by querying `[role="group"]` elements.
   c. For each visual, scroll into view and take a clipped screenshot.
8. Save screenshots with the naming convention: `<prefix>-<page><number>-<name>.png`

### Phase 4: Assembly

9. Build the wiki markdown following the template structure:
   - Business Context (from Phase 2)
   - Report Overview
   - Per-page, per-visual documentation with screenshots
   - Measures Dictionary
   - Data Model
   - Filters Reference
   - Glossary

### Phase 5: Publishing

10. Copy screenshots to wiki `.attachments/` folder.
11. Create wiki page `.md` file.
12. Update `.order` file.
13. Git add, commit, and push (with user confirmation).

## Playwright Screenshot Protocol

### Visual Position Mapping

```javascript
// Query all visual groups inside the report container
var report = document.querySelector('[aria-label="Power BI Report"]');
var groups = report.querySelectorAll('[role="group"]');
// Filter: width > 250, height > 100, exclude "Plot area" label
// Record: aria-label, x, y, width, height
```

### Scrollable Container Discovery

```javascript
// Find the scrollable parent of the report
var parent = report.parentElement;
while (parent && parent.scrollHeight <= parent.clientHeight) {
  parent = parent.parentElement;
}
// Scroll: parent.scrollTop = <target>
```

### Clipped Screenshot via run_code

```javascript
async (page) => {
  var path = '<output_directory>';
  await page.screenshot({
    path: path + '<filename>.png',
    type: 'png',
    clip: { x: <x-5>, y: <y-5>, width: <w+10>, height: <h+10> }
  });
  return 'done';
}
```

### Page Tab Navigation

```javascript
// Click a specific page tab by name
var tabs = document.querySelectorAll('[role="tab"]');
for (var i = 0; i < tabs.length; i++) {
  if (tabs[i].textContent?.trim() === '<Page Name>') {
    tabs[i].click();
    break;
  }
}
```

### UI Cleanup (Hide Chrome)

```javascript
// Hide sidebar
var sidebar = document.querySelector('nav[aria-label="Sidebar"]');
if (sidebar) { var p = sidebar.closest('div'); if (p) p.style.display = 'none'; }
// Hide page pane
var pagesPane = document.querySelector('[aria-label="Report pages"]');
if (pagesPane) pagesPane.style.display = 'none';
```

## Wiki Template Structure

```markdown
# [Report Name] Wiki

> **Report Name:** ...
> **Workspace:** ...
> **Last Updated:** ...
> **Data Refresh:** ...
> **RLS:** ...

## Table of Contents

## Business Context
### What is this report about?
### [Domain Model]
### [Process Flow]

## Report Overview

## Page N: [Title]
### Visual N: [Title]
![Alt](/.attachments/<file>.png)
[Bindings table, business description, how-to-read]

## Measures and Calculations Dictionary
## Data Model: Tables and Relationships
## Filters and Slicers Reference
## Glossary of Business Terms
```

## Chief of Staff Prompt Template

When delegating business context research:

```
## Objective
Gather business context for the [REPORT_NAME] report wiki documentation.

## Context
Report: [REPORT_NAME]
Workspace: [WORKSPACE]
Report programs/topics: [GPS_INCENTIVE_NAMES, SOLUTION_AREAS]

## Questions to Research
1. What is the business program this report supports? Explain for a non-technical audience.
2. Search recent M365 activity (last 4 weeks) discussing this report:
   - New launches, page additions, enhancement deployments
   - Business logic decisions (attribution rules, rollup approaches)
   - Stakeholder-called nuances (multi-role partners, geo attribution, RLS changes)
3. Find Office Hours sessions where report enhancements were discussed.
4. Identify pending changes, backlog items, or known limitations.

## Expected Output
- Program overview (2-3 paragraphs, business-friendly)
- Key domain concepts with definitions
- Recent enhancements with source attribution (meeting, date, participants)
- Business nuances for report users
- Glossary of domain-specific terms
```

## Fabric DevOps Prompt Template (Optional)

When deeper semantic model or lineage analysis is needed:

```
## Objective
Analyze the data lineage and refresh patterns for the [SEMANTIC_MODEL] semantic model.

## Context
Semantic Model: [NAME] ([ID])
Workspace: [WORKSPACE]

## Skill Hint
Activate fabric-devops-analyze-lineage skill.

## Expected Output
- Upstream data sources (lakehouse tables, dataflows)
- Table-to-table mappings
- Refresh schedule and last refresh timestamps
- Any dependency risks or broken references
```

## Guardrails

- **Screenshots from PROD only** — PROD has the latest published version users see.
- **Never fabricate M365 context** — All business narrative must be grounded in WorkIQ results.
- **Confirm before git push** — Wiki repos are shared; always ask before pushing.
- **No raw DAX** — Measure calculations in business English only.
- **Clean markdown** — No empty table cells, no special chars in headings, test ToC anchors.
