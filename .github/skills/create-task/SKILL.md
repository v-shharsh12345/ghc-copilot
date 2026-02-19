---
name: 'create-task'
description: 'Create Azure DevOps tasks from context gathered across M365 meetings, Teams chats, Outlook emails, and GitHub Copilot conversations. Automatically extracts actionable items, determines the correct ADO project/iteration/parent, and creates well-structured tasks with proper fields and relationships.'
---

# Create Task from Context

Extract actionable tasks from meetings, chats, emails, and Copilot conversations, then create them as ADO work items in the correct location with proper details, assignments, and parent-child relationships.

## Version History

| Date | Version | Description |
|------|---------|-------------|
| 2026-02-09 | 1.1 | Updated: configurable project, What/When/Who description, mandatory comment, Story Points=1 + Effort=8h, Ad-hoc parent resolution |
| 2026-02-09 | 1.0 | Initial skill with multi-source context extraction and ADO task creation |

---

## Default Configuration

> **Configuration:** Read `config/user-context.yaml` at runtime to resolve ADO project, area path, and team defaults.

| Setting | Value |
|---------|-------|
| **ADO Project** | Resolve from `config/user-context.yaml` → `ado.projects.taskCreation.name` |
| **Work Item Type** | Task (default), Bug, or User Story depending on context |
| **Default Area Path** | Determined from Ad-hoc parent work item or user specification |
| **Default Iteration** | Current iteration (resolved dynamically) |
| **Story Points** | 1 |
| **Effort (hours)** | 8 |

---

## When to Use This Skill

Invoke this skill when:

- `"Create tasks from my last meeting"`
- `"Turn my meeting action items into ADO tasks"`
- `"Create a task for [description]"`
- `"Make tasks from my Teams chat with [person]"`
- `"Create follow-up tasks from today's standup"`
- `"Add tasks from our discussion to ADO"`
- `"Create a task under user story [ID]"`
- `"What action items do I have? Create tasks for them"`

---

## Prerequisites

| Requirement | Purpose |
|-------------|---------|
| ADO MCP Server | Create/update work items via `activate_azure_devops_work_item_management_tools` |
| M365 Copilot / WorkIQ | Extract context from meetings, emails, chats via `mcp_workiq_ask_work_iq` |
| Teams MCP Server | Read Teams chats/channels for action items via `mcp_mcp_teamsserv_*` tools |
| Calendar Access | Retrieve meeting details and context via `activate_calendar_view_tools` |
| Mail Access | Search emails for related context via `mcp_mcp_mailtools_SearchMessages` |

---

## How to Execute

### Step 1: Identify the Context Source

Determine where to extract task information from based on the user's request:

| User Says | Context Source | Tool to Use |
|-----------|---------------|-------------|
| "from my last meeting" | Calendar + Meeting recap | `mcp_workiq_ask_work_iq` |
| "from my chat with [person]" | Teams chat | `mcp_mcp_teamsserv_listChats` + `activate_chat_message_management_tools` |
| "from the [channel] discussion" | Teams channel | `activate_microsoft_teams_channel_management_tools` |
| "from the email about [topic]" | Outlook | `mcp_mcp_mailtools_SearchMessages` |
| "create a task for [description]" | Direct user input | No context gathering needed |
| "from our conversation" | Copilot chat history | Review current chat thread |

If the user is vague, query **all relevant sources** to maximize coverage.

### Step 2: Gather Context from M365

#### 2a: Meeting Context (Primary Source)

```text
Tool: mcp_workiq_ask_work_iq
Query: "What action items came out of my meeting about [topic]? 
        Include who was assigned each item and any deadlines mentioned."
```

```text
Tool: mcp_workiq_ask_work_iq
Query: "What were the key decisions and follow-ups from my [meeting name] meeting today?"
```

If a specific meeting is referenced, also pull calendar details:

```text
Tool: activate_calendar_view_tools -> ListCalendarView
Purpose: Get meeting title, attendees, time, and any attached notes
```

#### 2b: Teams Chat Context

```text
Tool: mcp_mcp_teamsserv_listChats
Parameters:
  userUpn: [person's UPN if specified]
  topic: [chat topic if known]
  top: 10
  expand: "lastMessagePreview"
```

Then retrieve messages from the identified chat:

```text
Tool: activate_chat_message_management_tools -> listChatMessages
Parameters:
  chatId: [from listChats result]
  top: 50
```

#### 2c: Teams Channel Context

```text
Tool: activate_microsoft_teams_channel_management_tools -> listChannelMessages
Parameters:
  teamId: [resolved from team name]
  channelId: [resolved from channel name]
```

#### 2d: Email Context

```text
Tool: mcp_mcp_mailtools_SearchMessages
Parameters:
  message: "emails about [topic] from [date range]"
```

#### 2e: Copilot Conversation Context

Review the current GitHub Copilot chat history for:
- Technical decisions made
- Implementation plans discussed
- Code-related tasks identified
- Analysis or investigation requests

### Step 3: Extract Actionable Tasks

From the gathered context, identify discrete, actionable tasks. For each task extract:

| Field | How to Determine |
|-------|-----------------|
| **Title** | Clear, action-oriented summary (verb + noun + context) |
| **Description** | Structured as **What** (task details), **When** (timeline/deadline), **Who** (stakeholders involved) |
| **Assigned To** | Person mentioned as owner/responsible; default to current user if unclear |
| **Priority** | Infer from urgency language (ASAP/blocker = P1, standard = P2, nice-to-have = P3) |
| **Parent Work Item** | User-specified parent ID, or the **Ad-hoc** parent in the current iteration |
| **Story Points** | Default: **1** (override if user specifies) |
| **Effort** | Default: **8 hours** (override if user specifies) |
| **Tags** | Technology and domain tags (same convention as update-user-story skill) |
| **Due Date** | Extract from explicit deadlines mentioned in context |

#### Task Title Guidelines

| Pattern | Example |
|---------|---------|
| **Good** | "Implement retry logic for Lakehouse refresh pipeline" |
| **Good** | "Update field names in eligibility report" |
| **Good** | "Validate charge amount data for current sprint" |
| **Bad** | "Do the thing we discussed" |
| **Bad** | "Fix stuff" |
| **Bad** | "Meeting follow-up" |

### Step 4: Determine the Right ADO Location

Resolve where each task should be created:

#### 4a: Project

- Default: Resolve from `config/user-context.yaml` → `ado.projects.taskCreation.name`
- Ask only if the user explicitly mentions a different project

#### 4b: Iteration Path

```text
Tool: mcp_microsoft_azu_work_list_team_iterations
Parameters:
  project: "<project from config/user-context.yaml>"
  team: [resolved team name]
  timeframe: "current"
Purpose: Get the current active iteration for the team
```

Use the **current iteration** unless the user specifies otherwise.

#### 4c: Resolve the Ad-hoc Parent Work Item

Every task **must** be parented under the correct **Ad-hoc** parent in the current iteration. This ensures tasks are visible on the sprint board.

**Step 1:** Find the Ad-hoc parent in the current iteration:
```text
Tool: activate_azure_devops_project_management_tools -> search work items
Query: "Ad-hoc" OR "Adhoc"
Project: <project from config/user-context.yaml>
Filter: Iteration Path = [current iteration path]
```

**Step 2:** If a user explicitly specifies a different parent ID, use that instead:
```text
Tool: activate_azure_devops_work_item_management_tools_2 -> get work item by ID
Purpose: Validate the parent exists and get its Area Path and Iteration Path
```

**Priority order for parent resolution:**
1. User-specified parent ID (explicit)
2. Ad-hoc parent work item in the current iteration (default)
3. If neither is found, ask the user

**Important:** Once the parent is identified, inherit its:
- Area Path
- Iteration Path (unless overridden)

#### 4d: Area Path

Resolve area path in this priority order:
1. Inherited from Ad-hoc parent or user-specified parent work item
2. Explicitly specified by user
3. Inferred from the topic/domain of the task
4. Default team area path

### Step 5: Create the Task in ADO

```text
Tool: activate_azure_devops_work_item_management_tools -> create work item
Parameters:
  project: "<project from config/user-context.yaml>"
  type: "Task"
  title: [extracted title]
  description: [HTML-formatted description — see template below]
  assignedTo: [resolved user]
  areaPath: [inherited from Ad-hoc parent]
  iterationPath: [current iteration]
  tags: [semicolon-separated tags]
```

**Then immediately set Story Points and Effort:**
```text
Tool: mcp_microsoft_azu_wit_update_work_items_batch
Parameters:
  updates:
    - id: [newly created task ID]
      path: "/fields/Microsoft.VSTS.Scheduling.StoryPoints"
      value: "1"
    - id: [newly created task ID]
      path: "/fields/Microsoft.VSTS.Scheduling.Effort"
      value: "8"
```

> **Defaults:** Story Points = 1, Effort = 8 hours. Override only if the user explicitly provides different values.

#### Task Description Template — What / When / Who (HTML)

Every task description **must** follow this structure:

```html
<div>
  <h2>What</h2>
  <p>[Clear description of what needs to be done and why]</p>
  <ul>
    <li>[Specific deliverable or action 1]</li>
    <li>[Specific deliverable or action 2]</li>
  </ul>
  
  <h2>When</h2>
  <p><strong>Created:</strong> [date task was created]</p>
  <p><strong>Deadline:</strong> [deadline if mentioned, otherwise "End of current sprint"]</p>
  <p><strong>Source Event:</strong> [Meeting name / Chat / Email] on [date]</p>
  
  <h2>Who</h2>
  <p><strong>Owner:</strong> [Assigned person]</p>
  <p><strong>Stakeholders:</strong> [Names of people involved in the discussion]</p>
  <p><strong>Raised by:</strong> [Person who raised the action item, if known]</p>
</div>
```

### Step 6: Add Comment with Meeting/Action Item Context

**This step is mandatory.** After creating the task, add a comment documenting the source meetings and action items:

```text
Tool: mcp_microsoft_azu_wit_add_work_item_comment
Parameters:
  project: "<project from config/user-context.yaml>"
  workItemId: [newly created task ID]
  comment: [HTML-formatted comment — see template below]
  format: "html"
```

#### Comment Template (HTML)

```html
<div>
  <h3>📝 Task Created from Context</h3>
  
  <h4>Source Meeting(s)</h4>
  <ul>
    <li><strong>[Meeting Name]</strong> — [Date], Attendees: [Name1, Name2, Name3]</li>
    <li><strong>[Meeting Name 2]</strong> — [Date], Attendees: [Names] (if multiple meetings)</li>
  </ul>
  
  <h4>Action Items Addressed</h4>
  <ul>
    <li>✅ [Action item 1 — what was decided and who owns it]</li>
    <li>✅ [Action item 2 — what was decided and who owns it]</li>
  </ul>
  
  <h4>Additional Context</h4>
  <p>[Any relevant notes from Teams chats, emails, or Copilot conversations that informed this task]</p>
  
  <p><em>Created by: GitHub Copilot Skill — [current date]</em></p>
</div>
```

### Step 7: Link to Ad-hoc Parent Work Item

Link the task as a **child** of the Ad-hoc parent (or user-specified parent):

```text
Tool: mcp_microsoft_azu_wit_work_items_link
Parameters:
  project: "<project from config/user-context.yaml>"
  updates:
    - id: [newly created task ID]
      linkToId: [Ad-hoc parent work item ID]
      type: "parent"
```

> **Note:** This step ensures the task appears on the sprint board under the correct parent.

### Step 8: Confirm Creation and Summarize

After creating all tasks, present a summary table to the user:

```markdown
## Tasks Created

| # | ID | Title | Assigned To | Parent | Iteration | Story Pts | Effort | Priority |
|---|-----|-------|------------|--------|-----------|-----------|--------|----------|
| 1 | [ID] | [Title] | [Person] | [Ad-hoc Parent ID] | [Iteration] | 1 | 8h | [P1/P2/P3] |
| 2 | [ID] | [Title] | [Person] | [Ad-hoc Parent ID] | [Iteration] | 1 | 8h | [P1/P2/P3] |

**Source:** [Meeting name / Chat with X / Email thread about Y]
**Created on:** [Date]
```

---

## Multi-Task Batch Creation

When multiple tasks are extracted from a single context (e.g., meeting action items), create them sequentially and track each:

1. Extract all tasks first — present the full list to the user
2. Ask for confirmation: *"I found [N] actionable tasks. Shall I create all of them, or would you like to modify the list?"*
3. Create each task one by one using the ADO tools
4. Link all tasks to the same parent if applicable
5. Present the summary table

---

## Tag Guidelines

Apply tags consistently based on task content:

| Condition | Tag |
|-----------|-----|
| Involves Fabric/Lakehouse work | `Fabric` |
| Involves Power BI reports or semantic models | `Power-BI` |
| Involves Python notebooks or scripts | `Python` |
| Involves SQL queries or stored procedures | `SQL` |
| Involves data pipeline work | `Data-Engineering` |
| Involves report design or visualization | `Reporting` |
| Involves infrastructure or DevOps | `Infrastructure` |
| Originated from a meeting | `Meeting-Action-Item` |
| Originated from a Teams chat | `Chat-Follow-Up` |
| Originated from an email | `Email-Follow-Up` |

---

## Priority Inference Rules

| Signal in Context | Inferred Priority | ADO Priority |
|-------------------|-------------------|--------------|
| "ASAP", "blocker", "urgent", "critical", "P0" | Critical | 1 |
| "high priority", "important", "this sprint", "P1" | High | 1 |
| "should", "plan for", "next sprint", "P2" | Medium | 2 |
| "nice to have", "consider", "eventually", "P3" | Low | 3 |
| No urgency signal | Default Medium | 2 |

---

## Handling Ambiguity

| Situation | Resolution |
|-----------|------------|
| Task owner unclear | Assign to current user; add comment noting it needs reassignment |
| Parent work item unknown | Find the Ad-hoc parent in the current iteration; if not found, ask user |
| Iteration unclear | Use current active iteration via `mcp_microsoft_azu_work_list_team_iterations` |
| Multiple possible parents | Present options and ask user to choose |
| Vague action item | Ask user to clarify before creating; do not guess |
| Duplicate task suspected | Search existing work items first; warn user if a match is found |
| Ad-hoc parent not found | Search with alternate terms ("Ad-hoc", "Adhoc", "Ad hoc"); if still not found, ask user for parent ID |

### Duplicate Detection

Before creating a task, search for potential duplicates:

```text
Tool: activate_azure_devops_project_management_tools -> search work items
Query: [task title keywords]
Project: <project from config/user-context.yaml>
```

If a potential duplicate is found, present it to the user:
> "I found an existing work item **#[ID]: [Title]** that may cover this. Should I skip this task, or create it anyway?"

---

## Example Scenarios

### Scenario 1: Tasks from a Meeting

**User:** "Create tasks from my standup meeting today"

**Execution:**
1. Query WorkIQ: *"What were the action items from my standup meeting today?"*
2. Pull calendar event for attendees and meeting name
3. Extract tasks like:
   - "Investigate data discrepancy in staging charge amounts" → Assigned to Alice
   - "Update Silver layer notebook for new schema fields" → Assigned to Bob
   - "Review PR #312 for validation framework changes" → Assigned to Carol
4. Resolve current iteration
5. Find the Ad-hoc parent in the current iteration
6. Create 3 tasks in ADO under configured project, each with Story Points=1, Effort=8h
7. Add comment to each task citing the standup meeting and specific action items
8. Link all tasks as children of the Ad-hoc parent
9. Present summary table

### Scenario 2: Task from a Teams Chat

**User:** "Create a task from my chat with Bob about the Bronze pipeline"

**Execution:**
1. List chats filtering by Bob's UPN and topic "Bronze pipeline"
2. Read recent messages to extract the discussed task
3. Extract: "Add error handling for null partition keys in Bronze_DataProcessing_Pipeline"
4. Create task in ADO, assigned to current user
5. Tag with `Fabric`, `Data-Engineering`, `Python`

### Scenario 3: Task from Copilot Conversation

**User:** "Create a task for what we just discussed"

**Execution:**
1. Review current Copilot chat history
2. Identify the technical topic — e.g., "Refactor workspace_item_utilities.py to support incremental deployment retries"
3. Create task with technical description from the conversation
4. Tag with `Python`, `Infrastructure`, `Enhancement`

### Scenario 4: Direct Task with Parent

**User:** "Create a task under user story 12345 to add unit tests for the validation framework"

**Execution:**
1. Fetch parent work item #12345 to get Area Path and Iteration Path
2. Create task: "Add unit tests for validation framework" with What/When/Who description
3. Set Story Points=1, Effort=8h
4. Inherit Area Path and Iteration from parent
5. Link as child of #12345
6. Add comment citing the conversation context
7. Tag with `Python`, `Testing`

---

## Troubleshooting

| Issue | Resolution |
|-------|------------|
| No meetings found | Broaden the date range or ask user for meeting name |
| Teams chat not found | Ask user for the person's name/UPN or chat topic |
| ADO work item creation fails | Verify project name, check permissions, validate field values |
| Cannot resolve person to ADO user | Ask user for the ADO display name or email |
| Parent work item not found | Verify the ID and project; ask user to double-check |
| WorkIQ returns no action items | Try querying with different phrasing; fall back to calendar/chat tools |
| Cannot determine iteration | List available iterations and ask user to select |

---

## Notes

- **Always confirm before bulk creation**: When extracting multiple tasks, show the list and get user approval before creating
- **Preserve context**: Always include the source (meeting/chat/email) in the task description
- **Use consistent formatting**: Follow the HTML description template for proper ADO rendering
- **Link related tasks**: If multiple tasks come from the same source, consider linking them under a common parent
- **Default project is resolved from `config/user-context.yaml`**: Only ask about project if user explicitly mentions a different one
- **Always set Story Points and Effort**: Default to Story Points=1, Effort=8 hours on every task
- **Always add a comment**: Every task must have a comment citing the source meetings and action items
- **Always parent under Ad-hoc**: Default parent is the Ad-hoc work item in the current iteration
- **Description must use What/When/Who format**: Every description must follow the structured template
- **Respect existing assignments**: If context mentions a specific person as the owner, assign to them
- **Add source tag**: Always tag tasks with their origin (`Meeting-Action-Item`, `Chat-Follow-Up`, etc.)
