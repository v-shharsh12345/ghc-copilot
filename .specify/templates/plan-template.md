# Implementation Plan — {{FEATURE_ID}} {{FEATURE_TITLE}}

> Produced by `/speckit.plan`. Lives at `specs/{{FEATURE_ID}}-{{slug}}/plan.md`.
> Linked spec: [`spec.md`](spec.md). Approver: the accountable owner declared
> in `MSSales/es-metadata.yml`.

| Field | Value |
|---|---|
| **Feature ID** | {{FEATURE_ID}} |
| **Linked Spec** | `spec.md` |
| **Linked ADO SD** | #{{ADO_SD_ID}} |
| **Author** | {{AUTHOR}} |
| **Plan version** | 1 |
| **Status** | Draft \| Approved \| Superseded |

---

## 0. Constitution Check (GATE — must be PASS before tasks)

> The `/speckit.plan` command refuses to advance if any row is `FAIL` without
> a written `Justification`. The AI PR Review pipeline re-evaluates these
> rows at PR time.

| ID | Principle | Status | Evidence / Justification |
|---|---|---|---|
| P1 | Medallion Layer Discipline | PASS / FAIL / N/A | Which layer this feature writes to; confirm no cross-layer reads/writes. |
| P2 | Notebook Authoring Standards | PASS / FAIL / N/A | Header cells + revision history planned; `%run CommonUtilitiesFunctions` reuse confirmed. |
| P3 | Fabric Artifact Conventions | PASS / FAIL / N/A | Notebook name `<Domain>_<Layer>_<Object>`; folder suffix `.Notebook`/`.DataPipeline`/`.Lakehouse`; Spark pool environment chosen from approved list. |
| P4 | Security, Compliance & Supply-Chain (NON-NEGOTIABLE) | PASS / FAIL | No new secrets; uses `notebookutils.credentials`; no new external repo refs; 1ES + CodeQL + AI PR Review remain enabled. |
| P5 | Reproducibility & Data Quality Gates | PASS / FAIL / N/A | Routed through canonical master pipeline; BVT coverage added/updated; `CSP_Gold_RefreshLog` (or domain equivalent) updated; Z-ordering scope updated if new Gold table. |
| P6 | Work Item Hygiene & Traceability | PASS / FAIL | Task titles match `^\[<Domain>\]: <verb> <specific noun> .{8,}$`; parent links Task→SD→BS→Project; approved tag taxonomy only; SD state synced to child Tasks; Test Cases linked when SP ≥ 8 or schema-affecting; closure comment will include PR ID + `Done` tag. |
| P7 | Hierarchy Integrity & Lifecycle Cascade | PASS / FAIL | Type hierarchy `Project→BS→SD→Task` respected (no schema violations); closure cascade honored (no parent Closed with open children); cross-quarter carryover linked via Predecessor/Successor or source `Removed`; only catalogued states used (no `On Hold` / `Ready for Engineering`); Project iteration includes `FY{YY}\Q{N}`; sprint belongs to one quarterly Project; legacy pre-Q3 items reported as `legacy-pre-Q3`, not blocking. |

**Any `FAIL` requires either a written justification approved by the
accountable owner or a constitution amendment PR before `/speckit.tasks`.**

## 1. Technical Context

### 1.1 Architecture summary
<!-- One paragraph + one diagram-ish bullet flow. -->

```
[Source] → Bronze (notebook) → Silver (notebook) → Gold (notebook) → View (vw_*) → Semantic model → Report
```

### 1.2 Affected artifacts inventory

| Artifact | Type | Path | Action |
|---|---|---|---|
| `CSP_Gold_FactMarketIR` | Notebook | `MSSales/Fabric/CSPvNext/CSP_Gold_FactMarketIR.Notebook/` | modify |
| `vw_Fact_Market_IR` | View DDL | `MSSales/Fabric/Stored Procedure/usp_CreateViews_CSPvNext_Update.sql` | modify |
| `CSP_Silver_BVT` | Pipeline | `MSSales/Fabric/CSPvNext/CSP_Silver_BVT.DataPipeline/` | extend |
| _new_ `CSP_Gold_DimIRTenantPLAMapping` | Notebook | `MSSales/Fabric/CSPvNext/...` | create |

### 1.3 Data flow & lineage

| Step | Reads | Writes | Owner notebook |
|---|---|---|---|
| 1 | | | |

### 1.4 Spark configuration

| Notebook | Resource profile | Spark pool environment | Justification |
|---|---|---|---|
| | (default / writeHeavy / readHeavy) | (Small_Pool / Medium_Pool / Large_Pool / XLarge_Pool / XXLarge_Pool) | |

### 1.5 Semantic model & report impact

| Model | Tables added | Measures added/changed | Relationships changed | Report(s) affected |
|---|---|---|---|---|
| | | | | |

> Direct Lake / composite-model implications? RLS roles touched? Mark
> explicitly. (Sai's review feedback: silent RLS breakage is a recurring
> trap.)

## 2. Phased Execution

> Phases align with the Spec Kit lifecycle. Each phase ends with a commit
> via the `after_*` hook in `.specify/extensions.yml`.

### Phase A — Analysis & Contract
- [ ] Confirm source schema + row counts.
- [ ] Confirm grain and join keys.
- [ ] Write/refresh the **Data Contract** section of `spec.md`.

### Phase B — Bronze / Silver
- [ ] Create or modify Silver notebook(s).
- [ ] Add Silver BVT entries.
- [ ] Run Silver DQ agent (`CSP_DataQualityAgent_Silver`) in DEV.

### Phase C — Gold
- [ ] Create or modify Gold notebook(s) (header + revision row + `%run CommonUtilitiesFunctions`).
- [ ] Add Gold BVT entries.
- [ ] Run Gold DQ agent in DEV.
- [ ] Add new large Gold tables to `CSP_Gold_ZOrdering` scope.

### Phase D — Views, Semantic Model, Report
- [ ] Update view DDL in `MSSales/Fabric/Stored Procedure/`.
- [ ] Regenerate views via `usp_CreateViews_<Domain>_Update`.
- [ ] Update semantic model (relationships, measures); validate RLS roles still resolve.
- [ ] Update report visuals + tooltips + data dictionary entry.

### Phase E — Validation
- [ ] DEV end-to-end pipeline pass.
- [ ] BVT pass; if waived, link incident ticket per Principle V.
- [ ] Row-count + revenue parity against baseline within tolerance (state %).
- [ ] Compare report visuals against UAT/PROD baseline (regression).

### Phase F — Promotion
- [ ] PR opened; AI PR Review ≥ 70 threshold passes.
- [ ] 1ES build green (CodeQL, CodeSign, CredScan, SdtReport, PostAnalysis all green).
- [ ] Reviewer signs Constitution Check section above.
- [ ] Merge → ADO Tasks closed via ADO MCP server → status posted to parent SD.

## 3. Effort & Schedule

| Phase | Estimate (AI-assisted) | Estimate (manual) | Owner |
|---|---|---|---|
| A | | | |
| B | | | |
| C | | | |
| D | | | |
| E | | | |
| F | | | |
| **Total** | | | |

Story points: **{{SP}}** _(reference: SD #40926 = 8, SD #40927 = 21)_

## 4. Risk Register

| ID | Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| R-1 | | L/M/H | L/M/H | | |

## 5. Rollback Plan

- **Trigger:** _(e.g., BVT fails in PROD, partner-facing report regression detected)_
- **Procedure:** _(revert PR commit; re-run `*_Skip_*BVTFailure` master with incident ref; restore previous view DDL.)_
- **Communications:** _(who to notify; SharePoint update; ADO comment.)_

## 6. Open Questions

> Will be re-checked by `/speckit.analyze` and surfaced in the AI PR Review.

- [ ]
