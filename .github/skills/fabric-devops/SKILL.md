---
name: fabric-devops
description: Unified Fabric lifecycle orchestration skill that composes existing Fabric skills for build, operate, monitor, validate, and promote workflows.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-17 | 2.6 | Added rapid UI/UX iteration guidance for server-side UAT report updates, including proven workflow patterns, anti-patterns, and fast validation loop. |
| 2026-02-17 | 2.5 | Updated UI/UX workflow to API-first report definition round-trip (`getDefinition` → PBIR patch → `updateDefinition`) with explicit Power BI API limitations. |
| 2026-02-17 | 2.4 | Added ui-ux-changes module for PBIR-native report formatting, spacing, font consistency, and design-system enforcement. |
| 2026-02-13 | 2.3 | Added semantic-link-labs-driven metadata generation patterns for report and semantic model analysis. |
| 2026-02-13 | 2.2 | Added analyze-lineage module for table, column, and report-level data lineage tracing. |
| 2026-02-12 | 2.1 | Added engine-aware routing with Fabric API, Fabric CLI, Fabric SemPy, and Context7 guidance fallback. |
| 2026-02-12 | 2.0 | Refactored to modular structure with config-driven intent routing and stage-specific modules. |
| 2026-02-12 | 1.0 | Added meta-orchestration skill to unify Fabric lifecycle workflows using existing Fabric skills. |

Operate as the single Fabric lifecycle entrypoint. Route requests to focused modules and execute only the minimum required path.

> ⚠️ **CRITICAL: PRODUCTION ENVIRONMENT PROTECTION**
>
> - ✅ **READ-ONLY operations are allowed** on PROD (list, get, export, query, compare)
> - ❌ **WRITE operations are PROHIBITED** on PROD (create, update, delete, deploy, commit)
> - Require explicit confirmation before any write operation in non-PROD

## Modular Layout

| Path | Purpose |
| --- | --- |
| [config/intent-router.yaml](config/intent-router.yaml) | Intent-to-module routing rules and guardrails |
| [config/execution-router.yaml](config/execution-router.yaml) | Engine selection and fallback policy (API/CLI/SemPy/Context7) |
| [config/workspace-catalog.yaml](config/workspace-catalog.yaml) | Central workspace/environment metadata |
| [modules/capability-matrix.md](modules/capability-matrix.md) | Lifecycle event to route coverage matrix |
| [modules/execution-routing.md](modules/execution-routing.md) | Deterministic engine selection workflow |
| [modules/runtime-checks.md](modules/runtime-checks.md) | Concrete engine availability checks |
| [modules/develop.md](modules/develop.md) | Build/update flows |
| [modules/operate-monitor.md](modules/operate-monitor.md) | Monitoring and run health |
| [modules/lakehouse-diagnostics.md](modules/lakehouse-diagnostics.md) | Lakehouse incident diagnostics |
| [modules/validate.md](modules/validate.md) | Cross-environment validation |
| [modules/release-promote.md](modules/release-promote.md) | Promotion and release controls |
| [modules/analyze-lineage.md](modules/analyze-lineage.md) | Data lineage analysis (table/column/report) |
| [modules/ui-ux-changes.md](modules/ui-ux-changes.md) | PBIR-native report UI/UX formatting, spacing, font & color consistency |
| [modules/safety-guardrails.md](modules/safety-guardrails.md) | Safety rules and environment protections |

## Operating Model

1. Resolve environment and action intent.
2. Load routing rules from `config/intent-router.yaml`.
3. Select execution engine from `config/execution-router.yaml`.
4. Execute the mapped module procedure.
5. Enforce guardrails before every write operation.
6. Return concise status with next action.

## Engine Resolution

- Default routes use executable engines first: Fabric API, Fabric CLI, then Fabric SemPy where analytical validation is required.
- For metadata-heavy requests (PBIR/report parsing, semantic model object extraction, broken object detection), prefer Fabric SemPy with `semantic-link-labs` (`sempy_labs`).
- Context7 is guidance-only and used as advisory fallback when execution engines are unavailable or ambiguous.
- Event-specific overrides in `config/execution-router.yaml` take precedence over generic intent defaults.

## Intent Routing

- **Develop/Build** → [modules/develop.md](modules/develop.md)
- **Operate/Monitor** → [modules/operate-monitor.md](modules/operate-monitor.md)
- **Lakehouse Diagnostics** → [modules/lakehouse-diagnostics.md](modules/lakehouse-diagnostics.md)
- **Validate/Compare** → [modules/validate.md](modules/validate.md)
- **Analyze/Lineage** → [modules/analyze-lineage.md](modules/analyze-lineage.md)
- **UI/UX Changes** → [modules/ui-ux-changes.md](modules/ui-ux-changes.md)
- **Promote/Release** → [modules/release-promote.md](modules/release-promote.md)

## Backward Compatibility

Legacy Fabric skill folders remain as compatibility aliases and now delegate to this modular lifecycle skill.

## Response Contract

For each operation, return:

- Scope (workspace/environment/items)
- Chosen route (intent + primary engine + fallbacks)
- Actions executed
- Findings (PASS/WARN/FAIL)
- Risk notes (guardrails)
- Next step
