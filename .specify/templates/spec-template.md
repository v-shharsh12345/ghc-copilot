# Feature Specification — {{FEATURE_ID}} {{FEATURE_TITLE}}

> Produced by `/speckit.specify`. Lives at `specs/{{FEATURE_ID}}-{{slug}}/spec.md`.
> Update this file as understanding evolves; it is the source of truth that
> `plan.md`, `tasks.md`, `checklist.md`, and `/speckit.analyze` will check
> against.

| Field | Value |
|---|---|
| **Feature ID** | {{FEATURE_ID}} |
| **Title** | {{FEATURE_TITLE}} |
| **ADO Scenario Detail** | #{{ADO_SD_ID}} — {{ADO_SD_TITLE}} |
| **ADO Business Scenario (parent)** | #{{ADO_BS_ID}} — {{ADO_BS_TITLE}} |
| **ADO Project (grandparent)** | #{{ADO_PROJECT_ID}} — {{ADO_PROJECT_TITLE}} |
| **Domain** | {{DOMAIN}} _(one of: CSPvNext, POSOT_Sales, SalesReports, MSSalesUserSecurity, Investment_FDL)_ |
| **Owning Lakehouse(s)** | {{LAKEHOUSE_LIST}} |
| **Author** | {{AUTHOR}} |
| **Created** | {{ISO_DATE}} |
| **Status** | Draft \| Ready for Plan \| In Plan \| In Implementation \| Done |
| **Branch** | `{{BRANCH_NAME}}` |

---

## 1. Business Context — *Why*

<!-- 2–4 sentences. Quote the BRD, exec note, or stakeholder ask. Link
     the original artifact (SharePoint, Teams thread, ADO comment). -->

- **Problem / opportunity:**
- **Strategic driver:** _(e.g., FY26 Q4 IR Mitigation, Partner Transition Report, APA ACR Rewire)_
- **Stakeholders:** _(Business owner, SME, downstream consumer)_
- **Decision reference:** _(Meeting / email / ADO comment URL)_

## 2. User Story

> **As a** {{persona}}
> **I want** {{capability}}
> **So that** {{outcome}}

### Personas affected
| Persona | Today (pain) | After this feature |
|---|---|---|
| | | |

## 3. Scope

### In scope
- [ ]
- [ ]

### Explicitly OUT of scope
- [ ]
- [ ]

### Assumptions
- [ ]

## 4. Functional Requirements (FR)

| ID | Requirement | Acceptance signal |
|---|---|---|
| FR-1 | _The system MUST …_ | _How we will observe this is met (query, KPI, test ID)._ |
| FR-2 | | |

## 5. Non-Functional Requirements (NFR)

> Mark any that are explicitly **N/A** with a one-line justification.

| ID | Category | Requirement |
|---|---|---|
| NFR-1 | Performance | Refresh latency target / row count tolerance / SLA. |
| NFR-2 | Reliability | Restartability, idempotency, retry behavior. |
| NFR-3 | Security & Compliance | Data classification, RLS impact, secret handling (Principle IV). |
| NFR-4 | Observability | Refresh log entry, BVT coverage, alert thresholds. |
| NFR-5 | Cost / Compute | Spark pool tier selected and why (Principle III). |
| NFR-6 | Documentation | Notebook header + revision history, view DDL, README update. |

## 6. Data Contract

### Inputs
| Source | Layer | Object | Grain | Owner | Refresh cadence |
|---|---|---|---|---|---|
| | Bronze/Silver/Gold | `Schema.Table` | | | |

### Outputs
| Layer | Object (Lakehouse/View) | Grain | Key columns | Downstream consumers |
|---|---|---|---|---|
| Silver/Gold/View | | | | |

### Schema changes (if any)
| Object | Change type | Column(s) | Backfill needed? | Downstream impact |
|---|---|---|---|---|
| | add / rename / drop / retype | | Y/N | |

> Per **Principle V**, every Silver/Gold schema change requires (a) updated
> view DDL in `MSSales/Fabric/Stored Procedure/`, (b) a revision-history
> entry in the producing notebook, and (c) the **Downstream impact** column
> populated in the PR description.

## 7. Acceptance Criteria (Gherkin)

> One AC per row. Each AC MUST be objectively testable and SHOULD map to a
> task in `tasks.md` (the `/speckit.analyze` phase will check this).

- **AC-1** — GIVEN _\<precondition>_, WHEN _\<action>_, THEN _\<observable outcome>_.
- **AC-2** —
- **AC-3** —

## 8. Dependencies & Risks

| Type | Description | Owner | Mitigation |
|---|---|---|---|
| Upstream blocker | | | |
| Downstream report impact | | | |
| Source system change | | | |
| Open business question | | | |

## 9. Out-of-Cycle Items / Follow-ups

<!-- Anything the team agreed to defer. Becomes inputs to /speckit.analyze
     so we don't silently lose scope. -->

- [ ]

## 10. Glossary

| Term | Definition |
|---|---|
| | |

---

### Spec Quality Checklist (self-review before `/speckit.plan`)
- [ ] All sections filled OR explicitly marked **N/A** with a one-line reason.
- [ ] Section 1 cites the source of the business decision.
- [ ] Section 4 has at least one FR; each FR is testable.
- [ ] Section 5 considers every NFR row (no silent skips).
- [ ] Section 6 names the exact Lakehouse(s) and view(s) touched.
- [ ] Section 7 ACs use GIVEN/WHEN/THEN and are unambiguous.
- [ ] ADO Scenario Detail ID populated in the header.
