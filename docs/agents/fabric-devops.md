# Fabric DevOps Agent

> **File:** `.github/agents/fabric-devops.agent.md`
> **Version:** 1.7 (Feb 2026)

## Overview

The **Fabric DevOps** agent is a thin dispatcher for Microsoft Fabric lifecycle management. It activates self-declaring capability skills based on their declared intent triggers, engine preferences, and procedures. Each skill owns its routing — the agent reads skill declarations and dispatches accordingly.

## Architecture

The agent uses a **skill-driven intent routing** system:

1. User prompt arrives
2. Agent scores the prompt against each capability skill's declared triggers and weight
3. The matching skill's engine preference determines the execution engine
4. The skill's procedure (referencing a parent module) provides domain-specific instructions
5. `workspace-catalog.yaml` resolves workspace IDs and connection strings

## Capability Skills

| Skill | Domain | Weight |
|-------|--------|--------|
| `fabric-devops-develop` | Create/update notebooks, pipelines, semantic models in non-PROD | 1.0 |
| `fabric-devops-operate-monitor` | Inventory items, job status, health trends | 1.0 |
| `fabric-devops-lakehouse-diagnostics` | Failure correlation, dependency tracing, root cause | 1.0 |
| `fabric-devops-analyze-lineage` | Column/table/report lineage graphs with metadata extraction | 1.05 |
| `fabric-devops-semantic-model-testing` | Schema drift and data-quality parity across environments | 1.1 |
| `fabric-devops-validate` | Pre/post-deployment checks with PASS/WARN/FAIL scoring | 0.95 |
| `fabric-devops-release-promote` | Git sync, deployment pipeline promotion DEV→UAT→PROD | 1.0 |

## Shared Resources (in `fabric-devops/`)

| File | Purpose |
|------|---------|
| `config/workspace-catalog.yaml` | Maps workspace names to Fabric workspace IDs and SQL connection strings |
| `config/execution-router.yaml` | Engine definitions, fallback policy, and execution profiles |
| `config/intent-router.yaml` | Reference index of routes (skills are authoritative) |
| `modules/safety-guardrails.md` | Safety policy and environment protections |
| `modules/*.md` | Canonical procedure modules consumed by capability skills |

## Safety Guardrails

- **PROD is read-only.** All write operations on PROD workspaces are blocked.
- Schema-altering operations require confirmation before execution.
- `modules/safety-guardrails.md` defines the full safety policy.
- `modules/runtime-checks.md` validates operations at runtime.

## MCP Servers Required

| Server | Purpose |
|--------|---------|
| Fabric MCP | OneLake, workspace, item management |
| Power BI Remote | Semantic model schema and DAX comparisons |
| Teams | Notifications and alerts |
| MSSQL | SQL Endpoint queries |
| Context7 | Library documentation lookup |

## Example Prompts

```
Run post-deploy validation on UAT for the main Lakehouse
Show me the lineage for Fact_Payments table
What Fabric jobs failed in the last 24 hours?
Deploy notebook X from DEV to UAT
Compare semantic models between DEV and UAT
```

## Key Behaviors

- Skill-driven routing: each skill declares its own triggers, the agent dispatches
- Environment auto-detection from prompt context (defaults to DEV for writes)
- Structured output with emoji indicators (✅ PASS, ⚠️ WARN, ❌ FAIL)
- Parallel skill activation when operations span multiple domains
