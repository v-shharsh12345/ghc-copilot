# Inventory — Procedure Module

## Overview

This module defines the canonical procedure for listing, inspecting, and monitoring Copilot Studio agents and their components. **PAC CLI is the primary engine** (proven working with v2.2.1). Dataverse Web API is the secondary/fallback.

---

## URL Parsing

Users may provide Copilot Studio URLs instead of IDs. Parse them:

```
https://copilotstudio.preview.microsoft.com/environments/{ENVIRONMENT_ID}/bots/{BOT_ID}/overview
```

Extract:
- `ENVIRONMENT_ID` → segment after `/environments/`
- `BOT_ID` → segment after `/bots/`

Both are GUIDs. Use them directly with `--environment` and `--bot-id` PAC CLI flags.

---

## Step 1: Verify Authentication

```bash
# Check PAC CLI auth (PROVEN WORKING)
pac auth list
# Expected output: Index, Active (*), Kind (UNIVERSAL), User (v-sutharapuh@microsoft.com)
```

## Step 2: List All Agents in an Environment (PAC CLI — Primary)

```bash
# List all copilots in an environment (PROVEN: returns Name, Copilot ID, Component State, Is Managed, Status Code, State Code)
pac copilot list --environment <ENVIRONMENT_ID>
```

**Output columns:**
| Column | Description |
|--------|-------------|
| Name | Display name of the agent |
| Copilot ID | Unique GUID identifier |
| Component State | Published / Draft |
| Is Managed | Managed (imported via solution) / Unmanaged (authored in-env) |
| Solution ID | GUID of the containing solution |
| Status Code | Active / Inactive |
| State Code | Provisioned / Deprovisioned |

## Step 2b: Check Specific Agent Status

```bash
# Get provisioning status for a specific bot (PROVEN)
pac copilot status --environment <ENVIRONMENT_ID> --bot-id <BOT_ID>
```

## Step 2c: List Solutions (to find agent packaging)

```bash
# List all solutions in environment (PROVEN: shows Unique Name, Friendly Name, Version, Managed)
pac solution list --environment <ENVIRONMENT_ID>
```

## Step 2d: List AI Builder Models

```bash
# List AI Builder models used by copilots (PROVEN)
pac copilot model list --environment <ENVIRONMENT_ID>
```

## Step 3: Extract Full Agent Configuration (PAC CLI — PROVEN)

The most powerful inspection tool — extracts the complete agent definition as a YAML file:

```bash
# Extract full agent template with all topics, flows, adaptive cards, settings (PROVEN: 2,382 lines for IncentiveIQ)
pac copilot extract-template --environment <ENVIRONMENT_ID> --bot <BOT_ID> --templateFileName <output-path.yaml> --overwrite
```

**What you get:**
- Full `BotDefinition` with auth settings, access control policy, generative actions config
- All `DialogComponent` definitions (topics) with complete conversation logic
- All trigger phrases, conditions, actions, variables, adaptive cards
- Power Automate flow references (flow IDs)
- Knowledge source configurations
- Localization status

**Output structure:**
```yaml
kind: BotDefinition
entity:
  accessControlPolicy: Any
  authenticationMode: Integrated
  authenticationTrigger: Always
  configuration:
    settings:
      GenerativeActionsEnabled: true
  template: kickStartTemplate-1.0.0

components:
  - kind: DialogComponent
    displayName: <Topic Name>
    state: Active
    dialog:
      beginDialog:
        kind: <TriggerType>
        actions: [...]
  # ... all topics, flows, entities
```

## Step 4: Get Agent Components via Dataverse (Secondary/Fallback)

### Component Types Reference
| componenttype | Description |
|---------------|-------------|
| 0 | Bot (root) |
| 1 | Topic |
| 2 | Entity |
| 3 | Dialog |
| 4 | Trigger |
| 5 | Skill |
| 11 | Knowledge Source |

```bash
# Fallback: List all components via Dataverse Web API
curl -X GET "{environmentUrl}/api/data/v9.2/bots(<BOT_ID>)/bot_botcomponent?\
$select=name,componenttype,statecode,modifiedon,description" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Accept: application/json"
```

## Step 5: Check Publish Status

```bash
# PAC CLI status check (PROVEN)
pac copilot status --environment <ENVIRONMENT_ID> --bot-id <BOT_ID>
# Output: "Copilot <Name> with ID <ID> has been provisioned."
```

Alternatively, `pac copilot list` shows Component State (Published/Draft) for all agents.

## Step 6: View AI Models Used by Copilots

```bash
# List all AI Builder models in the environment (PROVEN)
pac copilot model list --environment <ENVIRONMENT_ID>
```

## Step 6: Format Inventory Report

### Summary Format

```
## Agent Inventory — {Environment}

| # | Agent Name | Schema Name | Status | Topics | Last Modified |
|---|-----------|-------------|--------|--------|---------------|
| 1 | HR Support Bot | cr_hrsupport | Active | 12 | 2026-02-20 |
| 2 | IT Helpdesk   | cr_ithelpdesk | Active | 8 | 2026-02-18 |

Total Agents: 2 | Active: 2 | Inactive: 0
```

### Detailed Format (per agent)

```
## Agent Detail — HR Support Bot

| Property | Value |
|----------|-------|
| Schema Name | cr_hrsupport |
| Bot ID | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx |
| Status | Active |
| Created | 2026-01-15 |
| Last Modified | 2026-02-20 |

### Components
| Type | Name | Status | Last Modified |
|------|------|--------|---------------|
| Topic | Greeting | Active | 2026-02-20 |
| Topic | Leave Request | Active | 2026-02-18 |
| Knowledge | HR Policies PDF | Active | 2026-02-10 |
| Action | Submit Leave | Active | 2026-02-15 |
```
