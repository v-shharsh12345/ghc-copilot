# Update User Story Skill

## Overview

The **update-user-story** skill updates Azure DevOps user stories in the configured ADO project based on referenced materials — documents, conversations, specifications, and meeting notes. It enriches stories with detailed descriptions, acceptance criteria, comments, and tags.

## Key Capabilities

| Capability | Description |
|------------|-------------|
| **Description enrichment** | Converts reference materials into structured functional/technical requirements |
| **Acceptance criteria** | Generates testable Given/When/Then acceptance criteria |
| **Implementation comments** | Adds comments with technical details and clarifications |
| **Smart tagging** | Applies category, technology, and priority tags |
| **Multi-source context** | Processes documents, Copilot chat, specifications, and meeting notes |

## Example Invocations

```
"Update user story 12345 with the requirements from our last meeting"
"Add acceptance criteria to story 67890 based on the BRD"
"Enrich story [ID] with implementation details from today's discussion"
"Tag user story [ID] with the correct area tags"
```

## Required MCP Servers

- **ADO MCP Server** — Read/update work items in OneMW project
- **WorkIQ** — Extract meeting notes and context (optional)
- **Mail MCP Server** — Pull email threads for requirements context (optional)

## Workflow

1. **Retrieve** the existing user story by ID from OneMW project
2. **Gather context** from all referenced materials (documents, chat, specs, meetings)
3. **Organize** extracted information into functional requirements, technical requirements, and constraints
4. **Update description** with structured requirements using HTML formatting
5. **Add/update acceptance criteria** in Given/When/Then format
6. **Apply tags** for categorization (component, technology, priority)
7. **Add comment** with implementation details and source references
8. **Verify** the update was applied correctly

## Source File

[.github/skills/update-user-story/SKILL.md](../../.github/skills/update-user-story/SKILL.md)
