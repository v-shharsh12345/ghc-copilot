---
name: 'ado-board-hygiene'
description: 'Audit Azure DevOps sprint boards for compliance gaps, missing fields, stale items, and hygiene violations. Produces a scored report with actionable remediation steps. Optionally auto-fixes issues with user confirmation.'
---

# ADO Board Hygiene Audit

Run repeatable compliance audits against the current sprint board, validating work items against team standards for mandatory fields, state-appropriate tags, story pointing, parent links, test case coverage, and documentation requirements.

## Version History

| Date | Version | Description |
|------|---------|-------------|
| 2026-02-20 | 1.0 | Initial skill — compliance audit, auto-fix, and reporting. |

---

## When to Use This Skill

Invoke this skill when:

- `"Audit the board"` or `"board hygiene check"`
- `"Sprint health check"` or `"sprint compliance"`
- `"What's missing on my items?"` or `"what needs attention"`
- `"Check compliance for story [ID]"` or `"validate [ID]"`
- `"Find stale items"` or `"what's stuck"`
- `"Fix up the board"` or `"clean up my work items"`

---

## Default Configuration

> **Configuration:** Read `config/user-context.yaml` at runtime to resolve ADO defaults.

| Setting | Value |
|---------|-------|
| **ADO Project** | Resolve from `config/user-context.yaml` → `ado.projects.taskCreation.name` |
| **Team** | Resolve from `config/user-context.yaml` → `ado.team` |
| **Scope** | Current iteration (default) or user-specified iteration/work item |

---

## Audit Modes

### Mode 1: Sprint Audit (Default)

Audits all work items in the current sprint iteration.

```
1. Resolve current iteration via work_list_team_iterations
2. Query all work items in the iteration: User Stories, Tasks, Bugs
3. Run each item through the compliance checklist
4. Generate scored report
```

### Mode 2: Single Item Audit

Audits a specific work item by ID.

```
1. Fetch work item by ID
2. Fetch all child/linked items
3. Run compliance checklist against the item and its children
4. Report findings
```

### Mode 3: My Items Audit

Audits all items assigned to the current user.

```
1. Fetch items via wit_my_work_items
2. Run compliance checklist
3. Report findings
```

---

## Compliance Checklist

### User Story Checks

| # | Check | States | Severity | How to Validate |
|---|-------|--------|----------|-----------------|
| US-01 | Description populated | ≥ In Planning | 🔴 Critical | Description field is not empty/null |
| US-02 | Requirements structured | ≥ In Planning | 🟡 Warning | Description contains Overview, Requirements, Dependencies sections |
| US-03 | Acceptance Criteria present | ≥ Ready | 🔴 Critical | Acceptance Criteria field is not empty |
| US-04 | ACs use Given-When-Then | ≥ Ready | 🟡 Warning | Acceptance Criteria contains Given/When/Then keywords |
| US-05 | ≥3 Acceptance Criteria | ≥ Ready | 🟡 Warning | Count of AC blocks ≥ 3 |
| US-06 | Story Points assigned | ≥ Ready | 🔴 Critical | Story Points field > 0 |
| US-07 | Story Points < 13 | Any | 🟠 Attention | Story Points < 13, else flag for decomposition |
| US-08 | Approach documented | ≥ Ready | 🟡 Warning | Comments contain "Technical Approach" or "Solution Design" |
| US-09 | Target Date set | ≥ Active | 🟡 Warning | Target Date field is not empty |
| US-10 | Iteration assigned | ≥ Active | 🔴 Critical | Iteration Path is not the root |
| US-11 | Parent link exists | Any | 🟡 Warning | Has parent relation |
| US-12 | Test Cases linked | ≥ QA In Progress | 🔴 Critical | Has Test Case links or child test cases |
| US-13 | State-appropriate tags | Any | 🟡 Warning | Tags match the required tags for current state |
| US-14 | Not stale | Active states | 🟠 Attention | Changed Date within last 14 days |

### Bug Checks

| # | Check | States | Severity | How to Validate |
|---|-------|--------|----------|-----------------|
| BG-01 | Repro Steps populated | ≥ New | 🔴 Critical | Repro Steps field is not empty |
| BG-02 | Severity set | ≥ New | 🟡 Warning | Severity field is populated |
| BG-03 | Priority set | ≥ New | 🟡 Warning | Priority field is populated |
| BG-04 | Parent link exists | Any | 🟡 Warning | Has parent relation |
| BG-05 | Root cause documented | ≥ Ready | 🟡 Warning | Comments contain root cause or Description updated |
| BG-06 | Fix description on Resolved | ≥ Resolved | 🟡 Warning | Comments contain fix description or resolution notes |
| BG-07 | Regression test on Tested | ≥ Tested | 🟡 Warning | Linked test case or test comment exists |
| BG-08 | Bug tag present | Any | 🟡 Warning | Tags include "Bug" |

### Task Checks

| # | Check | States | Severity | How to Validate |
|---|-------|--------|----------|-----------------|
| TK-01 | Parent link exists | Any | 🟡 Warning | Has parent relation |
| TK-02 | Story Points assigned | ≥ Active | 🟡 Warning | Story Points field > 0 |
| TK-03 | Effort (hours) set | ≥ Active | 🟡 Warning | Effort field > 0 |
| TK-04 | Assigned To set | ≥ Active | 🔴 Critical | Assigned To field is not empty |
| TK-05 | Iteration assigned | ≥ Active | 🔴 Critical | Iteration Path is not the root |
| TK-06 | Not stale | Active states | 🟠 Attention | Changed Date within last 14 days |

---

## Execution Steps

### Step 1: Resolve Scope

```text
Tool: work_list_team_iterations
Parameters:
  project: <from config>
  team: <from config>
  timeframe: "current"
```

### Step 2: Fetch Work Items

```text
Tool: search_workitem
Query: Iteration Path = [current iteration] AND State <> Closed AND State <> Removed
```

For single-item mode, use `wit_get_work_item` instead.

### Step 3: Run Compliance Checks

For each work item:
1. Determine the work item type (User Story, Bug, Task)
2. Look up the applicable checks from the checklist above
3. Filter checks to those relevant for the item's current state
4. Evaluate each check
5. Record result: ✅ PASS or severity level (🔴/🟠/🟡)

### Step 4: Calculate Compliance Score

```
compliance_score = (passed_checks / total_applicable_checks) × 100
```

| Score | Rating |
|-------|--------|
| 90–100% | ✅ Healthy |
| 70–89% | 🟡 Needs Attention |
| 50–69% | 🟠 At Risk |
| < 50% | 🔴 Critical |

### Step 5: Generate Report

Use the audit report format from the ADO DevOps agent §8.2.

### Step 6: Offer Auto-Fix (Optional)

For items that can be auto-fixed, present the list and ask for confirmation:

| Auto-Fixable | Action |
|-------------|--------|
| Missing tags | Add state-appropriate tags |
| Missing Bug tag | Add "Bug" tag to Bug items |
| Missing Story Points on tasks | Set to 1 (default) |
| Missing Effort on tasks | Set to 8h (default) |

> **Never auto-fix:** Description, Acceptance Criteria, Approach, Target Date — these require human judgment.

Present auto-fix proposal:
```markdown
## 🔧 Auto-Fix Available

I can automatically fix [N] items:

| # | Work Item | Fix | Before | After |
|---|-----------|-----|--------|-------|
| 1 | #[ID] | Add tags | (none) | `In-Progress` |
| 2 | #[ID] | Set Story Points | (empty) | 1 |

Shall I apply these fixes?
```

---

## Reporting Format

### Sprint Audit Report

```markdown
## 📋 Board Hygiene Audit Report

**Sprint:** [Iteration Name]
**Team:** [Team Name]
**Date:** [Date]
**Items Audited:** [count]

### Summary

| Severity | Count | Items |
|----------|-------|-------|
| 🔴 Critical | [n] | #[IDs] |
| 🟠 Attention | [n] | #[IDs] |
| 🟡 Warning | [n] | #[IDs] |
| ✅ Clean | [n] | — |

### Compliance Score: [X]% — [Rating]

### Critical Issues (Action Required)

| # | Item | Type | State | Issue | Check | Fix |
|---|------|------|-------|-------|-------|-----|
| 1 | #[ID] [Title] | User Story | Active | Missing Acceptance Criteria | US-03 | Add Given-When-Then ACs |

### Warnings

| # | Item | Type | State | Issue | Check | Fix |
|---|------|------|-------|-------|-------|-----|
| 1 | #[ID] [Title] | Task | Active | Missing Story Points | TK-02 | Set points using sizing guide |

### Stale Items (>14 days without update)

| # | Item | Type | State | Last Updated | Days Stale |
|---|------|------|-------|-------------|------------|
| 1 | #[ID] [Title] | User Story | Active | [date] | [N] |

### Auto-Fix Available
[List of fixable items or "No auto-fixable items found"]
```

### Single Item Audit Report

```markdown
## 📋 Compliance Report: #[ID] — [Title]

**Type:** [User Story/Bug/Task]
**State:** [Current State]
**Sprint:** [Iteration]

### Checks

| # | Check | Status | Detail |
|---|-------|--------|--------|
| US-01 | Description populated | ✅ | Present |
| US-03 | Acceptance Criteria | ❌ | Missing — add Given-When-Then ACs |
| US-06 | Story Points | ✅ | 3 points |
| US-09 | Target Date | ⚠️ | Not set — required for Active state |

### Compliance: [X]% — [N] of [M] checks passed

### To reach next state ([target state]):
1. [Action 1]
2. [Action 2]
```

---

## Troubleshooting

| Issue | Resolution |
|-------|------------|
| No items found in iteration | Verify team name and iteration; try listing all iterations |
| Permission denied | Ensure ADO MCP server has read access to the project |
| Cannot determine state requirements | Fall back to checking essential fields: Title, Description, Assigned To |
| Too many items to audit | Limit to user's assigned items first, then expand scope |
| Work item type unknown | Query work item type from ADO; skip unknown types |
