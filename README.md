# Copilot Agents

GitHub Copilot **agents** and **skills** for Fabric DevOps, Databricks DevOps, Azure DevOps work-item management, Wiki DevOps, M365 productivity, and board compliance. One orchestrator agent delegates to specialist subagents with built-in context verification, write gates, and session checkpointing.

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
| 3 | [Use Cases & ROI](docs/3-Use-Cases-and-ROI.md) | 9 real workflows with before/after comparisons (~9.8 hrs/week saved) |
| 4 | [Setup Guide](docs/4-Setup-Guide.md) | Prerequisites, installation, configuration, verification |

## Agents

| Agent | Purpose |
|-------|---------|
| **Orchestrator** | Single entrypoint — routes to specialists, context verification, write gates |
| **Chief of Staff** | M365 triage, status emails, meeting prep, comms drafts |
| **ADO DevOps** | ADO work items, compliance, board hygiene, multi-item disambiguation |
| **Fabric DevOps** | Full Fabric lifecycle (develop, monitor, validate, promote), data access routing |
| **Databricks DevOps** | Full Databricks lifecycle (notebooks, jobs, clusters, CI/CD) |
| **Wiki DevOps** | ADO Wiki operations and content management |

## Skills

| Skill | Agent | Domain |
|-------|-------|--------|
| Daily Status Email | Chief of Staff | Auto-generated status → manager |
| Create Task | ADO DevOps | M365 signals → ADO tasks |
| Update User Story | ADO DevOps | Reference docs → enriched ADO stories |
| Board Hygiene Audit | ADO DevOps | 28-point compliance check, scored report, auto-fix |
| Fabric DevOps (7 capabilities) | Fabric DevOps | Develop, Monitor, Diagnostics, Validate, Lineage, Testing, Promote |
| Databricks DevOps (7 capabilities) | Databricks DevOps | Develop, Monitor, Diagnostics, Validate, Data Ops, Security, Promote |
| Wiki DevOps | Wiki DevOps | ADO Wiki content management |

## Evaluation Framework

The repo includes an evaluation framework for testing agent routing, skill activation, and interaction quality.

| File | Purpose |
|------|---------|
| [EVAL-FRAMEWORK.md](.github/evaluations/EVAL-FRAMEWORK.md) | Scoring dimensions, weights, and pass thresholds |
| [baseline.yaml](.github/evaluations/baseline.yaml) | Baseline scores from dry-run classification |
| [eval-manifest.yaml](.github/evaluations/eval-manifest.yaml) | 54 test scenarios across 12 categories |

Run evaluations via: `@orchestrator Run the evaluation suite`

## Contributing

1. Create a feature branch from `main`
2. Add or update agents/skills following existing patterns
3. Test in VS Code Copilot Chat
4. Submit a PR

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guidelines.
