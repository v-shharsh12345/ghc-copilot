# Fabric DevOps Agent

> **File:** `.github/agents/fabric-devops.agent.md`
> **Version:** 1.3 (Feb 2026)

## Overview

The **Fabric DevOps** agent provides end-to-end lifecycle management for Microsoft Fabric workspaces. It handles development, monitoring, diagnostics, lineage analysis, deployment validation, and CI/CD promotion across DEV, UAT, and PROD environments.

## Architecture

The agent uses a **config-driven intent routing** system:

1. User prompt arrives
2. `intent-router.yaml` classifies intent into a lifecycle mode
3. `execution-router.yaml` determines the execution steps
4. The appropriate module (`.md` file) provides domain-specific instructions
5. `workspace-catalog.yaml` resolves workspace IDs and connection strings

## Lifecycle Modes

| Mode | Module | Description |
|------|--------|-------------|
| **Develop** | `modules/develop.md` | Create/update notebooks, pipelines, semantic models in non-PROD |
| **Operate & Monitor** | `modules/operate-monitor.md` | Inventory items, job status, health trends |
| **Lakehouse Diagnostics** | `modules/lakehouse-diagnostics.md` | Failure correlation, dependency tracing, root cause |
| **Analyze Lineage** | `modules/analyze-lineage.md` | Column/table/report lineage graphs with DAX introspection |
| **Validate** | `modules/validate.md` | Pre/post-deployment checks with PASS/WARN/FAIL scoring |
| **CI/CD** | `modules/release-promote.md` | Git sync, deployment pipeline promotion DEV→UAT→PROD |
| **UI/UX Changes** | `modules/ui-ux-changes.md` | PBIR-native report formatting and visual updates |

## Safety Guardrails

- **PROD is read-only.** All write operations on PROD workspaces are blocked.
- Schema-altering operations require confirmation before execution.
- `modules/safety-guardrails.md` defines the full safety policy.
- `modules/runtime-checks.md` validates operations at runtime.

## Configuration Files

| File | Purpose |
|------|---------|
| `config/workspace-catalog.yaml` | Maps workspace names to Fabric workspace IDs and SQL connection strings |
| `config/intent-router.yaml` | Maps natural language intents to lifecycle modes |
| `config/execution-router.yaml` | Maps modes to execution steps, tools, and modules |

## MCP Servers Required

| Server | Purpose |
|--------|---------|
| Fabric MCP | OneLake, workspace, item management |
| Teams | Notifications and alerts |
| MSSQL | SQL Endpoint queries |
| Context7 | Library documentation lookup |

## Example Prompts

```
Run post-deploy validation on UAT for IncentiveReporting
Show me the lineage for Claims_Payments table
What Fabric jobs failed in the last 24 hours?
Deploy notebook X from DEV to UAT
Create a new notebook in DEV workspace
```

## Key Behaviors

- Environment auto-detection from prompt context (defaults to DEV for writes)
- Capability matrix checks before attempting operations
- Structured output with emoji indicators (✅ PASS, ⚠️ WARN, ❌ FAIL)
- Parallel module loading when operations span multiple modes
