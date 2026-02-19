# Architecture & Design Thinking

This page explains **how** our agentic system is designed, **why** each piece exists, and the deliberate decisions behind the structure. If you want to add a new agent, skill, or capability — understanding these patterns will help you extend the system without breaking it.

---

## 1. The Three-Layer Architecture

The system is organized into three cognitive layers, each with a distinct responsibility:

```
┌─────────────────────────────────────────────────────────────┐
│  LAYER 1: TRIAGE (Orchestrator)                             │
│  ─ Routes requests to the right specialist                  │
│  ─ Does NOT execute domain work directly                    │
│  ─ Runs subagents in parallel for multi-domain tasks        │
└────────────────────────┬────────────────────────────────────┘
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  LAYER 2:   │  │  LAYER 2:   │  │  LAYER 2:   │
│  Chief of   │  │  Fabric     │  │  Databricks │
│  Staff      │  │  DevOps     │  │  DevOps     │
│  (PM/M365)  │  │  (Data Eng) │  │  (Data Eng) │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                │
       ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│  LAYER 3: EXECUTION SKILLS                                  │
│  ─ Create Task, Daily Status Email, Update User Story       │
│  ─ Develop, Monitor, Validate, Promote, Lineage, etc.       │
│  ─ Each skill is a self-contained SOP with inputs/outputs   │
└─────────────────────────────────────────────────────────────┘
```

### Why Three Layers?

| Layer | Analogy | Why It Exists |
| :--- | :--- | :--- |
| **Orchestrator** | Front desk receptionist | Keeps the user-facing interface simple. One entrypoint, not 15 agents to choose from. Prevents "which agent do I use?" confusion. |
| **Domain Agents** | Department heads | Own the "world view" for a domain — workspace IDs, environments, guardrails. They decide **which skill** to activate based on intent scoring, not the user. |
| **Skills** | Standard Operating Procedures | Encapsulate repeatable workflows. Version-controlled. Testable. Portable across agents. |

**Design principle:** Each layer has a single concern. The orchestrator triages. Agents strategize. Skills execute. No layer does another layer's job.

---

## 2. Agents: The "Who" of the System

### Current Agents

| Agent | Domain | Key Responsibility |
| :--- | :--- | :--- |
| **Orchestrator** | Cross-domain | Single user entrypoint; routes to specialist subagents |
| **Chief of Staff** | PM & M365 | Triage, status reporting, ADO work items, email drafts |
| **Fabric DevOps** | Microsoft Fabric | Full lifecycle — develop, monitor, diagnose, validate, promote |
| **Databricks DevOps** | Azure Databricks | Full lifecycle — notebooks, jobs, clusters, Unity Catalog, security |

### Agent Design Rules

1. **Agents are thin dispatchers, not executors.** An agent should be ~100 lines of routing logic, not 500 lines of procedure. The heavy lifting lives in skills.

2. **Each agent declares its tool whitelist.** Only the tools an agent needs are listed in its YAML frontmatter. A Chief of Staff agent has no access to Fabric APIs. A Fabric agent has no access to Outlook. This is **least-privilege by design**.

3. **Agents are not user-invokable (except the Orchestrator).** Users talk to `@orchestrator`. The orchestrator delegates to `chief-of-staff` or `fabric-devops`. This prevents users from needing to know which agent to call.

4. **Agents own context, skills own procedure.** The agent resolves *where* (which workspace?), *when* (which environment?), and *what guardrails apply*. The skill knows *how* to do the work.

### Why a Separate Orchestrator?

We considered two alternatives:

| Approach | Problem |
| :--- | :--- |
| **Single monolithic agent** | Too many tools, too much context. The model gets confused when it has 50+ tools available. Performance degrades. |
| **User picks the agent manually** | Requires users to know the agent taxonomy. "Was that `fabric-devops` or `fabric-devops-develop`?" — bad UX. |
| **Orchestrator → Subagents** ✅ | User says what they want. Orchestrator routes. Subagent focuses with its constrained toolset. Best of both worlds. |

The orchestrator pattern also enables **parallel execution**. A request like *"Check pipeline health in Fabric AND create a follow-up task in ADO"* runs both subagents simultaneously.

---

## 3. Skills: The "How" of the System

### What Is a Skill?

A skill is a **SKILL.md** file that contains:
- **Intent triggers** — keywords/phrases that activate it
- **Engine preference** — which execution engine to use (API, CLI, SDK)
- **Procedure** — step-by-step instructions the agent follows
- **Guardrails** — safety rules specific to this capability
- **Input/output contract** — what the skill needs and what it produces

### Current Skill Inventory

#### Cross-Domain Skills (used by Chief of Staff)

| Skill | Purpose | Typical Trigger |
| :--- | :--- | :--- |
| **Create Task** | Extract action items from M365 signals → ADO tasks | "Create tasks from my standup" |
| **Daily Status Email** | Synthesize day's activities → formatted email, auto-send | "Generate my daily status" |
| **Update User Story** | Enrich ADO user stories with structured requirements | "Update user story 12345 with these requirements" |

#### Fabric DevOps Capability Skills

| Skill | Purpose | Typical Trigger |
| :--- | :--- | :--- |
| **Develop** | Create/update notebooks, pipelines, lakehouses | "Create a notebook in DEV" |
| **Operate & Monitor** | Inventory items, check job health, surface failures | "What's the status of my DEV workspace?" |
| **Lakehouse Diagnostics** | Investigate table load failures, trace dependencies | "Why did the Bronze table fail?" |
| **Validate** | Cross-environment config and metadata comparison | "Validate DEV matches UAT" |
| **Semantic Model Testing** | Schema drift, row count, metric variance, freshness checks | "Compare semantic model in DEV vs PROD" |
| **Analyze Lineage** | Trace data flow from lakehouse → semantic model → report | "What reports depend on FactClaims?" |
| **Release & Promote** | Lifecycle promotion DEV → UAT → PROD | "Promote my notebook to UAT" |

#### Databricks DevOps Capability Skills

| Skill | Purpose | Typical Trigger |
| :--- | :--- | :--- |
| **Develop** | Create/update notebooks, jobs, clusters, warehouses | "Create a job in DEV workspace" |
| **Operate & Monitor** | Workspace inventory, job/cluster health | "Show cluster status" |
| **Cluster Diagnostics** | Driver logs, OOM, timeout, Spark UI investigation | "Why did my job fail?" |
| **Validate** | Cross-environment drift detection | "Compare DEV vs PROD configs" |
| **Data Ops** | Unity Catalog, Delta tables, DBFS, data quality | "List tables in catalog" |
| **Security** | Permissions, secrets, ACLs, cluster policies | "Who has access to PROD?" |
| **Release & Promote** | Bundle-based CI/CD promotion | "Deploy bundle to UAT" |

### The Shared Resource Layer Pattern

Both Fabric DevOps and Databricks DevOps use a **shared resource layer** — a parent skill that doesn't route requests but provides shared configuration consumed by all capability skills:

```
fabric-devops/                    ← Shared resource layer (SKILL.md)
├── config/
│   ├── workspace-catalog.yaml    ← All workspace IDs and environments
│   ├── execution-router.yaml     ← Engine definitions and preferences
│   └── intent-router.yaml        ← Reference intent routing index
└── modules/
    ├── safety-guardrails.md      ← Universal safety rules
    ├── develop.md                ← Procedure consumed by fabric-devops-develop
    ├── operate-monitor.md        ← Procedure consumed by fabric-devops-operate-monitor
    ├── validate.md               ← Procedure consumed by fabric-devops-validate
    └── ...                       ← One module per capability
```

**Why this pattern?**
- **DRY (Don't Repeat Yourself):** Workspace IDs, safety rules, and engine definitions are defined once, consumed by 7 skills.
- **Consistency:** All skills enforce the same guardrails — you can't accidentally skip safety checks.
- **Maintainability:** Change a workspace ID in one place, all skills pick it up. Add a new safeguard, all skills inherit it.

---

## 4. Key Design Decisions: Skill vs. Agent Context

One of the most important decisions is **where to put context** — in the agent or in the skill?

### Decision Framework

| Context Type | Put It In... | Why |
| :--- | :--- | :--- |
| **Environment metadata** (workspace IDs, connection strings) | Shared resource layer config (`workspace-catalog.yaml`) | Consumed by multiple skills; changes infrequently |
| **Safety rules** (PROD read-only, write confirmations) | Shared resource layer modules (`safety-guardrails.md`) | Must be universal; inherited by all capability skills |
| **Engine routing** (which API to use for which operation) | Shared resource layer config (`execution-router.yaml`) | Engine decisions are cross-cutting, not skill-specific |
| **User identity & preferences** (name, ADO defaults, team) | `config/user-context.yaml` (gitignored) | Personal per-user; referenced by agents and skills |
| **Tool access control** (which MCP tools are available) | Agent YAML frontmatter (`tools:`) | Least-privilege per agent; keeps tool surface minimal |
| **Domain routing** (which skill handles "deploy")  | Agent routing table + skill `Intent` declarations | Agent reads skill declarations; skills self-declare |
| **Step-by-step procedures** (how to create a task) | Skill `SKILL.md` file | Skills own their SOPs; agents delegate, don't dictate |
| **Intent triggers** (keywords that activate a skill) | Skill `Intent` section | Skills are authoritative about what they handle |
| **Business-domain knowledge** (fact tables, report names) | `config/user-context.yaml` | Project-specific; keeps skills generic |

### The Self-Declaring Skill Pattern

A critical design choice: **skills declare their own intent scope, not the agent.**

```
# In fabric-devops-operate-monitor/SKILL.md:

## Intent
| Property | Value |
| --- | --- |
| Triggers | monitor, status, inventory, jobs, run history, health |
| Weight | 1.0 |
| Minimum Confidence | 0.45 |
```

The agent reads all skill declarations, scores the user's request against each skill's triggers, and activates the highest-scoring match. This means:

- **Adding a new capability** = adding a new `SKILL.md` file with intent declarations. No agent code changes needed.
- **Adjusting routing** = changing trigger keywords or weights in a skill. The agent adapts automatically.
- **Testing a skill** = invoking it directly. It's self-contained.

### How Agents Leverage Skills Across Domains

Skills can be reused across agent boundaries:

```
Chief of Staff agent
  ├── Uses: create-task skill
  ├── Uses: daily-status-email skill
  └── Uses: update-user-story skill

Fabric DevOps agent
  ├── Uses: fabric-devops-develop skill
  ├── Uses: fabric-devops-validate skill
  │     └── Internally references: compare-semantic-models skill
  └── Uses: fabric-devops-operate-monitor skill

Orchestrator
  └── Can run Chief of Staff + Fabric DevOps in parallel
      (e.g., "Check pipeline health AND create a task for the failure")
```

The orchestrator doesn't need to know about individual skills — it delegates to the right agent, and the agent activates the right skill.

---

## 5. Execution Engine Routing

Not all operations use the same API. The system supports multiple execution engines with deterministic routing:

### Fabric Engines

| Engine | Best For |
| :--- | :--- |
| `fabric-api` | CRUD operations, job execution, deployments |
| `fabric-cli` | Scripted automation, CI/CD pipelines |
| `fabric-sempy` | Metadata analysis, lineage, semantic-link-labs |
| `context7-guidance` | Advisory-only fallback (no execution) |

### Databricks Engines

| Engine | Best For |
| :--- | :--- |
| `databricks-api` | REST API for all workspace resources |
| `databricks-cli` | CLI + Asset Bundles for CI/CD |
| `databricks-sdk-py` | Python SDK for programmatic workflows |
| `databricks-sql` | SQL queries and warehouse management |
| `context7-guidance` | Advisory-only fallback (no execution) |

### Engine Selection Is Deterministic

Each skill declares its preferred engine order. The system doesn't guess — it follows a codified preference cascade:

```yaml
# From execution-router.yaml
intentEnginePreference:
  develop:
    preferred: [fabric-api, fabric-cli]
    fallback: [context7-guidance]
  validate:
    preferred: [fabric-sempy, fabric-api]
    fallback: [fabric-cli, context7-guidance]
  analyze-lineage:
    preferred: [fabric-sempy, fabric-api]
    fallback: [fabric-cli, context7-guidance]
```

This means: for validation tasks, try `fabric-sempy` first (it's best for analytical comparisons). If unavailable, fall back to `fabric-api`. If that fails, try `fabric-cli`. Last resort: provide guidance only.

---

## 6. The `runSubagent` Pattern

When the orchestrator delegates to a specialist, it uses the `runSubagent` tool. Key behaviors:

| Behavior | Why |
| :--- | :--- |
| **Subagent invocations are stateless** | Each call is independent. The orchestrator must provide full context in the prompt. No "continuing from last time." |
| **Subagent returns a single message** | The agent does its work and returns one consolidated result. No back-and-forth. |
| **Parallel execution is supported** | Two subagents can run simultaneously for independent tasks. |
| **Subagent output is not visible to the user** | The orchestrator receives the result and decides what to show the user. This allows synthesis and filtering. |

### Implications for Design

- **Prompts must be self-contained.** When the orchestrator calls `fabric-devops`, it includes the full request context — not "see above."
- **Results must be structured.** Skills return findings in a predictable format (scope, actions, PASS/WARN/FAIL, next steps) so the orchestrator can synthesize across subagents.
- **Error handling is per-subagent.** If Fabric fails but ADO succeeds, the orchestrator reports both results — it doesn't block one on the other.

---

## 7. MCP (Model Context Protocol) Servers

The agents don't call APIs directly — they use **MCP servers** that expose APIs as tools. This provides a uniform tool interface regardless of the underlying API technology.

### MCP Server Map

| Server | Type | Used For |
| :--- | :--- | :--- |
| **Azure DevOps** | stdio (npx) | Work items, iterations, pull requests |
| **Playwright** | stdio (npx) | Browser automation, Power BI report testing |
| **WorkIQ** | stdio (npx) | M365 search (emails, chats, calendar) |
| **Context7** | stdio (npx) | Library documentation lookup |
| **Mail Tools** | HTTP | Email draft/send operations |
| **Calendar Tools** | HTTP | Meeting queries |
| **Teams** | HTTP | Chat and channel operations |
| **Power BI Remote** | HTTP | DAX execution, semantic model schema |
| **Microsoft Docs** | HTTP | Documentation search |
| **NL2DAB** | HTTP | Natural language to data queries |

### Why MCP Matters

1. **Uniform interface** — Every external API is exposed as a tool call. The agent doesn't need to know REST semantics, auth flows, or JSON schemas.
2. **Composability** — An agent can use ADO tools AND Fabric tools AND M365 tools in the same conversation.
3. **Least privilege** — Each agent declares exactly which MCP tools it can access. Chief of Staff can't touch Fabric. Fabric can't send emails.

---

## 8. Configuration Architecture

```
copilot-agents/
├── config/
│   └── user-context.yaml           ← Personal config (gitignored)
├── .github/
│   ├── agents/                     ← Agent definitions (*.agent.md)
│   └── skills/
│       ├── fabric-devops/          ← Shared resource layer
│       │   ├── config/             ← Workspace catalog, engine router
│       │   └── modules/            ← Safety rules, procedures
│       ├── fabric-devops-develop/  ← Capability skill (self-declaring)
│       ├── fabric-devops-validate/ ← Capability skill (self-declaring)
│       └── ...
└── .vscode/
    └── mcp.json                    ← MCP server configuration
```

### What Goes Where?

| Need | File | Why |
| :--- | :--- | :--- |
| "I want to add a new Fabric capability" | Create `skills/fabric-devops-<name>/SKILL.md` | Self-declaring — the agent auto-discovers it |
| "I want to add a new workspace" | Edit `skills/fabric-devops/config/workspace-catalog.yaml` | Central catalog consumed by all skills |
| "I want to change safety rules" | Edit `skills/fabric-devops/modules/safety-guardrails.md` | Applied universally |
| "I want to add a new MCP server" | Edit `.vscode/mcp.json` | VS Code auto-discovers MCP servers |
| "I want to change my ADO defaults" | Edit `config/user-context.yaml` | Per-user, gitignored |
| "I want to add a new agent" | Create `.github/agents/<name>.agent.md` | VS Code auto-discovers agents |

---

## 9. Extending the System

### Adding a New Capability Skill

1. Create a folder: `.github/skills/<domain>-<capability>/`
2. Add `SKILL.md` with:
   - Intent section (triggers, weight, confidence threshold)
   - Engine preference
   - Procedure reference to the shared resource layer module
   - Guardrails reference
3. Create the procedure module in the shared layer: `skills/<domain>/modules/<capability>.md`
4. The parent agent will auto-discover the new skill via its intent declarations

**No changes needed to the agent file.** The self-declaring pattern means the agent reads skill declarations at runtime.

### Adding a New Agent

1. Create `.github/agents/<name>.agent.md`
2. Define YAML frontmatter: name, description, tools (whitelist)
3. Add routing rules for the orchestrator in `orchestrator.agent.md`
4. If the agent uses skills, reference them from the instruction body

### Adding a New MCP Server

1. Add the server configuration to `.vscode/mcp.json`
2. Whitelist relevant tools in the agent(s) that need them
3. Test the tools are available in Copilot Chat
