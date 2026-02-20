# Composite Workflow Patterns

These are common multi-agent patterns the orchestrator recognizes and executes automatically.
Referenced from `orchestrator.agent.md` §8.

---

## 8.1 Deploy → Validate → Report

**Trigger:** "deploy X to UAT and verify" or "promote and check"
1. `fabric-devops` or `databricks-devops` → execute promotion
2. Same agent → run post-deployment validation
3. `ado-devops` → create ADO task or comment if issues found

---

## 8.2 Diagnose → Fix → Verify

**Trigger:** "investigate failure in X" or "why did pipeline Y fail"
1. `fabric-devops` or `databricks-devops` → run diagnostics
2. Same agent → apply fix if safe (DEV/UAT only)
3. Same agent → re-run validation to confirm fix

---

## 8.3 Morning Triage (Full Stack)

**Trigger:** "daily triage" or "morning briefing"
1. `chief-of-staff` → M365 triage (meetings, priority mail, action items)
2. `ado-devops` → ADO sprint status, stale items, compliance summary (parallel with step 1)
3. `fabric-devops` → overnight job health summary (parallel with step 1)
4. `databricks-devops` → overnight job health summary (parallel with step 1)
5. Cross-reference: inject M365 action items into ADO context to flag any that lack corresponding work items
6. Synthesize into unified briefing with priorities, using `### M365 Source Context` and `### ADO Status Context` blocks (§5.3) to merge findings

---

## 8.4 Cross-Platform Comparison

**Trigger:** "compare DEV vs PROD" without specifying platform
1. Ask which platform (Fabric, Databricks, or both) — or infer from entity names
2. Route to appropriate agent(s) with comparison scope
3. `fabric-devops` with `fabric-devops-semantic-model-testing` skill hint if the comparison is about semantic model data quality

---

## 8.5 End-of-Sprint Validation

**Trigger:** "validate everything before release" or "pre-release checks"
1. `fabric-devops` → cross-environment validation (DEV vs UAT or UAT vs PROD)
2. `fabric-devops` → semantic model parity checks (fabric-devops-semantic-model-testing skill)
3. `databricks-devops` → config drift detection (if Databricks in scope)
4. `ado-devops` → update ADO work items with validation results

---

## 8.6 Impact Analysis

**Trigger:** "what will break if I change table X" or "trace lineage for column Y"
1. `fabric-devops` → lineage analysis (upstream/downstream)
2. `fabric-devops` → check affected semantic models (fabric-devops-semantic-model-testing skill)
3. Synthesize into impact map with risk assessment

---

## 8.7 Wiki Documentation Generation

**Trigger:** "create wiki for [report]" or "document [report] for business users" or "update wiki for [report]"
1. `wiki-devops` → full pipeline (metadata extraction + screenshots + assembly)
2. `wiki-devops` internally delegates to `chief-of-staff` for M365 business context
3. `wiki-devops` internally delegates to `fabric-devops` for lineage/model deep-dives if needed
4. `wiki-devops` → publishes to ADO wiki (with user confirmation)

Note: `wiki-devops` manages its own multi-agent coordination. The orchestrator should route the full request to `wiki-devops` and let it handle subagent delegation.

---

## 8.8 M365 Action Items → ADO Work Items

**Trigger:** "create tasks from my meeting" or "convert action items to ADO" or "check emails for action items and track them"
1. `chief-of-staff` → extract action items from specified M365 source (meeting, email thread, Teams chat)
2. `ado-devops` → create ADO work items using `### M365 Source Context` block (see §5.3). Apply compliance validation on creation.
3. Report created item IDs mapped back to original action items.

---

## 8.9 ADO Status → Status Email / Meeting Prep

**Trigger:** "send sprint status email" or "prep for standup" or "summarize ADO progress for my manager"
1. `ado-devops` → gather sprint status, item states, blockers, compliance score (activate `ado-board-hygiene` skill if health requested)
2. `chief-of-staff` → compose status email or meeting prep using `### ADO Status Context` block (see §5.3). Activate `create-daily-status-email` skill if daily status email requested.
3. Deliver draft or send as specified.

---

## 8.10 Full-Cycle Sync (M365 ↔ ADO Round-Trip)

**Trigger:** "sync my action items" or "triage emails and update board" or "check meetings, create tasks, send confirmation"
1. `chief-of-staff` → extract action items and decisions from M365 sources
2. `ado-devops` → create/update ADO items with M365 context, run compliance checks
3. `chief-of-staff` → send confirmation email or Teams message listing created/updated items with ADO links
4. Synthesize: what was extracted → what was created → what was communicated
