# Safety Guardrails Module

## Non-Negotiables

- Never execute write operations in PROD.
- Require explicit environment confirmation for writes.
- Prefer promotion pipelines over direct modifications.
- Stop and ask for confirmation if environment cannot be resolved.

## Allowed in PROD

- List
- Get
- Export
- Query
- Compare
- Status checks

## Prohibited in PROD

- Create
- Update
- Delete
- Deploy
- Commit
- Promote directly to PROD without validation
