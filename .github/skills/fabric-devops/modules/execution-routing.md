# Execution Routing Module

## Goal

Select the best execution route for each lifecycle event using available engines:

- Fabric API
- Fabric CLI
- Fabric SemPy
- Context7 guidance (advisory fallback via `io.github.upstash/context7`)

## Inputs

- Resolved intent (`develop`, `operate-monitor`, `lakehouse-diagnostics`, `validate`, `analyze-lineage`, `ui-ux-changes`, `promote-release`)
- Event type (if known)
- Environment and permissions
- Tool/runtime availability

## Routing Rules

1. Resolve intent from `config/intent-router.yaml`.
2. Resolve engine preference from `config/execution-router.yaml`.
3. Apply event override when event type is provided.
4. Run availability checks from `modules/runtime-checks.md`.
5. Remove engines that are unavailable in current runtime.
6. If no executable engine remains, return guidance-only plan using Context7.

## Selection Criteria

- Prefer deterministic execution over guidance.
- For `ui-ux-changes` on reports, prefer Fabric API definition round-trip (`getDefinition` and `updateDefinition`) as the write path.
- Prefer SemPy for semantic/analytical comparisons.
- Prefer SemPy + semantic-link-labs for metadata-heavy parsing and audit support (PBIR report objects, TOM model inventory, broken-object detection).
- Prefer API/CLI for deployment and operational actions.
- Treat Power BI REST API report operations as complementary (for content replacement), not as the primary per-visual/page editing surface.
- Keep PROD write guardrails enforced regardless of engine.

## Output Contract

Return:

- Selected intent
- Selected primary engine
- Fallback engines in order
- Why this route was chosen
- Any blockers (permissions/tool availability)
