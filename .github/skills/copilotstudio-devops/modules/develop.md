# Develop — Procedure Module

## Overview

Create, update, and manage Copilot Studio agent components.

**Key PAC CLI commands (proven working):**
- `pac copilot create` — Create a new agent from a template file
- `pac copilot extract-template` — Extract an existing agent’s full config as YAML
- `pac copilot publish` — Publish an agent programmatically
- `pac copilot model predict` — Test AI model prompts

All write operations are restricted to DEV and UAT environments.

---

## URL Parsing

Users provide Copilot Studio URLs:
```
https://copilotstudio.preview.microsoft.com/environments/{ENV_ID}/bots/{BOT_ID}/overview
```
Extract `ENV_ID` and `BOT_ID` GUIDs for use with PAC CLI flags.

---

## Important: Copilot Studio Authoring Model

Copilot Studio agents are primarily authored through the Copilot Studio web UI. Programmatic creation of topics is possible via Dataverse but has limitations:

1. **Topic content** is stored as JSON in the `content` column of the `botcomponent` table
2. **The content format is complex** — topic JSON includes nodes, triggers, actions, variables, and conditions
3. **Recommended approach**: Use the Copilot Studio UI for authoring, then export via solution for source control
4. **Programmatic approach**: Best used for bulk updates, trigger phrase modifications, and metadata changes

## Step 1: Understand the Data Model

### Bot → BotComponent Relationship

```
bot (agent)
  └── bot_botcomponent (M:M relationship)
       └── botcomponent (topic, knowledge source, action, etc.)
            ├── name: display name
            ├── componenttype: type code (see below)
            ├── content: JSON definition of the component
            ├── description: searchable text
            └── statecode: 0 = Active, 1 = Inactive
```

## Step 2: Create a Topic (via Dataverse)

> ⚠️ **Limitation:** Creating topics with full dialog logic programmatically requires knowledge of
> the internal YAML/JSON format. For complex topics, author in Copilot Studio UI and manage via solutions.

### Simple Topic with Trigger Phrases

```bash
# Create a new botcomponent of type Topic
curl -X POST "{environmentUrl}/api/data/v9.2/botcomponents" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "New Topic Name",
    "componenttype": 1,
    "description": "Handles user questions about topic X",
    "content": "{\"triggers\": [\"trigger phrase 1\", \"trigger phrase 2\"]}"
  }'
```

### Link Topic to Bot

```bash
# Associate the new botcomponent with the bot
curl -X POST "{environmentUrl}/api/data/v9.2/bots(<BOT_ID>)/bot_botcomponent/$ref" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "@odata.id": "{environmentUrl}/api/data/v9.2/botcomponents(<NEW_COMPONENT_ID>)"
  }'
```

## Step 3: Update Existing Topic

```bash
# Update a topic's trigger phrases or content
curl -X PATCH "{environmentUrl}/api/data/v9.2/botcomponents(<COMPONENT_ID>)" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Updated description",
    "content": "{\"triggers\": [\"new trigger 1\", \"new trigger 2\", \"existing trigger\"]}"
  }'
```

## Step 4: Add Knowledge Source

Knowledge sources are managed via the Copilot Studio UI primarily, but metadata can be queried:

```bash
# List knowledge sources (componenttype = 11)
curl -X GET "{environmentUrl}/api/data/v9.2/botcomponents?\
$filter=componenttype eq 11\
&$select=name,description,content,modifiedon" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Accept: application/json"
```

## Step 5: Source Control Workflow (Recommended)

The recommended development workflow uses solution export/import for version control:

```bash
# 1. Author changes in Copilot Studio UI (DEV environment)

# 2. Export the solution containing the agent
pac solution export --name <SolutionName> --path ./exports/agent-solution.zip

# 3. Unpack for source control
pac solution unpack --zipfile ./exports/agent-solution.zip --folder ./src/agent-solution

# 4. Commit to git
git add ./src/agent-solution
git commit -m "feat: add new topic for leave requests"
git push

# 5. For PR review, the unpacked solution shows:
#    - Topic definitions in YAML/JSON
#    - Knowledge source references
#    - Action configurations
#    - Connector bindings
```

## Step 6: Publish Agent Changes (PAC CLI — PROVEN)

After making changes, publish the agent programmatically:

```bash
# Publish a copilot (PAC CLI)
pac copilot publish --environment <ENVIRONMENT_ID> --bot <BOT_ID_OR_SCHEMA_NAME>
```

This is equivalent to clicking "Publish" in the Copilot Studio UI.

## Step 7: Create a New Agent from Template (PAC CLI)

If you have a template YAML (from `pac copilot extract-template`):

```bash
# Create a new copilot from a template
pac copilot create --environment <ENVIRONMENT_ID> --templateFileName <template.yaml>
```

This enables:
- Cloning an agent from one environment to another
- Creating standardized agents from a template library
- Bootstrapping new agents with predefined topics and flows

## Step 8: Test AI Model Prompts

```bash
# Send a test prompt to an AI Builder model
pac copilot model predict --environment <ENVIRONMENT_ID> --model-id <MODEL_ID> --text "<test prompt>"
```

## Recommended Workflow Summary

| Task | Best Approach |
|------|--------------|
| Author new topics | Copilot Studio UI |
| Bulk update trigger phrases | Dataverse API (PATCH botcomponent) |
| Add knowledge sources | Copilot Studio UI |
| Version control agent changes | PAC CLI: export → unpack → git commit |
| Code review agent changes | PR on unpacked solution files |
| Deploy to UAT/PROD | Solution import via PAC CLI or Pipelines |
