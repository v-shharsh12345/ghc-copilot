# Fabric DevOps Skill

## Overview

The **fabric-devops** skill is a unified Fabric lifecycle orchestration layer that routes requests to focused modules for building, operating, monitoring, validating, and promoting Fabric artifacts across DEV/UAT/PROD environments.

## Key Capabilities

| Capability | Description |
|------------|-------------|
| **Intent routing** | Config-driven routing maps user requests to the correct module |
| **Engine selection** | Deterministic selection: Fabric API → CLI → SemPy → Context7 |
| **Modular architecture** | Separate modules for develop, operate, validate, release, lineage, and semantic model testing |
| **Production safety** | Read-only enforcement on PROD; write operations blocked without explicit confirmation |
| **Lineage analysis** | Table, column, and report-level data lineage tracing via SemPy |
| **Semantic model testing** | Repeatable schema/row count/metric/freshness checks across DEV/UAT/PROD |

## Module Layout

| Module | Purpose |
|--------|---------|
| `config/intent-router.yaml` | Intent-to-module routing rules |
| `config/execution-router.yaml` | Engine selection and fallback policy |
| `config/workspace-catalog.yaml` | Central workspace/environment metadata |
| `modules/develop.md` | Build/update flows |
| `modules/operate-monitor.md` | Monitoring and run health |
| `modules/lakehouse-diagnostics.md` | Lakehouse incident diagnostics |
| `modules/validate.md` | Cross-environment validation |
| `modules/release-promote.md` | Promotion and release controls |
| `modules/analyze-lineage.md` | Data lineage analysis |
| `modules/semantic-model-testing.md` | Semantic model schema/data-quality comparison workflow |
| `modules/safety-guardrails.md` | Safety rules and protections |

## Production Safety Rules

- **READ-ONLY** operations allowed on PROD (list, get, export, query, compare)
- **WRITE** operations **PROHIBITED** on PROD (create, update, delete, deploy, commit)
- Explicit confirmation required before any write in non-PROD

## Example Invocations

```
"Deploy notebook X to UAT"
"Check pipeline refresh status in PROD"
"Compare semantic models between DEV and UAT"
"Trace lineage for table FactSales"
"Run post-deploy validation checks"
```

## Required MCP Servers

- **Fabric API** — Primary execution engine for workspace operations
- **Fabric CLI** — Fallback for deployment and artifact management
- **Fabric SemPy / semantic-link-labs** — Metadata analysis and lineage tracing
- **Power BI Remote** — Semantic model queries and schema comparison

## Source File

[.github/skills/fabric-devops/SKILL.md](../../.github/skills/fabric-devops/SKILL.md)
