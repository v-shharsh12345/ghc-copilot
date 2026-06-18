<!--
SYNC IMPACT REPORT
==================

Version change: (none) → 1.0.0

Rationale: Initial ratification of the project constitution for the MSSales
Global Partner Solutions Platform Microsoft Fabric monorepo. MAJOR baseline
because all principles are newly defined and binding.

Modified principles: (initial creation — none renamed)
  - Added: I. Medallion Layer Discipline
  - Added: II. Notebook Authoring Standards
  - Added: III. Fabric Artifact Conventions
  - Added: IV. Security, Compliance & Supply-Chain Integrity (NON-NEGOTIABLE)
  - Added: V. Reproducibility & Data Quality Gates

Added sections:
  - Platform & Technology Constraints
  - Development Workflow & Review Process
  - Governance

==================
Version change: 1.1.0 → 1.2.0
Rationale: MINOR bump — a new Core Principle (VII. Hierarchy Integrity &
Lifecycle Cascade) is added, codifying cross-quarter structural patterns
surfaced after walking ALL five child Projects under Program #21671
(#9020 Q1, #25138 Q2, #34134 Q3, #40056 Q4, #44109 APA), 42 Business
Scenarios, and their Scenario-Detail relations. Principle VI is
unchanged; P7 covers structural concerns (type hierarchy, closure
cascade, quarter carryover, sprint scoping, calendar-gated enforcement)
that are distinct from per-task hygiene.

Modified principles:
  - Added: VII. Hierarchy Integrity & Lifecycle Cascade
  - (I–VI unchanged)

Evidence (full hierarchy walk audited 2026-05-29):
  Q1 #9020 (Closed): 4 BS — 0% Desc/AC coverage; #8012 BS Active
    while parent Closed; #26921 typed as Scenario Detail directly
    under Project (skips BS layer).
  Q2 #25138 (Closed): 8 BS — 0% Desc/AC; #25142 in unrecognized state
    `On Hold`; #27267 used Sprint Q (a Q3-era sprint) under Q2 parent.
  Q3 #34134 (Closed): 14 BS — Project administratively closed while
    0 of 14 children Closed (5 Active, 1 Ready for Engineering, 8 New).
    #35754 BS has SP=20 with no Description, no AC, no decomposition
    tag. New unrecognized state `Ready for Engineering` observed.
  Q4 #40056 (Active): 14 BS + 1 schema-violation Task (#42425) directly
    under Project; 9 of 14 BSes are exact title clones of Q3 originals
    that were never closed → live duplicate trackers. Tag `P0` used
    as priority-as-tag (#40041). Hash-prefixed tags `#Target1; #Target2`
    on #42425.
  APA #44109 (Active): 1 BS, exceptionally rich Project-level
    documentation (10 custom HTML fields populated); inverse anti-
    pattern — BS itself bare.

Cross-quarter patterns now formalized:
  1. Schema violations — non-BS work items as direct children of a
     Project (Task #42425, SD #26921).
  2. Parent–child state desync at quarter scale (Q3 Project Closed
     with all 14 children open).
  3. Quarterly carryover without Predecessor/Successor links produces
     live duplicate trackers (9 Q3↔Q4 pairs).
  4. Unrecognized states `On Hold` and `Ready for Engineering` outside
     the catalogued §4.1 state machine.
  5. Closed-without-iteration: items closed while iteration path sits
     at root (`Global Partner Solutions`) with no sprint (5+ Q1/Q2 BSes).
  6. Sprint-spans-quarters: Sprint S appears under both Q3 and Q4
     projects → ambiguous sprint-to-quarter mapping.
  7. Tag taxonomy fragmentation across quarters: hyphenated vs spaced
     vs all-caps acronyms vs hash-prefixed vs priority-as-tag.
  8. Calendar step-change in metadata discipline at Q3 — pre-Q3 items
     have ~0% Desc/AC, post-Q3 items climb to ~57%.
  9. Project-level custom-field boilerplate copy-pasted across
     #9020/#25138/#34134/#40056 with identical text.
 10. BS-level Story Points effectively unused (1 of 42 BSes has SP).

Added sections: (Principle VII; no other section additions)
Removed sections: none

Templates requiring updates:
  - ✅ .specify/templates/plan-template.md  — Constitution Check table
        must add a P7 row.
  - ✅ .specify/templates/tasks-template.md — Phase F gains T-F8/T-F9
        (hierarchy + carryover audits).
  - ✅ .specify/templates/checklist-template.md — add §1.7 Principle VII
        block with cascade + carryover + state-whitelist checks.
  - ✅ .specify/extensions.yml — add P7 gate + `hierarchy_integrity`
        config (type_hierarchy, closure_cascade, carryover_links,
        allowed_states, sprint_scope_regex, calendar_gate,
        boilerplate_detection).
  - ✅ .specify/memory/constitution.md — version mirror line refresh.
  - ⏳ .specify/templates/spec-template.md — no change needed.

Follow-up TODOs:
  - TODO(RATIFICATION_DATE confirmation): Original ratification date
    2026-05-26 retained.
  - TODO(legacy grandfathering): Confirm calendar-gate cutoff of
    Project #34134 (FY26 Q3) creation date 2026-02-? for pre-Q3
    read-only treatment.
  - TODO(MSSales/README.md): Repository README still a stub.
  - TODO(retroactive cleanup batch): 9 Q3↔Q4 carryover pairs need
    Predecessor/Successor links or Q3 source moved to `Removed`;
    1 Task (#42425) needs reparenting to a BS or SD; 1 SD (#26921)
    needs reparenting under a BS.
-->

# MSSales Platform Constitution
<!-- Microsoft Fabric monorepo for the Global Partner Solutions (GPS) Sales &
     CSP data platform, owned by MCAPS Data Engineering. -->

## Core Principles

### I. Medallion Layer Discipline

All data assets MUST be organized according to a Bronze → Silver → Gold
medallion architecture and live under their owning domain folder
(`Fabric/CSPvNext/`, `Fabric/POSOT_Sales/`, `Fabric/SalesReporting/`,
`Fabric/MSSalesUserSecurity/`, `Fabric/Investment_FDL/`, etc.).

Rules (MUST):
- A Gold notebook MUST NOT read directly from raw/source systems; it reads
  only from Silver (or other Gold) Lakehouse tables in the same domain.
- A Silver notebook MUST NOT write to a Gold table, and vice versa.
- Lakehouse names MUST encode the layer and domain (e.g., `POSOT_CSP`,
  `POSOT_CSPvNext_Reporting`, `POSOT_Sales_Reporting`).
- Reporting/serving notebooks MUST live under the domain's `*Reporting`
  or `Sales Reports` folder and read only from Gold.

Rationale: A strict, directional medallion flow keeps lineage auditable,
makes BVT (build verification test) failures localized to a single layer,
and prevents accidental coupling between ingestion and serving concerns.

### II. Notebook Authoring Standards

Every Fabric notebook (`*.Notebook/notebook-content.py`) MUST be readable,
self-describing, and reuse shared utilities instead of duplicating logic.

Rules (MUST):
- The first markdown cell MUST declare: `Project Name`, `Notebook Stage`
  (Bronze | Silver | Gold | Init | Reporting | Tools), `Notebook Name`,
  `Purpose`, `Parameter Info`, and a `Revision History` table.
- Every code change to a notebook MUST append a new row to the
  `Revision History` table (Date, Author, Description, Execution Time).
- Common Spark/IO helpers MUST be invoked via
  `%run CommonUtilitiesFunctions` (or the domain's equivalent shared
  notebook) rather than re-implemented.
- Spark resource profile and pool selection
  (`spark.fabric.resourceProfile`, attached `Environment`) MUST be set
  explicitly when the workload deviates from the domain default.
- Notebook metadata blocks (`# META {...}`) MUST be preserved; do not
  hand-edit kernel or `language_group` fields without justification.

Rationale: These notebooks are the production code of the platform. A
consistent header, revision trail, and shared-utility reuse are what
make on-call triage, audit, and onboarding tractable across hundreds
of notebooks.

### III. Fabric Artifact Conventions

Fabric artifacts (Notebooks, DataPipelines, Lakehouses, Environments,
Stored Procedures) MUST follow predictable naming and placement so that
deployment, lineage, and security tooling work without custom mappings.

Rules (MUST):
- Notebook folders MUST end in `.Notebook`, pipelines in `.DataPipeline`,
  lakehouses in `.Lakehouse`, environments in `.Environment` — matching
  the Fabric Git integration contract.
- Notebook names MUST be prefixed with `<Domain>_<Layer>_` (e.g.,
  `CSP_Gold_FactSales`, `CSP_Gold_DimCustomer`). Fact tables use the
  `Fact*` stem, dimensions `Dim*`, bridges `DimBridge*`, snapshots
  `*Snapshot`.
- Spark pool environments under `Fabric/Environments/` (`Small_Pool`,
  `Medium_Pool`, `Large_Pool`, `XLarge_Pool`, `XXLarge_Pool`) are the
  ONLY approved compute targets; ad-hoc pool definitions MUST NOT be
  introduced without amending this constitution.
- T-SQL view definitions for the warehouse MUST live in
  `Fabric/Stored Procedure/` and be created via the
  `usp_CreateViews_*_Update` stored procedures (one per domain), not
  via direct `CREATE VIEW` scripts in notebooks.
- Files staged for ingestion MUST be placed under
  `Fabric/Files/<Domain>/`.

Rationale: Fabric Git integration, deployment pipelines, and security
scoping all rely on these folder/suffix conventions. Drift breaks
publish, CodeQL indexing, and 1ES artifact tracking.

### IV. Security, Compliance & Supply-Chain Integrity (NON-NEGOTIABLE)

All changes MUST pass the Microsoft 1ES secure pipeline and the
MCAPSDE AI PR Review before merge. Production credentials and tenant
data MUST never enter the repository.

Rules (MUST):
- The 1ES pipeline (`MSSales/MSSales_Build_1ES.yml`) and CodeQL onboarding
  (`MSSales/codeqlonboarding.yml`) MUST remain green; CodeQL, CodeSign,
  CredScan, SdtReport, and PostAnalysis tasks MUST NOT be removed or
  permanently disabled without an approved security exception.
- The AI PR review pipeline (`MSSales/ado/azure-pipelines.yaml`) MUST
  remain enabled on all PRs; the configured pass threshold (currently
  70) MUST NOT be lowered without sign-off from the accountable service
  owner declared in `MSSales/es-metadata.yml`.
- Secrets, connection strings, SAS tokens, production tenant identifiers,
  OAuth client secrets, and personal data MUST NOT be committed. Use
  Fabric workspace connections, Key Vault references, or pipeline
  variable groups.
- Notebooks MUST use `notebookutils.credentials` / workspace identities
  for authentication; hard-coded service principals are prohibited.
- New top-level pipelines or external repository references MUST be
  reviewed against the `MCAPS Data Engineering` allow-list.

Rationale: This repository powers MCAPS revenue and partner-compliance
reporting. A single leaked credential or unsigned artifact has both
regulatory and revenue impact, so these gates are absolute.

### V. Reproducibility & Data Quality Gates

Every refresh path MUST be reproducible from source control and MUST
fail loudly when data contracts are violated.

Rules (MUST):
- Orchestration MUST flow through the canonical master pipelines
  (`CSP_Master_Refresh_Full`, `CSP_Staging_Master_Refresh_Full`,
  `CSP_Reporting_Refresh_Full`, and the Sales / UserSecurity
  equivalents). Ad-hoc one-off pipelines MUST NOT be scheduled in
  production.
- Data quality MUST be enforced via the existing agents
  (`CSP_DataQualityAgent_Silver`, `CSP_DataQualityAgent_Gold`) and the
  Silver/Gold BVT pipelines (`CSP_Silver_BVT`, `CSP_Mart_Master_BVT`).
  A failing BVT MUST block downstream Gold/Reporting refresh unless
  routed through an explicit `*_Skip_*BVTFailure` master, which itself
  requires an incident ticket reference.
- Every Gold notebook MUST update the refresh log
  (`CSP_Gold_RefreshLog` or the domain equivalent) on both success and
  failure.
- Z-ordering / table maintenance (`CSP_Gold_ZOrdering`) MUST be run on
  the schedule defined in the master pipeline; large new Gold tables
  MUST be added to its scope.
- Schema-affecting changes (new/removed/renamed columns in Silver or
  Gold tables, or in `vw_*` views) MUST be accompanied by: (a) updated
  view definitions in `Fabric/Stored Procedure/`, (b) a revision-history
  entry in the producing notebook, and (c) a note in the PR description
  describing downstream report impact.

Rationale: Partner incentive, IR compliance, and sales-attainment
reports are computed from these tables. Silent schema drift or skipped
BVTs translate directly into incorrect partner payouts and customer-
facing dashboards.

### VI. Work Item Hygiene & Traceability

Every unit of work MUST be traceable from Program → Project → Business
Scenario → Scenario Detail → Task → Pull Request → merged commit, with
no orphan items at any level. This principle was added in v1.1.0 after
an audit of Program #21671 surfaced recurring traceability gaps that
blocked PR review and sprint reporting.

Rules (MUST):
- **Task title convention.** Every Task title MUST start with a domain
  tag in square brackets and contain a unique, specific noun phrase —
  not just "Work on <feature>":
  `[<Domain>]: <Verb> <Specific Object> — <Sprint or PR scope>`
  Examples:
  - GOOD: `[CSP]: Field Dashboard SM — remove unused tables & retest RLS (PR #####)`
  - GOOD: `[APA ACR]: ARM HttpIncomingRequests — chunked Bronze ingestion notebook`
  - BAD : `[CSP]: Work on Customer Reporting Phase 2` (collides across days/assignees)
  A Task title MUST NOT duplicate another open Task title in the same
  sprint+area path. Rename one before closing the second.
- **Parent linking.** Every Task MUST be parented (Hierarchy-Reverse) to
  a Scenario Detail. Tasks parented directly to Business Scenario,
  Project, or Program are non-compliant and MUST be re-parented before
  closure. A Scenario Detail MUST be parented to a Business Scenario.
- **Tag taxonomy.** The approved tag vocabulary is:
  - Workflow:     `Copilot`, `WorkFAST`, `SpecKit`
  - Sprint focus: `Target 1`, `Target 2`, `Target 3` (pick exactly one
    per Task; multiple Target tags on one Task indicate scope drift
    and MUST be split into separate Tasks).
  - Lifecycle:    `Done` (applied on closure), `Blocked`, `Waiver`.
  - Domain:       `CSP`, `CSPvNext`, `POSOT_Sales`, `MSSalesUserSecurity`,
    `Investment_FDL`, `APA-ACR`.
  Free-form tags (`Copilot 1`, casing/typo variants, ad-hoc topic tags)
  MUST NOT be introduced. New tags require a constitution PATCH.
- **Description & Acceptance Criteria.** The standard fields
  `System.Description` and `Microsoft.VSTS.Common.AcceptanceCriteria` (or
  the work-item-type equivalent — `TCM.ReproSteps` on Scenario Detail)
  MUST be populated for every Scenario Detail and every Task estimated
  at ≥ 4 hours. Content placed only in Custom HTML fields
  (`Custom.Narrative`, `Custom.BusinessRequirements`, etc.) MUST also be
  mirrored to the standard fields so spec-kit, AI PR Review, and stock
  ADO queries can read them.
- **Closure comment.** Closing a Task MUST add a comment containing, at
  minimum: (a) the merged PR ID(s), (b) one sentence per major
  deliverable, (c) any open follow-ups linked to a new Task ID. The
  `Done` tag MUST be applied at the same time the state moves to Closed.
- **State sync.** A Scenario Detail MUST NOT remain in `New` once any
  child Task is `Active` or `Closed`. SDs are moved to `Active` when
  the first child Task starts and to `Closed` only after every child
  Task is `Closed` or explicitly de-scoped via a linked follow-up SD.
- **Test Case coverage.** Any Scenario Detail with Story Points ≥ 8 OR
  any schema-affecting Scenario Detail (per Principle V) MUST link at
  least one Test Case (`Tested-By` relationship) per Acceptance
  Criterion. SD #40926 (13 Test Cases for 5 ACs) is the reference
  example; SD #40927 (21 SP, schema-affecting, zero TCs at audit time)
  is the anti-pattern.
- **Effort & schedule fields.** Every Active Task MUST have either
  `Original Estimate` or `Story Points` set, and every Active Scenario
  Detail MUST have a `Target Date`. Items missing both block sprint
  capacity planning and are non-compliant.
- **Spec Kit cross-reference.** When the change is executed through Spec
  Kit (`/speckit.specify` → `…` → `/speckit.implement`), the feature
  branch name and `specs/NNN-<slug>/` folder MUST encode the Scenario
  Detail ID (`NNN-<adoId>-<slug>`), and the closure comment MUST link
  the merged PR back to the SD.

Rationale: Sprint-level reporting, AI PR Review, on-call triage, and
portfolio dashboards all read these fields. Generic titles like "Work
on Customer Reporting Phase 2" repeated six times in one sprint, missing
PR IDs on closure, and `New` SDs sitting on top of 20 `Closed` Tasks
break every one of those consumers and silently inflate planning
estimates. The cost of enforcement is a few minutes per Task; the cost
of skipping it is a sprint-end reconciliation exercise on every cycle.

### VII. Hierarchy Integrity & Lifecycle Cascade

The ADO work-item tree under Program #21671 MUST stay structurally
sound across quarter boundaries. Where Principle VI governs an
individual Task's hygiene, Principle VII governs the **shape, state
cascade, and quarterly carryover** of the tree itself. Violations here
produce duplicate trackers, prematurely-closed parents, and orphaned
sprints that no per-task fix can recover.

Rules (MUST):

- **Type hierarchy is fixed**: `Program → Project → Business Scenario
  → Scenario Detail → (Task | Bug | Test Case)`. A Project's direct
  children MUST be of type `Business Scenario` only. Any `Scenario
  Detail`, `Task`, `Bug`, or `Test Case` attached directly to a Project
  (e.g., Task #42425, SD #26921) is a **P0 schema violation** and MUST
  be reparented or recreated under the correct BS/SD.

- **Closure cascade**: A Project, Business Scenario, or Scenario
  Detail MUST NOT transition to `Closed` while any direct child is in
  an open state (`New`, `Active`, `Ready`, `Ready for Engineering`,
  `Blocked`, `On Hold`). Q3 Project #34134 closing with 14/14 BSes
  still open is the canonical anti-pattern this rule blocks.

- **Closed-with-sprint requirement**: A BS or SD MUST NOT be `Closed`
  while its iteration path sits at the program root
  (`Global Partner Solutions`) or the fiscal-year root
  (`Global Partner Solutions\FY{YY}`). Closed items MUST reference a
  specific sprint iteration that ran within their parent Project's
  calendar window.

- **Quarterly carryover discipline**: When work crosses a quarterly
  Project boundary (e.g., FY26 Q3 → FY26 Q4), the prior-quarter item
  MUST either (a) be moved to `Removed` with a comment naming the
  successor work item ID, or (b) be linked to the successor via the
  `Predecessor / Successor` relation. Cloning a BS into the next
  quarter without resolving the source creates the live duplicates
  observed across 9 Q3↔Q4 pairs and MUST NOT recur.

- **State whitelist**: BS, SD, and Task states are restricted to the
  catalogued set: `New`, `Active`, `Ready`, `Blocked`, `Resolved`,
  `Closed`, `Removed`. The non-catalogued states `On Hold` (#25142)
  and `Ready for Engineering` (#37141) are forbidden going forward;
  pre-existing items MUST migrate to `Blocked` and `Ready` respectively
  within the next sprint they touch.

- **Sprint scoping**: Each sprint iteration belongs to exactly one
  quarterly Project. A sprint MUST NOT carry items from two different
  quarterly Projects (the Sprint S overlap between Q3 #34134 and Q4
  #40056 is the anti-pattern). Project iteration path MUST be at least
  `Global Partner Solutions\FY{YY}\Q{N}` so sprint-to-quarter mapping
  is unambiguous; APA-style projects at the program root are exempt
  only when explicitly tagged `program-cross-cutting`.

- **Calendar-gated enforcement**: Items created before the start of
  FY26 Q3 (Project #34134 creation date) are **grandfathered as
  read-only legacy** — Principle VI and Principle VII audits report
  them as `legacy` and MUST NOT block their parents. Items created
  on or after that date receive full enforcement. The cutoff date is
  recorded in `.specify/extensions.yml :: hierarchy_integrity.calendar_gate`.

- **Project-level documentation uniqueness**: The Custom HTML fields
  on a Project (`CurrentState`, `DesiredState`, `KRs`, `Status
  Narrative`, `Work Plan`, `Project Summary`, etc.) MUST be unique per
  Project. Identical boilerplate copy-pasted across Q1/Q2/Q3/Q4
  Projects is a WARN-level violation and MUST be either replaced with
  project-specific narrative or pushed down to the BS level where the
  work actually lives.

- **BS-level Story Points are roll-up only**: Story Points on a
  Business Scenario MUST equal the sum of Story Points on its child
  Scenario Details (computed, not hand-entered). Independent BS-level
  SP entry is forbidden — the current ~0% coverage signals the field
  is misunderstood; we standardize on aggregation rather than re-
  pointing.

- **Recurring-theme pre-seeding**: At the open of each new quarterly
  Project, the four evergreen themes — `Executive Views / Summary`,
  `Channel Motion`, `Exception / Exemption Logic`, `Customer Journey /
  SMB` — MUST exist as empty BS shells under the new Project, even
  if unstaffed, so they are never forgotten mid-quarter and so
  carryover linking has a target on day one.

Rationale: A constitution that polices individual tasks but ignores
the shape of the tree they sit in cannot prevent the systemic failures
this program has already accumulated — quarters closing with all work
still open, the same BS title living in two consecutive quarters with
no link between them, sprints that belong to two quarters at once,
and `Closed` items that never made it into a sprint. Principle VII
adds the structural guardrails so Principle VI's per-task hygiene has
a sound tree to operate on. The calendar gate is deliberate: we do
not rewrite history, we draw a line at FY26 Q3 (when description and
AC coverage stepped from 0% to ~57% naturally) and enforce strictly
from there forward.

## Platform & Technology Constraints

- **Platform**: Microsoft Fabric (Lakehouse + Data Pipelines + Notebooks
  + Warehouse views). Azure DevOps for CI/CD (`MCAPS Data Engineering`
  project, 1ES official pool `1es_mcapsde_pool`).
- **Languages**: PySpark (`synapse_pyspark` kernel) for notebooks; T-SQL
  for warehouse views and stored procedures; YAML for pipeline
  definitions.
- **Compute**: Only the approved Spark pool environments under
  `Fabric/Environments/` may be referenced from notebooks.
- **Ownership**: Accountable service is the AAD service object declared
  in `MSSales/es-metadata.yml`; default area path
  `MCAPSDataEngineering\Global Partner Solutions\Platform`.
- **External repositories**: Only `1ESPipelineTemplates/...` and
  `MCAPS Data Engineering/MCAPSDE_PR_Review_Assistant` are pre-approved
  as `resources.repositories` references.

## Development Workflow & Review Process

- **Branching**: Work happens on feature branches; merges into the
  default branch occur via pull request. Speckit feature branches
  follow the `###-feature-name` convention enforced by
  `.specify/extensions.yml`.
- **Pull requests**: Every PR triggers the AI PR review pipeline and
  the 1ES build. Both MUST be green before merge. Reviewers MUST
  verify constitution compliance — in particular Principles I, II,
  IV, and V — and call out any violations explicitly.
- **Commits**: Speckit `after_*` hooks are configured to offer
  auto-commits per phase; commit messages SHOULD describe the
  artifact(s) touched (notebook name, pipeline name, view name).
- **Specs & plans**: Non-trivial changes (new Gold tables, new
  domains, new pipelines, schema breaks) SHOULD go through the
  speckit flow (`/speckit.specify` → `/speckit.plan` →
  `/speckit.tasks` → `/speckit.implement`) so the Constitution Check
  gate in the plan template is enforced.
- **Documentation**: When a new domain folder is introduced under
  `Fabric/`, a `Readme.md` MUST be added (even a one-line stub is
  better than absence) and the top-level `MSSales/README.md` SHOULD
  be updated to list the domain.

## Governance

This constitution supersedes ad-hoc conventions and prior tribal
practice. Where this document conflicts with an older wiki page,
runbook, or code comment, this document wins until an amendment is
ratified.

Amendment procedure:
1. Open a PR that edits `.specify/memory/constitution.md` with the
   proposed change and an updated Sync Impact Report comment.
2. Bump `CONSTITUTION_VERSION` using semantic versioning:
   - **MAJOR**: A principle is removed, redefined in a backward-
     incompatible way, or a NON-NEGOTIABLE rule is relaxed.
   - **MINOR**: A new principle or section is added, or material new
     guidance is introduced.
   - **PATCH**: Wording, typo, or clarification with no semantic shift.
3. Update `LAST_AMENDED_DATE` to the merge date (ISO `YYYY-MM-DD`).
4. Propagate any required edits to `.specify/templates/*` in the same
   PR.
5. Obtain approval from at least one accountable owner of the MSSales
   platform (per `MSSales/es-metadata.yml`).

Compliance review: PR reviewers MUST verify compliance with the Core
Principles on every change. Complexity or deviations MUST be justified
in the PR description; unjustified violations are grounds for blocking
the PR. The 1ES and AI PR Review pipelines are the automated portion
of this gate and MUST NOT be bypassed (e.g., `--no-verify`, disabling
tasks, or merging with failed required checks).

**Version**: 1.2.0 | **Ratified**: 2026-05-26 | **Last Amended**: 2026-05-29
