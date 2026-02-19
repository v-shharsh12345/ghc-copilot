# Develop Module — Databricks DevOps

## Scope

Create, update, and manage Databricks workspace items including notebooks, jobs, clusters, SQL warehouses, and pipelines.

## Procedures

### Create/Update Notebook

1. Verify auth: `databricks auth token -p <profile>`
2. Check target environment is non-PROD
3. Import notebook:
   - **CLI**: `databricks workspace import <local-path> <remote-path> --format SOURCE -p <profile>`
   - **API**: `POST /api/2.0/workspace/import` with `content` (base64), `path`, `language`, `format`
   - **SDK**: `w.workspace.import_(path=..., content=..., format=ImportFormat.SOURCE, language=Language.PYTHON)`
4. Verify import: `databricks workspace get-status <remote-path> -p <profile>`

### Create/Update Job

1. Define job spec with tasks, clusters, schedule
2. Create job:
   - **CLI**: `databricks jobs create --json '<job-spec>'`
   - **API**: `POST /api/2.1/jobs/create` with job definition
   - **SDK**: `w.jobs.create(name=..., tasks=[...])`
3. For updates: `PATCH /api/2.1/jobs/update` or `w.jobs.update(job_id=..., new_settings=...)`
4. Verify: `databricks jobs get --job-id <id>`

### Create/Update Cluster

1. Define cluster spec with Spark version, node type, workers, auto-termination
2. Enforce guardrails: `autotermination_minutes` set, `max_workers` reasonable
3. Create cluster:
   - **CLI**: `databricks clusters create --json '<cluster-spec>'`
   - **API**: `POST /api/2.0/clusters/create`
   - **SDK**: `w.clusters.create(cluster_name=..., spark_version=..., node_type_id=..., num_workers=...)`
4. Wait for RUNNING state: `w.clusters.create(...).result()` or poll `GET /api/2.0/clusters/get`

### Create/Update SQL Warehouse

1. Define warehouse spec (name, cluster_size, type)
2. Create warehouse:
   - **API**: `POST /api/2.0/sql/warehouses`
   - **SDK**: `w.warehouses.create(name=..., cluster_size=..., warehouse_type=...)`
3. For updates: `POST /api/2.0/sql/warehouses/{id}/edit`
4. Verify running: `GET /api/2.0/sql/warehouses/{id}`

### Run Job

1. Submit job run:
   - **CLI**: `databricks jobs run-now --job-id <id>`
   - **API**: `POST /api/2.1/jobs/run-now` with `job_id`
   - **SDK**: `w.jobs.run_now(job_id=...).result()`
2. Poll status until terminal state (SUCCEEDED/FAILED/CANCELLED)
3. Return run result and output link
