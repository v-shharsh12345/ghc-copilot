# Release & Promote Module — Databricks DevOps

## Scope

Bundle-based deployments, CI/CD promotion across DEV → UAT → PROD, pre-flight validation, and post-deploy verification.

## Procedures

### Bundle Project Setup

A Databricks Asset Bundle project uses `databricks.yml` at the root:

```yaml
bundle:
  name: my-project

workspace:
  host: https://adb-<workspace-id>.azuredatabricks.net

resources:
  jobs:
    my_job:
      name: "my-etl-job"
      tasks:
        - task_key: "main"
          notebook_task:
            notebook_path: ./notebooks/main.py
          new_cluster:
            spark_version: "14.3.x-scala2.12"
            node_type_id: "Standard_DS3_v2"
            num_workers: 2

targets:
  dev:
    mode: development
    default: true
    workspace:
      host: https://adb-<dev-id>.azuredatabricks.net
  uat:
    workspace:
      host: https://adb-<uat-id>.azuredatabricks.net
  prod:
    mode: production
    workspace:
      host: https://adb-<prod-id>.azuredatabricks.net
    run_as:
      service_principal_name: "deploy-sp"
```

### Bundle Validate

```bash
databricks bundle validate --target <target>
```

- Validates YAML syntax and resource references
- Checks workspace connectivity
- Must PASS before deploy

### Bundle Deploy

```bash
databricks bundle deploy --target <target>
```

- Uploads notebooks, libraries, and config to target workspace
- Creates/updates jobs, clusters, pipelines as defined in `databricks.yml`
- Idempotent — safe to re-run

**GUARDRAIL**: Always run `bundle validate` before `bundle deploy`. Never deploy to PROD without UAT validation first.

### Bundle Run (trigger a job)

```bash
databricks bundle run --target <target> <resource_key>
```

Example: `databricks bundle run --target uat my_job`

### Promotion Workflow: DEV → UAT → PROD

**Step 1 — DEV validation**
```bash
databricks bundle validate --target dev
databricks bundle deploy --target dev
databricks bundle run --target dev my_job
# Verify job succeeds
```

**Step 2 — UAT promotion**
```bash
databricks bundle validate --target uat
databricks bundle deploy --target uat
databricks bundle run --target uat my_job
# Run data quality checks (see data-ops.md)
# Compare outputs with DEV
```

**Step 3 — Pre-PROD checklist**
- [ ] UAT job run succeeded
- [ ] Data quality checks PASS
- [ ] Config drift validation PASS (see validate.md)
- [ ] Security review: permissions and secrets verified
- [ ] Approver sign-off obtained

**Step 4 — PROD deployment**
```bash
databricks bundle validate --target prod
databricks bundle deploy --target prod
```

**Step 5 — Post-deploy verification**
- Trigger a job run or wait for next scheduled run
- Monitor run status via `databricks jobs list-runs --job-id <id>`
- Verify data freshness downstream
- Report deployment result as PASS/FAIL

### Manual Promotion (without bundles)

For workspaces not using bundles:

1. **Export notebook** from source:
   ```bash
   databricks workspace export /path/to/notebook ./local/notebook.py --format SOURCE
   ```

2. **Import to target**:
   ```bash
   databricks workspace import ./local/notebook.py /path/to/notebook --format SOURCE --language PYTHON --overwrite
   ```

3. **Export/import job definition**:
   ```bash
   databricks jobs get --job-id <id> > job_def.json
   # Edit job_def.json: update cluster IDs, paths for target env
   databricks jobs create --json @job_def.json
   ```

**GUARDRAIL**: Prefer bundle-based deployments over manual export/import. Manual promotion requires explicit environment-specific config adjustment.

### Rollback Procedure

1. Identify the previous working state (last successful deploy or git commit)
2. Re-deploy the previous version:
   ```bash
   git checkout <previous_commit>
   databricks bundle deploy --target <target>
   ```
3. Verify rollback succeeded by running a test job
4. Document the rollback reason
