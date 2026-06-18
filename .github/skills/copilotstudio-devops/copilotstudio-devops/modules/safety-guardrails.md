# Safety Guardrails — Copilot Studio DevOps

## Environment Protection Rules

| Environment | Read | Write | Delete | Publish | Admin |
|-------------|------|-------|--------|---------|-------|
| **DEV** | ✅ | ✅ | ✅ (with confirmation) | ✅ | ✅ |
| **UAT** | ✅ | ✅ (with confirmation) | ❌ | ✅ (with confirmation) | ✅ |
| **PROD** | ✅ | ❌ | ❌ | ❌ | ❌ (except quarantine with admin approval) |

## Mandatory Rules

1. **PROD is read-only.** The only PROD operations allowed are: list agents, view topics, export solution (unmanaged NOT allowed), run conversational evaluation (non-destructive), view analytics.
2. **Never expose secrets.** Direct Line secrets, client secrets, access tokens, and PAT tokens must NEVER appear in agent output. Use `***REDACTED***` if referencing their existence.
3. **Confirm before write.** All write operations (create topic, update knowledge, import solution, publish agent) require explicit user confirmation with a summary of what will change.
4. **Confirm before admin.** Quarantine, unquarantine, and delete operations require:
   - Admin-level credentials verification
   - Written justification from the user
   - Explicit "yes, proceed" confirmation
5. **Solution promotion via ALM only.** Never directly modify agent components in UAT or PROD. Use solution export → import or pipeline deployment.
6. **Evaluate safely.** Conversational evaluation sends test messages to a published agent. This is non-destructive but may:
   - Trigger external connectors/APIs the agent is configured to call
   - Consume API quota
   - Appear in conversation transcripts/analytics
   - Warn the user about these side effects before evaluation

## Credential Handling

- Store credentials in environment variables, never in config files
- Direct Line tokens expire after 30 minutes — always generate fresh tokens
- PAC CLI auth profiles are stored securely by the CLI — never output profile details
- Entra ID tokens are acquired via interactive flow or client credentials — never cache in plain text

## Quarantine Rules

Quarantine is an emergency admin action. Before executing:
1. Confirm the user has Global Admin, AI Admin, or Power Platform Admin role
2. Verify the Bot ID and Environment ID are correct
3. Explain the impact: quarantined agents are immediately unavailable to all users
4. Require explicit written justification
5. Log the action for audit trail

## Error Escalation

| Error Type | Action |
|------------|--------|
| Auth failure (401/403) | Report error, suggest `pac auth create` or `az login` |
| Agent not found (404) | Report error, suggest verifying agent schema name and environment |
| Rate limiting (429) | Wait and retry once after 30 seconds, then report |
| Dataverse query error | Report error with entity and filter details |
| Direct Line timeout | Report timeout, suggest checking agent publish status |
| Solution import failure | Report error, suggest checking solution dependencies and components |
