# Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              USER (VS Code Chat Panel)                                  │
│                    "Deploy my notebook to UAT and validate"                              │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         │ natural language
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  LAYER 1 — ORCHESTRATOR                                                                 │
│  Intent classification · Agent routing · Multi-agent composition · Result synthesis      │
│  Tools: runSubagent, todo                                                               │
│  NO domain tools — delegates everything                                                 │
└────────┬──────────┬───────────────────┬────────────────────────┬────────────────┘
         │          │                   │                        │
         ▼          ▼                   ▼                        ▼
┌──────────────┐  ┌──────────────┐  ┌────────────────┐  ┌──────────────────┐
│ Chief of     │  │ ADO DevOps   │  │ Fabric DevOps  │  │ Databricks       │
│ Staff        │  │              │  │                │  │ DevOps           │
│              │  │ 3 skills     │  │  7 capability  │  │  7 capability    │
│ 1 skill      │  │ ADO work     │  │  skills        │  │  skills          │
│ M365 only    │  │ items + compl│  │  Fabric + PBI  │  │  DB + UC + DBFS  │
└──────┬───────┘  └──────┬───────┘  └───────┬────────┘  └────────┬─────────┘
       │                 │                  │                     │
       ▼                 ▼                  ▼                     ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  LAYER 3 — EXECUTION SKILLS (SKILL.md files)                                            │
│  Each skill self-declares: triggers, weight, engine preference, procedure, guardrails   │
│  Skills read shared config (workspace-catalog, execution-router, safety-guardrails)     │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         │ tool calls
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  MCP SERVERS + EXTERNAL APIs                                                            │
│  Fabric API · Power BI Remote · ADO · M365 (Mail/Calendar/Teams) · Context7 · NL2DAB   │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

| Layer | Role | Analogy |
| :--- | :--- | :--- |
| **Orchestrator** | Single entrypoint; classifies intent, routes to specialists, synthesizes results | Front desk receptionist |
| **Domain Agents** | Own environment context, guardrails, skill routing, tool permissions | Department heads |
| **Skills** | Repeatable, version-controlled procedures with self-declared intent | Standard Operating Procedures |
| **MCP Servers** | Uniform tool interface to external APIs; each agent only sees its allowed tools | Secure phone lines |

**Design principle:** Each layer has a single concern. The orchestrator triages. Agents strategize. Skills execute. MCP servers connect.

---

## How the Orchestrator Routes Requests

The orchestrator is a **classifier + dispatcher**. It never calls domain tools directly — it uses `runSubagent` to delegate to specialists.

### Intent Classification Pipeline

```
┌───────────────────────────────────────────────────────────────┐
│                     User Request                              │
│  "Deploy my notebook to UAT and run post-deploy validation"   │
└──────────────────────────┬────────────────────────────────────┘
                           │
                           ▼
               ┌───────────────────────┐
               │  1. SIGNAL EXTRACTION │
               │                       │
               │  Platform: "notebook"  │  ──► Fabric ✓ / DB ✓
               │  Action:   "deploy"    │  ──► promote-release
               │  Env:      "UAT"       │  ──► env-aware
               │  M365:     (none)      │  ──► Chief of Staff ✗
               │  ADO:      (none)      │  ──► ADO DevOps ✗
               └───────────┬───────────┘
                           │
                           ▼
               ┌───────────────────────┐
               │  2. ROUTING SCORES    │
               │                       │
               │  chief-of-staff: 0.05 │  ──► below threshold
               │  ado-devops:     0.00 │  ──► no triggers matched
               │  fabric-devops:  0.82 │  ──► "deploy" + "notebook" + "UAT"
               │  databricks:     0.15 │  ──► "notebook" partial match
               └───────────┬───────────┘
                           │
                           ▼
               ┌───────────────────────┐
               │  3. DECISION RULES    │
               │                       │
               │  Single agent ≥ 0.5?  │  ──► YES: fabric-devops
               │  Multi-agent needed?  │  ──► YES: "deploy" then "validate"
               │  Dependency?          │  ──► YES: sequential (output → input)
               └───────────┬───────────┘
                           │
                           ▼
               ┌───────────────────────┐
               │  4. PROMPT CONSTRUCT  │
               │                       │
               │  ## Objective         │
               │  ## Context           │
               │  ## Skill Hint        │  ──► fabric-devops-release-promote
               │  ## Expected Output   │
               │  ## Constraints       │
               └───────────┬───────────┘
                           │
                           ▼
               ┌───────────────────────┐
               │  5. runSubagent()     │
               │                       │
               │  agentName:           │
               │    "fabric-devops"    │
               │  prompt: (structured) │
               └───────────────────────┘
```

### Scoring Formula

```
score(agent) = (matched_triggers / agent_total_triggers) × trigger_weight
             + 0.2 if entity names match agent's domain catalog
             + 0.1 if environment keywords present and agent handles environments
```

### Decision Matrix

| Condition | Action |
| :--- | :--- |
| Single agent ≥ 0.5 | Route directly |
| Multiple agents ≥ 0.5, **independent** subtasks | Decompose → parallel `runSubagent` calls |
| Multiple agents ≥ 0.5, **dependent** subtasks | Sequential chain (pass output as context) |
| All agents < 0.3 | Ask one clarifying question |
| Scores 0.3–0.5 | Route to highest scorer with explicit skill hint |

### Trigger Keywords by Agent

| Agent | Trigger Keywords |
| :--- | :--- |
| `chief-of-staff` | email, mail, meeting, calendar, teams, chat, triage, status, daily, prep, draft, send |
| `ado-devops` | ADO, work item, user story, task, bug, action item, follow-up, board hygiene, compliance, test case, acceptance criteria, sprint, iteration, area path, state transition |
| `fabric-devops` | fabric, lakehouse, semantic model, power bi, notebook, pipeline, lineage, trace, monitor, validate, compare, promote, deploy, schema drift, row count, metric, freshness, shortcut, failure, logs, inventory, health, run history, report, pbir, tmdl, metadata, impact analysis |
| `databricks-devops` | databricks, cluster, job, warehouse, notebook, unity catalog, delta, DBFS, volume, schema, catalog, bundle, permissions, secrets, access control, cluster policy, token, ACL, driver logs, spark ui, OOM, timeout, config drift |

---

## Orchestrator v2 Behaviors

The orchestrator includes several interaction and safety behaviors that govern how it processes requests beyond basic routing.

### Interaction Style

The orchestrator operates as a **collaborative, guidance-driven** system — not an autonomous executor. It presents plans before acting on non-trivial requests, surfaces assumptions explicitly, and seeks confirmation before write actions.

| Behavior | Description |
| :--- | :--- |
| **Draft before execute** | For non-trivial requests, present execution plan and wait for confirmation. Trivial = single-agent read-only with no ambiguity. |
| **Surface assumptions** | When filling in gaps (environment, entity, time range), list assumptions as a numbered list. For read-only + low-risk, note and proceed. For write actions, list and wait. |
| **Be specific** | Reference exact entity names, workspace IDs, environments, and dates. |
| **Once guided, move fast** | After confirmation, execute without re-asking. Parallelize aggressively. |

### Context Verification Protocol

Before routing non-trivial requests, the orchestrator verifies understanding to prevent wasted subagent calls.

**Must verify:** Write/mutate actions, ambiguous scope, multi-agent requests, 2+ assumptions.
**Skip verification:** Single-agent read-only with clear scope, fully specified requests, follow-ups referencing prior confirmed context.

### Write Gate

Any action that creates, modifies, deletes, deploys, promotes, or sends must pass a write gate with a pre-flight summary showing action, target, irreversibility level, and side effects.

| Level | Examples | Behavior |
| :--- | :--- | :--- |
| **LOW** | Create ADO task, draft email, create DEV notebook | Brief confirmation |
| **MEDIUM** | Deploy to UAT, send email, promote pipeline | Full pre-flight, wait for explicit "go" |
| **HIGH** | Delete items, deploy to PROD, bulk state transitions | Pre-flight + irreversibility warning + explicit "yes, proceed" |

### Direct Skill Execution

For lightweight, single-skill, read-only tasks (e.g., catalog lookups, agent registry queries), the orchestrator may execute directly without dispatching a subagent, reducing overhead.

### Aggressive Parallelism

Default stance: parallelize unless blocked. Independent subtasks targeting different agents, same agent with different environments/entities, or any combination of read-only subtasks run in parallel.

### Session Checkpointing

After significant actions (multi-agent workflows, write actions), the orchestrator saves key results to `/memories/session/` to preserve context across long conversations.

---

## Multi-Agent Composition Patterns

The orchestrator recognizes composite workflows and auto-sequences them:

```
Pattern 1: DEPLOY → VALIDATE → REPORT
─────────────────────────────────────────────────────
User: "promote notebook to UAT and verify"

  ┌─────────────────┐      output      ┌────────────────┐      if issues     ┌────────────────┐
  │  fabric-devops   │ ──────────────► │  fabric-devops  │ ──────────────►   │  ado-devops     │
  │  release-promote │   run ID, status │  validate       │  drift found      │  create ADO bug │
  └─────────────────┘                  └────────────────┘                    └────────────────┘
       (sequential)                         (sequential)                         (conditional)


Pattern 2: MORNING TRIAGE (parallel fan-out)
─────────────────────────────────────────────────────
User: "daily triage"

  ┌── chief-of-staff ──── M365 triage (meetings, mail, action items) ──┐
  │                                                                     │
  ├── ado-devops ─────────── ADO work item triage (blockers, overdue) ─┤  → synthesize
  │                                                                     │    unified
  ├── fabric-devops ───── overnight job health summary ────────────────┤    briefing
  │                                                                     │
  └── databricks-devops ─ overnight job health summary ────────────────┘


Pattern 3: M365 ACTION ITEMS → ADO WORK ITEMS
─────────────────────────────────────────────────────
User: "create tasks from my standup meeting today"

  ┌── chief-of-staff ── extract action items from meeting ──┐
  │                                                          │  → orchestrator passes
  └── ado-devops ──────── create tasks in ADO ──────────────┘    M365 context to ADO
       (sequential, M365→ADO context sharing)


Pattern 4: IMPACT ANALYSIS (fan-out then merge)
─────────────────────────────────────────────────────
User: "what breaks if I change FactClaims?"

  ┌── fabric-devops ──────── lineage (upstream/downstream) ────────────┐
  │                                                                     │  → impact map
  └── fabric-devops ──────── semantic model testing ───────────────────┘    + risk score
```

---

## Fabric DevOps Agent — Internal Architecture

This is the most complex agent. It manages the entire Fabric lifecycle through seven self-declaring capability skills, a shared resource layer, and a deterministic execution routing pipeline.

### High-Level Structure

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                          FABRIC DEVOPS AGENT                                            │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐    │
│  │                         SKILL ACTIVATION TABLE                                  │    │
│  │                                                                                 │    │
│  │  ┌───────────┐ ┌──────────────┐ ┌────────────┐ ┌──────────┐ ┌──────────────┐  │    │
│  │  │  Develop   │ │  Operate &   │ │ Lakehouse  │ │ Validate │ │  Semantic    │  │    │
│  │  │  w=1.0     │ │  Monitor     │ │ Diagnostics│ │ w=0.95   │ │  Model Test │  │    │
│  │  │            │ │  w=1.0       │ │ w=1.0      │ │          │ │  w=1.1       │  │    │
│  │  └─────┬─────┘ └──────┬───────┘ └─────┬──────┘ └────┬─────┘ └──────┬───────┘  │    │
│  │  ┌─────┴───────────────┴───────────────┴─────────────┴──────────────┴───────┐  │    │
│  │  │  ┌──────────────┐  ┌──────────────┐                                      │  │    │
│  │  │  │  Analyze      │  │  Release &   │                                      │  │    │
│  │  │  │  Lineage      │  │  Promote     │                                      │  │    │
│  │  │  │  w=1.05       │  │  w=1.0       │                                      │  │    │
│  │  │  └──────────────┘  └──────────────┘                                      │  │    │
│  │  └──────────────────────────────────────────────────────────────────────────┘  │    │
│  └─────────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐    │
│  │                     SHARED RESOURCE LAYER                                       │    │
│  │                                                                                 │    │
│  │  config/                         modules/                                       │    │
│  │  ├─ workspace-catalog.yaml       ├─ safety-guardrails.md                        │    │
│  │  ├─ execution-router.yaml        ├─ develop.md                                  │    │
│  │  └─ intent-router.yaml           ├─ operate-monitor.md                          │    │
│  │                                  ├─ lakehouse-diagnostics.md                    │    │
│  │                                  ├─ validate.md                                 │    │
│  │                                  ├─ semantic-model-testing.md                   │    │
│  │                                  ├─ analyze-lineage.md                          │    │
│  │                                  ├─ release-promote.md                          │    │
│  │                                  ├─ execution-routing.md                        │    │
│  │                                  ├─ capability-matrix.md                        │    │
│  │                                  └─ runtime-checks.md                           │    │
│  └─────────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐    │
│  │                     TOOL PERMISSIONS (least-privilege)                           │    │
│  │                                                                                 │    │
│  │  Fabric MCP:    onelake_*, group_list                                           │    │
│  │  Power BI:      ExecuteQuery, GetSemanticModelSchema, GenerateQuery,            │    │
│  │                 GetReportMetadata, DiscoverArtifacts                             │    │
│  │  MSSQL:         mssql_connect, mssql_run_query, mssql_list_tables, ...          │    │
│  │  Context7:      resolve-library-id, get-library-docs                            │    │
│  │  General:       readFile, fileSearch, textSearch, web/fetch, todo               │    │
│  └─────────────────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### Skill Activation & Intent Routing (Detailed)

When the Fabric DevOps agent receives a request from the orchestrator, it runs this internal pipeline:

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│               FABRIC DEVOPS — INTERNAL ROUTING PIPELINE                         │
└──────────────────────────────────────────────────────────────────────────────────┘

  User request (via orchestrator)
  "Why did the Bronze table fail in DEV?"
         │
         ▼
  ┌──────────────────────────────────────┐
  │  Step 1: SCORE AGAINST SKILL TRIGGERS│
  │                                      │
  │  develop:               0.00         │  triggers: create, update, develop...
  │  operate-monitor:       0.10         │  triggers: monitor, status, health...
  │  lakehouse-diagnostics: 0.85         │  triggers: lakehouse, table load, failure, logs ◄── HIT
  │  validate:              0.10         │  triggers: validate, compare...
  │  semantic-model-testing:0.00         │  triggers: semantic model, schema drift...
  │  analyze-lineage:       0.05         │  triggers: lineage, trace, impact...
  │  release-promote:       0.00         │  triggers: promote, release, deploy...
  │                                      │
  │  Winner: lakehouse-diagnostics       │
  │  Score × Weight: 0.85 × 1.0 = 0.85  │
  └────────────────┬─────────────────────┘
                   │
                   ▼
  ┌──────────────────────────────────────┐
  │  Step 2: APPLY AMBIGUITY RULES      │
  │                                      │
  │  No competing intents above 0.5      │
  │  → Skip ambiguity resolution         │
  └────────────────┬─────────────────────┘
                   │
                   ▼
  ┌──────────────────────────────────────┐
  │  Step 3: RESOLVE WORKSPACE           │
  │                                      │
  │  Keyword "DEV" found                 │
  │  → workspace-catalog.yaml lookup     │
  │  → Contoso Analytics [DEV]          │
  │  → ID: xxxxxxxx-xxxx-...            │
  │  → writeAllowed: true                │
  └────────────────┬─────────────────────┘
                   │
                   ▼
  ┌──────────────────────────────────────┐
  │  Step 4: RESOLVE EXECUTION ENGINE    │  ◄── execution-router.yaml
  │                                      │
  │  Intent: lakehouse-diagnostics       │
  │  Profile preferred: [fabric-api,     │
  │                      fabric-sempy]   │
  │  Fallback:          [fabric-cli,     │
  │                      context7]       │
  │                                      │
  │  Event override check: none          │
  │  Runtime check: fabric-api available │
  │  → Selected: fabric-api              │
  └────────────────┬─────────────────────┘
                   │
                   ▼
  ┌──────────────────────────────────────┐
  │  Step 5: SAFETY GUARDRAIL CHECK     │  ◄── safety-guardrails.md
  │                                      │
  │  Target env: DEV                     │
  │  Write needed? Read-only diagnostics │
  │  writeAllowed: true (but N/A)        │
  │  → PASS: proceed                     │
  └────────────────┬─────────────────────┘
                   │
                   ▼
  ┌──────────────────────────────────────┐
  │  Step 6: EXECUTE SKILL PROCEDURE     │  ◄── modules/lakehouse-diagnostics.md
  │                                      │
  │  1. List lakehouse tables            │  → Fabric MCP: onelake_item_list
  │  2. Check table load status          │  → Fabric API: job run history
  │  3. Trace dependency chain           │  → Fabric API: upstream items
  │  4. Surface error logs               │  → Fabric API: run logs
  │  5. Produce root-cause summary       │
  └────────────────┬─────────────────────┘
                   │
                   ▼
  ┌──────────────────────────────────────┐
  │  Step 7: FORMAT RESPONSE             │
  │                                      │
  │ • Scope: DEV / IncentiveReporting    │
  │ • Route: lakehouse-diagnostics →     │
  │          fabric-api                  │
  │ • Finding: FAIL — Bronze_Claims      │
  │   dependency on shortcut X broken    │
  │ • Next: Re-create shortcut, re-run   │
  └──────────────────────────────────────┘
```

### Ambiguity Resolution — When Intents Compete

Some requests match multiple skills. The system uses declared ambiguity rules:

### Fabric Data Access Routing

The Fabric DevOps agent has three data access paths. Using the wrong path causes failures or unnecessary complexity.

| Path | Tools | Use For | Never Use For |
| :--- | :--- | :--- | :--- |
| **SQL Endpoint** | `mssql_connect`, `mssql_run_query`, `mssql_list_tables` | Querying table data, schema inspection, row counts, data validation | Creating items, uploading files |
| **OneLake Direct** | `onelake_item_list`, `onelake_item_create`, `onelake_upload_file` | Creating/updating items, file uploads, workspace inventory | Querying table data |
| **Power BI Remote** | `ExecuteQuery`, `GetSemanticModelSchema`, `GetReportMetadata` | DAX queries, semantic model inspection, report metadata | Lakehouse operations, file operations |

**Quick rule:** READ data = SQL endpoint. WRITE/CREATE items = OneLake. Semantic models = Power BI Remote.

Full decision matrix: [develop.md — Data Access Decision Matrix](../skills/fabric-devops/modules/develop.md#data-access-decision-matrix)

### Notebook Deployment Protocol

Notebook operations are the most failure-prone Fabric operations. The agent follows a strict protocol:

1. **Prerequisites checklist** — verify workspace, lakehouse, capacity, Spark environment, library dependencies
2. **Create vs update determination** — list existing items first, then choose CREATE or UPDATE path
3. **Structured fallback** — when upload fails, fall back to Context7 guidance instead of retrying the same call
4. **No automatic execution** — never run a notebook as a smoke test unless explicitly asked

Full protocol: [develop.md — Notebook Deployment Protocol](../skills/fabric-devops/modules/develop.md#notebook-deployment-protocol)

### Ambiguity Resolution — When Intents Compete

Some requests match multiple skills. The system uses declared ambiguity rules:

```
User: "Check if the semantic model schema drifted between DEV and PROD"
         │
         ▼
  ┌──────────────────────────────────────┐
  │  SCORING                             │
  │                                      │
  │  validate:              0.55         │  ◄── "check", "DEV and PROD"
  │  semantic-model-testing:0.75         │  ◄── "semantic model", "schema drifted"
  └────────────────┬─────────────────────┘
                   │  Both ≥ 0.5 → check ambiguity rules
                   ▼
  ┌──────────────────────────────────────┐
  │  AMBIGUITY RULE                      │
  │                                      │
  │  Competing: validate vs              │
  │             semantic-model-testing    │
  │                                      │
  │  Rule: prefer semantic-model-testing │
  │  when prompt contains:               │
  │    "schema drift" ✓                  │
  │    "row count"                       │
  │    "metric variance"                 │
  │    "freshness"                       │
  │    "dataset"                         │
  │                                      │
  │  → Winner: semantic-model-testing    │
  └──────────────────────────────────────┘
```

### Resolution Order (Full Pipeline)

The complete 8-step resolution pipeline codified in `intent-router.yaml`:

```
resolveIntent           ──► Match user keywords against skill triggers
    │
applyRouteWeight        ──► Multiply match score by skill's declared weight
    │
applyAmbiguityRules     ──► Prefer specific skill when prompt matches override keywords
    │
resolveExecutionProfile ──► Look up engine list from execution-router.yaml
    │
applyEventOverride      ──► Switch engine order for specific event types
    │
checkEngineAvailability ──► Runtime check: is the engine actually reachable?
    │
executeModule           ──► Run the skill's canonical procedure module
    │
formatResponse          ──► Structure output with scope, route, findings, next steps
```

---

## Execution Engine Routing

### How Engine Selection Works

Each skill declares its preferred engines. The execution router applies a deterministic fallback cascade based on the intent + event type:

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                          ENGINE SELECTION FLOW                                       │
│                                                                                      │
│  Intent resolved     ┌──────────────────────┐                                        │
│  ──────────────────► │ execution-router.yaml │                                        │
│                      │  executionProfiles    │                                        │
│                      └──────────┬───────────┘                                        │
│                                 │                                                    │
│              ┌──────────────────┼──────────────────┐                                 │
│              ▼                  ▼                   ▼                                 │
│   ┌──────────────────┐  ┌───────────────┐  ┌───────────────────┐                     │
│   │ Write Operations │  │ Read/Analyze  │  │ Advisory Only     │                     │
│   │                  │  │               │  │                   │                     │
│   │ 1. fabric-api    │  │ 1. fabric-api │  │ 1. context7       │                     │
│   │ 2. fabric-cli    │  │ 2. fabric-cli │  │    (guidance)     │                     │
│   │                  │  │ 3. fabric-sempy│  │                   │                     │
│   └──────────────────┘  └───────────────┘  └───────────────────┘                     │
│                                                                                      │
│  Event Override Example:                                                             │
│  ─────────────────────                                                               │
│  Event: column-lineage-trace                                                         │
│  Default order:  [fabric-api, fabric-cli, fabric-sempy]                              │
│  Override order: [fabric-sempy, fabric-api]   ◄── SemPy is better for lineage        │
│                                                                                      │
│  Fallback Cascade:                                                                   │
│  ─────────────────                                                                   │
│  fabric-api unavailable? ──► try fabric-cli                                          │
│  fabric-cli unavailable? ──► try fabric-sempy                                        │
│  All unavailable?        ──► context7-guidance (advisory only, no execution)          │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### Engine × Intent Matrix

| Intent | Primary | Secondary | Analytical | Fallback |
| :--- | :--- | :--- | :--- | :--- |
| **develop** | fabric-api | fabric-cli | — | context7 |
| **operate-monitor** | fabric-api | fabric-cli | fabric-sempy | context7 |
| **lakehouse-diagnostics** | fabric-api | fabric-sempy | — | fabric-cli, context7 |
| **validate** | fabric-sempy | fabric-api | — | fabric-cli, context7 |
| **semantic-model-testing** | powerbi-remote | fabric-sempy | — | fabric-api, context7 |
| **analyze-lineage** | fabric-sempy | fabric-api | — | fabric-cli, context7 |
| **release-promote** | fabric-api | fabric-cli | — | context7 |

### Fabric Engines

| Engine | Type | Best For |
| :--- | :--- | :--- |
| `fabric-api` | Fabric REST API | CRUD, job execution, deployment pipelines, item metadata |
| `fabric-cli` | Fabric CLI | Scripted automation, CI/CD workflows, inventory exports |
| `fabric-sempy` | sempy + semantic-link-labs | Metadata analysis, lineage, PBIR parsing, TOM wrappers, broken-object detection |
| `context7-guidance` | Knowledge guidance (via Context7 MCP) | Advisory-only fallback when no execution engine is available |

### Databricks Engines

| Engine | Type | Best For |
| :--- | :--- | :--- |
| `databricks-api` | REST API | Workspace resources, cluster management |
| `databricks-cli` | CLI + Asset Bundles | CI/CD, bundle deployments |
| `databricks-sdk-py` | Python SDK | Programmatic workflows |
| `databricks-sql` | SQL connector | Queries, warehouse management |

---

## MCP Server Topology & Authorization

Agents interact with external services exclusively through MCP (Model Context Protocol) servers. Each agent declares exactly which MCP tools it can access — enforcing **least-privilege per agent**.

### MCP Connection Architecture

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                              VS Code Host Process                                        │
│                                                                                          │
│  ┌────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                         .vscode/mcp.json (server registry)                         │  │
│  └────────────────────────────────────────────────────────────────────────────────────┘  │
│                                         │                                                │
│            ┌────────────────────────────┼────────────────────────────┐                    │
│            │                            │                            │                    │
│     ┌──────▼──────┐             ┌───────▼──────┐             ┌──────▼──────┐             │
│     │  stdio (npx) │             │  HTTP remote  │             │  stdio local│             │
│     │  servers     │             │  servers      │             │  servers    │             │
│     └──────┬──────┘             └───────┬──────┘             └──────┬──────┘             │
│            │                            │                            │                    │
│     ┌──────┼──────┐         ┌───────────┼────────────┐              │                    │
│     │      │      │         │           │            │              │                    │
│     ▼      ▼      ▼         ▼           ▼            ▼              ▼                    │
│  ┌─────┐┌─────┐┌──────┐ ┌──────┐ ┌──────────┐ ┌─────────┐  ┌───────────┐               │
│  │ ADO ││Play-││Work- │ │Mail  │ │Calendar  │ │Teams    │  │Excalidraw │               │
│  │     ││wrt  ││IQ    │ │Tools │ │Tools     │ │Server   │  │           │               │
│  └──┬──┘└──┬──┘└──┬───┘ └──┬───┘ └────┬─────┘ └────┬────┘  └───────────┘               │
│     │      │      │        │          │            │                                     │
│     ▼      ▼      ▼        ▼          ▼            ▼                                     │
│  Azure   Browser  M365   Outlook    Outlook      Teams                                   │
│  DevOps  Auto     Graph  (send)     (events)     (chats)                                 │
│                                                                                          │
│  ┌────────────────┐  ┌───────────────┐  ┌────────────────┐  ┌──────────────┐            │
│  │ Power BI Remote │  │ Microsoft Docs│  │ NL2DAB         │  │ Context7     │            │
│  │ (HTTP)          │  │ (HTTP)        │  │ (HTTP)         │  │ (stdio/npx)  │            │
│  └───────┬────────┘  └───────┬───────┘  └───────┬────────┘  └──────┬───────┘            │
│          ▼                   ▼                   ▼                  ▼                     │
│   Fabric/Power BI     Microsoft Learn     NL→SQL→Data       Library docs                 │
│   semantic models     documentation       (incentive data)   (implementation              │
│   (DAX queries,       (search + fetch)                        guidance)                   │
│    schema, reports)                                                                       │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

### Server Details

| Server | ID in `mcp.json` | Transport | Auth Mechanism | Capabilities |
| :--- | :--- | :--- | :--- | :--- |
| **Azure DevOps** | `microsoft/azure-devops-mcp` | stdio (npx) | Azure AD (ambient login) | Work items, repos, pipelines, wiki, test plans |
| **Playwright** | `microsoft/playwright-mcp` | stdio (npx) | None (local browser) | Browser automation, screenshots |
| **WorkIQ** | `workiq` | stdio (npx) | M365 Graph (delegated) | Outlook, Teams, Calendar signal extraction |
| **Context7** | `io.github.upstash/context7` | stdio (npx) | API key (`CONTEXT7_API_KEY`) | Library doc lookup, implementation guidance |
| **Mail Tools** | `mcp_MailTools` | HTTP (Power Platform) | Entra ID (delegated via environment) | Send/receive/draft emails, attachments |
| **Calendar Tools** | `mcp_CalendarTools` | HTTP (Power Platform) | Entra ID (delegated via environment) | List/create/update calendar events |
| **Teams Server** | `mcp_TeamsServer` | HTTP (Power Platform) | Entra ID (delegated via environment) | Chats, channels, messages, members |
| **M365 Copilot** | `mcp_M365Copilot` | HTTP (Power Platform) | Entra ID (delegated via environment) | Copilot chat queries |
| **Word Server** | `mcp_WordServer` | HTTP (Power Platform) | Entra ID (delegated via environment) | Document content, comments |
| **Power BI Remote** | `powerbi-remote` | HTTP (Fabric API) | Entra ID (Fabric token) | DAX queries, schema, report metadata, artifact discovery |
| **Microsoft Docs** | `microsoftdocs/mcp` | HTTP | None (public) | Search + fetch Microsoft Learn content |
| **NL2DAB** | `nl2dab-mcp-server` | HTTP (Azure Container App) | None (network boundary) | Natural language → SQL data queries |
| **Excalidraw** | `excalidraw` | stdio (local node) | None | Diagram creation |

### Agent → MCP Tool Permissions

Each agent's `.agent.md` frontmatter declares exactly which MCP tools it can call. Tools not listed are invisible to the agent.

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  AGENT TOOL PERMISSION MAP                                                          │
│                                                                                     │
│  Orchestrator ──────────────────► runSubagent, todo (ONLY)                          │
│                                   No domain tools; no MCP access                    │
│                                                                                     │
│  Chief of Staff ────────────────► WorkIQ (M365 signals)                              │
│                                   Mail Tools (send/draft email)                     │
│                                   Calendar Tools (events)                           │
│                                   Teams Server (chats, channels)                    │
│                                   Word Server (documents)                           │
│                                   M365 Copilot (queries)                            │
│                                                                                     │
│  ADO DevOps ────────────────────► ADO MCP (work items, repos, wiki, test plans)     │
│                                   Context7 (library docs, guidance)                 │
│                                   Microsoft Docs (search, fetch)                    │
│                                   File read/search (local definitions)              │
│                                                                                     │
│  Fabric DevOps ─────────────────► Fabric MCP (OneLake CRUD, workspace list)         │
│                                   Power BI Remote (DAX, schema, reports)            │
│                                   MSSQL (connect, query, schema)                    │
│                                   Context7 (library docs, guidance)                 │
│                                   Microsoft Docs (search, fetch)                    │
│                                   File read/search (local definitions)             │
│                                                                                     │
│  Databricks DevOps ─────────────► (Databricks-specific MCP tools)                   │
│                                   Context7 (library docs, guidance)                 │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Authorization Flow

```
  User in VS Code
       │
       │  1. Entra ID login (VS Code Azure Account extension)
       │     → acquires delegated tokens for:
       │        • Azure DevOps (api://...)
       │        • Fabric / Power BI (https://analysis.windows.net/powerbi/api)
       │        • Microsoft Graph (M365 services)
       │        • Power Platform (environment scope)
       │
       ▼
  MCP Server receives tool call
       │
       │  2. stdio servers: inherit VS Code process identity
       │     HTTP servers: VS Code passes bearer token in Authorization header
       │
       ▼
  External API
       │
       │  3. API validates token against:
       │     • Tenant ID
       │     • App registration scopes
       │     • Workspace-level RBAC (Fabric: Admin/Member/Contributor/Viewer)
       │     • Resource-level ACLs (ADO: project permissions, work item area paths)
       │
       ▼
  Response → MCP Server → Agent → Orchestrator → User
```

---

## Shared Resource Layer

Both Fabric and Databricks use a shared resource layer — centralized config consumed by all capability skills.

### Fabric DevOps Resource Layout

```
fabric-devops/
├── config/
│   ├── workspace-catalog.yaml     ← Environment → Workspace ID + permissions
│   ├── execution-router.yaml      ← Engine definitions, route policies, event overrides
│   └── intent-router.yaml         ← Trigger → skill mapping (reference; skills are authoritative)
└── modules/
    ├── safety-guardrails.md       ← Universal safety rules (PROD read-only, etc.)
    ├── capability-matrix.md       ← Lifecycle event → engine coverage matrix
    ├── execution-routing.md       ← Deterministic engine selection procedure
    ├── runtime-checks.md          ← Concrete engine availability checks
    ├── develop.md                 ← Canonical procedure for develop skill
    ├── operate-monitor.md         ← Canonical procedure for monitoring skill
    ├── lakehouse-diagnostics.md   ← Canonical procedure for diagnostics skill
    ├── validate.md                ← Canonical procedure for validation skill
    ├── semantic-model-testing.md  ← Canonical procedure for semantic model skill
    ├── analyze-lineage.md         ← Canonical procedure for lineage skill
    └── release-promote.md         ← Canonical procedure for promotion skill
```

### Workspace Catalog

The workspace catalog maps friendly environment names to Fabric workspace IDs and permissions:

```yaml
workspaces:
  - environment: DEV
    name: "Contoso Analytics [DEV]"
    workspaceId: "xxxxxxxx-xxxx-..."
    writeAllowed: true                    # ← Skills check this before writes
    defaultLakehouseName: "MainLakehouse"
    defaultLakehouseId: "yyyyyyyy-yyyy-..."

  - environment: PROD
    name: "Contoso Analytics [PROD]"
    workspaceId: "zzzzzzzz-zzzz-..."
    writeAllowed: false                   # ← Enforced: PROD is read-only
```

When a user says "in DEV", the agent resolves to the full workspace ID, lakehouse ID, and permission flags from this single file. All seven capability skills consume the same catalog.

---

## Safety Guardrails

Safety is enforced at multiple layers, not just one:

```
┌──────────────────────────────────────────────────────────────────┐
│  LAYER 1: WORKSPACE CATALOG                                     │
│  writeAllowed: false on PROD workspaces                         │
│  → Skills check before any write operation                      │
├──────────────────────────────────────────────────────────────────┤
│  LAYER 2: SAFETY-GUARDRAILS.MD                                  │
│  Universal rules consumed by every skill:                       │
│  • PROD: list, get, export, query, compare, status ONLY         │
│  • No create/update/delete/deploy/commit on PROD                │
│  • Require explicit env confirmation for DEV/UAT writes         │
│  • Prefer promotion pipelines over direct modifications         │
├──────────────────────────────────────────────────────────────────┤
│  LAYER 3: AGENT INSTRUCTIONS                                    │
│  fabric-devops.agent.md enforces:                               │
│  • "Never perform write operations in PROD workspaces"          │
│  • Execution contract includes safety check as mandatory step   │
├──────────────────────────────────────────────────────────────────┤
│  LAYER 4: ORCHESTRATOR PROMPT CONSTRUCTION                      │
│  Orchestrator includes "Constraints: PROD is read-only"         │
│  in every runSubagent prompt targeting PROD                     │
└──────────────────────────────────────────────────────────────────┘
```

| Action | DEV | UAT | PROD |
| :--- | :--- | :--- | :--- |
| List / Get / Query | ✅ | ✅ | ✅ |
| Export / Compare | ✅ | ✅ | ✅ |
| Create / Update | ✅ (with confirmation) | ✅ (with confirmation) | ❌ Blocked |
| Delete | ✅ (with confirmation) | ✅ (with confirmation) | ❌ Blocked |
| Deploy / Promote | ✅ Source | ✅ Source or Target | ❌ Direct write blocked; use pipeline |

---

## Self-Declaring Skill Pattern

Skills are the atomic unit of capability. Each `SKILL.md` file declares everything the agent needs to route and execute:

```yaml
# Example: fabric-devops-operate-monitor/SKILL.md frontmatter

name: fabric-devops-operate-monitor
description: Inventory Fabric items, monitor job execution health, summarize run trends.

# ── Intent declaration (the agent reads these to route) ──
Triggers: monitor, status, inventory, jobs, run history, health
Weight: 1.0
Minimum Confidence: 0.45

# ── Engine preference (the router reads these) ──
Engine Preference:
  Primary: fabric-api
  Secondary: fabric-cli
  Analytical: fabric-sempy
  Fallback: context7-guidance

# ── Procedure reference ──
Canonical Procedure: ../fabric-devops/modules/operate-monitor.md

# ── Guardrails ──
Guardrails: ../fabric-devops/modules/safety-guardrails.md
```

### Why Self-Declaring?

```
Traditional approach:                 Self-declaring approach:
─────────────────────                 ─────────────────────────
Agent has hardcoded routing table     Agent reads skill declarations at runtime
Adding a skill = edit agent + skill   Adding a skill = add SKILL.md only
Routing logic is centralized          Routing logic is distributed
Agent is the bottleneck               Skills are autonomous
```

Adding a new capability = adding a new `SKILL.md` file. No agent code changes needed.

---

## Agents

| Agent | Domain | Key Responsibility | Tool Access |
| :--- | :--- | :--- | :--- |
| **Orchestrator** | Cross-domain | Classify intent, route to specialists, compose multi-agent workflows, context verification, write gates | `runSubagent`, `todo` only |
| **Chief of Staff** | M365 | M365 triage, status emails, meeting prep, comms drafts | WorkIQ, Mail, Calendar, Teams, Word, M365 Copilot |
| **ADO DevOps** | Azure DevOps | Work items, compliance, board hygiene, multi-item disambiguation, test cases | ADO MCP, Context7, Docs |
| **Fabric DevOps** | Microsoft Fabric | Full lifecycle — develop, monitor, diagnose, validate, lineage, promote, data access routing | Fabric MCP, Power BI, MSSQL, Context7, Docs |
| **Databricks DevOps** | Azure Databricks | Full lifecycle — notebooks, jobs, clusters, Unity Catalog, security | Databricks-specific tools, Context7 |
| **Wiki DevOps** | Azure DevOps Wiki | Wiki content management and operations | ADO MCP |

### Agent Design Rules

1. **Agents are thin dispatchers.** Heavy lifting lives in skills.
2. **Least-privilege toolsets.** Each agent only sees tools for its domain.
3. **Users talk to the Orchestrator.** It delegates to the right specialist.
4. **Agents own context; skills own procedure.** The agent resolves *where* and *which guardrails*; the skill knows *how*.
5. **Server-side default.** Agents operate via MCP/API calls, not local file I/O, unless the user provides explicit local context.

---

## Skills

Skills are `SKILL.md` files that declare their intent triggers, engine preferences, and step-by-step procedures.

### Chief of Staff Skills

| Skill | Purpose | Example Trigger |
| :--- | :--- | :--- |
| **Daily Status Email** | Synthesize day → formatted email, auto-send | "Generate my daily status" |

### ADO DevOps Skills

| Skill | Purpose | Example Trigger |
| :--- | :--- | :--- |
| **Create Task** | M365 signals → ADO tasks, or direct task creation | "Create tasks from my standup" |
| **Update User Story** | Enrich ADO stories with requirements from references | "Update story 12345 with the BRD" |
| **Board Hygiene Audit** | 28-point compliance check, scored report, optional auto-fix | "Audit the sprint board for hygiene issues" |

### Fabric DevOps Skills

| Skill | Weight | Purpose | Example Trigger |
| :--- | :--- | :--- | :--- |
| **Develop** | 1.0 | Create/update notebooks, pipelines, lakehouses | "Create a notebook in DEV" |
| **Operate & Monitor** | 1.0 | Inventory, job health, failure summaries | "What's failing in DEV?" |
| **Lakehouse Diagnostics** | 1.0 | Trace load failures, dependency issues | "Why did the Bronze table fail?" |
| **Validate** | 0.95 | Cross-environment config and metadata comparison | "Validate DEV matches UAT" |
| **Semantic Model Testing** | 1.1 | Schema drift, row counts, metric variance | "Compare semantic model DEV vs PROD" |
| **Analyze Lineage** | 1.05 | Lakehouse → semantic model → report lineage | "What reports depend on FactClaims?" |
| **Release & Promote** | 1.0 | Lifecycle promotion DEV → UAT → PROD | "Promote my notebook to UAT" |

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

---

## End-to-End Request Flow — Walkthrough

Here is a complete trace of what happens when a user says: **"Promote my notebook to UAT and validate"**

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  1. USER INPUT                                                                          │
│     "Promote my notebook to UAT and validate"                                           │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  2. ORCHESTRATOR — INTENT CLASSIFICATION                                                │
│                                                                                         │
│  Signal extraction:                                                                     │
│    Platform: "notebook"    → Fabric ✓                                                   │
│    Actions:  "promote"     → release-promote                                            │
│              "validate"    → validate                                                    │
│    Env:      "UAT"         → env-aware                                                  │
│                                                                                         │
│  Scoring:                                                                               │
│    fabric-devops:  0.88    → ROUTE                                                      │
│    all others:     < 0.2                                                                │
│                                                                                         │
│  Decomposition:                                                                         │
│    Subtask A: promote (release-promote skill)                                           │
│    Subtask B: validate (validate skill) — depends on A's output                         │
│    → Sequential execution                                                               │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  3. ORCHESTRATOR — PROMPT CONSTRUCTION (Step A)                                         │
│                                                                                         │
│  runSubagent(agentName="fabric-devops", prompt="""                                      │
│    ## Objective                                                                         │
│    Promote notebook to UAT via deployment pipeline.                                     │
│    ## Context                                                                           │
│    Target: UAT (yyyyyyyy-yyyy-...)                                                      │
│    ## Skill Hint                                                                        │
│    Activate fabric-devops-release-promote                                               │
│    ## Expected Output                                                                   │
│    Pipeline run ID, promoted items, status                                              │
│    ## Constraints                                                                       │
│    UAT write allowed. Do not touch PROD.                                                │
│  """)                                                                                   │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  4. FABRIC DEVOPS AGENT — INTERNAL ROUTING                                              │
│                                                                                         │
│  a. Score triggers → release-promote wins (0.90 × 1.0)                                  │
│  b. Resolve workspace → UAT: yyyyyyyy-..., writeAllowed: true                           │
│  c. Resolve engine → fabric-api (primary for promote-release)                           │
│  d. Safety check → UAT write allowed ✓                                                  │
│  e. Execute modules/release-promote.md procedure                                        │
│     → Fabric API: trigger deployment pipeline                                           │
│     → Fabric API: poll pipeline run status                                              │
│  f. Return: Pipeline run ID 12345, status: Succeeded                                   │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         │  output: run ID, status
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  5. ORCHESTRATOR — PROMPT CONSTRUCTION (Step B, chained)                                │
│                                                                                         │
│  runSubagent(agentName="fabric-devops", prompt="""                                      │
│    ## Objective                                                                         │
│    Run post-deployment validation on UAT.                                               │
│    ## Context                                                                           │
│    Deployment pipeline run ID 12345 just completed.                                     │
│    Source: DEV. Target: UAT.                                                            │
│    ## Skill Hint                                                                        │
│    Activate fabric-devops-validate                                                      │
│    ## Expected Output                                                                   │
│    PASS/WARN/FAIL with item comparison table.                                           │
│  """)                                                                                   │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  6. FABRIC DEVOPS AGENT — INTERNAL ROUTING (validate)                                   │
│                                                                                         │
│  a. Score triggers → validate wins (0.85 × 0.95)                                        │
│  b. Resolve workspaces → DEV + UAT                                                      │
│  c. Resolve engine → fabric-sempy (primary for validate)                                │
│  d. Execute modules/validate.md procedure                                               │
│     → Power BI Remote: GetSemanticModelSchema (DEV vs UAT)                              │
│     → Fabric MCP: onelake_item_list (inventory comparison)                              │
│  e. Return: PASS — 14/14 items match, schema parity confirmed                          │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  7. ORCHESTRATOR — RESULT SYNTHESIS                                                     │
│                                                                                         │
│  ## Summary                                                                             │
│  Notebook promoted to UAT and post-deployment validation passed.                        │
│                                                                                         │
│  ## Results                                                                             │
│  ### Promotion                                                                          │
│  Pipeline run 12345 — Succeeded. 1 notebook promoted DEV → UAT.                        │
│                                                                                         │
│  ### Validation                                                                         │
│  PASS — 14/14 items match. Schema parity confirmed.                                    │
│                                                                                         │
│  ## Next Actions                                                                        │
│  1. Run semantic model testing if data freshness matters                                │
│  2. Proceed to UAT → PROD promotion when ready                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Error Recovery

| Failure Mode | Recovery Action |
| :--- | :--- |
| Subagent returns tool error (auth, API down) | Report specific error. Suggest credential check. Do not auto-retry. |
| Empty/no-data result | Report no data found. Suggest wider time range or different environment. |
| Partial completion (some steps OK, some failed) | Report successes and failures separately. Offer retry for failed portion. |
| Multi-agent: one fails, other succeeds | Deliver successful result. Report failure. Offer targeted retry. |
| Classification ambiguity | Ask one focused clarifying question. Never guess between agents. |
| Engine unavailable at runtime | Fall through to next engine in cascade. If all unavailable, return context7 guidance. |

---

## Extending the System

| Want To... | Do This |
| :--- | :--- |
| Add a new Fabric capability | Create `skills/fabric-devops-<name>/SKILL.md` with intent declarations |
| Add a new workspace | Edit `skills/fabric-devops/config/workspace-catalog.yaml` |
| Change safety rules | Edit `skills/fabric-devops/modules/safety-guardrails.md` |
| Add a new execution engine | Edit `skills/fabric-devops/config/execution-router.yaml` |
| Add a new MCP server | Edit `.vscode/mcp.json` + add tools to agent's `.agent.md` frontmatter |
| Change personal ADO defaults | Edit `config/user-context.yaml` |
| Add a new agent | Create `.github/agents/<name>.agent.md` + register in `orchestrator.agent.md` |
| Add ambiguity rules | Edit `skills/fabric-devops/config/intent-router.yaml` `ambiguityRules` section |
| Run agent evaluations | `@orchestrator Run the evaluation suite` — tests 54 scenarios across 12 categories |
| Add evaluation scenarios | Edit `.github/evaluations/eval-manifest.yaml` |
