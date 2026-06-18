---
name: azure-source-notebook-compare
description: Run comparison from an Azure/Fabric notebook link by extracting SQL from notebook content and producing comparison data for latest Gold vs Silver or latest Gold vs previous Gold, based on query intent in the notebook.
---

# Azure Source Notebook Compare

Use this skill when the user shares a Fabric notebook URL and asks for data comparison from SQL contained in that notebook.

## New Features

1. Fixed Notebook Mode:
- If the user says the notebook is the same as previously provided, reuse that exact notebook URL/id by default.
- Only ask for notebook link again when access fails or notebook id is missing.

2. Heading-Driven Cell Selection:
- Prefer SQL cells based on nearby heading/comments in notebook content (example: comments that indicate `Gold vs Silver`, `Validation`, `Gold`, `Sales Gold`, `Sales Silver`).
- When multiple SQL cells exist, select the cell whose heading keywords best match user intent.

3. Intent Fallback for Missing Heading:
- If user asks for `latest Gold vs previous Gold` and no explicit heading exists, infer intent and run schema-shift comparison automatically.
- Same fallback applies for new Azure validation asks that mention different requirements but reference existing notebook logic.

## Supported Comparison Modes

1. Latest Gold vs Silver
2. Latest Gold vs Previous Gold
3. PPR Warehouse Gold validation (single `Gold` schema)
4. Sales Gold vs Sales Silver (Source D — POSOT_Sales)
5. Latest Sales Gold vs Previous Sales Gold (Source D — POSOT_Sales)
6. Staged Sales Gold vs Silver validation via intermediate tables (Source D — POSOT_Sales)
7. Same-query cross-source validation — run the PPR Warehouse query against Sales by swapping only schema/table references (Source B vs Source D)

Mode is inferred from notebook SQL intent + heading keywords. If ambiguous, ask one short clarification question.

## Known Sources (pre-resolved)

These sources are already mapped from prior runs. Reuse them directly when a notebook query references them — do not re-discover unless access fails.

### Source A — POSOT_Azure (Azure processing lakehouse)
- Workspace: `GPS_Azure_Prod_Processing` (`c29380d6-b4aa-43d2-9bea-23d9e9004afd`)
- SQL database: `POSOT_Azure`
- SQL endpoint: `x6eps4xrq2xudenlfv6naeo3i4-22ajhqvkwtjehg7kepm6sack7u.msit-datawarehouse.fabric.microsoft.com`
- Gold schemas: dated `AzureGoldYYYYMMDDnn` (pick latest / previous)
- Silver schemas: `Silver`, `Silver_Old`

### Source B — PPR Warehouse (Integration warehouse)
- Workspace: `GPS_Integration_Prod_Processing` (`fa16bf34-663f-499c-89db-ddc3f1d81e77`)
- SQL database: `PPR Warehouse` (warehouse id `391eff17-0067-45f3-bf32-f2713915c3f8`)
- SQL endpoint: `x6eps4xrq2xudenlfv6naeo3i4-gs7rn6r7m2oetco33xb7dwa6o4.msit-datawarehouse.fabric.microsoft.com`
- Gold schema: single `Gold` schema (use it directly; no dated schema rotation)
- Notes: contains `Gold.FactAzureConsumption_Reporting`, `Gold.MapAzureAssociationPartnerPPR`, `Gold.DimIntegrationTime`

### Source C — POSOT_Integration (time dimension source)
- Workspace: `GPS_Integration_Prod_Processing` (`fa16bf34-663f-499c-89db-ddc3f1d81e77`)
- SQL database: `POSOT_Integration`
- SQL endpoint: `x6eps4xrq2xudenlfv6naeo3i4-gs7rn6r7m2oetco33xb7dwa6o4.msit-datawarehouse.fabric.microsoft.com`
- Gold schemas: dated `IntegrationGoldYYYYMMDDnn` (pick latest / previous) — holds `DimIntegrationTime`

### Source D — POSOT_Sales (Sales processing lakehouse)
- Workspace: `GPS_MSSales_Prod_Processing`
- Lakehouse / SQL database: `POSOT_Sales`
- Notebook queries: `Sales Gold` and `Sales Silver` (two queries added to the notebook)
- Gold schemas: dated `SalesGoldYYYYMMDDnn` (pick latest / previous)
- Silver schemas: `Silver` (use notebook-provided Silver tables/columns directly)
- Default table: when a Sales Gold validation is requested without an explicit table name, use `FactSales`. If the user names a table explicitly, use that table instead.
- Use for `Sales Gold vs Sales Silver` and `latest Sales Gold vs previous Sales Gold` comparisons.
- Intermediate tables (3 staging tables added to the notebook for staged Silver → Gold validation):
  - `factecspurchase_base`
  - `FactReconcileECSPurchase`
  - `Factecspurchase`
- Use these for the `Staged Sales Gold vs Silver validation via intermediate tables` mode (see below).

## Staged Sales Gold vs Silver Validation (intermediate tables)

Trigger: user says something like `validate sales gold and silver` (staged), or references the intermediate tables.

This mode validates the Sales data flow end-to-end across each transformation stage instead of a single Silver↔Gold compare. The notebook now contains 3 intermediate tables between Sales Silver and Sales Gold. Run the comparison stage-by-stage and follow the chain — each stage's downstream table becomes the upstream input for the next stage.

Validation chain (in order):

1. **Sales Silver → `factecspurchase_base`**
   - Compare Sales Silver against intermediate table `factecspurchase_base`.
2. **`factecspurchase_base` → `FactReconcileECSPurchase`**
   - Compare intermediate table `factecspurchase_base` against intermediate table `FactReconcileECSPurchase`.
3. **`FactReconcileECSPurchase` → `Factecspurchase`**
   - Compare intermediate table `FactReconcileECSPurchase` against intermediate table `Factecspurchase`.
4. **`Factecspurchase` → `FactSales` (Sales Gold)**
   - Compare intermediate table `Factecspurchase` against the Gold table `FactSales` (Sales Gold).

Column-mapping rule:
- Column names may differ across stages, but they are the **corresponding columns** from the Sales Silver code (and onward through each intermediate table). Map columns by their logical role/lineage from the Silver query, not by exact name match. Carry the column correspondence forward through every stage so equivalent measures are compared even when renamed.

Execution:
- Resolve the latest `SalesGoldYYYYMMDDnn` schema that contains the required tables (same dated-schema resolution as other Sales Gold modes).
- Run each of the 4 stage comparisons, preserving notebook joins, filters, and aggregation grain.
- Apply any user-requested normalization/exclusion (e.g. `CSP Tier 1` = `CSP Tier1`) after querying.

Output:
- Provide the **entire data** for the validation in Excel, with a clear **heading for each stage** so the full Sales Gold vs Sales Silver lineage is auditable in one workbook.
- Each stage's heading must name the upstream and downstream tables compared (e.g. `Stage 1: Sales Silver vs factecspurchase_base`).
- Include comparison value columns and a **percentage difference** column per stage, plus schema metadata columns used for the run.
- Difference must be expressed as a **percentage only** (see global Percentage Difference Rule below) — do not output a raw numeric difference column.

> Cross-source rule: PPR Warehouse uses a single `Gold` schema, so for PPR queries skip latest/previous dated-schema resolution and run against `Gold` directly. When a PPR-style query needs `DimIntegrationTime` from POSOT_Integration (different endpoint), fetch it separately and join in-memory.

## Same-Query Cross-Source Validation (PPR Warehouse with Sales)

Trigger: user says something like `validate PPR Warehouse with Sales` (or `validate PPRWarehouse with sales`).

**Meaning (important):** take the **existing PPR Warehouse query from the notebook** and run that **exact same query against Sales (Source D)**. Do **not** author or pick a separate Sales query. Only change the schema / database / table references so the identical logic — same CTE, joins, filters, aggregation grain, and measures — executes on the Sales side. Then compare the two result sets and output **percentage differences** by the shared grain.

**Always read the live notebook first.** Re-fetch the notebook definition (e.g. `scripts/fetch-live-notebook.ps1` → `scripts/live-decoded-notebook-content.py`) and copy the PPR queries verbatim. Never hardcode or assume the PPR SQL — the decoded notebook output is gitignored and must be re-fetched each run.

**There are TWO PPR Warehouse (Sales) notebook queries — run BOTH:**

1. **By Fiscal Month** (heading `PPR Warehouse based on Fiscalmonth(Sales)`): CTE of distinct `AssociationID` from `Map_Partner_Association_Sales` ⨝ `DimPartnerAssociation`; `SELECT FiscalMonthID, FiscalMonthName, SUM(SoldSeatsRevenue)` from `FactSalesPPR` ⨝ `DimIntegrationTime` ⨝ cte; `GROUP BY FiscalMonthID, FiscalMonthName`. Shared grain key = `FiscalMonthID`.
2. **By Association Type** (heading `PPR Warehouse based on Association Type(Sales)`): CTE of distinct `AssociationID, AssociationName` from `Map_Partner_Association_Sales`; `SELECT AssociationName, SUM(SoldSeatsRevenue) AS BilledRevenue` from `FactSalesPPR` ⨝ cte, `LEFT JOIN DimIntegrationTime`; `GROUP BY AssociationName`. Shared grain key = `AssociationName`.

When the user says `validate PPR Warehouse with Sales` (with no further qualifier), run both and emit a two-sheet Excel (`By FiscalMonth`, `By AssociationType`). If the user names one (`based on fiscal month` / `based on association type`), run only that one.

Schema / table reference mapping (PPR → Sales):

| PPR Warehouse reference | Sales (Source D) reference |
| --- | --- |
| Database `[PPR Warehouse]` | `[POSOT_Sales]` |
| Schema `[Gold]` | latest dated `[SalesGoldYYYYMMDDnn]` |
| Fact `[FactSalesPPR]` | `[FactSales]` (corresponding Sales fact) |
| Time dim `[DimIntegrationTime]` | `[DimSalesTime]` (corresponding Sales time dim) |
| `[Map_Partner_Association_Sales]` | same name |
| `[DimPartnerAssociation]` | same name |

Column/measure names stay the same across both sides (`AssociationID`, `SoldSeatsRevenue`, `FiscalMonthID`, `FiscalMonthName`).

Rules:
- Keep the query logic identical: same CTE, same join keys, same `GROUP BY` grain, same measure (e.g. `SUM(SoldSeatsRevenue)`).
- Run BOTH PPR (Sales) notebook queries (fiscal month + association type) unless the user names a specific one.
- Resolve the latest `SalesGoldYYYYMMDDnn` schema that contains all mapped tables; if one is missing, walk back to a previous schema or report the exact blocker.
- Only substitute a table/column name when the PPR name does not exist in Sales; map by lineage role (fact↔fact, time-dim↔time-dim) and **report every substitution made**.
- Do not re-introduce the standalone Sales query (with `DimBusiness` / `BusinessSummaryID` / `IsDisti` filters) for this mode — that is a different validation.
- Output one `%Diff` per shared grain key (`FiscalMonthID` for query 1, `AssociationName` for query 2) per the global Percentage Difference Rule.
- Runner script: `scripts/ppr-vs-sales-validate.ps1` (runs both queries, writes two-sheet `PPRWarehouse_vs_Sales_Validation.xlsx` + CSVs).

## Inputs

1. Notebook URL (Power BI/Fabric link)
2. Optional filters from user:
- AssociationType exclusions
- Value normalization rules (example: `CSP Tier 1` = `CSP Tier1`)
3. Optional intent phrase:
- `latest gold vs silver`
- `latest gold vs previous gold`
- custom validation requirement in Azure

## Execution Flow

### Step 1: Resolve notebook content from URL

1. Parse workspace id and notebook id from URL.
2. Call Fabric API:
- `GET /v1/workspaces/{workspaceId}/notebooks/{notebookId}` to validate access
- `POST /v1/workspaces/{workspaceId}/notebooks/{notebookId}/getDefinition`
3. Poll operation URL until `Succeeded`.
4. Retrieve `/result`, decode `definition.parts[].payload` (base64) and extract `notebook-content.py`.

### Step 2: Extract SQL cells and identify intent

Detect SQL blocks, read commented headings, then classify intent:

1. Build candidate list of SQL cells with:
- heading/comment text above the SQL block
- source references (workspace.database.schema.table)
- filter fields (BillingMonthID, Dim_DateId, FiscalMonthID)

2. Score candidates against user ask using heading keywords first, then SQL structure.

3. Select execution mode:
- Gold vs Silver if selected cell includes both Gold and Silver logic
- Gold vs Previous Gold if user asks previous Gold even when no heading says so

4. Gold vs Silver pattern:
- Gold tables in schema like `AzureGoldYYYYMMDDnn`
- Silver tables in `Silver.*`
5. Gold vs Previous Gold pattern:
- Gold schema references that can be shifted to previous available Gold schema.

6. If user asks new Azure validation requirement:
- Reuse the closest heading-matched SQL cell as base template
- Keep aggregation/filter intent from user ask
- Resolve schemas dynamically (latest/previous) before execution

### Step 3: Resolve latest schemas

For latest Gold:
- Discover schemas with `TABLE_SCHEMA LIKE 'AzureGold20%'`
- Keep only schemas that contain all required tables for the notebook query
- Pick highest schema lexicographically (dated pattern)

For previous Gold:
- Pick second highest schema satisfying required table availability
- If second highest schema lacks required table(s), walk backward until a valid previous schema is found

For Silver:
- Use notebook-provided Silver tables and columns directly
- Do not invent missing join keys; if impossible, report exact blocker

For Sales Gold (Source D):
- When the user requests Sales Gold validation, use the table name they explicitly provide.
- If no table name is given, default to `FactSales`.
- Resolve the latest/previous `SalesGoldYYYYMMDDnn` schema that contains the target table.

For PPR Warehouse (Source B):
- Do NOT apply dated-schema resolution — it has a single `Gold` schema.
- Run the notebook query against `Gold` directly.
- If `DimIntegrationTime` is needed and the query targets POSOT_Integration, resolve the latest `IntegrationGoldYYYYMMDDnn` schema from Source C and join in-memory.

### Step 4: Execute comparison query

1. Build execution SQL with resolved schemas.
2. Preserve notebook logic:
- joins
- filters (billing month/date id)
- aggregation grain (example: by `AssociationType`)
3. Run on Fabric SQL endpoint(s) derived from source names in query.
4. If cross-endpoint join is required, perform split query + in-memory merge.

### Step 5: Normalize and filter output (if requested)

Apply user-requested transforms after query:

1. Normalize labels
- Example mapping:
  - `CSP Tier 1` -> `CSP Tier1`
  - `CSP Tier 2` -> `CSP Tier2`
2. Exclude requested association types
- Example:
  - `TPOR-DIR`
  - `TPOR-IND`
  - `TPOR-SOA`
3. Re-aggregate after normalization and filtering.

### Step 6: Export and deliver

Always generate:

1. CSV in `scripts/`
2. Excel in workspace root
3. Excel copy on Desktop

Excel must include:

1. Comparison columns (`GoldValue`, `SilverValue` or `LatestGold`, `PreviousGold`)
2. A **percentage difference** column (see Percentage Difference Rule)
3. Schema metadata columns used for run

## Percentage Difference Rule (applies to ALL Excel outputs)

1. Every Excel this skill produces must express the difference as a **percentage only** — never a raw numeric difference column.
2. Formula: `%Diff = (UpstreamValue - DownstreamValue) / DownstreamValue` (for Gold vs Silver use `(GoldValue - SilverValue) / SilverValue`; for Gold vs Previous Gold use `(LatestGold - PreviousGold) / PreviousGold`).
3. Format the value as a percentage with 2 decimals (`0.00%`).
4. Edge cases:
   - Denominator is `0` and numerator is non-zero → output `n/a` (or `NULL`/division-undefined), do not output a number.
   - Both values `0` → `0.00%`.
   - Missing upstream or downstream value → leave blank.
5. Highlight any non-zero `%Diff` (abs > 0.0001) in red/bold so mismatches are obvious.
6. Provide one `%Diff` column per compared measure; do not emit absolute-difference columns alongside it.

## Guardrails

1. Never hardcode stale schema names from notebook; always resolve latest/previous from catalog.
2. If required table is missing in the target layer, stop and report precise missing table/column.
3. If values differ due to naming drift (`Tier 1` vs `Tier1`), suggest normalization and provide normalized output.
4. Prefer exact notebook logic first; only adapt when technically required and explain adaptation.
5. For fixed notebook mode, do not switch notebook unless user explicitly changes it or API access fails.
6. For heading-based selection, always return which heading/cell context was used.

## Output Contract

Return:

1. Mode used (`Gold vs Silver` or `Gold vs Previous Gold`)
2. Source endpoint(s) and database(s)
3. Resolved schema names
4. Billing month/date filter used
5. Row count and notable differences
6. Paths to CSV and Excel outputs
7. Heading/cell context used for query selection

## Example Summary Format

1. Mode: `Latest Gold vs Silver`
2. Gold schema: `AzureGold2026061501`
3. Silver schema: `Silver`
4. Filter: `BillingMonthID=20250701`
5. Output files:
- `scripts/source1-gold-vs-silver-notebook-query-normalized.csv`
- `Source1_Gold_vs_Silver_NotebookQuery_Normalized.xlsx`
- Desktop copy path
