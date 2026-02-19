# Operate & Monitor Module — Databricks DevOps

## Scope

Inventory workspace resources, monitor job/cluster health, summarize run trends, and surface actionable risk signals.

## Procedures

### Inventory Workspace Items

1. List notebooks: `databricks workspace list / --output json -p <profile>` or `GET /api/2.0/workspace/list`
2. List clusters: `databricks clusters list -p <profile>` or `GET /api/2.0/clusters/list`
3. List jobs: `databricks jobs list --output json -p <profile>` or `GET /api/2.1/jobs/list`
4. List SQL warehouses: `GET /api/2.0/sql/warehouses` or `w.warehouses.list()`
5. Summarize counts by type, owner, and state

### Monitor Job Health

1. List recent job runs: `GET /api/2.1/jobs/runs/list` with `limit`, `completed_only`, `start_time_from`
2. Filter by state: `FAILED`, `TIMED_OUT`, `CANCELLED`
3. For each failing run, capture:
   - `run_id`, `job_id`, `job_name`
   - `state.result_state`, `state.state_message`
   - `start_time`, `end_time`, `run_duration`
4. Aggregate: failure rate, avg duration, retry count
5. Produce health summary: PASS (0 failures), WARN (intermittent), FAIL (repeated failures)

### Monitor Cluster Health

1. List all clusters: `GET /api/2.0/clusters/list`
2. Check for:
   - Clusters without auto-termination set
   - Long-running idle clusters (state=RUNNING, no recent jobs)
   - Clusters with termination reasons (`CLOUD_PROVIDER_ERROR`, `INIT_SCRIPT_FAILURE`)
3. Get cluster events for diagnostics: `POST /api/2.0/clusters/events` with `cluster_id`
4. Summarize: running count, idle waste, recent failures

### Monitor SQL Warehouses

1. List warehouses: `GET /api/2.0/sql/warehouses`
2. Check for oversized warehouses (>Medium), missing auto-stop
3. Query history: `GET /api/2.0/sql/history/queries` for recent errors
4. Summarize warehouse utilization and health

### Escalation Rules

- Repeated job failures on same cluster → escalate to cluster-diagnostics skill
- Permission errors in job runs → escalate to security skill
- Delta table access failures → escalate to data-ops skill
