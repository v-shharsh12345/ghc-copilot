# Chief of Staff Agent

> **File:** `.github/agents/chief-of-staff.agent.md`
> **Version:** 3.0 (Jan 2026)

## Overview

The **Chief of Staff** is a personal productivity and execution agent that triages Microsoft 365 signals — Outlook, Teams, Calendar, and Azure DevOps — and produces actionable outputs. It acts as a trusted aide-de-camp: connecting dots across communications, surfacing risks, preparing you for meetings, and turning decisions into tracked work items.

## Capabilities

### Signal Triage & Awareness

- Scans recent emails, Teams chats, and calendar events via WorkIQ
- Correlates signals with existing ADO work items to detect stale or at-risk items
- Generates a morning briefing sorted by priority quadrants

### Work Item Management

- Creates ADO User Stories, Tasks, and Bugs in the **OneMW** project
- Auto-resolves the current sprint iteration path and Ad-hoc parent stories
- Applies proper fields: Area Path, Story Points, Effort, Priority, Tags
- Detects duplicates before creation

### Communication Drafting

- Drafts and sends status emails via Mail MCP
- Generates meeting prep docs with agenda, context, and talking points
- Creates follow-up summaries after meetings

## Commands

| Command | Description |
|---------|-------------|
| `Daily triage` | Full morning briefing with priorities, risks, calendar |
| `What changed since yesterday?` | Delta summary of notable M365 + ADO changes |
| `Prep me for my next meeting` | Agenda context, attendees, and talking points |
| `Draft my status mail` | Two-section email (Tasks + Key Meetings) |
| `Create user story for [topic]` | ADO User Story with full fields |
| `Create task for [topic]` | ADO Task under Ad-hoc parent |
| `Convert action items to ADO` | Parse meeting/chat into work items |
| `Update story [ID]` | Enrich existing story from references |

## MCP Servers Required

| Server | Purpose |
|--------|---------|
| WorkIQ | M365 signal search (Outlook, Teams, Calendar) |
| Azure DevOps | Work items, repos, iterations, queries |
| Mail Tools | Send/reply/forward Outlook email |

## Skills Used

- [`create-task`](../skills/create-task.md) — Task creation from M365 signals
- [`daily-status-email`](../skills/daily-status-email.md) — Status email generation
- [`update-user-story`](../skills/update-user-story.md) — User story enrichment

## Key Behaviors

1. **Priority Quadrants** — Items are sorted into P0 (Blocking), P1 (Due today), P2 (Active), P3 (Watching)
2. **Source Citation** — Every work item includes a comment citing the M365 or conversation source
3. **Duplicate Detection** — Searches ADO title+tags before creating new items
4. **Short-Reply Protocol** — Conversational answers are ≤ 3 sentences unless detail is requested

## Configuration

The agent uses the following ADO defaults (configurable in the agent file):

| Setting | Default |
|---------|---------|
| Organization | `msit.visualstudio.com` |
| Project | `OneMW` |
| Area Path | `OneMW\MCAPS\Partner & Customer Programs\US SMS&P\Data & AI\Data_Reporting` |
| Work Item Types | User Story, Task, Bug |
