# Daily Status Email Skill

## Overview

The **daily-status-email** skill generates a professional end-of-day status email for your manager, summarizing accomplishments, action items, and key meetings. It pulls context from WorkIQ (Outlook, Teams, Calendar) and GitHub Copilot chat history, then **automatically sends** the email.

## Key Capabilities

| Capability | Description |
|------------|-------------|
| **Auto-send** | Email is sent automatically after generation (configurable) |
| **Action Items table** | Structured table of tasks with status, source, and owner |
| **Key Meetings table** | Summary of the day's meetings with decisions and follow-ups |
| **Multi-source context** | Aggregates signals from Calendar, Teams, Outlook, and Copilot |
| **Date flexibility** | Can generate for today or any specified date |

## Default Configuration

| Setting | Value |
|---------|-------|
| Default Recipient | `arnavl@maqsoftware.com` |
| Subject Format | `Arnav Loonker: Daily Status Update as of [MM/DD/YYYY]` |
| Auto-Send | Enabled |

## Example Invocations

```
"Generate my daily status email"
"Draft status update for my manager"
"Daily status for 02/18/2026"
"Summarize today's meetings and actions"
```

## Required MCP Servers

- **WorkIQ MCP Server** — Access Outlook, Teams, Calendar signals
- **Mail MCP Server** — Send the email via `mcp_mcp_mailtools_CreateDraftMessage` / `mcp_mcp_mailtools_SendDraftMessage`
- **GitHub Copilot Chat** — Recent conversation history for coding/technical work

## Workflow

1. **Query WorkIQ** for today's calendar events, email threads, and Teams chats
2. **Review Copilot chat history** for technical work completed
3. **Build Action Items table** — status, description, source, owner
4. **Build Key Meetings table** — meeting name, attendees, decisions, follow-ups
5. **Compose email** in the standard subject/body format
6. **Auto-send** to the configured recipient

## Source File

[.github/skills/daily-status-email/SKILL.md](../../.github/skills/daily-status-email/SKILL.md)
