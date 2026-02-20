# Copilot Agents

GitHub Copilot **agents** and **skills** for Fabric DevOps, Databricks DevOps, Azure DevOps work-item management, M365 productivity, and board compliance. One orchestrator agent delegates to specialist subagents.

## Quick Start

```powershell
git clone <repo-url> copilot-agents
cd copilot-agents
.\setup.ps1
code .
```

Then chat: `@orchestrator Daily triage`

See the [Setup Guide](docs/4-Setup-Guide.md) for full configuration steps.

## Documentation

| # | Page | Description |
|---|------|-------------|
| 1 | [Why Agentic?](docs/1-Why.md) | Motivation, five pillars, mental model shift |
| 2 | [Architecture](docs/2-Architecture.md) | Three-layer design, agents, skills, MCP servers, extensibility |
| 3 | [Use Cases & ROI](docs/3-Use-Cases-and-ROI.md) | 8 real workflows with before/after comparisons (~9.4 hrs/week saved) |
| 4 | [Setup Guide](docs/4-Setup-Guide.md) | Prerequisites, installation, configuration, verification |

## Agents

| Agent | Purpose |
|-------|---------|
| **Orchestrator** | Single entrypoint — routes to specialists |
| **Chief of Staff** | M365 triage, status emails, meeting prep, comms drafts |
| **ADO DevOps** | ADO work items, compliance, board hygiene, test cases |
| **Fabric DevOps** | Full Fabric lifecycle (develop, monitor, validate, promote) |
| **Databricks DevOps** | Full Databricks lifecycle (notebooks, jobs, clusters, CI/CD) |

## Skills

| Skill | Agent | Domain |
|-------|-------|--------|
| Daily Status Email | Chief of Staff | Auto-generated status → manager |
| Create Task | ADO DevOps | M365 signals → ADO tasks |
| Update User Story | ADO DevOps | Reference docs → enriched ADO stories |
| Board Hygiene Audit | ADO DevOps | 28-point compliance check, scored report, auto-fix |
| Fabric DevOps (7 capabilities) | Fabric DevOps | Develop, Monitor, Diagnostics, Validate, Lineage, Testing, Promote |
| Databricks DevOps (7 capabilities) | Databricks DevOps | Develop, Monitor, Diagnostics, Validate, Data Ops, Security, Promote |

## Contributing

1. Create a feature branch from `main`
2. Add or update agents/skills following existing patterns
3. Test in VS Code Copilot Chat
4. Submit a PR
