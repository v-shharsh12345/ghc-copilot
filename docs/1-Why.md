# Why Agentic?

## The Problem

Our team works across **Fabric, Databricks, Azure DevOps, Power BI, Outlook, Teams, and SharePoint** daily. A single task like "investigate a failed pipeline, fix it, promote to UAT, and update ADO" touches 4–6 browser tabs, requires remembering workspace GUIDs, and involves dozens of menu clicks.

This is a **cognitive load** problem. Every context switch costs mental energy, and [research shows](https://queue.acm.org/detail.cfm?id=3454124) context switching is one of the top destroyers of engineering velocity.

## Five Pillars

### 1. Reduce Cognitive Effort

| Traditional | Agentic |
| :--- | :--- |
| Memorize workspace GUIDs, URLs, iteration paths | Say "DEV" — the agent resolves the rest |
| Navigate portals to check status | "What's the health of my DEV workspace?" |
| Translate intent → technical steps → UI clicks | Express the **intent**; the agent handles the **how** |

### 2. Eliminate Dependencies

Knowledge locked in people's heads creates bottlenecks. Agents codify institutional knowledge into version-controlled config:

| Knowledge | Where It Lives |
| :--- | :--- |
| Workspace IDs and environments | `workspace-catalog.yaml` |
| ADO project paths and defaults | `config/user-context.yaml` |
| Safety rules for PROD | `modules/safety-guardrails.md` |
| Deployment procedures | Skill modules (e.g., `release-promote.md`) |

Any team member can clone the repo, run setup, and have the **same operational capability** as a senior engineer — with guardrails that prevent catastrophic mistakes.

### 3. Enable Delegation

The system mirrors a well-run team: you state what you need, the orchestrator routes to the right specialist, the specialist activates the right skill, and you get a structured result.

- **PMs** ask "What changed since yesterday?" without learning Fabric APIs
- **Devs** say "Deploy my notebook to UAT and validate" without portal navigation
- **Leads** say "Generate my daily status" without reviewing 15 email threads

### 4. Accelerate Velocity

| Task | Before | After | Savings |
| :--- | :--- | :--- | :--- |
| Create ADO task from a meeting | 10–15 min | ~1 min | **~90%** |
| Validate DEV vs PROD semantic model | 30–45 min | ~3 min | **~90%** |
| Investigate a pipeline failure | 20–40 min | ~5 min | **~80%** |
| Send end-of-day status | 15–20 min | ~2 min | **~90%** |
| Onboard a new team member | Days | Hours | **~90%** |

### 5. Safety & Governance by Default

In a browser workflow, preventing accidental PROD deletion relies on human attention. In the agentic model:

- PROD workspaces are marked `writeAllowed: false` in the catalog
- Every skill checks safety guardrails before executing writes
- The agent refuse destructive PROD operations and explains why
- All actions are logged in the chat thread for full auditability

## The Mental Model Shift

| Concept | Traditional | Agentic |
| :--- | :--- | :--- |
| **Interface** | 8 browser tabs | 1 chat window |
| **Knowledge** | In people's heads | In version-controlled YAML/Markdown |
| **Execution** | Click-by-click | Intent-driven |
| **Safety** | "Be careful" | Codified guardrails |
| **Reproducibility** | "I think I clicked here…" | Every prompt is a log |
| **Onboarding** | Shadow a senior for 2 weeks | Clone, setup, chat |

## Who Benefits

| Role | Primary Benefit |
| :--- | :--- |
| **Program Managers** | Triage, meeting prep, and status in seconds |
| **Data Engineers** | Deploy, monitor, troubleshoot without portal navigation |
| **Team Leads** | Visibility into work items, pipelines, and team status from a single prompt |
| **New Team Members** | Full operational capability from day one with built-in safety nets |

## What This Is NOT

- **Not a replacement for human judgment.** Agents execute; humans decide.
- **Not magic.** Agents follow codified skills — they're as good as the SOPs we write.
- **Not uncontrolled AI.** Every agent has a constrained toolset, safety guardrails, and specific responsibilities.
- **Not vendor lock-in.** Skills and agents are Markdown files — portable and version-controlled.
