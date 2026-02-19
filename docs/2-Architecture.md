# Architecture

## Three-Layer Design

```
┌──────────────────────────────────────────────────────────┐
│  LAYER 1: TRIAGE (Orchestrator)                          │
│  Routes requests — does NOT execute domain work          │
└───────────────────────┬──────────────────────────────────┘
         ┌──────────────┼──────────────┐
         ▼              ▼              ▼
┌────────────┐  ┌────────────┐  ┌─────────────┐
│ Chief of   │  │ Fabric     │  │ Databricks  │
│ Staff      │  │ DevOps     │  │ DevOps      │
│ (PM/M365)  │  │ (Data Eng) │  │ (Data Eng)  │
└─────┬──────┘  └─────┬──────┘  └──────┬──────┘
      │               │                │
      ▼               ▼                ▼
┌──────────────────────────────────────────────────────────┐
│  LAYER 3: EXECUTION SKILLS                               │
│  Self-contained SOPs: Create Task, Deploy, Validate, …   │
└──────────────────────────────────────────────────────────┘
```

| Layer | Role | Analogy |
| :--- | :--- | :--- |
| **Orchestrator** | Single entrypoint; routes to specialists | Front desk receptionist |
| **Domain Agents** | Own environment context, guardrails, skill routing | Department heads |
| **Skills** | Repeatable, version-controlled procedures | Standard Operating Procedures |

**Design principle:** Each layer has a single concern. The orchestrator triages. Agents strategize. Skills execute.

---

## Agents

| Agent | Domain | Key Responsibility |
| :--- | :--- | :--- |
| **Orchestrator** | Cross-domain | Routes to specialist subagents; runs them in parallel for multi-domain tasks |
| **Chief of Staff** | PM & M365 | Triage, status reporting, ADO work items, email drafts |
| **Fabric DevOps** | Microsoft Fabric | Full lifecycle — develop, monitor, diagnose, validate, promote |
| **Databricks DevOps** | Azure Databricks | Full lifecycle — notebooks, jobs, clusters, Unity Catalog, security |

### Agent Design Rules

1. **Agents are thin dispatchers.** Heavy lifting lives in skills.
2. **Least-privilege toolsets.** Each agent only has tools for its domain.
3. **Users talk to the Orchestrator.** It delegates to the right specialist.
4. **Agents own context; skills own procedure.** The agent resolves *where* and *which guardrails*; the skill knows *how*.

---

## Skills

Skills are `SKILL.md` files that declare their intent triggers, engine preferences, and step-by-step procedures.

### Chief of Staff Skills

| Skill | Purpose | Example Trigger |
| :--- | :--- | :--- |
| **Create Task** | M365 signals → ADO tasks | "Create tasks from my standup" |
| **Daily Status Email** | Synthesize day → formatted email, auto-send | "Generate my daily status" |
| **Update User Story** | Enrich ADO stories with requirements | "Update story 12345 with the BRD" |

### Fabric DevOps Skills

| Skill | Purpose | Example Trigger |
| :--- | :--- | :--- |
| **Develop** | Create/update notebooks, pipelines, lakehouses | "Create a notebook in DEV" |
| **Operate & Monitor** | Inventory, job health, failure summaries | "What's failing in DEV?" |
| **Lakehouse Diagnostics** | Trace load failures, dependency issues | "Why did the Bronze table fail?" |
| **Validate** | Cross-environment config and metadata comparison | "Validate DEV matches UAT" |
| **Semantic Model Testing** | Schema drift, row counts, metric variance | "Compare semantic model DEV vs PROD" |
| **Analyze Lineage** | Lakehouse → semantic model → report lineage | "What reports depend on FactClaims?" |
| **Release & Promote** | Lifecycle promotion DEV → UAT → PROD | "Promote my notebook to UAT" |

### Databricks DevOps Skills

| Skill | Purpose | Example Trigger |
| :--- | :--- | :--- |
| **Develop** | Notebooks, jobs, clusters, warehouses | "Create a job in DEV" |
| **Operate & Monitor** | Workspace inventory, job/cluster health | "Show cluster status" |
| **Cluster Diagnostics** | Driver logs, OOM, Spark UI | "Why did my job fail?" |
| **Validate** | Cross-environment drift detection | "Compare DEV vs PROD configs" |
| **Data Ops** | Unity Catalog, Delta tables, DBFS | "List tables in catalog" |
| **Security** | Permissions, secrets, ACLs, policies | "Who has access to PROD?" |
| **Release & Promote** | Bundle-based CI/CD promotion | "Deploy bundle to UAT" |

### Self-Declaring Skill Pattern

Skills declare their own intent scope — the agent doesn't hardcode routing:

```yaml
# In fabric-devops-operate-monitor/SKILL.md:
Triggers: monitor, status, inventory, jobs, run history, health
Weight: 1.0
```

Adding a new capability = adding a new `SKILL.md` file. No agent code changes needed.

---

## Shared Resource Layer

Both Fabric and Databricks use a shared resource layer — shared config consumed by all capability skills:

```
fabric-devops/
├── config/
│   ├── workspace-catalog.yaml     ← Workspace IDs and environments
│   ├── execution-router.yaml      ← Engine definitions and fallback policy
│   └── intent-router.yaml         ← Reference routing index
└── modules/
    ├── safety-guardrails.md       ← Universal safety rules
    ├── develop.md                 ← Procedure for develop skill
    ├── validate.md                ← Procedure for validate skill
    └── ...                        ← One module per capability
```

**Why:** Workspace IDs, safety rules, and engine definitions are defined once and consumed by all skills. Change a workspace ID in one place → all skills pick it up.

---

## Execution Engines

Each skill declares its preferred engine. The system follows a deterministic fallback cascade:

### Fabric

| Engine | Best For |
| :--- | :--- |
| `fabric-api` | CRUD, job execution, deployments |
| `fabric-cli` | Scripted automation, CI/CD |
| `fabric-sempy` | Metadata analysis, lineage |
| `context7-guidance` | Advisory-only fallback |

### Databricks

| Engine | Best For |
| :--- | :--- |
| `databricks-api` | REST API for workspace resources |
| `databricks-cli` | CLI + Asset Bundles for CI/CD |
| `databricks-sdk-py` | Python SDK for programmatic workflows |
| `databricks-sql` | SQL queries and warehouse management |

---

## MCP Servers

Agents use MCP (Model Context Protocol) servers to interact with external APIs through a uniform tool interface.

| Server | Type | Used By |
| :--- | :--- | :--- |
| **Azure DevOps** | stdio (npx) | Chief of Staff |
| **Playwright** | stdio (npx) | Browser automation |
| **WorkIQ** | stdio (npx) | Chief of Staff (M365 signals) |
| **Context7** | stdio (npx) | Fabric DevOps (library docs) |
| **Mail Tools** | HTTP | Chief of Staff (send email) |
| **Calendar Tools** | HTTP | Chief of Staff |
| **Teams** | HTTP | Fabric DevOps, Create Task |
| **Power BI Remote** | HTTP | Semantic model queries |
| **Microsoft Docs** | HTTP | Fabric DevOps |
| **NL2DAB** | HTTP | Natural language data queries |

Each agent declares exactly which MCP tools it can access — enforcing least-privilege per agent.

---

## Safety Guardrails

- **PROD is read-only.** Write operations on PROD workspaces are blocked.
- Schema-altering operations require confirmation.
- All safety rules are codified in `modules/safety-guardrails.md` and enforced universally.
- Junior team members can execute complex operations knowing the system prevents damage.

---

## Extending the System

| Want To... | Do This |
| :--- | :--- |
| Add a new Fabric capability | Create `skills/fabric-devops-<name>/SKILL.md` with intent declarations |
| Add a new workspace | Edit `skills/fabric-devops/config/workspace-catalog.yaml` |
| Change safety rules | Edit `skills/fabric-devops/modules/safety-guardrails.md` |
| Add a new MCP server | Edit `.vscode/mcp.json` |
| Change personal ADO defaults | Edit `config/user-context.yaml` |
| Add a new agent | Create `.github/agents/<name>.agent.md` |
