# Fabric DevOps Skill

## Overview

The **fabric-devops** skill is a shared resource layer that provides workspace catalog, engine definitions, safety guardrails, and canonical procedure modules consumed by 7 self-declaring capability skills.

## Architecture

Each capability skill self-declares its intent triggers, engine preference, and procedure. The parent `fabric-devops` skill does not route — it provides shared resources. The `fabric-devops` agent reads skill declarations and dispatches accordingly.

## Capability Skills

| Skill | Domain | Declared Weight |
|-------|--------|----------------|
| `fabric-devops-develop` | Build/update items | 1.0 |
| `fabric-devops-operate-monitor` | Inventory, monitoring, health | 1.0 |
| `fabric-devops-lakehouse-diagnostics` | Lakehouse failure diagnostics | 1.0 |
| `fabric-devops-validate` | Cross-environment validation | 0.95 |
| `fabric-devops-semantic-model-testing` | Schema/data parity testing | 1.1 |
| `fabric-devops-analyze-lineage` | Data lineage analysis | 1.05 |
| `fabric-devops-release-promote` | Lifecycle promotion | 1.0 |

## Shared Resources

| Resource | Purpose |
|----------|---------|
| `config/workspace-catalog.yaml` | Central workspace/environment metadata |
| `config/execution-router.yaml` | Engine definitions and fallback policy |
| `config/intent-router.yaml` | Reference index (skills are authoritative) |
| `modules/safety-guardrails.md` | Safety rules and protections |
| `modules/*.md` | Canonical procedure modules |

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
