# Security & Governance — Procedure Module

## Overview

Manage security, compliance, and admin operations for Copilot Studio agents via the Power Platform API and Dataverse Web API.

---

## Quarantine Operations

### Prerequisites

The caller must have one of these admin roles:
- Global tenant administrator
- AI administrator
- Power Platform administrator

The Entra ID app registration must have the `CopilotStudio.AdminActions.Invoke` scope granted under the Power Platform API.

### Quarantine an Agent

Makes an agent immediately unavailable to all users.

```bash
# Acquire admin token
TOKEN=$(az account get-access-token --resource https://api.powerplatform.com --query accessToken -o tsv)

# Quarantine the bot
curl -X POST "https://api.powerplatform.com/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/botAdminOperations/quarantine?api-version=1" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

**Response:** `204 No Content` on success.

### Unquarantine an Agent

Restores agent availability after remediation.

```bash
curl -X POST "https://api.powerplatform.com/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/botAdminOperations/unquarantine?api-version=1" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

### Check Quarantine Status

```bash
curl -X GET "https://api.powerplatform.com/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/botAdminOperations/quarantineStatus?api-version=1" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json"
```

---

## Delete Agent (Admin)

**⚠️ IRREVERSIBLE OPERATION**

```bash
curl -X DELETE "https://api.powerplatform.com/copilotstudio/environments/{EnvironmentId}/bots/{BotId}/api/botAdminOperations?api-version=1" \
  -H "Authorization: Bearer $TOKEN"
```

**Response:** `204 No Content` on success.

### Pre-Delete Checklist

1. ✅ Confirm Bot ID and Environment ID are correct
2. ✅ Verify the agent is the intended target (list details first)
3. ✅ Export a backup solution before deletion
4. ✅ Get written justification from the user
5. ✅ Get explicit "yes, delete" confirmation
6. ✅ Warn: "This is irreversible. The agent and all its components will be permanently removed."

---

## Audit Agent Permissions

### List Agent Ownership and Sharing

```bash
# Query bot entity for ownership info
curl -X GET "{environmentUrl}/api/data/v9.2/bots(<BOT_ID>)?$select=name,ownerid,_owningteam_value,_owninguser_value,modifiedon,createdon" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Accept: application/json"
```

### Check Agent Channel Configuration

```bash
# List bot components that define channels and security
curl -X GET "{environmentUrl}/api/data/v9.2/bots(<BOT_ID>)/bot_botcomponent?\
$filter=componenttype eq 4\
&$select=name,content,description" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Accept: application/json"
```

---

## Security Audit Checklist

Generate a security audit report covering:

| Check | Query | Pass Criteria |
|-------|-------|---------------|
| Auth configured | Check agent settings for authentication mode | Auth enabled (not "No authentication") |
| Channel security | Check web channel security settings | Direct Line secret configured |
| DLP compliance | Cross-reference with environment DLP policies | No restricted connectors used |
| Sharing scope | Check agent sharing configuration | Not shared to entire org (unless intended) |
| Knowledge sources | List knowledge source types | No external URLs to untrusted domains |
| Connector auth | Check connector authentication types | OAuth/API key (not anonymous) |

### Audit Report Format

```
## Security Audit — {Agent Name} ({Environment})

| # | Check | Status | Detail |
|---|-------|--------|--------|
| 1 | Authentication | ✅ PASS | Microsoft Entra ID configured |
| 2 | Channel Security | ⚠️ WARN | Direct Line secret not configured |
| 3 | DLP Compliance | ✅ PASS | No restricted connectors |
| 4 | Sharing Scope | ✅ PASS | Shared to specific team only |
| 5 | Knowledge Sources | ✅ PASS | 2 SharePoint sources (internal) |
| 6 | Connector Auth | ✅ PASS | All connectors use OAuth |

**Overall: PASS with warnings**
- Action: Configure Direct Line secret for web channel
```

---

## DLP Policy Compliance

DLP (Data Loss Prevention) policies in Power Platform restrict which connectors can be used together.

### Check DLP Policies

```bash
# List DLP policies in the environment
curl -X GET "https://api.powerplatform.com/policy/environments/{EnvironmentId}/dlpPolicies?api-version=2021-10-01" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json"
```

### Cross-Reference with Agent Connectors

1. List the agent's connector references via `botcomponent_connectionreference`
2. Map each connector to its DLP classification (Business, Non-Business, Blocked)
3. Check if the agent uses connectors from conflicting groups
4. Report any DLP violations
