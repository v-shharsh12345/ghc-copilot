# Validate Module — Databricks DevOps

## Scope

Cross-environment validation of cluster configs, job definitions, notebook presence, and configuration drift detection.

## Procedures

### Cross-Environment Config Comparison

1. Resolve source and target workspaces from workspace-catalog.yaml
2. For each resource type (clusters, jobs, notebooks, warehouses):
   - List items in source environment
   - List items in target environment
   - Compare by name matching
3. Report: items only in source, only in target, in both but different

### Cluster Config Drift Detection

1. Get cluster definitions from both environments
2. Compare key properties:
   - `spark_version`, `node_type_id`, `num_workers`/`autoscale`
   - `spark_conf`, `spark_env_vars`
   - `init_scripts`, `custom_tags`
   - `autotermination_minutes`, `cluster_log_conf`
3. Flag differences by severity:
   - ERROR: Spark version mismatch, missing init scripts
   - WARN: Worker count differences, tag mismatches
   - INFO: Name/label differences

### Job Definition Validation

1. Export job definitions from both environments
2. Compare:
   - Task structure and ordering
   - Cluster configurations (new_cluster or existing_cluster_id)
   - Notebook paths and parameters
   - Schedule/trigger configuration
   - Library dependencies
3. Flag structural differences vs. expected environment-specific overrides

### Notebook Presence Validation

1. List workspace paths recursively in both environments
2. Compare notebook inventories
3. Report missing notebooks (exist in source, missing in target)
4. Optionally compare notebook content checksums

### Pre-Deployment Readiness Check

1. Verify target environment auth works
2. Confirm compute resources exist (clusters, warehouses)
3. Validate Unity Catalog objects exist (catalogs, schemas, tables)
4. Check permissions are sufficient for deployment user
5. Produce PASS/WARN/FAIL summary
