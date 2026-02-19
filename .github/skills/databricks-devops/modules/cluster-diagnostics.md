# Cluster Diagnostics Module — Databricks DevOps

## Scope

Diagnose cluster start failures, Spark job errors, OOM issues, driver log analysis, and performance bottlenecks.

## Procedures

### Diagnose Cluster Start Failure

1. Get cluster info: `GET /api/2.0/clusters/get?cluster_id=<id>`
2. Check `state` and `state_message` for error details
3. Check `termination_reason.code`:
   - `CLOUD_PROVIDER_SHUTDOWN` — cloud VM issue
   - `INIT_SCRIPT_FAILURE` — init script error
   - `DRIVER_UNREACHABLE` — networking issue
   - `DBFS_DOWN` — DBFS unavailable
   - `CLOUD_PROVIDER_LAUNCH_FAILURE` — quota or capacity
4. Get cluster events: `POST /api/2.0/clusters/events` with `cluster_id`, `event_types`
5. Correlate with recent changes (cluster edits, policy updates)
6. Recommend fix based on termination code

### Diagnose Job Run Failure

1. Get run details: `GET /api/2.1/jobs/runs/get?run_id=<id>`
2. Check `state.result_state` and `state.state_message`
3. Get run output: `GET /api/2.1/jobs/runs/get-output?run_id=<id>`
4. Check task-level failures for multi-task jobs
5. Correlate with cluster state during run
6. Common patterns:
   - `LIBRARY_NOT_FOUND` — missing dependency
   - `SPARK_DRIVER_OOM` — increase driver memory
   - `INTERNAL_ERROR` — platform issue, retry
   - `RUN_DURATION_EXCEEDED` — optimize or increase timeout

### Diagnose OOM/Performance

1. Get cluster's Spark version and config
2. Check driver memory vs. data size
3. Review Spark configuration parameters:
   - `spark.driver.memory`
   - `spark.executor.memory`
   - `spark.sql.shuffle.partitions`
4. Recommend optimizations:
   - Increase worker count or memory
   - Optimize Spark SQL (broadcast hints, partition pruning)
   - Check for data skew in joins
5. Suggest Delta table optimizations (OPTIMIZE, ZORDER, VACUUM)

### Driver Log Analysis

1. Retrieve logs via cluster log delivery destination
2. Parse for common error patterns:
   - Java/Scala stack traces
   - Python tracebacks
   - Spark task failure reasons
3. Correlate with event timeline
4. Produce root cause summary and fix recommendation
