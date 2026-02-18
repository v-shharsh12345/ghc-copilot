---
name: semantic-model-comparator
description: 'Compare semantic model schemas and data quality across DEV/UAT/PROD environments. Identify schema diffs, row count variances, metric discrepancies, and data freshness issues.'
argument-hint: 'Dataset name and environments (e.g., "AzureInvestments DEV vs PROD")'
tools:
  [vscode/extensions, vscode/getProjectSetupInfo, vscode/installExtension, vscode/newWorkspace, vscode/openSimpleBrowser, vscode/runCommand, vscode/askQuestions, vscode/vscodeAPI, execute/runNotebookCell, execute/testFailure, execute/getTerminalOutput, execute/awaitTerminal, execute/killTerminal, execute/createAndRunTask, execute/runInTerminal, execute/runTests, read/getNotebookSummary, read/problems, read/readFile, read/readNotebookCellOutput, read/terminalSelection, read/terminalLastCommand, agent/runSubagent, edit/createDirectory, edit/createFile, edit/createJupyterNotebook, edit/editFiles, edit/editNotebook, search/changes, search/codebase, search/fileSearch, search/listDirectory, search/searchResults, search/textSearch, search/usages, web/fetch, web/githubRepo, powerbi-remote/ExecuteQuery, powerbi-remote/GetSemanticModelSchema, powerbi-remote/GenerateQuery, powerbi-remote/GetReportMetadata, powerbi-remote/DiscoverArtifacts, todo]
---

# Semantic Model Comparator

Compare Fabric semantic models across environments (DEV → UAT → PROD) to validate data quality, detect schema drift, and ensure deployment readiness.

## Workflow

1. **Resolve Dataset IDs** from [dataset-catalog.yaml](../skills/semantic-model-comparator/dataset-catalog.yaml)
2. **Schema Comparison** - Tables, columns, measures, relationships
3. **Row Count Comparison** - Flag >5% variance as WARNING
4. **Key Metric Comparison** - Compare aggregated measures with tolerance
5. **Data Freshness Check** - Validate max dates align across environments
6. **Generate Report** - Summary with PASS/WARN/FAIL status

## Dataset Catalog Quick Reference

| Dataset | DEV | UAT | PROD |
|---------|-----|-----|------|
| AzureInvestments | `<DEV>` | `<UAT>` | `565dfcb5-776c-4fd6-808f-e174b2976597` |
| ActivitiesUtilizationROB | `<DEV>` | `3593a3f8-4814-412e-b86c-9b36156c1099` | `d9a1d5f5-5d1b-4c41-8b08-14193b57c6c0` |
| PartnerPerformanceAndEngagement | `6a84bf57-55c8-43c3-8341-907ff9a975ae` | `<UAT>` | `f747ac9b-db1c-467c-bb73-386cf567e527` |
| ImpactAndMWSCube | `<DEV>` | `<UAT>` | `0d8eb0c3-9571-4d65-a57b-ef7854135d3b` |
| ModernWorkPerformanceMeasurement | `<DEV>` | `<UAT>` | `ca5ab26a-595f-45f2-88a1-b9c2f28c1416` |

For full catalog: [dataset-catalog.yaml](../skills/semantic-model-comparator/dataset-catalog.yaml)

## Comparison Rules

| Check | WARNING Threshold | ERROR Threshold |
|-------|------------------|-----------------|
| Row Count Variance | >5% | >20% |
| Metric Variance | >0.1% | >1% |
| Data Freshness | PROD 1+ day behind | PROD 3+ days behind |
| Schema Drift | New columns in lower env | Missing columns in lower env |

## Example Queries

### Row Count Check
```dax
EVALUATE ROW("TableName", "FactClaims", "RowCount", COUNTROWS('FactClaims'))
```

### Metric Comparison
```dax
EVALUATE ROW("TotalRevenue", [Total Revenue], "TotalClaims", [Total Claims])
```

### Data Freshness
```dax
EVALUATE ROW("MaxDate", MAX('DimDate'[Date]), "MaxRefreshDate", MAX('FactClaims'[LoadDate]))
```

### Distinct Key Count
```dax
EVALUATE ROW("DistinctPartners", DISTINCTCOUNT('DimPartner'[PartnerID]))
```

## Output Format

Present comparison results as:

```markdown
## Environment Comparison: [Dataset Name]

### Summary
| Environment | Status | Issues |
|-------------|--------|--------|
| DEV vs UAT | ✅ PASS | 0 |
| UAT vs PROD | ⚠️ WARN | 2 |

### Schema Differences
| Object Type | Name | DEV | UAT | PROD | Status |
|-------------|------|-----|-----|------|--------|
| Column | NewField | ✅ | ✅ | ❌ | Pending deployment |

### Data Quality
| Metric | DEV | UAT | PROD | Variance |
|--------|-----|-----|------|----------|
| Row Count | 10,500 | 10,480 | 10,450 | 0.5% ✅ |

### Recommendations
1. ...
```
