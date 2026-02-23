# Develop Module

## Goal

Create/update Fabric items in non-PROD environments with dependency-safe defaults.

## Inputs

- Environment (`DEV` or `UAT`)
- Workspace ID or workspace name
- Item type (`Notebook`, `DataPipeline`, `Lakehouse`, `SemanticModel`, `Report`)
- Source path and deployment intent

## Preferred Route

- Primary: `fabric-api`
- Secondary: `fabric-cli`
- Guidance fallback: `context7-guidance`

## General Procedure

1. Resolve environment and workspace from `config/workspace-catalog.yaml`.
2. Block operation if target is PROD and request is a write.
3. Validate dependencies using the **item-specific prerequisites checklist** below.
4. Apply create/update operation using the **item-specific deployment protocol** below.
5. Run smoke test where applicable.
6. Return summary with item IDs and status.

---

## Notebook Deployment Protocol

Notebook deployment has specific requirements that differ from other item types. Follow this protocol exactly.

### Step 1: Verify Prerequisites

Before creating or uploading any notebook, verify ALL of the following:

| Prerequisite | How to Verify | Failure Action |
|---|---|---|
| **Target workspace exists** | `onelake_workspace_list` — confirm workspace ID from catalog | Stop — cannot deploy without workspace |
| **Default lakehouse exists** | `onelake_item_list` — check for lakehouse by name/ID from catalog | Create lakehouse first, or stop and report |
| **Lakehouse attachment config** | Notebook must reference the correct lakehouse ID in its metadata | Inject lakehouse ID into notebook definition |
| **Spark environment available** | Check if workspace has a default Spark environment or custom environment | Use workspace default; note if custom env is needed |
| **Library dependencies** | Check notebook imports — are required packages available in the environment? | List missing packages; recommend `%pip install` cell or environment config |
| **Resource/capacity** | Workspace must have active Fabric capacity assigned | Stop — report capacity issue |

### Step 2: Determine Create vs Update

```
1. List existing items: onelake_item_list(workspaceId, type="Notebook")
2. Search for notebook by name in the response
3. If found → UPDATE path (Step 3b)
4. If not found → CREATE path (Step 3a)
```

### Step 3a: Create New Notebook

```
Tool: onelake_item_create
Parameters:
  workspaceId: [from workspace-catalog.yaml]
  displayName: [notebook name]
  type: "Notebook"
  definition:  # see "Notebook Definition Format" below
```

After creation, upload the notebook content:

```
Tool: onelake_upload_file
Parameters:
  workspaceId: [workspace ID]
  itemPath: [notebook item path — see path format below]
  content: [notebook .py or .ipynb content]
```

### Step 3b: Update Existing Notebook

For updating an existing notebook, you CANNOT use `onelake_item_create` again — it will fail with a conflict.

**Update strategy:**
1. Get the existing notebook's item ID from `onelake_item_list`
2. Upload the updated content payload to the notebook's OneLake path:
   ```
   Tool: onelake_upload_file
   Parameters:
     workspaceId: [workspace ID]
     itemPath: "<notebook-name>.Notebook/notebook-content.py"
     content: [updated .py content]
   ```
3. If the upload path fails (common issue), fall back to the **guidance fallback** (Step 3c) — there is no direct delete-and-reupload tool available for notebook items.

### Step 3c: Fallback — When Upload Fails

The `onelake_upload_file` tool can fail for notebooks because notebook items have a specific internal structure. When this happens:

1. **Do NOT retry the same call.** The tool doesn't support notebook-format payloads directly in all cases.
2. **Fall back to Context7 guidance:**
   ```
   Tool: resolve-library-id → "microsoft-fabric"
   Tool: get-library-docs → topic: "notebook item definition API"
   ```
3. **Alternative: Guide the user** to use Fabric Git integration or the Fabric UI for notebook upload, and offer to validate the notebook content structure instead.
4. **Report clearly** what failed and why, instead of retrying silently.

### Notebook Path Format

Notebook content lives at specific OneLake paths:

| Content Type | OneLake Path |
|---|---|
| Python notebook | `<NotebookName>.Notebook/notebook-content.py` |
| Jupyter notebook | `<NotebookName>.Notebook/notebook-content.ipynb` |
| Notebook metadata | `<NotebookName>.Notebook/.platform` |
| Lakehouse attachment | Referenced in `.platform` metadata via `lakehouse` property |

### Notebook Definition Format

When creating via `onelake_item_create`, the notebook definition MUST include lakehouse attachment:

```json
{
  "displayName": "my_notebook",
  "type": "Notebook",
  "definition": {
    "parts": [
      {
        "path": "notebook-content.py",
        "payload": "<base64-encoded notebook content>",
        "payloadType": "InlineBase64"
      }
    ]
  }
}
```

**Important:** After creation, the lakehouse attachment must be configured separately via the `.platform` metadata or through the notebook's default lakehouse setting.

### Notebook Smoke Test

After successful deployment, verify the notebook is functional:

1. Confirm the notebook appears in `onelake_item_list` with correct name
2. Confirm the lakehouse attachment is set (check `.platform` metadata if accessible)
3. **Do NOT attempt to run the notebook as a validation step** unless explicitly asked — notebook execution requires an active Spark session and can fail for infrastructure reasons unrelated to the deployment
4. Instead, report: notebook deployed, lakehouse attached, ready for manual execution or pipeline trigger

---

## Data Access Decision Matrix

The agent has two data access paths: **MSSQL tools** (SQL analytics endpoint) and **OneLake tools** (direct lakehouse). Use the right one for the right job.

### When to Use SQL Analytics Endpoint (MSSQL Tools)

| Use Case | Why SQL Endpoint |
|---|---|
| **Query lakehouse tables** (SELECT) | SQL endpoint provides read-only T-SQL access to Delta tables — fastest path for data queries |
| **Schema inspection** (`mssql_show_schema`, `mssql_list_tables`) | SQL endpoint exposes table/view metadata directly |
| **Row counts and data validation** | `SELECT COUNT(*)` is faster than scanning OneLake files |
| **Compare data across tables** | JOIN, UNION, aggregations available via T-SQL |
| **Semantic model testing** (via Power BI Remote) | Semantic models sit on top of the SQL endpoint |
| **Read-only diagnostics** | Checking if tables exist, have data, schema matches expectations |

**Connection pattern:**
```
1. mssql_connect → SQL endpoint for the target lakehouse
   - Server: <lakehouse-sql-endpoint-url>
   - Database: <lakehouse-name>
   - Authentication: Azure AD (default)
2. mssql_run_query → SELECT/diagnostic queries
```

**SQL endpoint URL pattern:** `<workspace-name>-<lakehouse-name>.msit.datawarehouse.fabric.microsoft.com` (resolve from workspace catalog or discover via `onelake_item_list`).

### When to Use OneLake Direct (Fabric MCP Tools)

| Use Case | Why OneLake Direct |
|---|---|
| **Create/delete items** (notebooks, pipelines, lakehouses) | SQL endpoint is read-only — can't create items |
| **Upload/download files** to lakehouse Files section | OneLake is the file system layer |
| **List workspace contents** | `onelake_item_list` for inventory |
| **Notebook deployment** | Item creation goes through OneLake/Fabric API |
| **File management** (CSV uploads, config files, static data) | OneLake Files section, not Tables |
| **Directory operations** (create/delete folders) | OneLake file system operations |

### When to Use Power BI Remote Tools

| Use Case | Why Power BI Remote |
|---|---|
| **Query semantic models** (DAX) | `ExecuteQuery` runs DAX against published models |
| **Inspect semantic model schema** | `GetSemanticModelSchema` for tables/columns/measures |
| **Report metadata** | `GetReportMetadata` for visuals, pages, filters |
| **Discover artifacts** | `DiscoverArtifacts` for workspace-level Power BI inventory |

### Decision Flowchart

```
Is the operation a WRITE (create/update/delete/upload)?
  YES → Use OneLake tools (Fabric MCP)
  NO → Is the target a semantic model or report?
    YES → Use Power BI Remote tools
    NO → Is the target lakehouse table DATA?
      YES → Use SQL endpoint (MSSQL tools) — fastest for reads
      NO → Use OneLake tools for file/item operations
```

### Common Mistakes to Avoid

| Mistake | Correction |
|---|---|
| Using `onelake_file_list` to check if a table has data | Use `mssql_run_query` → `SELECT COUNT(*) FROM table` instead |
| Using SQL endpoint to create a notebook | SQL endpoint is read-only — use `onelake_item_create` |
| Querying the SQL endpoint for file-section contents | Files section isn't exposed via SQL — use `onelake_file_list` |
| Running `mssql_connect` without knowing the endpoint URL | Resolve workspace first, then discover the SQL endpoint from item metadata |

---

## Notebook Prerequisites Checklist

Before any notebook operation (create, update, execute, or validate), verify this checklist:

### Infrastructure Prerequisites

| # | Prerequisite | Check Method | Required For |
|---|---|---|---|
| 1 | **Fabric capacity active** | Workspace responds to API calls | All operations |
| 2 | **Workspace exists and is accessible** | `onelake_workspace_list` returns workspace | All operations |
| 3 | **Spark environment available** | Workspace has default or custom Spark environment | Execution only |
| 4 | **Starter pool or custom pool** | Fabric uses starter pools by default; custom pools need explicit config | Execution only |

### Data Prerequisites

| # | Prerequisite | Check Method | Required For |
|---|---|---|---|
| 5 | **Default lakehouse attached** | Notebook metadata references lakehouse ID from catalog | Create, Execute |
| 6 | **Source tables exist** | `mssql_list_tables` on the lakehouse SQL endpoint | Execute |
| 7 | **Source tables have data** | `mssql_run_query` → `SELECT COUNT(*)` | Execute, Validate |
| 8 | **Target tables/paths writable** | OneLake file operations succeed on target path | Execute |

### Code Prerequisites

| # | Prerequisite | Check Method | Required For |
|---|---|---|---|
| 9 | **Library dependencies** | Parse notebook imports — check for non-standard packages | Execute |
| 10 | **Configuration parameters** | Check if notebook expects parameters (widgets, `dbutils.widgets`) | Execute |
| 11 | **Secrets/credentials** | Check if notebook references Key Vault or environment variables | Execute |
| 12 | **Notebook language** | Confirm PySpark/Python/Scala/R — matches target environment | Create, Execute |

### Pre-Deployment Validation

Before deploying a notebook, run this quick validation:

```
1. Parse the notebook content for import statements
2. Flag any imports not in the standard Spark/Fabric environment:
   - Standard (no action): pyspark, delta, mssparkutils, notebookutils, pandas, numpy
   - Needs verification: semantic-link, sempy, plotly, scikit-learn
   - Likely missing: custom internal packages, pip-only packages
3. Check for hardcoded workspace/lakehouse IDs → flag for environment parameterization
4. Check for `mssparkutils.lakehouse.get*` calls → confirm lakehouse is attached
5. Check for `spark.conf.set` calls → document required configs
```

---

## Outputs

- Updated item list with IDs
- Validation notes (including prerequisite check results)
- Data access path used (SQL endpoint / OneLake / Power BI Remote)
- Next recommended step (test / review / promote)
