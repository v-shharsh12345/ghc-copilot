# Releases

## v1.1 — Databricks DevOps & Evaluation Framework

**Status:** Current

### Highlights
- **Databricks DevOps agent** with 7 capability skills — Develop, Monitor, Diagnostics, Validate, Data Ops, Security, Promote
- **Evaluation Framework** — 54 test scenarios across 12 categories for routing accuracy, skill activation, and guardrail enforcement
- **Wiki DevOps agent** for ADO wiki content management and publishing

### What's New
| Area | Details |
|------|---------|
| Databricks DevOps | Full lifecycle agent covering notebooks, jobs, clusters, Unity Catalog, Delta tables, DBFS, and Asset Bundle deployments |
| Evaluation Suite | Dry-run classification tests with baseline scoring — run via `@orchestrator Run the evaluation suite` |
| Wiki DevOps | Generates wiki documentation for Power BI reports with semantic model analysis, screenshots, and ADO wiki publishing |
| Session Checkpointing | Orchestrator saves key decisions and intermediate results to session memory for context continuity |
| Cross-Agent Context | M365 ↔ ADO bidirectional context sharing — meeting action items flow into work items and back into status emails |

---

## v1.0 — Orchestrator & Fabric DevOps

### Highlights
- **Orchestrator agent** — single entrypoint with intent classification, fast-path routing, write gates, and context verification
- **Fabric DevOps agent** with 7 capability skills — Develop, Monitor, Diagnostics, Validate, Lineage, Semantic Model Testing, Promote
- **ADO DevOps agent** with Board Hygiene Audit, Create Task, and Update User Story skills
- **Chief of Staff agent** with Daily Status Email and M365 triage

### What's New
| Area | Details |
|------|---------|
| Orchestrator | Decompose → delegate → synthesize pattern with parallel execution, error recovery, and result merging |
| Fabric DevOps | Full Fabric lifecycle — lakehouse diagnostics, lineage tracing, cross-environment validation, deployment promotion |
| ADO DevOps | 28-point board hygiene audit with scored compliance reports and optional auto-fix |
| Chief of Staff | Auto-generated daily status emails pulling context from Outlook, Teams, Calendar, and Copilot chat history |
| Composite Patterns | 10 multi-agent workflow templates — deploy→validate, morning triage, M365→ADO chains, impact analysis |
| Write Gates | Pre-flight confirmation for all create/modify/delete/deploy/send actions with irreversibility classification |

---

## v0.9 — Foundation

### Highlights
- Initial project scaffolding with agent and skill directory structure
- First working Fabric DevOps capabilities (develop + monitor)
- MCP server configuration and setup automation

### What's New
| Area | Details |
|------|---------|
| Project Structure | `.github/agents/`, `.github/skills/`, `config/`, `docs/` directory layout |
| Fabric DevOps | Initial develop and monitor capabilities for Fabric workspaces |
| MCP Configuration | Template-based MCP server config (`mcp.template.json`) with setup script |
| Documentation | Four-page doc framework — Why Agentic, Architecture, Use Cases & ROI, Setup Guide |
| Setup Script | `setup.ps1` for one-command environment configuration |
| Contribution Guidelines | PR templates and contributing guide |
