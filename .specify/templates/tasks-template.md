# Tasks — {{FEATURE_ID}} {{FEATURE_TITLE}}

> Produced by `/speckit.tasks`. Lives at `specs/{{FEATURE_ID}}-{{slug}}/tasks.md`.
> Each task SHOULD map to (a) an ADO Task work item created via the ADO MCP
> server under Scenario Detail #{{ADO_SD_ID}}, and (b) one or more ACs in
> `spec.md`. `/speckit.analyze` checks the mapping and flags orphans.

| Field | Value |
|---|---|
| **Feature ID** | {{FEATURE_ID}} |
| **Linked Plan** | `plan.md` |
| **ADO SD parent** | #{{ADO_SD_ID}} |
| **ADO Project** | "Global Partner Solutions" |
| **Default Area Path** | `Global Partner Solutions\Sales and Consumption` |
| **Default Iteration** | `@CurrentIteration` |
| **Default Tags** | `Copilot`, `WorkFAST`, `{{DOMAIN_TAG}}` |

---

## How to read this file
- **ID** — local task ID (`T-A1`, `T-B1`, …). Phase prefix matches `plan.md`.
- **ADO** — populated after `/speckit.tasks` pushes to ADO (`#XXXXX`).
- **Maps to** — `spec.md` AC IDs or plan checklist items.
- **Est** — AI-assisted hours / story points.
- **Status** — `todo` · `in-progress` · `pr-open` · `done` · `blocked`.

---

## Phase A — Analysis & Contract

| ID | ADO | Title | Maps to | Est | Owner | Status |
|---|---|---|---|---|---|---|
| T-A1 | #_____ | Source schema + row-count baseline pull | FR-1, AC-1 | 1h | | todo |
| T-A2 | #_____ | Grain & join key confirmation with SME | FR-2 | 1h | | todo |
| T-A3 | #_____ | Update `spec.md` Data Contract section | §6 | 0.5h | | todo |

## Phase B — Bronze / Silver

| ID | ADO | Title | Maps to | Est | Owner | Status |
|---|---|---|---|---|---|---|
| T-B1 | #_____ | Modify/create Silver notebook (header + `%run CommonUtilitiesFunctions`) | P2, FR-_ | | | todo |
| T-B2 | #_____ | Extend `CSP_Silver_BVT` with new checks | P5 | | | todo |
| T-B3 | #_____ | Run `CSP_DataQualityAgent_Silver` in DEV; attach output | P5, AC-_ | | | todo |

## Phase C — Gold

| ID | ADO | Title | Maps to | Est | Owner | Status |
|---|---|---|---|---|---|---|
| T-C1 | #_____ | Create/modify Gold notebook(s) | P1, P2, FR-_ | | | todo |
| T-C2 | #_____ | Update `CSP_Gold_RefreshLog` calls (success + failure) | P5 | | | todo |
| T-C3 | #_____ | Extend `CSP_Mart_Master_BVT` | P5 | | | todo |
| T-C4 | #_____ | Add new large table to `CSP_Gold_ZOrdering` | P5 | | | todo |
| T-C5 | #_____ | Run `CSP_DataQualityAgent_Gold` in DEV; attach output | P5, AC-_ | | | todo |

## Phase D — Views, Semantic Model, Report

| ID | ADO | Title | Maps to | Est | Owner | Status |
|---|---|---|---|---|---|---|
| T-D1 | #_____ | Update view DDL in `MSSales/Fabric/Stored Procedure/` | P3, P5 | | | todo |
| T-D2 | #_____ | Run `usp_CreateViews_<Domain>_Update` in DEV | P5 | | | todo |
| T-D3 | #_____ | Semantic model — tables, relationships, measures | FR-_, AC-_ | | | todo |
| T-D4 | #_____ | **RLS sanity check** — every RLS role still returns rows on each table touched | P4, AC-_ | | | todo |
| T-D5 | #_____ | Report visual / tooltip / data dictionary update | FR-_ | | | todo |

## Phase E — Validation

| ID | ADO | Title | Maps to | Est | Owner | Status |
|---|---|---|---|---|---|---|
| T-E1 | #_____ | DEV end-to-end pipeline run | AC-_, NFR-2 | | | todo |
| T-E2 | #_____ | Row-count + revenue parity vs baseline within tolerance | AC-_, NFR-1 | | | todo |
| T-E3 | #_____ | Report regression vs UAT/PROD baseline | AC-_ | | | todo |
| T-E4 | #_____ | DQ agent reports archived to PR description | P5 | | | todo |

## Phase F — Promotion

| ID | ADO | Title | Maps to | Est | Owner | Status |
|---|---|---|---|---|---|---|
| T-F1 | #_____ | Open PR; verify AI PR Review ≥ 70 | P4 | | | todo |
| T-F2 | #_____ | 1ES build green (CodeQL, CodeSign, CredScan, SdtReport, PostAnalysis) | P4 | | | todo |
| T-F3 | #_____ | Reviewer signs Constitution Check rows in `plan.md` | P1–P5 | | | todo |
| T-F4 | #_____ | Update parent SD #{{ADO_SD_ID}} with completion comment + PR link | hygiene | | | todo |
| T-F5 | #_____ | Apply `Done` tag to all completed tasks | hygiene | | | todo |
| T-F6 | #_____ | Verify parent SD state moved from `New`/`Active` per child rollup (P6) | P6 | | | todo |
| T-F7 | #_____ | Audit task titles + tags against `work_item_hygiene` rules in `.specify/extensions.yml` (P6) | P6 | | | todo |
| T-F8 | #_____ | Verify type hierarchy (no Task/SD direct under Project) + closure cascade (no parent Closed with open children) (P7) | P7 | | | todo |
| T-F9 | #_____ | If this work carries over to next quarter, set Predecessor/Successor link or move source to `Removed` with successor-ID comment (P7) | P7 | | | todo |

---

## Out-of-Spec-Kit Tasks
> Items that can't be executed inside Spec Kit / Copilot scope (e.g., model
> publish through the Power BI service, manual file uploads). Track here so
> they show up in `/speckit.analyze` gap detection.

| ID | Title | Owner | Status |
|---|---|---|---|
| T-X1 | Publish semantic model via Fabric portal (manual) | | todo |

## Notes for the ADO MCP push
- Parent every Task to `#{{ADO_SD_ID}}`.
- Apply default tags above plus any sprint-specific tag.
- Set `Original Estimate` from the `Est` column.
- Iteration falls back to `@CurrentIteration` unless plan.md states otherwise.
