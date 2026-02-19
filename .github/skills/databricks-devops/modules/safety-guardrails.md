# Safety Guardrails Module — Databricks DevOps

## Non-Negotiables

- Never execute write operations in PROD (create, update, delete, terminate, deploy).
- Never expose tokens, secrets, passwords, or credentials in output.
- Require explicit environment confirmation for any write operation.
- Prefer bundle-based promotion (DEV → UAT → PROD) over direct modifications.
- Stop and ask for confirmation if environment cannot be resolved.
- Respect cluster cost controls: enforce auto-termination, max worker limits.

## Allowed in PROD

- List (clusters, jobs, notebooks, warehouses, catalogs, schemas, tables)
- Get (item metadata, job status, run history, cluster info)
- Export (notebooks, workspace objects)
- Query (SELECT statements via SQL warehouses — no DDL/DML)
- Compare (cross-environment config validation)
- Status checks (cluster state, job run status, warehouse state)

## Prohibited in PROD

- Create (clusters, jobs, notebooks, warehouses, secrets, scopes)
- Update (cluster config, job definitions, notebook content, permissions)
- Delete (clusters, jobs, notebooks, tables, secrets, scopes, DBFS files)
- Deploy (bundle deploy, notebook import/overwrite)
- Terminate (forced cluster termination, warehouse stop)
- DDL/DML SQL (CREATE, DROP, ALTER, INSERT, UPDATE, DELETE, MERGE)

## Credential Safety

- Never print or log Databricks tokens (dapi_*)
- Never display secret values from secret scopes
- Never expose Azure SP client secrets, tenant IDs in raw form
- When displaying auth config, mask sensitive values: `dapi_****XXXX`
- Use `databricks auth token` only to verify auth works, never to display tokens

## Cost Protection

- All clusters must have `autotermination_minutes` set (default: 20 min)
- Warn if `max_workers` > 10 without explicit user acknowledgment
- Warn if warehouse size > `Medium` without explicit user acknowledgment
- Prefer serverless compute where available
