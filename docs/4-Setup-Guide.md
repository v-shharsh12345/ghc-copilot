# Setup Guide

## Prerequisites

| Requirement | Purpose | Install |
|---|---|---|
| **Node.js 18+** | Runs npm-based MCP servers | [nodejs.org](https://nodejs.org) (LTS) |
| **Azure CLI** | Auth for Fabric and Power BI APIs | [Install Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) |
| **VS Code** | Host for Copilot agents | [code.visualstudio.com](https://code.visualstudio.com) |
| **GitHub Copilot** | Agent execution engine | `code --install-extension GitHub.copilot` |
| **GitHub Copilot Chat** | Chat interface for agents | `code --install-extension GitHub.copilot-chat` |
| **SQL Server extension** | MSSQL tools for Fabric DevOps | `code --install-extension ms-mssql.mssql` |

## Quick Start

```powershell
# 1. Clone and setup
git clone <repo-url> copilot-agents
cd copilot-agents
.\setup.ps1

# 2. Open in VS Code
code .
```

The setup script will:
- Verify Node.js, npm, and Azure CLI are installed
- Check that required VS Code extensions are present
- Pre-cache all npm-based MCP server packages
- Create `config/user-context.yaml` from the template if it doesn't exist
- Validate the workspace MCP configuration

## Configuration

### Step 1: Personal Context

Edit `config/user-context.yaml` with your details:

```yaml
user:
  displayName: "Your Name"
  email: "you@contoso.com"

statusEmail:
  recipient: "manager@contoso.com"
  subjectPrefix: "Your Name"
  autoSend: true

ado:
  organization: "dev.azure.com/your-org"
  projects:
    taskCreation:
      name: "YourProject"
      defaultAreaPath: "YourProject\\YourTeam"
  team: "Your Team Name"
```

### Step 2: Fabric Workspace IDs

Edit `.github/skills/fabric-devops/config/workspace-catalog.yaml` with your workspace GUIDs:

```yaml
workspaces:
  DEV:
    id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    name: "DEV-Workspace"
  UAT:
    id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    name: "UAT-Workspace"
  PROD:
    id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    name: "PROD-Workspace"
    writeAllowed: false
```

### Step 3: Semantic Model Dataset IDs

Edit `.github/skills/compare-semantic-models/dataset-catalog.yaml` with your dataset GUIDs per environment.

### Step 4: First-Use Prompts

On first use, VS Code will prompt you for:

| Input | Description |
|---|---|
| Azure DevOps org | Your ADO organization name |
| ADO domains | Which domains to enable (core, work-items, etc.) |
| Team name | Your primary ADO team |
| Power Platform Environment ID | For M365 MCP tools |
| Context7 API key | For library documentation lookup |

## Verify Setup

After completing configuration, test with these prompts in Copilot Chat:

```
@orchestrator Daily triage
@orchestrator What's the health of my DEV workspace?
@chief-of-staff Create a task for testing the setup
```

## Repository Structure

```
copilot-agents/
├── README.md                          ← Landing page
├── setup.ps1                          ← Setup script
├── config/
│   └── user-context.yaml              ← Your personal config (gitignored)
├── docs/                              ← Documentation
│   ├── 1-Why.md
│   ├── 2-Architecture.md
│   ├── 3-Use-Cases-and-ROI.md
│   └── 4-Setup-Guide.md              ← You are here
├── .vscode/
│   └── mcp.json                       ← MCP server config (auto-discovered)
└── .github/
    ├── agents/                        ← Agent definitions
    │   ├── orchestrator.agent.md
    │   ├── chief-of-staff.agent.md
    │   ├── fabric-devops.agent.md
    │   └── databricks-devops.agent.md
    └── skills/                        ← Skill definitions + config
        ├── create-task/
        ├── daily-status-email/
        ├── update-user-story/
        ├── compare-semantic-models/
        ├── fabric-devops/             ← Shared resource layer
        ├── fabric-devops-*/           ← Capability skills
        └── databricks-devops-*/       ← Capability skills
```

## MCP Server Reference

| Server | Type | Used By |
|---|---|---|
| **Azure DevOps** | stdio (npx) | Chief of Staff |
| **Playwright** | stdio (npx) | Browser automation |
| **WorkIQ** | stdio (npx) | Chief of Staff (M365 signals) |
| **Context7** | stdio (npx) | Fabric DevOps (library docs) |
| **Mail / Calendar / Teams** | HTTP | Chief of Staff, Create Task |
| **Power BI Remote** | HTTP | Semantic model queries |
| **Microsoft Docs** | HTTP | Fabric DevOps |

> HTTP-based servers require no local install — they connect directly to cloud endpoints. npm-based servers are downloaded automatically by npx on first use.

## Adding New Components

| Want To... | Do This |
|---|---|
| Add a new agent | Create `.github/agents/<name>.agent.md` |
| Add a new skill | Create `.github/skills/<name>/SKILL.md` |
| Add a new MCP server | Add entry to `.vscode/mcp.json` |
| Add a workspace | Edit `skills/fabric-devops/config/workspace-catalog.yaml` |

## Contributing

1. Create a feature branch from `main`
2. Add or update agents/skills following existing patterns
3. Test in VS Code Copilot Chat
4. Submit a PR
