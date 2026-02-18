---
name: fabric-devops-analyze-lineage
description: Trace end-to-end data lineage from lakehouse tables through semantic models to report visuals at table, column, and report granularity.
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-18 | 1.0 | Self-contained capability skill for lineage and metadata analysis. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `lineage`, `analyze`, `trace`, `column lineage`, `table lineage`, `report lineage`, `impact analysis`, `upstream`, `downstream`, `data flow`, `dependency graph`, `metadata`, `report metadata`, `semantic model metadata`, `pbir`, `tmdl`, `tom`, `object usage`, `broken visuals`, `field mapping` |
| Weight | 1.05 |
| Minimum Confidence | 0.45 |

## Scope

- Trace table-level, column-level, and report-level lineage
- Parse PBIR and semantic model metadata for object mapping
- Detect broken mappings, orphan references, and missing columns
- Generate metadata snapshots using semantic-link-labs
- Safe read-only operation in all environments including PROD

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `fabric-sempy` | Semantic-link-labs for metadata extraction, TOM wrappers, report parsing |
| Secondary | `fabric-api` | Workspace scans, item metadata |
| Operational | `fabric-cli` | Scripted lineage flows |
| Guidance | `context7-guidance` | Advisory when tooling is unavailable |

## Procedure

### Phase 1 — Scope Resolution
1. Identify scope anchor type (report / semantic model / lakehouse).
2. Resolve workspace from [workspace-catalog.yaml](../fabric-devops/config/workspace-catalog.yaml).
3. Discover bound objects (report → semantic model → lakehouse).

### Phase 2 — Metadata Collection
4. Collect report-to-semantic-model field mappings (if report in scope).
5. Extract semantic model tables, columns, measures, partitions.
6. Get lakehouse tables and columns for schema mapping.

### Phase 3 — Lineage Assembly
7. Map lakehouse → semantic model (table and column level).
8. Map semantic model → report (column/measure to visual bindings).
9. Detect orphan columns, missing mappings, and broken references.

### Phase 4 — Output
10. Produce lineage graph and structured output.
11. Summarize coverage: PASS (full lineage) / WARN (gaps) / FAIL (unable to trace).

Canonical procedure reference: [analyze-lineage.md](../fabric-devops/modules/analyze-lineage.md)

## Inputs

- Scope anchor: report name, semantic model name, or lakehouse name
- Workspace: name or ID
- Environment: DEV / UAT / PROD
- Depth: `table` (default), `column`, or `full`

## Outputs

- Lineage graph (table-level and/or column-level)
- Structured DataFrame/JSON with source → target mappings
- Orphan detection report
- Coverage summary (PASS / WARN / FAIL)

## Guardrails

- This skill is read-only in all environments (DEV/UAT/PROD)
- No write operations are performed
- All connections use `readonly=True`
- Safe to run against PROD workspaces

Full safety policy: [safety-guardrails.md](../fabric-devops/modules/safety-guardrails.md)
