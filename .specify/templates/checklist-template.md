# PR Checklist — {{FEATURE_ID}} {{FEATURE_TITLE}}

> Produced by `/speckit.checklist`. Paste this list as the body of your PR
> description (or link to `specs/{{FEATURE_ID}}-{{slug}}/checklist.md`).
> The AI PR Review pipeline reads it; reviewers will not approve a PR with
> unchecked blocking items unless an explicit waiver comment is attached.

| Field | Value |
|---|---|
| **Feature ID** | {{FEATURE_ID}} |
| **Linked artifacts** | [`spec.md`](spec.md) · [`plan.md`](plan.md) · [`tasks.md`](tasks.md) |
| **ADO Scenario Detail** | #{{ADO_SD_ID}} |
| **Author** | {{AUTHOR}} |
| **PR** | !{{PR_NUMBER}} |

---

## 1. Constitution gates (BLOCKING)

### Principle I — Medallion Layer Discipline
- [ ] No Gold notebook reads from raw / source systems directly.
- [ ] No Silver notebook writes to a Gold table (or vice versa).
- [ ] Lakehouse names encode `<Domain>_<Layer>` (e.g., `POSOT_CSP`, `POSOT_CSPvNext_Reporting`).
- [ ] Reporting/serving notebook lives under `*Reporting` or `Sales Reports` and reads only Gold.

### Principle II — Notebook Authoring Standards
- [ ] First markdown cell declares Project / Stage / Notebook Name / Purpose / Parameter Info / Revision History.
- [ ] **Revision History table has a new row** for this change (Date, Author, Description, Execution Time).
- [ ] Shared helpers are invoked via `%run CommonUtilitiesFunctions` (or domain equivalent) — no copy-paste of common logic.
- [ ] `# META {…}` blocks preserved; kernel / language_group not hand-edited.

### Principle III — Fabric Artifact Conventions
- [ ] Folder suffixes correct: `.Notebook`, `.DataPipeline`, `.Lakehouse`, `.Environment`.
- [ ] Notebook name prefixed `<Domain>_<Layer>_` (Fact*/Dim*/DimBridge*/*Snapshot stems for tables).
- [ ] Spark pool environment chosen from approved set (Small/Medium/Large/XLarge/XXLarge Pool).
- [ ] T-SQL views live in `MSSales/Fabric/Stored Procedure/` and are created via `usp_CreateViews_<Domain>_Update`.
- [ ] Staged files placed under `MSSales/Fabric/Files/<Domain>/`.

### Principle IV — Security, Compliance & Supply-Chain (NON-NEGOTIABLE)
- [ ] **1ES pipeline green** (`MSSales/MSSales_Build_1ES.yml`) — CodeQL, CodeSign, CredScan, SdtReport, PostAnalysis all PASS.
- [ ] **AI PR Review** (`MSSales/ado/azure-pipelines.yaml`) ≥ 70 threshold — pass without lowering threshold.
- [ ] No secrets, connection strings, SAS tokens, production tenant IDs, OAuth client secrets, or personal data added.
- [ ] Notebooks authenticate via `notebookutils.credentials` / workspace identities — no hard-coded SPs.
- [ ] No new top-level pipelines or `resources.repositories` references outside the allow-list (`1ESPipelineTemplates/*`, `MCAPS Data Engineering/MCAPSDE_PR_Review_Assistant`).

### Principle V — Reproducibility & Data Quality Gates
- [ ] Orchestration routed through a canonical master pipeline (`CSP_Master_Refresh_Full` / `CSP_Reporting_Refresh_Full` / domain equivalent). **No ad-hoc PROD schedules.**
- [ ] Silver BVT (`CSP_Silver_BVT`) and/or Gold BVT (`CSP_Mart_Master_BVT`) updated and passing in DEV.
- [ ] If BVT failure intentionally skipped via `*_Skip_*BVTFailure` master, **incident ticket reference attached.**
- [ ] Gold notebook updates `CSP_Gold_RefreshLog` on both success and failure paths.
- [ ] New large Gold tables added to `CSP_Gold_ZOrdering` scope.
- [ ] **Schema-affecting change?** If yes:
  - [ ] View DDL updated in `MSSales/Fabric/Stored Procedure/`.
  - [ ] Producing notebook Revision History row references the schema change.
  - [ ] Downstream report impact written in this PR description.

### Principle VI — Work Item Hygiene & Traceability
- [ ] Every Task title matches `^\[<Domain>\]: <verb> <specific noun> .{8,}$` and is unique within sprint+area path (no collisions with another open task).
- [ ] Every Task is parented to a Scenario Detail; SD parented to a Business Scenario; BS parented to a Project.
- [ ] Tags use only the approved taxonomy (workflow / sprint / lifecycle / domain); no `Copilot 1`-style typos; exactly one `Target N` tag per Task.
- [ ] Each closed Task has a closure comment containing the merged PR ID and the `Done` tag is applied.
- [ ] Parent SD state has been advanced to match child rollup (no `New` SD over `Closed` children).
- [ ] If SD has `Story Points ≥ 8` OR is schema-affecting, at least one Test Case is linked per Acceptance Criterion.
- [ ] Every Active Task has `Original Estimate` or `Story Points` set; every Active SD has a `Target Date`.
- [ ] Standard Description / Acceptance Criteria fields populated (not only Custom HTML fields).
- [ ] Feature branch and `specs/` folder encode the SD ID (`NNN-<adoId>-<slug>`); closure comment links PR back to SD.

### Principle VII — Hierarchy Integrity & Lifecycle Cascade
- [ ] Type hierarchy respected: every Task/Bug/Test Case has an SD parent; every SD has a BS parent; every BS has a Project parent. **Zero** non-BS items attached directly to a Project.
- [ ] No parent (`Project`, `Business Scenario`, `Scenario Detail`) is in `Closed` state while any direct child is still open.
- [ ] No BS or SD is `Closed` with iteration path at `Global Partner Solutions` root or `Global Partner Solutions\FY{YY}` root — closed items reference a specific sprint.
- [ ] If this work carries over from a prior quarterly Project, the source work item is either moved to `Removed` (with successor ID in comment) or linked via Predecessor/Successor.
- [ ] All work items use only the catalogued state set: `New`, `Active`, `Ready`, `Blocked`, `Resolved`, `Closed`, `Removed`. Any pre-existing `On Hold` migrated to `Blocked`; `Ready for Engineering` migrated to `Ready`.
- [ ] Sprint iteration belongs to exactly one quarterly Project; Project iteration path includes `FY{YY}\Q{N}` (or carries `program-cross-cutting` tag).
- [ ] Pre-FY26-Q3 items touched by this PR carry the `legacy-pre-Q3` tag and are reported as legacy (not enforcement-blocking).
- [ ] Project-level Custom HTML fields are unique-per-project (no copy-pasted boilerplate from sibling Projects).
- [ ] BS-level Story Points (if any) equal the sum of child SD Story Points (roll-up only — no independent BS-level SP entry).

## 2. Data quality & validation evidence

- [ ] DEV end-to-end pipeline run attached (link to run / screenshot).
- [ ] Silver DQ agent output attached.
- [ ] Gold DQ agent output attached.
- [ ] Row-count parity report (vs. baseline) — within stated tolerance.
- [ ] Revenue / KPI parity report (vs. baseline) — within stated tolerance (typically ≤ 0.1%).
- [ ] Report visual regression check (vs. UAT/PROD baseline).
- [ ] **RLS sanity check** — every RLS role used on touched tables returns rows in DEV.

## 3. Semantic model

- [ ] Tables added/removed match `plan.md` §1.5.
- [ ] Relationships still resolve; no broken bridges.
- [ ] Measures with the same display name as before still return matching values for the validation sample.
- [ ] Direct Lake / composite-model implications documented.
- [ ] Data dictionary entry added/updated.

## 4. Documentation

- [ ] If a new domain folder under `MSSales/Fabric/` was introduced, `Readme.md` added.
- [ ] Top-level `MSSales/README.md` updated if a domain or major capability was added.
- [ ] `spec.md` / `plan.md` / `tasks.md` reflect the final state (no stale `TODO`s).
- [ ] Constitution mirror (`.specify/memory/constitution.md`) re-synced if the root `constitution.md` was amended in this PR.

## 5. Hygiene (non-blocking but expected)

- [ ] Branch name matches `^\d{3}-[a-z0-9-]{3,61}$` (per `.specify/extensions.yml`).
- [ ] Each commit message describes the artifact(s) touched (notebook / pipeline / view name).
- [ ] ADO Tasks under SD #{{ADO_SD_ID}} are updated/closed with PR ID in the comment (Sai's traceability ask).
- [ ] Tasks tagged with `Done` once closed.
- [ ] No collision with another open task title in the same sprint (rename if needed).

## 6. Waivers (if any)

> Any unchecked item in §1 requires a written waiver here, approved by the
> accountable owner in `MSSales/es-metadata.yml`. State which checklist item,
> why it cannot be met, and the mitigation.

| Item | Waiver justification | Approver | Date |
|---|---|---|---|
| | | | |

---

### Self-attestation
> By marking the boxes above, the author confirms compliance with the
> MSSales Platform Constitution v1.0.0. Misrepresentation is a constitution
> violation in its own right (Governance section).

- [ ] I have run this checklist against the actual code, not from memory.
