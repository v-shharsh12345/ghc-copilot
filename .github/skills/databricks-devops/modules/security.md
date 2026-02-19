# Security Module — Databricks DevOps

## Scope

Permission management, secret scopes, cluster policies, token management, and access control.

## Procedures

### Permissions — Get Object Permissions

```
GET /api/2.0/permissions/<object_type>/<object_id>
```

Object types: `clusters`, `jobs`, `notebooks`, `directories`, `sql/warehouses`, `registered-models`, `experiments`.

CLI: `databricks permissions get <object_type> <object_id>`

### Permissions — Update Object Permissions

```
PATCH /api/2.0/permissions/<object_type>/<object_id>
{
  "access_control_list": [
    {
      "user_name": "<user>",
      "permission_level": "CAN_MANAGE"
    }
  ]
}
```

Permission levels vary by object type:
- Clusters: CAN_ATTACH_TO, CAN_RESTART, CAN_MANAGE
- Jobs: CAN_VIEW, CAN_MANAGE_RUN, IS_OWNER, CAN_MANAGE
- Notebooks: CAN_READ, CAN_RUN, CAN_EDIT, CAN_MANAGE

**GUARDRAIL**: Never remove IS_OWNER. Never grant CAN_MANAGE to broad groups without approval.

### Secret Scopes — List

```
GET /api/2.0/secrets/scopes/list
```

CLI: `databricks secrets list-scopes`

### Secret Scopes — Create

```
POST /api/2.0/secrets/scopes/create
{
  "scope": "<scope_name>",
  "initial_manage_principal": "users"
}
```

CLI: `databricks secrets create-scope <scope_name>`

For Azure Key Vault-backed scopes:
```
POST /api/2.0/secrets/scopes/create
{
  "scope": "<scope_name>",
  "scope_backend_type": "AZURE_KEYVAULT",
  "backend_azure_keyvault": {
    "resource_id": "<keyvault_resource_id>",
    "dns_name": "https://<vault>.vault.azure.net/"
  }
}
```

### Secrets — Put/Get/Delete

```
POST /api/2.0/secrets/put
{ "scope": "<scope>", "key": "<key>", "string_value": "<value>" }
```

CLI: `databricks secrets put-secret <scope> <key> --string-value <value>`

**GUARDRAIL**: Never log, print, or expose secret values. Use `dbutils.secrets.get(scope, key)` in notebooks — values are redacted in output.

### Secret ACLs

```
GET  /api/2.0/secrets/acls/list?scope=<scope>
POST /api/2.0/secrets/acls/put
{ "scope": "<scope>", "principal": "<user_or_group>", "permission": "READ" }
```

Permissions: READ, WRITE, MANAGE.

### Cluster Policies — List

```
GET /api/2.0/policies/clusters/list
```

CLI: `databricks cluster-policies list`

### Cluster Policies — Create/Update

```
POST /api/2.0/policies/clusters/create
{
  "name": "<policy_name>",
  "definition": {
    "spark_version": { "type": "fixed", "value": "14.3.x-scala2.12" },
    "autotermination_minutes": { "type": "range", "maxValue": 120, "defaultValue": 60 },
    "num_workers": { "type": "range", "maxValue": 10 }
  }
}
```

### Token Management — List/Revoke

```
GET  /api/2.0/token/list
POST /api/2.0/token/delete
{ "token_id": "<token_id>" }
```

**GUARDRAIL**: Never create tokens in automated scripts without expiry. Always set `lifetime_seconds`.

### IP Access Lists

```
GET  /api/2.0/ip-access-lists
POST /api/2.0/ip-access-lists
{
  "label": "<name>",
  "list_type": "ALLOW",
  "ip_addresses": ["10.0.0.0/8"]
}
```

### Unity Catalog Grants

```sql
GRANT <privilege> ON <securable_type> <name> TO <principal>
SHOW GRANTS ON <securable_type> <name>
```

Securable types: CATALOG, SCHEMA, TABLE, VOLUME, FUNCTION, EXTERNAL LOCATION, STORAGE CREDENTIAL.

Privileges: USE_CATALOG, USE_SCHEMA, SELECT, MODIFY, CREATE_TABLE, CREATE_SCHEMA, ALL PRIVILEGES.

**GUARDRAIL**: Never grant ALL PRIVILEGES on CATALOG in PROD without explicit approval.
