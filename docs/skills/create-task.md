# Create Task Skill

## Overview

The **create-task** skill extracts actionable tasks from Microsoft 365 signals — meetings, Teams chats, Outlook emails, and Copilot conversations — and creates Azure DevOps work items with proper fields, assignments, and parent-child relationships.

## Key Capabilities

| Capability | Description |
|------------|-------------|
| **Multi-source extraction** | Pulls action items from Calendar, Teams, Outlook, and Copilot chat history |
| **Smart routing** | Automatically determines the correct ADO project, area path, and iteration |
| **Parent resolution** | Links new tasks to parent User Stories (ad-hoc or specified) |
| **Default sizing** | Story Points = 1, Effort = 8h applied automatically |
| **What/When/Who format** | Task descriptions follow a structured template |

## Default Configuration

| Setting | Value |
|---------|-------|
| ADO Project | `PartnerIncentivePlatform-DevOps` |
| Work Item Type | Task (default), Bug, or User Story |
| Story Points | 1 |
| Effort (hours) | 8 |

## Example Invocations

```
"Create tasks from my last meeting"
"Turn my meeting action items into ADO tasks"
"Create a task for [description]"
"Create a task under user story [ID]"
```

## Required MCP Servers

- **ADO MCP Server** — Create/update work items
- **WorkIQ / M365 Copilot** — Extract context from meetings, emails, chats
- **Teams MCP Server** — Read Teams chats/channels
- **Calendar Access** — Retrieve meeting details
- **Mail Access** — Search emails for related context

## Workflow

1. **Gather context** from the specified source (meeting, chat, email, or Copilot history)
2. **Extract action items** — identify tasks with owners, deadlines, and descriptions
3. **Resolve ADO location** — determine project, area path, iteration, and parent
4. **Create work items** — populate all fields using the What/When/Who template
5. **Add mandatory comment** — attach source context as a work item comment
6. **Report results** — return links to created work items

## Source File

[.github/skills/create-task/SKILL.md](../../.github/skills/create-task/SKILL.md)
