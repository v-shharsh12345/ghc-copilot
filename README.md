# Copilot Agents

GitHub Copilot **agents** and **skills** for Fabric DevOps, Azure DevOps work-item management, M365 productivity, and data quality validation. One orchestrator agent delegates to specialist subagents.

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
| **Chief of Staff** | M365 triage, ADO work items, status emails |
| **Fabric DevOps** | Full Fabric lifecycle (develop, monitor, validate, promote) |
| **Databricks DevOps** | Full Databricks lifecycle (notebooks, jobs, clusters, CI/CD) |

## Skills

| Skill | Domain |
|-------|--------|
| Create Task | M365 signals → ADO tasks |
| Daily Status Email | Auto-generated status → manager |
| Update User Story | Reference docs → enriched ADO stories |
| Fabric DevOps (7 capabilities) | Develop, Monitor, Diagnostics, Validate, Lineage, Testing, Promote |
| Databricks DevOps (7 capabilities) | Develop, Monitor, Diagnostics, Validate, Data Ops, Security, Promote |
| Compare Semantic Models | DAX-based cross-environment model comparison |

## Contributing

1. Create a feature branch from `main`
2. Add or update agents/skills following existing patterns
3. Test in VS Code Copilot Chat
4. Submit a PR
