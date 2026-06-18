# Spec Kit — MSSales / Global Partner Solutions Platform

This directory holds the Spec Kit operating system for the MSSales monorepo:
the **constitution**, the per-phase **templates**, and the orchestration
**extensions.yml**.

## Layout

```
.specify/
├─ README.md                   ← you are here
├─ extensions.yml              ← branch rules, phase hooks, ADO defaults, domain registry
├─ memory/
│  └─ constitution.md          ← mirror of /constitution.md (keep in sync)
└─ templates/
   ├─ spec-template.md         ← /speckit.specify  output
   ├─ plan-template.md         ← /speckit.plan     output (Constitution Check gate)
   ├─ tasks-template.md        ← /speckit.tasks    output (pushable to ADO)
   └─ checklist-template.md    ← /speckit.checklist output (PR body)
```

Per-feature outputs live under `specs/NNN-<adoId>-<slug>/`:

```
specs/
└─ 042-40377-multi-pla-exemption/
   ├─ spec.md
   ├─ plan.md
   ├─ tasks.md
   └─ checklist.md
```

## Daily execution pattern

Run these against any new Scenario Detail you pick up:

| # | Command | What it produces | Stops when |
|---|---|---|---|
| 1 | `/speckit.specify`   | `spec.md` (business context, FRs, NFRs, data contract, ACs) | Spec Quality Checklist passes. |
| 2 | `/speckit.plan`      | `plan.md` (Constitution Check + architecture + phases A–F) | All P1–P5 rows are PASS (or have approved justifications). |
| 3 | `/speckit.tasks`     | `tasks.md` (phase-aligned task list) — optionally pushed to ADO under the SD | Every AC in `spec.md` is referenced by ≥ 1 task. |
| 4 | `/speckit.checklist` | `checklist.md` (PR body) | All blocking items map to a task in `tasks.md`. |
| 5 | `/speckit.implement` | Code changes on the feature branch | Phases A–E green; PR opened. |
| 6 | `/speckit.analyze`   | Gap report (spec ↔ plan ↔ tasks ↔ code) | No orphans; out-of-scope items moved to "Out-of-Spec-Kit Tasks". |

## Conventions enforced

- **Branch name:** `NNN-<adoId>-<slug>` — pattern in `extensions.yml`.
- **ADO parenting:** tasks pushed by `/speckit.tasks` are parented to the
  Scenario Detail referenced in `spec.md`.
- **Constitution gates:** every `plan.md` MUST fill the P1–P5 table in
  Section 0. The AI PR Review pipeline re-evaluates the same rows.
- **Constitution source of truth:** root `/constitution.md`. Edits MUST be
  mirrored to `.specify/memory/constitution.md` in the same PR (checklist
  enforces this).

## Where to find context

- **Constitution:** [`../constitution.md`](../constitution.md)
- **MSSales repo (the system this governs):** `../../MSSales/`
- **Active ADO surface:**
  - Program — [#21671 FY26 Partner Performance](https://dev.azure.com/MCAPSDataEngineering/Global%20Partner%20Solutions/_workitems/edit/21671)
  - Active Project — [#40056 FY26 Q4 E2E CSP Reporting](https://dev.azure.com/MCAPSDataEngineering/Global%20Partner%20Solutions/_workitems/edit/40056)
  - Active Project — [#44109 APA (ACR) System Sandbox](https://dev.azure.com/MCAPSDataEngineering/Global%20Partner%20Solutions/_workitems/edit/44109)
