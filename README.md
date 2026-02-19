# Copilot Agents

A centralized repository for GitHub Copilot **agents** and **skills**. These agents extend GitHub Copilot Chat in VS Code with domain-specific capabilities for Fabric DevOps, Azure DevOps work-item management, M365 productivity, and data quality validation.

Current architecture uses one orchestrator agent that delegates to specialist subagents.

---

## Quick Start

### Prerequisites

| Requirement | Purpose | Install |
|-------------|---------|---------|
| **Node.js 18+** | Runs npm-based MCP servers via npx | [nodejs.org](https://nodejs.org) (LTS) |
| **Azure CLI** | Auth for Fabric and Power BI APIs | [Install Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) |
| **VS Code** | Host for Copilot agents | [code.visualstudio.com](https://code.visualstudio.com) |
| **GitHub Copilot extension** | Runs agents and skills | `code --install-extension GitHub.copilot` |
| **GitHub Copilot Chat extension** | Chat interface for agents | `code --install-extension GitHub.copilot-chat` |
| **SQL Server extension** | MSSQL tool for Fabric DevOps | `code --install-extension ms-mssql.mssql` |

### Setup (New User)

```powershell
# 1. Clone the repo
git clone <repo-url> copilot-agents
cd copilot-agents

# 2. Run the setup script (checks prerequisites, pre-caches MCP packages)
.\setup.ps1

# 3. Open in VS Code
code .
```

The setup script will:
- Verify Node.js, npm, and Azure CLI are installed
- Check that required VS Code extensions are present
- Pre-cache all npm-based MCP server packages (`@azure-devops/mcp`, `@playwright/mcp`, `@microsoft/workiq`, `@upstash/context7-mcp`)
- Validate the workspace MCP configuration

### What Happens After Setup

1. VS Code auto-discovers MCP servers from `.vscode/mcp.json` (workspace-level config).
2. Copilot auto-discovers agents from `.github/agents/` and skills from `.github/skills/`.
3. On **first use**, VS Code will prompt you for configurable values:
   - **Azure DevOps org** — your ADO organization name
   - **ADO domains** — which domains to enable (core, work-items, repositories, etc.)
   - **Team name** — your primary ADO team
   - **Power Platform Environment ID** — for M365 MCP tools
   - **Context7 API key** — for library documentation lookup
4. Copy `config/user-context.template.yaml` to `config/user-context.yaml` and fill in your personal and project context.
5. Fill in workspace IDs in `.github/skills/fabric-devops/config/workspace-catalog.yaml`.
6. Fill in dataset IDs in `.github/skills/compare-semantic-models/dataset-catalog.yaml`.
7. Invoke an agent in Copilot Chat — e.g., `@orchestrator Daily triage`.

> **Note**: HTTP-based MCP servers (Power BI Remote, Microsoft Docs, M365 tools) require no local install — they connect directly to cloud endpoints. The npm-based servers are downloaded automatically by npx on first use if not pre-cached.

### Personalization

All personal and project-specific configuration is stored in `config/user-context.yaml` (gitignored). This keeps the repo clean and shareable while letting each user maintain their own context.

```powershell
# Copy the template
cp config/user-context.template.yaml config/user-context.yaml

# Edit with your values
code config/user-context.yaml
```

**What to configure:**

| File | What Goes There |
|------|-----------------|
| `config/user-context.yaml` | Your name, email, ADO project, team members, business domain terms |
| `.github/skills/fabric-devops/config/workspace-catalog.yaml` | Your Fabric workspace GUIDs for DEV/UAT/PROD |
| `.github/skills/compare-semantic-models/dataset-catalog.yaml` | Your semantic model dataset GUIDs per environment |

Agents and skills read `config/user-context.yaml` at runtime for personal context (names, emails, ADO defaults, etc.) and the catalog files for Fabric workspace and dataset IDs.

---

## Repository Structure

```
copilot-agents/
├── README.md                          ← You are here
├── setup.ps1                          ← Run after cloning to install dependencies
├── .gitignore
├── config/
│   └── user-context.template.yaml     ← Copy to user-context.yaml and fill in your values
├── .vscode/
│   └── mcp.json                       ← Workspace-level MCP server config (auto-discovered)
└── .github/
    ├── agents/                        ← Agent definitions (*.agent.md)
    │   ├── orchestrator.agent.md
    │   ├── chief-of-staff.agent.md
    │   ├── fabric-devops.agent.md
    │   └── semantic-model-comparator.agent.md
    └── skills/                        ← Skill definitions (SKILL.md + config)
        ├── compare-semantic-models/
        │   ├── SKILL.md
        │   ├── dataset-catalog.yaml
        │   └── comparison-queries.md
        ├── create-task/
        │   └── SKILL.md
        ├── daily-status-email/
        │   └── SKILL.md
        ├── fabric-devops/                  ← Shared resource layer
        │   ├── SKILL.md
        │   ├── config/
        │   │   ├── execution-router.yaml
        │   │   ├── intent-router.yaml
        │   │   └── workspace-catalog.yaml
        │   └── modules/
        │       ├── analyze-lineage.md
        │       ├── capability-matrix.md
        │       ├── develop.md
        │       ├── execution-routing.md
        │       ├── lakehouse-diagnostics.md
        │       ├── operate-monitor.md
        │       ├── release-promote.md
        │       ├── runtime-checks.md
        │       ├── safety-guardrails.md
        │       ├── semantic-model-testing.md
        │       └── validate.md
        ├── fabric-devops-develop/          ← Capability skill
        │   └── SKILL.md
        ├── fabric-devops-operate-monitor/  ← Capability skill
        │   └── SKILL.md
        ├── fabric-devops-lakehouse-diagnostics/ ← Capability skill
        │   └── SKILL.md
        ├── fabric-devops-validate/         ← Capability skill
        │   └── SKILL.md
        ├── fabric-devops-semantic-model-testing/ ← Capability skill
        │   └── SKILL.md
        ├── fabric-devops-analyze-lineage/  ← Capability skill
        │   └── SKILL.md
        ├── fabric-devops-release-promote/  ← Capability skill
        │   └── SKILL.md
        └── update-user-story/
            └── SKILL.md
```

---

## Agents

### 0. Orchestrator (`orchestrator`)

| | |
|---|---|
| **File** | `.github/agents/orchestrator.agent.md` |
| **Purpose** | Single entrypoint that routes requests to the right specialist subagent |
| **Version** | 1.1 (Feb 2026) |

**What it does:**

- Delegates PM/M365/ADO execution work to `chief-of-staff`
- Delegates Fabric engineering and testing work to `fabric-devops`
- Runs subagents in parallel for multi-domain tasks and synthesizes one response

**Subagents managed:**

- `chief-of-staff`
- `fabric-devops`

### 1. Chief of Staff (`chief-of-staff`)

| | |
|---|---|
| **File** | `.github/agents/chief-of-staff.agent.md` |
| **Purpose** | Personal productivity and execution agent for the Microsoft 365 ecosystem |
| **Version** | 3.0 (Jan 2026) |

**What it does:**

- Triages signals from Outlook, Teams, Calendar, and Azure DevOps
- Connects dots across emails, chats, meetings, and work items
- Generates daily briefings, meeting prep, and status updates
- Creates and updates ADO User Stories, Tasks, and Bugs
- Drafts and sends status emails

**Key commands:**

| Command | Action |
|---------|--------|
| `Daily triage` | Morning briefing with priorities, risks, and meetings |
| `What changed since yesterday?` | Delta summary of notable changes |
| `Prep me for my next meeting` | Agenda, context, and talking points |
| `Draft my status mail` | Two-section status update email |
| `Create user story for [topic]` | Create ADO User Story with proper fields |
| `Create task for [topic]` | Create ADO Task under Ad-hoc parent |
| `Convert action items to ADO` | Parse meeting/chat and create work items |

**MCP servers used:** WorkIQ, Azure DevOps, Mail Tools

---

### 2. Fabric DevOps (`fabric-devops`)

| | |
|---|---|
| **File** | `.github/agents/fabric-devops.agent.md` |
| **Purpose** | End-to-end Fabric lifecycle management across DEV/UAT/PROD |
| **Version** | 1.7 (Feb 2026) |

**What it does:**

- Acts as a thin dispatcher that activates self-declaring capability skills
- Each capability skill declares its own intent triggers, engine preference, and procedure
- The agent reads skill declarations and routes to the matching skill

**Capability skills:**

| Skill | Domain |
|-------|--------|
| `fabric-devops-develop` | Build/update items |
| `fabric-devops-operate-monitor` | Inventory, monitoring, health |
| `fabric-devops-lakehouse-diagnostics` | Lakehouse failure diagnostics |
| `fabric-devops-validate` | Cross-environment validation |
| `fabric-devops-semantic-model-testing` | Schema/data parity testing |
| `fabric-devops-analyze-lineage` | Data lineage analysis |
| `fabric-devops-release-promote` | Lifecycle promotion |

**Safety:** Write operations are **prohibited** on PROD workspaces. PROD access is read-only.

**MCP servers used:** Fabric MCP, Teams, MSSQL, Context7

---

### 3. Semantic Model Comparator (`semantic-model-comparator`)

| | |
|---|---|
| **File** | `.github/agents/semantic-model-comparator.agent.md` |
| **Purpose** | Legacy compatibility agent (deprecated) |
| **Version** | Deprecated |

**Status:**

- Semantic model comparison is now part of `fabric-devops` as a repeatable workflow.
- Keep this agent only for backward compatibility.

**Thresholds:**

| Check | Warning | Error |
|-------|---------|-------|
| Row Count Variance | >5% | >20% |
| Metric Variance | >0.1% | >1% |
| Data Freshness | PROD 1+ day behind | PROD 3+ days behind |
| Schema Drift | New columns in lower env | Missing columns in lower env |

**Configuration:** Dataset IDs are managed in `skills/compare-semantic-models/dataset-catalog.yaml`.

**MCP servers used:** Power BI Remote

---

## Skills

Skills are reusable instruction sets that agents (or Copilot directly) can invoke to perform specific tasks.

### 1. Create Task (`create-task`)

| | |
|---|---|
| **File** | `.github/skills/create-task/SKILL.md` |
| **Purpose** | Extract actionable tasks from M365 signals and create structured ADO work items |
| **Version** | 1.1 (Feb 2026) |

Gathers context from WorkIQ (meetings, emails, Teams chats) and Copilot conversations, then creates ADO Tasks with:
- **What / When / Who** structured descriptions
- Automatic Ad-hoc parent resolution in the current sprint
- Story Points (1) and Effort (8h) defaults
- Mandatory source-citing comments
- Duplicate detection before creation

---

### 2. Daily Status Email (`daily-status-email`)

| | |
|---|---|
| **File** | `.github/skills/daily-status-email/SKILL.md` |
| **Purpose** | Generate and send a professional end-of-day status email |
| **Version** | 1.1 (Jan 2026) |

Pulls context from WorkIQ (calendar, email, Teams) and Copilot chat history to produce:
- **Tasks Completed** section with action-verb-led bullet points
- **Key Meetings** table with attendees and follow-up tasks
- Auto-sends via Mail MCP to the configured manager email

---

### 3. Update User Story (`update-user-story`)

| | |
|---|---|
| **File** | `.github/skills/update-user-story/SKILL.md` |
| **Purpose** | Enrich ADO User Stories with detailed requirements from reference materials |
| **Version** | 1.0 |

Processes documents, conversations, and specifications to update:
- Description (Overview, Background, Requirements, Dependencies)
- Acceptance Criteria (Given-When-Then format)
- Tags (technology, priority, domain)
- Implementation comments with source citations

---

### 4. Fabric DevOps (`fabric-devops`)

| | |
|---|---|
| **File** | `.github/skills/fabric-devops/SKILL.md` |
| **Purpose** | Shared resource layer providing workspace catalog, engine definitions, safety guardrails, and procedure modules |
| **Version** | 4.0 (Feb 2026) |

Houses shared resources consumed by 7 capability skills. Each capability skill self-declares its intent triggers, engine preference, and procedure. The parent skill does not route — it provides:
- `config/workspace-catalog.yaml` — workspace IDs and connection strings
- `config/execution-router.yaml` — engine definitions and fallback policy
- `modules/safety-guardrails.md` — universal safety rules
- `modules/*.md` — canonical procedure modules consumed by skills

### 4a–4g. Fabric DevOps Capability Skills

| Skill | File | Purpose |
|-------|------|---------|
| `fabric-devops-develop` | `.github/skills/fabric-devops-develop/SKILL.md` | Build/update Fabric items in non-PROD |
| `fabric-devops-operate-monitor` | `.github/skills/fabric-devops-operate-monitor/SKILL.md` | Inventory, job monitoring, health |
| `fabric-devops-lakehouse-diagnostics` | `.github/skills/fabric-devops-lakehouse-diagnostics/SKILL.md` | Lakehouse failure diagnostics |
| `fabric-devops-validate` | `.github/skills/fabric-devops-validate/SKILL.md` | Cross-environment validation |
| `fabric-devops-semantic-model-testing` | `.github/skills/fabric-devops-semantic-model-testing/SKILL.md` | Schema/row count/metric/freshness parity |
| `fabric-devops-analyze-lineage` | `.github/skills/fabric-devops-analyze-lineage/SKILL.md` | Table/column/report lineage analysis |
| `fabric-devops-release-promote` | `.github/skills/fabric-devops-release-promote/SKILL.md` | Lifecycle promotion DEV→UAT→PROD |

Each skill is a single SKILL.md file that declares its own intent, engine preference, and procedure reference.

---

### 5. Compare Semantic Models (`compare-semantic-models`)

| | |
|---|---|
| **File** | `.github/skills/compare-semantic-models/SKILL.md` |
| **Purpose** | DAX-based cross-environment semantic model comparison |
| **Version** | 1.0 |

Provides reusable DAX query patterns and a dataset catalog for comparing schemas, row counts, metrics, and data freshness. Supporting files:
- `dataset-catalog.yaml` — Dataset IDs by environment (DEV/UAT/PROD)
- `comparison-queries.md` — Reusable DAX patterns for row counts, metrics, freshness, key coverage

This skill is consumed by the `fabric-devops` semantic model testing module.

---

## MCP Server Setup

All MCP servers are configured in [.vscode/mcp.json](.vscode/mcp.json) at the workspace level — **no manual `settings.json` editing is needed**. The setup script pre-caches npm packages so first-run is faster.

### Server Reference

| MCP Server | Type | Package / URL | Used By |
|------------|------|---------------|---------|
| **Azure DevOps** (`microsoft/azure-devops-mcp`) | stdio (npx) | `@azure-devops/mcp@latest` | Chief of Staff, Create Task, Update User Story |
| **Playwright** (`microsoft/playwright-mcp`) | stdio (npx) | `@playwright/mcp@latest` | Browser automation, Power BI report testing |
| **WorkIQ** (`workiq`) | stdio (npx) | `@microsoft/workiq` | Chief of Staff, Daily Status Email, Create Task |
| **Context7** (`io.github.upstash/context7`) | stdio (npx) | `@upstash/context7-mcp@1.0.31` | Fabric DevOps (library docs lookup) |
| **Mail Tools** (`mcp_MailTools`) | http | `agent365.svc.cloud.microsoft` | Chief of Staff, Daily Status Email |
| **Calendar Tools** (`mcp_CalendarTools`) | http | `agent365.svc.cloud.microsoft` | Chief of Staff |
| **Teams** (`mcp_TeamsServer`) | http | `agent365.svc.cloud.microsoft` | Fabric DevOps, Create Task |
| **M365 Copilot** (`mcp_M365Copilot`) | http | `agent365.svc.cloud.microsoft` | Chief of Staff |
| **Word** (`mcp_WordServer`) | http | `agent365.svc.cloud.microsoft` | Chief of Staff |
| **NL2DAB** (`nl2dab-mcp-server`) | http | Azure Container Apps endpoint | Natural language to data queries |
| **Power BI Remote** (`powerbi-remote`) | http | `api.fabric.microsoft.com` | Semantic Model Comparator, Fabric DevOps |
| **Microsoft Docs** (`microsoftdocs/mcp`) | http | `learn.microsoft.com` | Fabric DevOps (documentation search) |

### Configurable Inputs

These values are prompted on first use (stored per-workspace by VS Code):

| Input | Description | Default |
|-------|-------------|---------|
| `ado_org` | Azure DevOps organization name | _(none — must provide)_ |
| `ado_domain` | ADO domains to enable | _(none — must provide)_ |
| `ado_team1` | Primary team name | _(none — must provide)_ |
| `environment_id` | Power Platform Environment ID | _(none — must provide)_ |
| `CONTEXT7_API_KEY` | Context7 API key (secret) | _(none — must provide)_ |

### VS Code Extensions Required

| Extension | ID | Purpose |
|-----------|----|---------|
| GitHub Copilot | `GitHub.copilot` | Agent execution engine |
| GitHub Copilot Chat | `GitHub.copilot-chat` | Chat interface for invoking agents |
| SQL Server (mssql) | `ms-mssql.mssql` | Provides MSSQL MCP tools for Fabric DevOps |

---

## Adding a New Agent

1. Create a new `.agent.md` file in `.github/agents/`.
2. Define the YAML front matter (`name`, `description`, `tools`).
3. Write the agent instructions in Markdown below the front matter.
4. If the agent needs a reusable skill, create a folder under `.github/skills/` with a `SKILL.md`.
5. Update this README with the agent's documentation.

## Adding a New Skill

1. Create a folder under `.github/skills/<skill-name>/`.
2. Add a `SKILL.md` with YAML front matter (`name`, `description`).
3. Add any supporting config files (`.yaml`, `.md`) in the same folder.
4. Reference the skill from agents that need it.
5. Update this README.

---

## Contributing

1. Create a feature branch from `main`.
2. Add or update agents/skills following the patterns above.
3. Test the agent in VS Code Copilot Chat.
4. Submit a PR with a description of what changed and why.

---

## Version History

| Date | Change |
|------|--------|
| 2026-02-18 | Initial repository created; consolidated agents and skills into a reusable template |
