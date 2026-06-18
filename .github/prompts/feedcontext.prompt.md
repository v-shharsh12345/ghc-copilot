---
description: "Enrich personal context files by tapping into WorkIQ (people, projects, discussions), Fabric/Power BI (reports, semantic models, datasets), and ADO (sprints, backlogs, recent activity). Updates config/user-context.yaml with live data from all three sources."
agent: "agent"
tools: ['workiq/*', 'mcp_CalendarTools/*', 'mcp_TeamsServer/*', 'mcp_MailTools/*', 'powerbi-remote/*', 'microsoft/azure-devops-mcp/*', 'read/readFile', 'edit/editFile', 'search/textSearch']
---

# Feed Context — Enrich Personal Configuration from Live Sources

You are a context-enrichment agent. Your job is to gather real data from three MCP sources and update the user's `config/user-context.yaml` file with accurate, current information. Work through all three phases sequentially, then write a single consolidated update.

**Start by reading the current config:**
```
Read: config/user-context.yaml
Read: config/user-context.template.yaml
```

Understand what's already populated and what needs enrichment. Then execute the three phases below.

---

## Phase 1: WorkIQ — People, Projects & Discussions

Goal: Discover the user's key collaborators, active projects, and recent discussion topics.

### 1a. Key People

```
Tool: mcp_workiq_ask_work_iq
Query: "Who are the people I interact with most frequently in the last 30 days? 
        List their names, roles, and how we typically interact (meetings, emails, Teams)."
```

Extract and structure as:
```yaml
people:
  frequentCollaborators:
    - name: "<Name>"
      role: "<Role/Title>"
      interactionType: "meetings, email, Teams"  # how you interact
    # ... top 8-10 people
```

### 1b. Active Projects & Initiatives

```
Tool: mcp_workiq_ask_work_iq
Query: "What are the main projects and initiatives I've been involved in over the last 30 days?
        Include recurring meetings, email threads, and Teams channels that indicate project involvement."
```

Extract and structure as:
```yaml
projects:
  activeInitiatives:
    - name: "<Project/Initiative Name>"
      description: "<One-line summary>"
      signals: "recurring meeting, email thread, Teams channel"
    # ... top 5-8 initiatives
```

### 1c. Recent Discussion Topics

```
Tool: mcp_workiq_ask_work_iq
Query: "What are the top themes and topics from my recent meetings, emails, and chats?
        Summarize the 5-8 most discussed subjects with context about what decisions or actions are pending."
```

Extract and structure as:
```yaml
discussions:
  recentTopics:
    - topic: "<Topic>"
      context: "<What's being discussed and what's pending>"
    # ... top 5-8 topics
```

---

## Phase 2: Fabric / Power BI — Reports, Datasets & Analytics Landscape

Goal: Build a rich inventory of reports, semantic models, and workspaces the user works with.

### 2a. Discover Artifacts

```
Tool: mcp_powerbi-remot_DiscoverArtifacts
```

This returns all accessible workspaces, reports, semantic models, and datasets. Capture the full inventory.

### 2b. For Each Key Semantic Model — Get Schema

For the top 5-10 most important semantic models (based on name relevance to the user's domain):

```
Tool: mcp_powerbi-remot_GetSemanticModelSchema
Input: artifactId = "<datasetId>"
```

Extract key tables and measures from each model.

### 2c. For Each Key Report — Get Metadata

For the top 5-10 most important reports:

```
Tool: mcp_powerbi-remot_GetReportMetadata
Input: artifactId = "<reportId>"
```

Extract report pages, visuals count, and connected dataset.

### 2d. Structure the Results

```yaml
fabric:
  workspaces:
    - name: "<Workspace Name>"
      id: "<workspaceId>"
      environment: "DEV | UAT | PROD"  # infer from name patterns
  
  reports:
    - name: "<Report Name>"
      id: "<reportId>"
      workspaceId: "<workspaceId>"
      datasetId: "<connected datasetId>"
      pageCount: <N>
    # ... all discovered reports

  semanticModels:
    - name: "<Model Name>"
      id: "<datasetId>"
      workspaceId: "<workspaceId>"
      keyTables: ["Table1", "Table2"]
      keyMeasures: ["Measure1", "Measure2"]
      summary: "<One-line description based on schema>"
    # ... all discovered models

  lakehouses:
    - name: "<Lakehouse Name>"
      id: "<lakehouseId>"
      workspaceId: "<workspaceId>"
    # ... all discovered lakehouses
```

---

## Phase 3: Azure DevOps — Sprints, Activity & Team Dynamics

Goal: Capture current sprint state, recent activity patterns, team interactions, and backlog health.

### 3a. Current Sprint & Iterations

```
Tool: mcp_microsoft_azu_work_list_team_iterations
Parameters:
  project: (from existing config → ado.projects.taskCreation.name)
  team: (from existing config → ado.team)
  timeframe: "current"
```

### 3b. My Recent Work Items

```
Tool: mcp_microsoft_azu_wit_my_work_items
```

Capture all items I own or recently touched.

### 3c. Sprint Board State

```
Tool: mcp_microsoft_azu_wit_run_wiql_query
Query: "SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo], 
        [System.WorkItemType], [Microsoft.VSTS.Scheduling.StoryPoints],
        [System.ChangedDate], [System.Tags]
        FROM WorkItems 
        WHERE [System.IterationPath] UNDER @currentIteration
        AND [System.TeamProject] = '<project>'
        ORDER BY [System.ChangedDate] DESC"
```

### 3d. Recent Activity — Who Touches What

Analyze the work items to extract:
- Which teammates are most active
- What types of work dominate (bugs, tasks, stories)
- Common tags and themes
- Items with recent comments/updates

### 3e. Structure the Results

```yaml
adoActivity:
  currentSprint:
    name: "<Iteration Name>"
    path: "<Iteration Path>"
    startDate: "<date>"
    endDate: "<date>"
  
  myItems:
    total: <N>
    byState:
      active: <N>
      new: <N>
      closed: <N>
    byType:
      tasks: <N>
      userStories: <N>
      bugs: <N>
    recentItems:
      - id: <ID>
        title: "<Title>"
        type: "<Type>"
        state: "<State>"
        tags: "<Tags>"
      # ... last 10 most recently changed
  
  teamActivity:
    activeMembers:
      - name: "<Name>"
        itemCount: <N>
        primaryWorkType: "tasks | stories | bugs"
    # ... team members with recent activity
  
  boardHealth:
    totalItems: <N>
    completionRate: "<X>%"
    staleItems: <N>  # not updated in 7+ days
    blockers: <N>    # items tagged as blocked
```

---

## Phase 4: Write the Consolidated Update

After gathering data from all three phases, update `config/user-context.yaml` by:

1. **Preserve all existing fields** — never remove or overwrite manually-configured values (ado.organization, ado.projects, statusEmail, etc.)
2. **Add new sections** under these keys:
   - `people` — from Phase 1a
   - `projects` — from Phase 1b
   - `discussions` — from Phase 1c
   - `fabric` — from Phase 2
   - `adoActivity` — from Phase 3
3. **Update existing domain.exampleEntities** — enrich with any newly discovered tables, reports, pipelines, lakehouses, and semantic models from Phase 2
4. **Update team.members** — merge any new frequent collaborators from Phase 1a and Phase 3e
5. **Add a metadata block** at the bottom:

```yaml
# ── Feed Context Metadata ─────────────────────────────────
feedContextMetadata:
  lastRefreshed: "<ISO 8601 timestamp>"
  sources:
    workiq: true | false    # whether WorkIQ data was gathered
    fabric: true | false     # whether Fabric data was gathered
    ado: true | false        # whether ADO data was gathered
  refreshNote: "Auto-populated by /feedcontext"
```

---

## Output Summary

After completing all phases, present a summary table:

```markdown
## Context Feed Complete

| Source | Status | Items Discovered |
|--------|--------|-----------------|
| WorkIQ — People | ✅ / ⚠️ / ❌ | N collaborators |
| WorkIQ — Projects | ✅ / ⚠️ / ❌ | N initiatives |
| WorkIQ — Discussions | ✅ / ⚠️ / ❌ | N topics |
| Fabric — Workspaces | ✅ / ⚠️ / ❌ | N workspaces |
| Fabric — Reports | ✅ / ⚠️ / ❌ | N reports |
| Fabric — Semantic Models | ✅ / ⚠️ / ❌ | N models (N with schema) |
| Fabric — Lakehouses | ✅ / ⚠️ / ❌ | N lakehouses |
| ADO — Sprint | ✅ / ⚠️ / ❌ | <Sprint Name> |
| ADO — My Items | ✅ / ⚠️ / ❌ | N items (N active) |
| ADO — Team Activity | ✅ / ⚠️ / ❌ | N active members |

**File updated:** `config/user-context.yaml`
```

If any MCP server is unavailable, mark that source as ⚠️ and continue with the others. Never fail the entire command because one source is down.

---

## Error Handling

- If WorkIQ is unavailable → skip Phase 1, mark sources.workiq: false
- If Power BI Remote is unavailable → skip Phase 2, mark sources.fabric: false
- If ADO MCP is unavailable → skip Phase 3, mark sources.ado: false
- Always write whatever data was successfully gathered
- Never delete existing manual configuration values
