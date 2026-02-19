# Analyze Lineage Module

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-13 | 1.1 | Added semantic-link-labs metadata generation fast path for report/semantic model parsing and broken-object detection. |
| 2026-02-13 | 1.0 | Initial lineage analysis module — column, table, and report-level lineage tracing. |

## Goal

Produce end-to-end data lineage from lakehouse source tables through semantic model tables/columns to Power BI report visuals. Output a directed lineage graph at three granularities: **table-level**, **column-level**, and **report-level**.

## Expected Output Format

```
Lakehouse.Schema.SourceTable
  → Lakehouse.Schema.DerivedTable
    → SemanticModel.TableName
      → Report.PageName.VisualTitle
```

Column-level:

```
Lakehouse.Schema.Table.Column
  → SemanticModel.Table[Column]
    → Report.Page.Visual (field reference)
```

## Inputs

- **Scope anchor**: Report name (primary), or semantic model name, or lakehouse name
- **Workspace**: Name or ID (defaults to workspace-catalog.yaml entry for the environment)
- **Environment**: DEV / UAT / PROD (read-only in all environments for this module)
- **Depth**: `table` (default), `column`, or `full` (both + report visuals)

## Preferred Route

- Primary: `fabric-sempy` (`sempy_labs` / semantic-link-labs) — lowest call count, richest metadata, DataFrame output
- Secondary: `fabric-api` — workspace item inventory, item definitions
- Operational fallback: `fabric-cli` — scripted extraction when SemPy unavailable
- Guidance fallback: `context7-guidance` — via `io.github.upstash/context7` for unfamiliar patterns

## Semantic-Link-Labs Fast Path (Metadata Heavy)

Use this path when the request emphasizes report parsing, semantic model metadata generation, usage analysis, or broken reference detection.

Primary APIs:

- Report metadata: `ReportWrapper(...).list_pages()`, `list_visuals()`, `list_visual_objects()`, `list_report_filters()`, `list_semantic_model_objects(extended=True)`
- Cross-report usage: `labs.list_report_semantic_model_objects(...)`, `labs.list_semantic_model_object_report_usage(..., include_dependencies=True, extended=True)`
- Semantic model metadata: `connect_semantic_model(..., readonly=True)` + `all_columns()`, `all_measures()`, `all_hierarchies()`, partition/source extraction
- Dependency enrichment: `labs.measure_dependency_tree(...)`, `labs.get_dax_query_dependencies(...)`
- Quality overlay: `rep.run_report_bpa(...)`, `labs.run_model_bpa(..., extended=True)`

Metadata output artifacts (recommended):

- `report_pages`, `report_visuals`, `report_filters`, `report_visual_bindings`
- `semantic_model_tables`, `semantic_model_columns`, `semantic_model_measures`, `semantic_model_relationships`, `semantic_model_partitions`
- `lineage_edges_table`, `lineage_edges_column`, `broken_objects`, `usage_frequency`, `bpa_findings`

## Why SemPy-Primary is Optimal

| Criteria | SemPy | Admin Scanner API | Direct REST API |
| --- | --- | --- | --- |
| API calls for full lineage | 5-8 | 3 + polling | 10-15+ |
| Context/payload size | Low (DataFrames) | Very High (full tenant) | High (many payloads) |
| Column-level metadata | Yes (TOM) | Yes (but bulky) | Partial |
| Partition source expressions | Yes (direct TOM) | Yes (in scan blob) | No (need definition parse) |
| Report-visual-to-model mapping | Yes (`list_report_semantic_model_objects`) | Yes (in scan blob) | Manual definition parse |
| Required permissions | Workspace member | Tenant Admin | Workspace member |
| Runtime requirement | Python + sempy_labs | Any HTTP client | Any HTTP client |

## Procedure

### Phase 1 — Scope Resolution

1. Identify the scope anchor type (report / semantic model / lakehouse).
2. Resolve workspace ID from `config/workspace-catalog.yaml` or user input.
3. If scope is a **report**: discover bound semantic model → discover bound lakehouse.
4. If scope is a **semantic model**: discover bound lakehouse from partition expressions.
5. If scope is a **lakehouse**: discover dependent semantic models via workspace scan.

### Phase 2 — Report Layer (if scope includes report)

Collect report-to-semantic-model field mappings.

```python
import sempy_labs as labs

# List all semantic model objects used by reports bound to this model
df_report_objects = labs.list_report_semantic_model_objects(
    dataset=semantic_model_name,
    workspace=workspace_name,
    extended=True
)
# Columns returned: Report Name, Page, Visual, Table, Column/Measure, Valid Semantic Model Object
```

For deeper visual-level detail:

```python
from sempy_labs.report import ReportWrapper

rpt = ReportWrapper(report=report_name, workspace=workspace_name)
df_pages = rpt.list_pages()            # Report pages
df_visuals = rpt.list_visuals()        # All visuals with page, type, fields
df_visual_objects = rpt.list_visual_objects()  # Visual-level model object bindings
df_filters = rpt.list_report_filters() # Report-level filters
df_measures = rpt.list_report_level_measures()  # Report-level measures
df_semantic_objects = rpt.list_semantic_model_objects(extended=True)  # Includes validity flags
```

### Phase 3 — Semantic Model Layer

Extract tables, columns, measures, and partition source expressions.

```python
from sempy_labs.tom import connect_semantic_model

with connect_semantic_model(dataset=semantic_model_name, workspace=workspace_name, readonly=True) as tom:

    # --- Table + Column inventory ---
    model_inventory = []
    for t in tom.model.Tables:
        for c in t.Columns:
            model_inventory.append({
                "Table": t.Name,
                "Column": c.Name,
                "DataType": str(c.DataType),
                "Type": str(c.Type),  # Data / Calculated / RowNumber
            })

    # --- Partition source expressions (reveals lakehouse binding) ---
    partition_map = []
    for p in tom.all_partitions():
        partition_map.append({
            "Table": p.Table.Name,
            "Partition": p.Name,
            "SourceType": str(p.SourceType),          # M / Entity / Calculated
            "Expression": getattr(p, 'Expression', None) or getattr(p, 'EntityName', None),
        })
        # For Direct Lake: EntityName = lakehouse table name
        # For Import/DirectQuery: Expression = M query referencing lakehouse
```

### Phase 4 — Lakehouse Layer

Get lakehouse tables and columns for schema mapping.

```python
import sempy_labs.lakehouse as lake

# Table inventory
df_lh_tables = lake.get_lakehouse_tables(
    lakehouse=lakehouse_name,
    workspace=workspace_name,
    extended=True   # includes row counts, Direct Lake risk flags
)

# Column inventory
df_lh_columns = lake.get_lakehouse_columns(
    lakehouse=lakehouse_name,
    workspace=workspace_name
)
```

For schema-enabled lakehouses (SQL endpoint):

```python
import sempy_labs as labs

with labs.ConnectLakehouse(lakehouse=lakehouse_name, workspace=workspace_name) as sql:
    df_tables = sql.query("SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'")
    df_columns = sql.query("SELECT * FROM INFORMATION_SCHEMA.COLUMNS ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION")
```

### Phase 5 — Lineage Assembly

#### 5a. Lakehouse → Semantic Model (Table Level)

Match partition source expressions to lakehouse tables:

- **Direct Lake models**: `EntityName` on partition = lakehouse table name (exact match).
- **Import/DirectQuery models**: Parse M expression for `Lakehouse.Contents` navigation to extract `lakehouseId`, table name.

```
For each partition P in semantic model:
  If P.SourceType == "Entity":
    Link: Lakehouse.{schema}.{P.EntityName} → SemanticModel.{P.Table.Name}
  If P.SourceType == "M":
    Parse P.Expression for table reference
    Link: Lakehouse.{schema}.{parsed_table} → SemanticModel.{P.Table.Name}
```

#### 5b. Lakehouse → Semantic Model (Column Level)

Match semantic model columns to lakehouse columns by name within linked tables:

```
For each linked pair (LH_Table → SM_Table):
  For each column C in SM_Table where C.Type == "Data":
    If C.Name exists in LH_Table columns:
      Link: Lakehouse.{schema}.{LH_Table}.{C.Name} → SemanticModel.{SM_Table}[{C.Name}]
```

#### 5c. Semantic Model → Report (Column/Measure Level)

Use the report objects DataFrame from Phase 2:

```
For each row in df_report_objects:
  Link: SemanticModel.{Table}[{Column|Measure}] → Report.{Page}.{Visual}
```

#### 5d. Lakehouse → Lakehouse (Intra-Lakehouse Dependencies)

If SQL endpoint is available, query `INFORMATION_SCHEMA.VIEW_COLUMN_USAGE` to detect view-to-table dependencies within the lakehouse.

### Phase 6 — Output Formatting

When depth is `full`, always include both lineage graph output and normalized metadata tables from the Semantic-Link-Labs fast path.

#### Table-Level Lineage Graph

```
SalesLakehouse.dbo.Fact_Orders_Raw
  → SalesLakehouse.dbo.Fact_Orders_Processed
    → SalesModel.Fact Orders
      → Sales Dashboard (Page: Overview, Visual: Revenue KPI Card)
      → Sales Dashboard (Page: Detail, Visual: Orders Table)
```

#### Column-Level Lineage Graph

```
SalesLakehouse.dbo.Fact_Orders_Raw.OrderAmount
  → SalesModel.Fact Orders[OrderAmount]
    → Sales Dashboard.Overview.Revenue KPI Card (field)
    → Sales Dashboard.Detail.Orders Table (field)
```

#### Structured Output (DataFrame/JSON)

| Source Layer | Source Object | Target Layer | Target Object | Grain |
| --- | --- | --- | --- | --- |
| Lakehouse | SalesLakehouse.dbo.Fact_Raw | SemanticModel | SalesModel.Fact Orders | Table |
| SemanticModel | SalesModel.Fact Orders[Amount] | Report | Dashboard.Overview.KPI Card | Column |

## Fallback: Fabric REST API Route

When SemPy is unavailable, use these REST endpoints in order:

### Step 1 — Workspace Inventory

```
GET https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items
```

Filter by type: `SemanticModel`, `Report`, `Lakehouse`.

### Step 2 — Semantic Model Definition

```
GET https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/semanticModels/{modelId}/definition
```

Parse the TMDL/TMSL definition for tables, columns, partition expressions.

### Step 3 — Report Definition

```
GET https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/reports/{reportId}/definition
```

Parse `report.json` for pages, visuals, and field references.

### Step 4 — Lakehouse Tables

```
GET https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/lakehouses/{lakehouseId}/tables
```

### Step 5 — Assemble

Apply the same linkage logic as Phase 5.

## Fallback: Admin Scanner API Route

For tenant-wide lineage when scope is broad or cross-workspace:

```
POST https://api.fabric.microsoft.com/v1/admin/workspaces/getInfo
  ?lineage=true&datasourceDetails=true&datasetSchema=true&datasetExpressions=true
Body: { "workspaces": ["{workspaceId}"] }

→ Poll: GET /v1/admin/workspaces/scanStatus/{scanId}
→ Result: GET /v1/admin/workspaces/scanResult/{scanId}
```

The scan result contains datasets with tables, columns, expressions, measures, report pages, and datasource bindings — everything needed for lineage in a single payload. Use only when SemPy and direct API are unavailable, due to:

- Admin-level permissions required
- Large payload size increases context cost
- Rate limited to 30 scans per hour

## Safety Notes

- This module is **read-only** in all environments (DEV/UAT/PROD).
- No write operations are performed.
- All connections use `readonly=True`.
- Safe to run against PROD workspaces.

## Outputs

- **Lineage graph** (table-level and/or column-level, depending on depth)
- **Structured DataFrame/JSON** with source → target mappings
- **Orphan detection**: columns in semantic model not found in lakehouse, or visuals referencing missing model objects
- **Coverage summary**: PASS (full lineage traced) / WARN (gaps detected) / FAIL (unable to trace)
