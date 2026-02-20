# Fabric DevOps Agent — Architecture

> Deep-dive into the internals of the Fabric DevOps agent: intent routing, skill activation, execution engines, MCP tool topology, authorization, shared resources, safety guardrails, and how it all connects to the overall orchestrator architecture.

---

## Table of Contents

- [Position in the Overall System](#position-in-the-overall-system)
- [Agent Internals — High-Level](#agent-internals--high-level)
- [Intent Routing Pipeline](#intent-routing-pipeline)
  - [Step-by-Step Flow](#step-by-step-flow)
  - [Scoring Formula](#scoring-formula)
  - [Ambiguity Resolution](#ambiguity-resolution)
  - [Resolution Order](#resolution-order)
- [Skill Activation Table](#skill-activation-table)
  - [Skill Detail Cards](#skill-detail-cards)
  - [Self-Declaring Skill Pattern](#self-declaring-skill-pattern)
- [Execution Engine Routing](#execution-engine-routing)
  - [Engine Selection Flow](#engine-selection-flow)
  - [Engine × Intent Matrix](#engine--intent-matrix)
  - [Event Overrides](#event-overrides)
  - [Route Policies](#route-policies)
  - [Runtime Availability Checks](#runtime-availability-checks)
- [MCP Tool Topology & Authorization](#mcp-tool-topology--authorization)
  - [Tool Permission Boundary](#tool-permission-boundary)
  - [MCP Servers Used by Fabric DevOps](#mcp-servers-used-by-fabric-devops)
  - [Authorization Flow](#authorization-flow)
  - [Token Scope Map](#token-scope-map)
- [Shared Resource Layer](#shared-resource-layer)
  - [Directory Layout](#directory-layout)
  - [Workspace Catalog](#workspace-catalog)
  - [Execution Router Config](#execution-router-config)
  - [Intent Router Config](#intent-router-config)
  - [Procedure Modules](#procedure-modules)
- [Safety Guardrails — Multi-Layer Enforcement](#safety-guardrails--multi-layer-enforcement)
- [How the Orchestrator Invokes Fabric DevOps](#how-the-orchestrator-invokes-fabric-devops)
  - [Orchestrator → Agent Handoff](#orchestrator--agent-handoff)
  - [Prompt Construction Protocol](#prompt-construction-protocol)
  - [Multi-Skill Chaining](#multi-skill-chaining)
- [End-to-End Walkthrough](#end-to-end-walkthrough)
- [Capability Matrix](#capability-matrix)
- [Error Recovery](#error-recovery)
- [Extending Fabric DevOps](#extending-fabric-devops)

---

## Position in the Overall System

The Fabric DevOps agent sits at **Layer 2 (Domain Agent)** in the three-layer architecture. The orchestrator routes to it; it dispatches to capability skills; skills call MCP tools.

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  LAYER 1 — ORCHESTRATOR                                                                 │
│  Intent classification · Agent routing · Multi-agent composition · Result synthesis      │
│  Tools: runSubagent, todo ONLY — no domain tools                                        │
└────────┬───────────────────┬────────────────────────┬──────────────────┬────────────────┘
         │                   │                        │                  │
         ▼                   ▼                        ▼                  ▼
┌──────────────┐  ┌══════════════════╗  ┌──────────────────┐  ┌──────────────────────┐
│ Chief of     │  ║ FABRIC DEVOPS    ║  │ Databricks       │  │ ADO DevOps           │
│ Staff        │  ║ ◄── THIS DOC     ║  │ DevOps           │  │ (Work items,         │
│ (M365)       │  ║ 7 skills         ║  │ (7 skills)       │  │  compliance)         │
└──────────────┘  ╚════════╤═════════╝  └──────────────────┘  └──────────────────────┘
                           │
         ┌─────────────────┼─────────────────────────────────────┐
         ▼                 ▼                                     ▼
┌──────────────┐  ┌──────────────┐          ...           ┌──────────────┐
│ Develop      │  │ Operate &    │                        │ Release &    │
│ SKILL.md     │  │ Monitor      │                        │ Promote      │
│              │  │ SKILL.md     │                        │ SKILL.md     │
└──────┬───────┘  └──────┬───────┘                        └──────┬───────┘
       │                 │                                       │
       ▼                 ▼                                       ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  MCP SERVERS (Fabric MCP · Power BI Remote · MSSQL · Context7 · Microsoft Docs)         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

**Key distinction:** The orchestrator decides *which agent*. The agent decides *which skill*. The skill decides *which procedure steps and tool calls*.

---

## Agent Internals — High-Level

```
┌═══════════════════════════════════════════════════════════════════════════════════════════┐
║                            FABRIC DEVOPS AGENT                                           ║
║                                                                                          ║
║  ┌────────────────────────────────────────────────────────────────────────────────────┐  ║
║  │  ROUTING ENGINE                                                                    │  ║
║  │                                                                                    │  ║
║  │  1. Score user request against skill-declared triggers                             │  ║
║  │  2. Apply intent weights and ambiguity rules                                       │  ║
║  │  3. Resolve workspace (environment → ID + permissions)                             │  ║
║  │  4. Resolve execution engine (intent → engine cascade)                             │  ║
║  │  5. Enforce safety guardrails                                                      │  ║
║  │  6. Dispatch to winning skill's procedure module                                   │  ║
║  └────────────────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                          ║
║  ┌────────────────────────────────────────────────────────────────────────────────────┐  ║
║  │  SKILL ACTIVATION TABLE (7 self-declaring capability skills)                       │  ║
║  │                                                                                    │  ║
║  │  ┌───────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────┐ ┌──────────────┐   │  ║
║  │  │ Develop    │ │ Operate &    │ │ Lakehouse    │ │ Validate │ │ Semantic     │   │  ║
║  │  │ w=1.0      │ │ Monitor      │ │ Diagnostics  │ │ w=0.95   │ │ Model Test  │   │  ║
║  │  │ conf≥0.45  │ │ w=1.0        │ │ w=1.0        │ │ conf≥0.45│ │ w=1.1       │   │  ║
║  │  │            │ │ conf≥0.45    │ │ conf≥0.45    │ │          │ │ conf≥0.45   │   │  ║
║  │  └────────────┘ └──────────────┘ └──────────────┘ └──────────┘ └─────────────┘   │  ║
║  │  ┌──────────────┐ ┌──────────────┐                                                │  ║
║  │  │ Analyze       │ │ Release &    │                                                │  ║
║  │  │ Lineage       │ │ Promote      │                                                │  ║
║  │  │ w=1.05        │ │ w=1.0        │                                                │  ║
║  │  │ conf≥0.45     │ │ conf≥0.60    │ ◄── Higher confidence required for deployments │  ║
║  │  └──────────────┘ └──────────────┘                                                │  ║
║  └────────────────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                          ║
║  ┌────────────────────────────────────────────────────────────────────────────────────┐  ║
║  │  SHARED RESOURCE LAYER                                                             │  ║
║  │                                                                                    │  ║
║  │  config/                              modules/                                     │  ║
║  │  ├─ workspace-catalog.yaml            ├─ safety-guardrails.md                      │  ║
║  │  ├─ execution-router.yaml             ├─ capability-matrix.md                      │  ║
║  │  └─ intent-router.yaml               ├─ execution-routing.md                      │  ║
║  │                                       ├─ runtime-checks.md                        │  ║
║  │                                       ├─ develop.md                               │  ║
║  │                                       ├─ operate-monitor.md                       │  ║
║  │                                       ├─ lakehouse-diagnostics.md                 │  ║
║  │                                       ├─ validate.md                              │  ║
║  │                                       ├─ semantic-model-testing.md                │  ║
║  │                                       ├─ analyze-lineage.md                       │  ║
║  │                                       └─ release-promote.md                       │  ║
║  └────────────────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                          ║
║  ┌────────────────────────────────────────────────────────────────────────────────────┐  ║
║  │  TOOL PERMISSIONS (least-privilege boundary from .agent.md frontmatter)            │  ║
║  │                                                                                    │  ║
║  │  Fabric MCP ──► onelake_workspace_list, onelake_item_list, onelake_item_create,   │  ║
║  │                 onelake_file_list, onelake_upload_file, onelake_download_file,     │  ║
║  │                 onelake_directory_create, onelake_directory_delete,                │  ║
║  │                 onelake_file_delete, group_list                                    │  ║
║  │                                                                                    │  ║
║  │  Power BI  ──► ExecuteQuery, GetSemanticModelSchema, GenerateQuery,               │  ║
║  │                GetReportMetadata, DiscoverArtifacts                                │  ║
║  │                                                                                    │  ║
║  │  MSSQL     ──► mssql_connect, mssql_change_database, mssql_list_tables,           │  ║
║  │                mssql_list_views, mssql_show_schema, mssql_run_query                │  ║
║  │                                                                                    │  ║
║  │  Context7  ──► resolve-library-id, get-library-docs                               │  ║
║  │                                                                                    │  ║
║  │  General   ──► readFile, fileSearch, textSearch, web/fetch, todo                   │  ║
║  └────────────────────────────────────────────────────────────────────────────────────┘  ║
╚═══════════════════════════════════════════════════════════════════════════════════════════╝
```

---

## Intent Routing Pipeline

### Step-by-Step Flow

When the Fabric DevOps agent receives a delegated request (from the orchestrator via `runSubagent`), it runs this deterministic 8-step pipeline:

```
  Request from Orchestrator
  ─────────────────────────
  "Why did the Bronze table fail in DEV?"
         │
         ▼
  ┌──────────────────────────────────────┐
  │  Step 1: RESOLVE INTENT              │
  │  Match keywords against each skill's │
  │  declared triggers                   │
  │                                      │
  │  develop:               0.00         │  triggers: create, update, build...
  │  operate-monitor:       0.10         │  triggers: monitor, status, health...
  │  lakehouse-diagnostics: 0.85  ◄─ HIT│  triggers: lakehouse, table load, failure, logs
  │  validate:              0.10         │  triggers: validate, compare...
  │  semantic-model-testing:0.00         │  triggers: semantic model, schema drift...
  │  analyze-lineage:       0.05         │  triggers: lineage, trace, impact...
  │  release-promote:       0.00         │  triggers: promote, release, deploy...
  └────────────────┬─────────────────────┘
                   │
                   ▼
  ┌──────────────────────────────────────┐
  │  Step 2: APPLY ROUTE WEIGHT          │
  │                                      │
  │  Raw score × declared weight:        │
  │  0.85 × 1.0 = 0.85                  │
  │  Min confidence: 0.45 → PASS ✓       │
  └────────────────┬─────────────────────┘
                   │
                   ▼
  ┌──────────────────────────────────────┐
  │  Step 3: APPLY AMBIGUITY RULES       │
  │                                      │
  │  Check: any other skill ≥ 0.5?       │
  │  No competing intents → skip         │
  └────────────────┬─────────────────────┘
                   │
                   ▼
  ┌──────────────────────────────────────┐
  │  Step 4: RESOLVE EXECUTION PROFILE   │  ◄── execution-router.yaml
  │                                      │
  │  Intent: lakehouse-diagnostics       │
  │  Profile:                            │
  │    preferred: [fabric-api,           │
  │               fabric-sempy]          │
  │    fallback:  [fabric-cli,           │
  │               context7-guidance]     │
  └────────────────┬─────────────────────┘
                   │
                   ▼
  ┌──────────────────────────────────────┐
  │  Step 5: APPLY EVENT OVERRIDE        │
  │                                      │
  │  Event: lakehouse-load-failure?      │
  │  Override: [fabric-api, fabric-sempy,│
  │            fabric-cli]               │
  │  → fabric-api stays primary ✓        │
  └────────────────┬─────────────────────┘
                   │
                   ▼
  ┌──────────────────────────────────────┐
  │  Step 6: CHECK ENGINE AVAILABILITY   │  ◄── runtime-checks.md
  │                                      │
  │  fabric-api:                         │
  │    az account show ✓                 │
  │    get-access-token ✓                │
  │    workspace list succeeds ✓         │
  │  → fabric-api: AVAILABLE             │
  └────────────────┬─────────────────────┘
                   │
                   ▼
  ┌──────────────────────────────────────┐
  │  Step 7: EXECUTE MODULE              │  ◄── modules/lakehouse-diagnostics.md
  │                                      │
  │  Resolve workspace:                  │
  │    "DEV" → workspace-catalog.yaml    │
  │    → df9b352f-..., writeAllowed:true │
  │                                      │
  │  Execute procedure:                  │
  │  1. Enumerate lakehouse tables       │  → onelake_item_list
  │  2. Correlate failing pipeline runs  │  → Fabric API: job run history
  │  3. Trace upstream dependencies      │  → Fabric API: item references
  │  4. Surface error logs               │  → Fabric API: run logs
  │  5. Build root-cause hypothesis      │
  └────────────────┬─────────────────────┘
                   │
                   ▼
  ┌──────────────────────────────────────┐
  │  Step 8: FORMAT RESPONSE             │
  │                                      │
  │  • Scope: DEV / IncentiveReporting   │
  │  • Route: lakehouse-diagnostics →    │
  │           fabric-api                 │
  │  • Finding: FAIL — Bronze_Claims     │
  │    dependency on shortcut X broken   │
  │  • Remediation: Re-create shortcut,  │
  │    re-run Bronze pipeline            │
  │  • Next: Verify with health check    │
  └──────────────────────────────────────┘
```

### Scoring Formula

```
score(skill) = (matched_triggers / total_triggers_for_that_skill) × skill.weight
```

Contextual bonuses (applied by the agent's routing logic):
- **+0.2** if entity names in the prompt match known workspace/item catalog entries
- **+0.1** if environment keywords (DEV/UAT/PROD) are present

A skill activates when its weighted score ≥ its declared `minimumConfidence`.

### Ambiguity Resolution

When two or more skills score above their confidence threshold, dedicated ambiguity rules from `intent-router.yaml` break the tie:

```
  User: "Check if the semantic model schema drifted between DEV and PROD"
         │
         ▼
  ┌──────────────────────────────────────┐
  │  SCORING                             │
  │                                      │
  │  validate:              0.55         │ ◄── "check", "DEV and PROD"
  │  semantic-model-testing:0.75         │ ◄── "semantic model", "schema drifted"
  │                                      │
  │  Both above 0.45 → ambiguity!       │
  └────────────────┬─────────────────────┘
                   │
                   ▼
  ┌──────────────────────────────────────┐
  │  AMBIGUITY RULE APPLICATION          │
  │                                      │
  │  Rule: [validate, semantic-model-    │
  │         testing]                     │
  │  Prefer: semantic-model-testing      │
  │  When prompt contains ANY of:        │
  │    ✓ "schema drift"                  │
  │    · "row count"                     │
  │    · "metric variance"               │
  │    · "freshness"                     │
  │    · "dataset"                       │
  │                                      │
  │  Match found → semantic-model-testing│
  └──────────────────────────────────────┘
```

All declared ambiguity rules:

| Competing Intents | Prefer | When Prompt Contains |
| :--- | :--- | :--- |
| validate vs semantic-model-testing | semantic-model-testing | schema drift, row count, metric variance, freshness, dataset |
| validate vs analyze-lineage | analyze-lineage | lineage, upstream, downstream, impact, pbir, tmdl |
| develop vs release-promote | release-promote | deploy, promote, pipeline stage, dev to uat, uat to prod |

### Resolution Order

The complete 8-step pipeline codified in `intent-router.yaml`:

```
resolveIntent              ──► Match user keywords against skill-declared triggers
       │
applyRouteWeight           ──► Multiply raw score by skill's declared weight
       │
applyAmbiguityRules        ──► Prefer specific skill when prompt matches override keywords
       │
resolveExecutionProfile    ──► Look up engine cascade from execution-router.yaml
       │
applyEventOverride         ──► Switch engine order for specific lifecycle event types
       │
checkEngineAvailability    ──► Runtime checks: is the selected engine actually reachable?
       │
executeModule              ──► Run the skill's canonical procedure module
       │
formatResponse             ──► Structure output: scope, route, findings, next steps
```

---

## Skill Activation Table

| Skill | Weight | Min Confidence | Declared Triggers | Primary Engine |
| :--- | :--- | :--- | :--- | :--- |
| **Develop** | 1.0 | 0.45 | create, update, develop, build, notebook, pipeline | fabric-api |
| **Operate & Monitor** | 1.0 | 0.45 | monitor, status, inventory, jobs, run history, health | fabric-api |
| **Lakehouse Diagnostics** | 1.0 | 0.45 | lakehouse, table load, shortcut, failure, logs, dependency | fabric-api |
| **Validate** | 0.95 | 0.45 | validate, compare, post deployment, verification, prod check, metadata drift, broken object validation | fabric-sempy |
| **Semantic Model Testing** | 1.1 | 0.45 | semantic model, dataset compare, model compare, schema drift, row count variance, metric variance, data freshness, dev vs uat, uat vs prod, deployment readiness | powerbi-remote |
| **Analyze Lineage** | 1.05 | 0.45 | lineage, analyze, trace, column lineage, table lineage, report lineage, impact analysis, upstream, downstream, data flow, dependency graph, metadata, pbir, tmdl, tom, object usage, broken visuals, field mapping | fabric-sempy |
| **Release & Promote** | 1.0 | **0.60** | promote, release, deploy, dev to uat, uat to prod, deployment pipeline, stage, push to production, move to uat, lifecycle promotion | fabric-api |

**Note:** Release & Promote has a higher minimum confidence (0.60) because deployment actions carry higher risk and require clearer intent signal.

### Skill Detail Cards

#### Develop
```
Scope:        Create/update notebooks, pipelines, lakehouses, semantic models, reports
Engines:      fabric-api → fabric-cli → context7
Procedure:    modules/develop.md
Guardrails:   Block PROD writes; require env confirmation for DEV/UAT
Key tools:    onelake_item_create, onelake_upload_file, Fabric API items
Outputs:      Item IDs, validation notes, next step (test / review / promote)
```

#### Operate & Monitor
```
Scope:        Inventory items, monitor job health, summarize run trends
Engines:      fabric-api → fabric-cli → fabric-sempy → context7
Procedure:    modules/operate-monitor.md
Guardrails:   Read-only in all environments; escalate correlated failures to diagnostics
Key tools:    onelake_item_list, onelake_workspace_list, Fabric API job status
Outputs:      PASS/WARN/FAIL health summary, failing items with run references
```

#### Lakehouse Diagnostics
```
Scope:        Diagnose load failures, trace dependency breakages, root-cause analysis
Engines:      fabric-api → fabric-sempy → fabric-cli → context7
Procedure:    modules/lakehouse-diagnostics.md
Guardrails:   Prefer read-only diagnostics first; restrict write remediation to non-PROD
Key tools:    onelake_item_list, onelake_file_list, Fabric API job history
Outputs:      Root-cause hypothesis, impacted objects, remediation plan
```

#### Validate
```
Scope:        Cross-environment metadata drift, item parity, broken object detection
Engines:      fabric-sempy → fabric-api → fabric-cli → context7
Procedure:    modules/validate.md
Guardrails:   PROD is read-only; compare-only operations
Key tools:    GetSemanticModelSchema, onelake_item_list, DiscoverArtifacts
Outputs:      PASS/WARN/FAIL with item comparison table, drift severity classification
```

#### Semantic Model Testing
```
Scope:        Schema drift, row-count variance, metric variance, data freshness parity
Engines:      powerbi-remote → fabric-sempy → fabric-api → context7
Procedure:    modules/semantic-model-testing.md
Thresholds:   Row count >5% WARN / >20% FAIL, Metric >0.1% WARN / >1% FAIL, Freshness >1d WARN / >3d FAIL
Key tools:    GetSemanticModelSchema, ExecuteQuery (DAX), GenerateQuery
Outputs:      Schema diff, data quality findings, overall PASS/WARN/FAIL, go/no-go recommendation
```

#### Analyze Lineage
```
Scope:        Table/column/report lineage, PBIR parsing, broken mapping detection
Engines:      fabric-sempy → fabric-api → fabric-cli → context7
Procedure:    modules/analyze-lineage.md (3-phase: scope → metadata → assembly)
Guardrails:   Read-only in ALL environments including PROD; safe for production workspaces
Key tools:    GetSemanticModelSchema, GetReportMetadata, onelake_item_list
Outputs:      Lineage graph, source→target mappings, orphan detection, coverage summary
```

#### Release & Promote
```
Scope:        DEV → UAT → PROD lifecycle promotion via deployment pipelines
Engines:      fabric-api → fabric-cli → context7
Procedure:    modules/release-promote.md (3-phase: pre-flight → promote → post-verify)
Guardrails:   PROD promotion requires explicit user confirmation; pre-flight auto-runs;
              post-deploy verification cannot be skipped
Key tools:    Fabric API deployment pipeline, onelake_item_list (verification)
Outputs:      Pre-flight report, deployment status (SUCCESS/PARTIAL/FAILED), post-deploy summary
Cross-skill:  Invokes validate and semantic-model-testing skills during pre-flight and post-deploy
```

### Self-Declaring Skill Pattern

Each skill's `SKILL.md` frontmatter declares everything the agent needs to route and execute:

```yaml
# Example: fabric-devops-operate-monitor/SKILL.md

name: fabric-devops-operate-monitor
description: Inventory Fabric items, monitor job execution health, summarize run trends.

# Intent declaration (agent reads these to route)
Triggers: monitor, status, inventory, jobs, run history, health
Weight: 1.0
Minimum Confidence: 0.45

# Engine preference (execution router reads these)
Engine Preference:
  Primary: fabric-api
  Secondary: fabric-cli
  Analytical: fabric-sempy
  Fallback: context7-guidance

# Procedure reference
Canonical Procedure: ../fabric-devops/modules/operate-monitor.md

# Safety reference
Guardrails: ../fabric-devops/modules/safety-guardrails.md
```

**Why self-declaring matters:**

| Traditional (hardcoded) | Self-Declaring |
| :--- | :--- |
| Agent has a hardcoded routing table | Agent reads skill declarations at runtime |
| Adding a skill = edit agent + skill | Adding a skill = add SKILL.md only |
| Routing logic is centralized in the agent | Routing logic is distributed across skills |
| Agent is the bottleneck for changes | Skills are autonomous and independently versioned |

Adding a new capability = creating a new `SKILL.md` file. No agent code changes needed.

---

## Execution Engine Routing

### Engine Selection Flow

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                            ENGINE SELECTION FLOW                                         │
│                                                                                          │
│  Intent resolved ────► execution-router.yaml                                             │
│                        (executionProfiles section)                                       │
│                                │                                                         │
│                 ┌──────────────┼──────────────────┐                                      │
│                 ▼              ▼                   ▼                                      │
│      ┌──────────────────┐ ┌──────────────┐ ┌───────────────────┐                         │
│      │ Write Operations │ │ Read/Analyze │ │ Advisory Only     │                         │
│      │                  │ │              │ │                   │                         │
│      │ 1. fabric-api    │ │ 1. fabric-api│ │ 1. context7       │                         │
│      │ 2. fabric-cli    │ │ 2. fabric-cli│ │    (guidance only) │                         │
│      │                  │ │ 3. fabric-   │ │                   │                         │
│      │                  │ │    sempy     │ │                   │                         │
│      └──────────────────┘ └──────────────┘ └───────────────────┘                         │
│                                                                                          │
│  ┌─ Event Override ──────────────────────────────────────────────────────────────────┐   │
│  │                                                                                    │   │
│  │  Event: column-lineage-trace                                                       │   │
│  │  Default order:  [fabric-api, fabric-cli, fabric-sempy]                            │   │
│  │  Override order: [fabric-sempy, fabric-api]  ◄── SemPy excels at lineage           │   │
│  │                                                                                    │   │
│  │  Event: semantic-model-parity                                                      │   │
│  │  Default order:  [fabric-api, fabric-cli]                                          │   │
│  │  Override order: [fabric-sempy, fabric-api]  ◄── SemPy excels at comparison        │   │
│  └────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                          │
│  ┌─ Fallback Cascade ───────────────────────────────────────────────────────────────┐    │
│  │                                                                                   │    │
│  │  fabric-api unavailable? ──► try fabric-cli                                       │    │
│  │  fabric-cli unavailable? ──► try fabric-sempy (if in profile)                     │    │
│  │  All exec engines unavailable? ──► context7-guidance (advisory only)              │    │
│  │                                    Returns guidance plan + blocker list            │    │
│  └───────────────────────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

### Engine × Intent Matrix

| Intent | Primary | Secondary | Analytical | Fallback |
| :--- | :--- | :--- | :--- | :--- |
| **develop** | fabric-api | fabric-cli | — | context7 |
| **operate-monitor** | fabric-api | fabric-cli | fabric-sempy | context7 |
| **lakehouse-diagnostics** | fabric-api | fabric-sempy | — | fabric-cli → context7 |
| **validate** | fabric-sempy | fabric-api | — | fabric-cli → context7 |
| **semantic-model-testing** | powerbi-remote | fabric-sempy | — | fabric-api → context7 |
| **analyze-lineage** | fabric-sempy | fabric-api | — | fabric-cli → context7 |
| **release-promote** | fabric-api | fabric-cli | — | context7 |

### Event Overrides

Specific lifecycle events can override the default engine order from the execution profile:

| Event | Intent | Override Engine Order |
| :--- | :--- | :--- |
| `semantic-model-parity` | validate | fabric-sempy → fabric-api |
| `report-definition-compare` | validate | fabric-api → fabric-sempy |
| `lakehouse-load-failure` | lakehouse-diagnostics | fabric-api → fabric-sempy → fabric-cli |
| `deployment-promotion` | promote-release | fabric-api → fabric-cli |
| `inventory-export` | operate-monitor | fabric-cli → fabric-api |
| `column-lineage-trace` | analyze-lineage | fabric-sempy → fabric-api |
| `report-lineage-trace` | analyze-lineage | fabric-sempy → fabric-api |
| `tenant-wide-lineage` | analyze-lineage | fabric-api → fabric-sempy |
| `report-metadata-generation` | analyze-lineage | fabric-sempy → fabric-api |
| `semantic-model-metadata-generation` | analyze-lineage | fabric-sempy → fabric-api |
| `broken-report-object-detection` | validate | fabric-sempy → fabric-api |
| `metadata-parity-validation` | validate | fabric-sempy → fabric-api |

### Route Policies

Global route policies from `execution-router.yaml`:

```yaml
routePolicy:
  defaultWriteOrder:  [fabric-api, fabric-cli]        # Writes always go through API first
  defaultReadOrder:   [fabric-api, fabric-cli, fabric-sempy]
  analyticsOrder:     [fabric-sempy, fabric-api, fabric-cli]  # Analytics prefer SemPy
  guidanceFallback:   [context7-guidance]              # Always available as last resort
```

### Fabric Engine Details

| Engine | Type | Strengths | Constraints |
| :--- | :--- | :--- | :--- |
| `fabric-api` | Fabric REST API | CRUD, job execution, deployment pipelines, workspace/item metadata | Requires auth token; long-running ops need polling |
| `fabric-cli` | Fabric CLI | Scripted automation, CI/CD, repeatable command-line workflows | Depends on CLI availability; command surface may lag API |
| `fabric-sempy` | sempy + semantic-link-labs | Metadata analysis, lineage, PBIR parsing, TOM wrappers, broken-object detection, notebook-native diagnostics | Requires Python runtime + packages; best for analytical workloads |
| `context7-guidance` | Knowledge guidance (Context7 MCP) | Implementation patterns, advisory for unfamiliar workflows | Guidance only — must pair with action engine |

### Runtime Availability Checks

Before selecting an engine, the system runs these concrete checks (from `modules/runtime-checks.md`):

| Engine | Checks |
| :--- | :--- |
| **fabric-api** | `az account show` ✓, `az account get-access-token --resource https://api.fabric.microsoft.com` ✓, workspace read succeeds ✓ |
| **fabric-cli** | `Get-Command fabric` exists ✓, `fabric --version` ✓, workspace list command succeeds ✓ |
| **fabric-sempy** | `import sempy` ✓, `import sempy_labs` ✓, `ReportWrapper` + `connect_semantic_model` importable ✓ |
| **context7** | MCP server `io.github.upstash/context7` configured in `mcp.json` ✓ |

An engine is marked `available` only if **all** its mandatory checks pass. The system selects the highest-ranked available engine from the resolved profile.

---

## MCP Tool Topology & Authorization

### Tool Permission Boundary

The Fabric DevOps agent's `.agent.md` frontmatter declares exactly which MCP tools it can call. Tools not listed are invisible to the agent. This enforces **least-privilege at the agent level**.

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│              FABRIC DEVOPS — MCP TOOL PERMISSION BOUNDARY                                │
│                                                                                          │
│  ┌─ Fabric MCP (OneLake) ──────────────────────────────────────────────────────────────┐ │
│  │  onelake_workspace_list   List all Fabric workspaces                                │ │
│  │  onelake_item_list        List items (notebooks, pipelines, lakehouses, etc.)       │ │
│  │  onelake_item_create      Create new items in a workspace                           │ │
│  │  onelake_file_list        List files within a lakehouse/item                        │ │
│  │  onelake_upload_file      Upload files to OneLake                                   │ │
│  │  onelake_download_file    Download files from OneLake                               │ │
│  │  onelake_directory_create Create directories in OneLake                             │ │
│  │  onelake_directory_delete Delete directories from OneLake                           │ │
│  │  onelake_file_delete      Delete files from OneLake                                │ │
│  │  group_list               List workspace groups/membership                          │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                          │
│  ┌─ Power BI Remote ──────────────────────────────────────────────────────────────────┐  │
│  │  ExecuteQuery             Execute DAX queries against semantic models               │  │
│  │  GetSemanticModelSchema   Retrieve full schema (tables, columns, measures, rels)    │  │
│  │  GenerateQuery            Auto-generate DAX for natural-language questions          │  │
│  │  GetReportMetadata        Report pages, visuals, and data bindings                 │  │
│  │  DiscoverArtifacts        Discover datasets, reports, and workspaces               │  │
│  └─────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                          │
│  ┌─ MSSQL ────────────────────────────────────────────────────────────────────────────┐  │
│  │  mssql_connect            Connect to Fabric SQL endpoint                           │  │
│  │  mssql_change_database    Switch lakehouse/warehouse context                       │  │
│  │  mssql_list_tables        List tables in current database                          │  │
│  │  mssql_list_views         List views                                               │  │
│  │  mssql_show_schema        Show table/view schema details                           │  │
│  │  mssql_run_query          Execute T-SQL queries                                    │  │
│  └─────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                          │
│  ┌─ Context7 ─────────────────────────────────────────────────────────────────────────┐  │
│  │  resolve-library-id       Find library ID for documentation lookup                 │  │
│  │  get-library-docs         Retrieve implementation guidance and patterns            │  │
│  └─────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                          │
│  ┌─ General ──────────────────────────────────────────────────────────────────────────┐  │
│  │  readFile                 Read local files (skill definitions, config)              │  │
│  │  fileSearch               Search for files by pattern                              │  │
│  │  textSearch               Grep/search within files                                 │  │
│  │  web/fetch                Fetch URLs (documentation, API docs)                     │  │
│  │  todo                     Manage task list within conversation                     │  │
│  └─────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                          │
│  ┌─ NOT accessible (belongs to other agents) ─────────────────────────────────────────┐  │
│  │  ✗ Azure DevOps MCP       → ADO DevOps only                                      │  │
│  │  ✗ WorkIQ / Mail / Cal    → Chief of Staff only                                    │  │
│  │  ✗ Teams Server           → Chief of Staff only                                    │  │
│  │  ✗ Playwright             → Cross-agent browser automation                         │  │
│  │  ✗ runSubagent            → Orchestrator only                                      │  │
│  └─────────────────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

### MCP Servers Used by Fabric DevOps

| Server | ID in `mcp.json` | Transport | Auth | What It Provides |
| :--- | :--- | :--- | :--- | :--- |
| **Fabric MCP** | `fabric-mcp` | VS Code extension | Entra ID (Fabric token) | OneLake file/item CRUD, workspace listing |
| **Power BI Remote** | `powerbi-remote` | HTTP → `api.fabric.microsoft.com` | Entra ID (Fabric token) | DAX queries, semantic model schema, report metadata, artifact discovery |
| **MSSQL** | `ms-mssql.mssql` | VS Code extension | Entra ID / SQL auth | T-SQL against Fabric SQL endpoints, lakehouse tables |
| **Context7** | `io.github.upstash/context7` | stdio (npx) | API key | Library documentation lookup, implementation guidance |
| **Microsoft Docs** | `microsoftdocs/mcp` | HTTP → `learn.microsoft.com` | None (public) | Search + fetch Microsoft Learn documentation |

### Authorization Flow

```
  ┌─────────────────────────────────────────────────────────────────────────────────┐
  │  VS Code User Session                                                           │
  │                                                                                 │
  │  1. USER AUTHENTICATES                                                          │
  │     Azure Account extension → Entra ID login                                    │
  │     Acquires delegated tokens scoped to:                                        │
  │       • https://api.fabric.microsoft.com    (Fabric REST API)                   │
  │       • https://analysis.windows.net/powerbi/api  (Power BI)                    │
  │       • https://database.windows.net         (SQL endpoints)                    │
  │                                                                                 │
  │  2. AGENT MAKES TOOL CALL                                                       │
  │     Fabric DevOps agent → invokes MCP tool (e.g., ExecuteQuery)                 │
  │                                                                                 │
  │  3. MCP SERVER HANDLES AUTH                                                     │
  │     ┌─ stdio servers ────────────────────────────────────────────────────┐      │
  │     │  Inherit VS Code process identity                                  │      │
  │     │  Token passed via environment / credential chain                   │      │
  │     └────────────────────────────────────────────────────────────────────┘      │
  │     ┌─ HTTP servers ─────────────────────────────────────────────────────┐      │
  │     │  VS Code passes bearer token in Authorization header               │      │
  │     │  Server forwards to target API                                     │      │
  │     └────────────────────────────────────────────────────────────────────┘      │
  │                                                                                 │
  │  4. EXTERNAL API VALIDATES                                                      │
  │     Token validated against:                                                    │
  │       • Tenant ID                                                               │
  │       • App registration scopes                                                 │
  │       • Workspace-level RBAC (Admin / Member / Contributor / Viewer)             │
  │       • Item-level permissions (semantic model, lakehouse, pipeline)             │
  │                                                                                 │
  │  5. RESPONSE FLOWS BACK                                                         │
  │     External API → MCP Server → Agent → Orchestrator → User                    │
  └─────────────────────────────────────────────────────────────────────────────────┘
```

### Token Scope Map

| Operation Type | Required Token Scope | Example Tool Call |
| :--- | :--- | :--- |
| Workspace operations | `https://api.fabric.microsoft.com` | `onelake_workspace_list` |
| Item CRUD | `https://api.fabric.microsoft.com` | `onelake_item_create` |
| DAX queries | `https://analysis.windows.net/powerbi/api` | `ExecuteQuery` |
| Schema retrieval | `https://analysis.windows.net/powerbi/api` | `GetSemanticModelSchema` |
| SQL queries | `https://database.windows.net` | `mssql_run_query` |
| Library docs | Context7 API key | `get-library-docs` |
| Microsoft Learn | None (public) | `microsoft_docs_search` |

---

## Shared Resource Layer

### Directory Layout

```
.github/skills/fabric-devops/
├── SKILL.md                           ← Shared resource layer declaration
├── config/
│   ├── workspace-catalog.yaml         ← Environment → workspace ID + permissions + defaults
│   ├── execution-router.yaml          ← Engine definitions, route policies, event overrides, execution profiles
│   └── intent-router.yaml             ← Trigger→skill reference index, ambiguity rules, resolution order
└── modules/
    ├── safety-guardrails.md           ← Universal safety rules (PROD read-only, etc.)
    ├── capability-matrix.md           ← Lifecycle event → engine coverage matrix
    ├── execution-routing.md           ← Deterministic engine selection procedure
    ├── runtime-checks.md             ← Concrete engine availability check commands
    ├── develop.md                     ← Canonical procedure for build/update skill
    ├── operate-monitor.md             ← Canonical procedure for inventory/health skill
    ├── lakehouse-diagnostics.md       ← Canonical procedure for failure diagnostics skill
    ├── validate.md                    ← Canonical procedure for cross-env validation skill
    ├── semantic-model-testing.md      ← Canonical procedure for semantic model QA skill
    ├── analyze-lineage.md             ← Canonical procedure for lineage tracing skill
    └── release-promote.md             ← Canonical procedure for promotion skill
```

All seven capability skills consume these shared resources via relative file references. Change a workspace ID, engine definition, or safety rule in one place → all skills pick it up.

### Workspace Catalog

Maps friendly environment names to concrete Fabric identifiers and permission flags:

```yaml
# config/workspace-catalog.yaml
workspaces:
  - environment: DEV
    name: "GPS Investments & Incentives [DEV]"
    workspaceId: "df9b352f-ff95-4701-a74a-1d2d3313d717"
    writeAllowed: true
    defaultLakehouseName: "IncentiveReporting"
    defaultLakehouseId: "5f103236-bcaf-4edf-85f7-5181432a2e7c"

  - environment: UAT
    name: "GPS Investments & Incentives [UAT]"
    workspaceId: "456bc970-249a-43dc-8ebf-d04184834876"
    writeAllowed: true
    defaultLakehouseName: "IncentiveReporting"
    defaultLakehouseId: "f2b5be99-e8d4-4c8c-9507-9023e2a49c3f"

  - environment: PROD
    name: "GPS Investments & Incentives [PROD]"
    workspaceId: "1b5aa9f1-a783-4820-8818-ad3bb2fc9ca9"
    writeAllowed: false                                         # ← ENFORCED: PROD read-only
    defaultLakehouseName: "IncentiveReporting"
    defaultLakehouseId: "63a9d305-4e2f-4fbf-89d3-f04e1ab5041e"
```

When a user says "in DEV", the routing pipeline resolves the full workspace ID, default lakehouse, and permission flags from this single file.

### Execution Router Config

Defines engines, route policies, per-intent profiles, and event overrides:

```yaml
# config/execution-router.yaml (key sections)

engines:
  - id: fabric-api       # Fabric REST API
  - id: fabric-cli       # Fabric CLI
  - id: fabric-sempy     # sempy + semantic-link-labs
  - id: context7-guidance # Advisory-only fallback

routePolicy:
  defaultWriteOrder:  [fabric-api, fabric-cli]
  defaultReadOrder:   [fabric-api, fabric-cli, fabric-sempy]
  analyticsOrder:     [fabric-sempy, fabric-api, fabric-cli]
  guidanceFallback:   [context7-guidance]

executionProfiles:
  develop:               { preferred: [fabric-api, fabric-cli],    fallback: [context7-guidance] }
  operate-monitor:       { preferred: [fabric-api, fabric-cli],    fallback: [fabric-sempy, context7-guidance] }
  lakehouse-diagnostics: { preferred: [fabric-api, fabric-sempy],  fallback: [fabric-cli, context7-guidance] }
  validate:              { preferred: [fabric-sempy, fabric-api],  fallback: [fabric-cli, context7-guidance] }
  semantic-model-testing:{ preferred: [powerbi-remote, fabric-sempy], fallback: [fabric-api, context7-guidance] }
  analyze-lineage:       { preferred: [fabric-sempy, fabric-api],  fallback: [fabric-cli, context7-guidance] }
  promote-release:       { preferred: [fabric-api, fabric-cli],    fallback: [context7-guidance] }

eventOverrides:
  - event: column-lineage-trace    → [fabric-sempy, fabric-api]
  - event: semantic-model-parity   → [fabric-sempy, fabric-api]
  - event: deployment-promotion    → [fabric-api, fabric-cli]
  # ... (12 overrides total)
```

### Intent Router Config

Reference index of trigger→skill mappings and ambiguity resolution rules:

```yaml
# config/intent-router.yaml (key sections)

routing:
  strategy: weighted-intent-match
  minimumConfidence: 0.45
  ambiguityMargin: 0.15
  allowMultiIntentWhenIndependent: true

routes:
  - intent: develop               → fabric-devops-develop          (w=1.0)
  - intent: operate-monitor       → fabric-devops-operate-monitor  (w=1.0)
  - intent: lakehouse-diagnostics → fabric-devops-lakehouse-diagnostics (w=1.0)
  - intent: validate              → fabric-devops-validate         (w=0.95)
  - intent: semantic-model-testing→ fabric-devops-semantic-model-testing (w=1.1)
  - intent: analyze-lineage       → fabric-devops-analyze-lineage  (w=1.05)
  - intent: promote-release       → fabric-devops-release-promote  (w=1.0)

ambiguityRules:
  - [validate, semantic-model-testing]  → prefer semantic-model-testing
  - [validate, analyze-lineage]         → prefer analyze-lineage
  - [develop, promote-release]          → prefer promote-release

resolutionOrder:
  resolveIntent → applyRouteWeight → applyAmbiguityRules →
  resolveExecutionProfile → applyEventOverride → checkEngineAvailability →
  executeModule → formatResponse
```

**Note:** Skills are authoritative for their own triggers and weights. This file is a reference index — the agent reads skills directly at runtime.

### Procedure Modules

Each procedure module is consumed by exactly one capability skill and follows a consistent structure:

| Module | Consumed By | Key Steps |
| :--- | :--- | :--- |
| `develop.md` | Develop | Resolve env → validate deps → apply create/update → smoke test → return IDs |
| `operate-monitor.md` | Operate & Monitor | Resolve workspace → inventory by type → pull job status → highlight failures → health summary |
| `lakehouse-diagnostics.md` | Lakehouse Diagnostics | Resolve workspace → enumerate tables → correlate failures → trace deps → root-cause |
| `validate.md` | Validate | Resolve envs → compare inventory → compare definitions → metadata parity → severity summary |
| `semantic-model-testing.md` | Semantic Model Testing | Resolve datasets → fetch schemas → diff → row counts → metrics → freshness → go/no-go |
| `analyze-lineage.md` | Analyze Lineage | Scope resolution → metadata collection → lineage assembly → orphan detection → graph output |
| `release-promote.md` | Release & Promote | Pre-flight validation → enumerate items → deploy pipeline → post-deploy verify → summary |

---

## Safety Guardrails — Multi-Layer Enforcement

Safety is not enforced at a single checkpoint — it's layered across four independent enforcement points:

```
┌═══════════════════════════════════════════════════════════════════════════════┐
║  LAYER 1: WORKSPACE CATALOG                                                  ║
║  config/workspace-catalog.yaml                                               ║
║                                                                              ║
║  PROD workspace has writeAllowed: false                                      ║
║  → Every skill checks this flag before any write operation                   ║
║  → Even if all other layers fail, this blocks PROD writes                    ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  LAYER 2: SAFETY-GUARDRAILS.MD                                               ║
║  modules/safety-guardrails.md                                                ║
║                                                                              ║
║  Universal rules consumed by every skill:                                    ║
║  • PROD: list, get, export, query, compare, status ONLY                      ║
║  • No create/update/delete/deploy/commit on PROD                             ║
║  • Require explicit env confirmation for DEV/UAT writes                      ║
║  • Prefer promotion pipelines over direct modifications                      ║
║  • Stop and ask if environment cannot be resolved                            ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  LAYER 3: AGENT INSTRUCTIONS                                                 ║
║  .github/agents/fabric-devops.agent.md                                       ║
║                                                                              ║
║  Agent-level enforcement:                                                    ║
║  • "Never perform write operations in PROD workspaces" in system prompt      ║
║  • Execution contract mandates safety check as Step 5 (before execution)     ║
║  • PROD allowed: read-only (list/get/export/query/compare/status)            ║
║  • DEV → UAT → PROD promotion through deployment pipelines only              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  LAYER 4: ORCHESTRATOR PROMPT CONSTRUCTION                                   ║
║  .github/agents/orchestrator.agent.md                                        ║
║                                                                              ║
║  When constructing runSubagent prompts for PROD-scoped requests:             ║
║  • Always includes "Constraints: PROD is read-only"                          ║
║  • Always includes "Do not perform write operations"                         ║
║  • This constraint is injected before the agent even starts processing       ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

### Environment Permission Matrix

| Action | DEV | UAT | PROD |
| :--- | :--- | :--- | :--- |
| List / Get / Query | ✅ | ✅ | ✅ |
| Export / Compare | ✅ | ✅ | ✅ |
| Create / Update | ✅ (with confirmation) | ✅ (with confirmation) | ❌ Blocked |
| Delete | ✅ (with confirmation) | ✅ (with confirmation) | ❌ Blocked |
| Deploy / Promote | ✅ Source | ✅ Source or Target | ❌ Direct write blocked |
| Lineage / Metadata | ✅ | ✅ | ✅ (read-only safe) |
| Diagnostics | ✅ (read + remediate) | ✅ (read + remediate) | ✅ Read-only diagnostics only |

### Skill-Specific Safety Behaviors

| Skill | PROD Behavior |
| :--- | :--- |
| Develop | BLOCKED — cannot create/update items in PROD |
| Operate & Monitor | ALLOWED — read-only inventory and health checks |
| Lakehouse Diagnostics | ALLOWED (read-only) — no write remediation in PROD |
| Validate | ALLOWED — compare-only, reads from PROD for comparison |
| Semantic Model Testing | ALLOWED — DAX queries and schema reads only |
| Analyze Lineage | ALLOWED — all operations are read-only by design |
| Release & Promote | PROD as target requires explicit user confirmation; pre-flight mandatory |

---

## How the Orchestrator Invokes Fabric DevOps

### Orchestrator → Agent Handoff

The orchestrator never calls Fabric tools directly. It uses `runSubagent` with a structured prompt:

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│  ORCHESTRATOR                                                                    │
│                                                                                  │
│  1. Classify intent → fabric-devops scores highest                               │
│  2. Determine skill hint (optional) from trigger analysis                        │
│  3. Construct structured prompt:                                                 │
│     ┌──────────────────────────────────────────────────────────────────────────┐ │
│     │  ## Objective                                                            │ │
│     │  [What the agent must accomplish]                                        │ │
│     │                                                                          │ │
│     │  ## Context                                                              │ │
│     │  [Entity names, environments, filters, prior results]                    │ │
│     │                                                                          │ │
│     │  ## Skill Hint                                                           │ │
│     │  Activate fabric-devops-<skill-name>                                     │ │
│     │                                                                          │ │
│     │  ## Expected Output                                                      │ │
│     │  [Format: table, PASS/FAIL, list, etc.]                                  │ │
│     │                                                                          │ │
│     │  ## Constraints                                                          │ │
│     │  [Env restrictions, PROD read-only, safety guardrails]                   │ │
│     └──────────────────────────────────────────────────────────────────────────┘ │
│  4. Call runSubagent(agentName="fabric-devops", prompt=...)                      │
│  5. Receive structured response                                                  │
│  6. Synthesize into user-facing output                                           │
└──────────────────────────────────────────────────────────────────────────────────┘
```

### Prompt Construction Protocol

The orchestrator follows these enrichment rules when building prompts for Fabric DevOps:

1. **Always forward entity names** — "AzureInvestments semantic model", "Master_Pipeline_AIPod" → include exact name
2. **Always forward environment scope** — "in PROD", "DEV vs UAT" → state explicitly
3. **Include skill hint when determinable** — bypasses the agent's internal intent classification, saving a routing step
4. **Specify output format** — table, PASS/FAIL verdict, list of items
5. **Carry forward conversation context** — if prior results exist in the conversation, summarize relevant facts

### Multi-Skill Chaining

Some requests require multiple skills to execute sequentially within the Fabric DevOps agent. The orchestrator handles this by making multiple `runSubagent` calls:

```
  User: "Promote my notebook to UAT and validate"
         │
         ▼
  Orchestrator decomposes:
    Step A: release-promote (deploy to UAT)
    Step B: validate (post-deploy check) — DEPENDS on A's output
         │
         ▼
  ┌──────────────────────────────────────────────────────────────────────┐
  │  runSubagent #1 (fabric-devops)                                     │
  │  Skill hint: release-promote                                        │
  │  → Returns: Pipeline run ID 12345, status: Succeeded                │
  └──────────────────────────────────┬─────────────────────────────────┘
                                     │  inject output as context
                                     ▼
  ┌──────────────────────────────────────────────────────────────────────┐
  │  runSubagent #2 (fabric-devops)                                     │
  │  Skill hint: validate                                               │
  │  Context: "Deployment pipeline run ID 12345 just completed"         │
  │  → Returns: PASS — 14/14 items match, schema parity confirmed       │
  └──────────────────────────────────────────────────────────────────────┘
```

The Release & Promote skill itself also orchestrates across skills internally — it invokes `validate` during pre-flight and `semantic-model-testing` during post-deployment verification.

---

## End-to-End Walkthrough

Complete trace: **"Promote my notebook to UAT and validate"**

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
│  Signals: Platform="notebook" → Fabric                                                  │
│           Actions="promote","validate" → release-promote + validate                     │
│           Env="UAT" → env-aware                                                         │
│  Score: fabric-devops 0.88 → ROUTE                                                      │
│  Decompose: Step A (promote, sequential) → Step B (validate, depends on A)              │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  3. ORCHESTRATOR → runSubagent #1                                                       │
│     Skill hint: fabric-devops-release-promote                                           │
│     Context: Target=UAT (456bc970-...), Constraints: UAT write OK, no PROD              │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  4. FABRIC DEVOPS AGENT — INTERNAL ROUTING (release-promote)                            │
│                                                                                         │
│  a. resolveIntent:           release-promote scores 0.90                                │
│  b. applyRouteWeight:        0.90 × 1.0 = 0.90 (conf ≥ 0.60 ✓)                        │
│  c. applyAmbiguityRules:     no competing intents                                       │
│  d. resolveExecutionProfile: preferred=[fabric-api, fabric-cli]                         │
│  e. applyEventOverride:      deployment-promotion → [fabric-api, fabric-cli] (same)     │
│  f. checkEngineAvailability: fabric-api checks pass ✓                                   │
│  g. resolveWorkspace:        UAT → 456bc970-..., writeAllowed: true ✓                   │
│  h. safetyCheck:             UAT write allowed ✓                                        │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  5. FABRIC DEVOPS — EXECUTE modules/release-promote.md                                  │
│                                                                                         │
│  Phase 1 (pre-flight):                                                                  │
│    → Invoke validate checks on source items                                             │
│    → All pass ✓                                                                         │
│                                                                                         │
│  Phase 2 (promotion):                                                                   │
│    → Fabric API: trigger deployment pipeline (DEV → UAT)                                │
│    → Fabric API: poll run status until complete                                         │
│    → Result: Pipeline run 12345 — Succeeded                                             │
│                                                                                         │
│  Phase 3 (post-deploy):                                                                 │
│    → Invoke validate checks on UAT target                                               │
│    → Item inventory matches ✓                                                           │
│                                                                                         │
│  Return: { runId: 12345, status: "Succeeded", itemsPromoted: 1 }                       │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         │  output injected to next prompt
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  6. ORCHESTRATOR → runSubagent #2                                                       │
│     Skill hint: fabric-devops-validate                                                  │
│     Context: "Pipeline run 12345 completed. Source=DEV, Target=UAT."                    │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  7. FABRIC DEVOPS AGENT — INTERNAL ROUTING (validate)                                   │
│                                                                                         │
│  a. resolveIntent:           validate scores 0.85                                       │
│  b. applyRouteWeight:        0.85 × 0.95 = 0.81 (conf ≥ 0.45 ✓)                       │
│  c. resolveExecutionProfile: preferred=[fabric-sempy, fabric-api]                       │
│  d. checkEngineAvailability: fabric-sempy checks pass ✓                                 │
│  e. resolveWorkspace:        DEV + UAT (comparison scope)                               │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  8. FABRIC DEVOPS — EXECUTE modules/validate.md                                         │
│                                                                                         │
│  → Power BI Remote: GetSemanticModelSchema (DEV) vs GetSemanticModelSchema (UAT)        │
│  → Fabric MCP: onelake_item_list (DEV) vs onelake_item_list (UAT)                      │
│  → Compare item counts, definitions, metadata parity                                    │
│  → Result: PASS — 14/14 items match, schema parity confirmed                           │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  9. ORCHESTRATOR — RESULT SYNTHESIS                                                     │
│                                                                                         │
│  ## Summary                                                                             │
│  Notebook promoted to UAT and post-deployment validation passed.                        │
│                                                                                         │
│  ## Results                                                                             │
│  ### Promotion (fabric-devops / release-promote)                                        │
│  Pipeline run 12345 — Succeeded. 1 notebook promoted DEV → UAT.                        │
│                                                                                         │
│  ### Validation (fabric-devops / validate)                                              │
│  PASS — 14/14 items match. Schema parity confirmed.                                    │
│                                                                                         │
│  ## Next Actions                                                                        │
│  1. Run semantic model testing if data freshness matters                                │
│  2. Proceed to UAT → PROD promotion when ready                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Capability Matrix

Complete mapping of lifecycle events to skills, engines, and routes:

| Lifecycle Event | Primary Skill | Preferred Engine | Secondary Engine | Fallback |
| :--- | :--- | :--- | :--- | :--- |
| Create/Update notebooks & pipelines | Develop | Fabric API | Fabric CLI | Context7 |
| Workspace inventory & status | Operate & Monitor | Fabric API | Fabric CLI | Context7 |
| Inventory export & automation | Operate & Monitor | Fabric CLI | Fabric API | Context7 |
| Lakehouse dependency & load diagnostics | Lakehouse Diagnostics | Fabric API | Fabric SemPy | Context7 |
| Semantic model & metadata parity | Validate | Fabric SemPy | Fabric API | Context7 |
| Schema/row-count/metric/freshness testing | Semantic Model Testing | Power BI Remote | Fabric SemPy | Context7 |
| Report definition comparison | Validate | Fabric API | Fabric SemPy | Context7 |
| Data lineage (table/column/report) | Analyze Lineage | Fabric SemPy | Fabric API | Context7 |
| PBIR + TOM metadata generation | Analyze Lineage | Fabric SemPy (semantic-link-labs) | Fabric API | Context7 |
| Broken object / orphan detection | Validate | Fabric SemPy | Fabric API | Context7 |
| Deployment promotion (DEV→UAT→PROD) | Release & Promote | Fabric API | Fabric CLI | Context7 |

---

## Error Recovery

| Failure Mode | Recovery Action |
| :--- | :--- |
| MCP tool error (auth expired, API down) | Report specific error with tool name. Suggest `az login` or credential refresh. Do not retry. |
| Engine unavailable at runtime | Fall through to next engine in cascade. If all executors down, return context7 guidance with blocker list. |
| Empty/no-data result | Report no data found. Suggest wider time range, different environment, or different scope. |
| Partial procedure completion | Report which steps succeeded and which failed. Offer to retry from the failed step. |
| Workspace not found in catalog | Stop and ask user which environment. Do not guess. |
| PROD write attempted | Block immediately (Layer 1 catalog check). Report: "PROD is read-only. Use DEV→UAT→PROD pipeline." |
| Ambiguous intent (two skills tied) | Apply ambiguity rules. If still tied (within `ambiguityMargin: 0.15`), ask one clarifying question. |
| Release pre-flight fails | Halt promotion. Report pre-flight findings at ERROR level. Do not proceed to promotion phase. |

---

## Extending Fabric DevOps

| Want To... | Do This |
| :--- | :--- |
| Add a new capability skill | Create `skills/fabric-devops-<name>/SKILL.md` with intent triggers, weight, engine preference, procedure reference |
| Add a new workspace/environment | Add an entry to `skills/fabric-devops/config/workspace-catalog.yaml` |
| Change safety rules | Edit `skills/fabric-devops/modules/safety-guardrails.md` |
| Add a new execution engine | Add engine definition + update route policies in `skills/fabric-devops/config/execution-router.yaml` |
| Add an event override | Add to `eventOverrides` in `skills/fabric-devops/config/execution-router.yaml` |
| Add ambiguity rules | Add to `ambiguityRules` in `skills/fabric-devops/config/intent-router.yaml` |
| Add new MCP tools | Edit `.vscode/mcp.json` + add tool names to `fabric-devops.agent.md` `tools` frontmatter |
| Add a procedure module | Create `skills/fabric-devops/modules/<name>.md` + reference from new skill's `SKILL.md` |
| Change engine preference for a skill | Edit the skill's `SKILL.md` Engine Preference section |
