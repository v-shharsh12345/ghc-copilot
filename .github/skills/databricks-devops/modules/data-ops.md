# Data Ops Module — Databricks DevOps

## Scope

Unity Catalog management, Delta table operations, DBFS file management, and data quality checks.

## Procedures

### Unity Catalog — List Catalogs

```
GET /api/2.1/unity-catalog/catalogs
```

CLI: `databricks catalogs list`

### Unity Catalog — Create/Get Schema

```
POST /api/2.1/unity-catalog/schemas
{ "name": "<schema>", "catalog_name": "<catalog>" }
```

CLI: `databricks schemas create --catalog-name <catalog> --name <schema>`

### Unity Catalog — List/Describe Tables

```
GET /api/2.1/unity-catalog/tables?catalog_name=<cat>&schema_name=<schema>
GET /api/2.1/unity-catalog/tables/<full_name>
```

CLI: `databricks tables list --catalog-name <cat> --schema-name <schema>`

### Unity Catalog — Table Lineage

```
GET /api/2.0/lineage-tracking/table-lineage?table_name=<full_name>
```

Use for tracing upstream/downstream dependencies before changes.

### Delta Table — Describe History

Run via SQL endpoint or notebook:
```sql
DESCRIBE HISTORY <catalog>.<schema>.<table>
```

Shows: version, timestamp, operation, operationParameters, operationMetrics.

### Delta Table — Optimize

```sql
OPTIMIZE <catalog>.<schema>.<table>
  ZORDER BY (<col1>, <col2>)
```

Pre-check: Verify table is Delta format. Post-check: Confirm numFilesAdded in output.

### Delta Table — Vacuum

```sql
VACUUM <catalog>.<schema>.<table> RETAIN 168 HOURS
```

**GUARDRAIL**: Never VACUUM with < 168 hours retention without explicit approval. Never `SET spark.databricks.delta.retentionDurationCheck.enabled = false`.

### Delta Table — Schema Evolution Check

```sql
DESCRIBE TABLE EXTENDED <catalog>.<schema>.<table>
```

Compare column names/types across environments to detect schema drift.

### DBFS — List Files

```
GET /api/2.0/dbfs/list?path=<path>
```

CLI: `databricks fs ls dbfs:/<path>`

### DBFS — Upload/Download

```
CLI: databricks fs cp <local_path> dbfs:/<remote_path>
CLI: databricks fs cp dbfs:/<remote_path> <local_path>
```

**GUARDRAIL**: Max file upload size via single PUT is 1 MB. For larger files, use streaming upload API.

### Volume Operations

```
GET /api/2.1/unity-catalog/volumes?catalog_name=<cat>&schema_name=<schema>
```

CLI: `databricks volumes list --catalog-name <cat> --schema-name <schema>`

For file operations on volumes:
```
CLI: databricks fs cp <local> dbfs:/Volumes/<catalog>/<schema>/<volume>/<path>
```

### Data Quality Check

1. Run row count query: `SELECT COUNT(*) FROM <table>`
2. Run null check: `SELECT COUNT(*) FROM <table> WHERE <key_col> IS NULL`
3. Run freshness check: `SELECT MAX(<timestamp_col>) FROM <table>`
4. Compare metrics across environments (DEV vs UAT vs PROD)
5. Report PASS/WARN/FAIL per check:
   - PASS: Counts match within 5%, no null keys, freshness < 24h
   - WARN: Counts differ 5-20%, freshness 24-48h
   - FAIL: Counts differ > 20%, null keys found, freshness > 48h
