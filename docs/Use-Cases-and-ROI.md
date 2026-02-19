# Use Cases & ROI

This page maps real workflows our team performs to agentic capabilities, with concrete estimates of cognitive effort saved. The goal: show PMs and leads **what they can delegate today** and how much it actually saves.

---

## How to Read This Page

Each use case follows this format:

1. **Scenario** — a real task our team does
2. **Before (Manual)** — what it takes today
3. **After (Agentic)** — what the agent does
4. **ROI** — time saved, cognitive effort reduced, dependencies eliminated

Cognitive effort is rated on a simple scale:

| Rating | Meaning |
| :--- | :--- |
| **Low** | Routine, one or two tools, no recall needed |
| **Medium** | Multiple tools, some recall of IDs/paths, moderate focus |
| **High** | Many context switches, recall of GUIDs/configs, significant focus |

---

## Use Case 1: Morning Triage & Daily Briefing

**Who benefits:** PMs, Team Leads

### Before (Manual)

| Step | Tool | Time | Cognitive Effort |
| :--- | :--- | :--- | :--- |
| Open Outlook, scan priority emails | Outlook | 5 min | Medium |
| Open Teams, check unread chats from stakeholders | Teams | 5 min | Medium |
| Open Calendar, review today's meetings | Calendar | 3 min | Low |
| Open ADO, check assigned work items and updates | Azure DevOps | 5 min | Medium |
| Mentally synthesize priorities and risks | Brain | 5 min | High |
| **Total** | **4 tools** | **~23 min** | **High** |

### After (Agentic)

```
User: @orchestrator Daily triage
```

The Chief of Staff agent:
1. Queries WorkIQ for emails, chats, and calendar in one pass
2. Checks ADO for work item changes
3. Synthesizes a structured briefing: meetings, priority communications, risks, pending actions

| Metric | Value |
| :--- | :--- |
| **Time** | ~2 min |
| **Tools touched by user** | 0 (agent handles all) |
| **Cognitive effort** | Low (read a summary) |

### ROI Summary

| Metric | Before | After | Savings |
| :--- | :--- | :--- | :--- |
| Time per occurrence | 23 min | 2 min | **21 min** |
| Frequency | Daily | Daily | — |
| Weekly savings | — | — | **~1.75 hours/week** |
| Dependencies eliminated | Remembering which stakeholders to check | Agent uses config file | **Institutional knowledge codified** |

---

## Use Case 2: Create ADO Tasks from a Meeting

**Who benefits:** PMs, Devs attending standups

### Before (Manual)

| Step | Tool | Time | Cognitive Effort |
| :--- | :--- | :--- | :--- |
| Recall what was discussed in the meeting | Memory | 3 min | High |
| Open ADO, navigate to the board | Azure DevOps | 2 min | Low |
| Find the current iteration | Azure DevOps | 1 min | Medium |
| Find the Ad-hoc parent work item | Azure DevOps | 2 min | Medium |
| Create each task (title, description, assignment, parent, tags) | Azure DevOps | 5 min × N tasks | High |
| Manually add context comment citing the meeting | Azure DevOps | 2 min × N tasks | Medium |
| **Total for 3 tasks** | **1 tool** | **~30 min** | **High** |

### After (Agentic)

```
User: @orchestrator Create tasks from my standup meeting today
```

The Chief of Staff agent activates the **Create Task** skill:
1. Queries WorkIQ for meeting action items
2. Extracts discrete tasks with titles, owners, and priorities
3. Resolves current iteration and Ad-hoc parent automatically
4. Creates each task with What/When/Who structured descriptions
5. Adds source citation comments
6. Links all tasks to the parent
7. Presents a summary table

| Metric | Value |
| :--- | :--- |
| **Time** | ~3 min (including confirmation step) |
| **Cognitive effort** | Low (review and confirm) |

### ROI Summary

| Metric | Before | After | Savings |
| :--- | :--- | :--- | :--- |
| Time per occurrence (3 tasks) | 30 min | 3 min | **27 min** |
| Frequency | 3–5 times/week | Same | — |
| Weekly savings | — | — | **~1.5–2.25 hours/week** |
| Quality improvement | Manual descriptions, often incomplete | Structured What/When/Who format, auto-linked | **Better traceability** |
| Dependencies eliminated | "Which iteration are we in?" "What's the parent ID?" | Auto-resolved | **No tribal knowledge needed** |

---

## Use Case 3: End-of-Day Status Email

**Who benefits:** Everyone who reports to a manager

### Before (Manual)

| Step | Tool | Time | Cognitive Effort |
| :--- | :--- | :--- | :--- |
| Review calendar for today's meetings | Calendar | 3 min | Low |
| Recall what was accomplished | Memory | 5 min | High |
| Review sent emails for context | Outlook | 3 min | Medium |
| Review Teams chats for decisions and follow-ups | Teams | 3 min | Medium |
| Write the email with bullet points and meeting table | Outlook | 5 min | Medium |
| **Total** | **3+ tools** | **~19 min** | **High** |

### After (Agentic)

```
User: @orchestrator Generate my daily status email
```

The Chief of Staff activates the **Daily Status Email** skill:
1. Gathers context from WorkIQ (calendar, emails, Teams)
2. Reviews Copilot chat history for technical work
3. Synthesizes action items and meeting summaries
4. Formats the email and auto-sends to the configured recipient

| Metric | Value |
| :--- | :--- |
| **Time** | ~2 min |
| **Cognitive effort** | Low (review before send) |

### ROI Summary

| Metric | Before | After | Savings |
| :--- | :--- | :--- | :--- |
| Time per occurrence | 19 min | 2 min | **17 min** |
| Frequency | Daily | Daily | — |
| Weekly savings | — | — | **~1.4 hours/week** |
| Quality improvement | Manually recalling accomplishments, often missing items | Agent captures everything from all sources | **Nothing falls through the cracks** |

---

## Use Case 4: Cross-Environment Semantic Model Validation

**Who benefits:** Data Engineers, Report Developers

### Before (Manual)

| Step | Tool | Time | Cognitive Effort |
| :--- | :--- | :--- | :--- |
| Open Power BI for DEV environment, find the semantic model | Power BI portal | 3 min | Medium |
| Note the schema (tables, columns, measures) | Power BI portal | 5 min | High |
| Repeat for UAT | Power BI portal | 5 min | High |
| Repeat for PROD | Power BI portal | 5 min | High |
| Write DAX queries for row counts per table | DAX Studio or PBI | 10 min | High |
| Run queries in each environment and copy results | DAX Studio | 5 min | High |
| Manually compare schemas and metrics | Excel/Notepad | 10 min | High |
| Document findings | Email/Wiki | 5 min | Medium |
| **Total** | **3–4 tools** | **~48 min** | **Very High** |

### After (Agentic)

```
User: @orchestrator Compare AzureInvestments semantic model across DEV, UAT, and PROD
```

The Fabric DevOps agent activates the **Semantic Model Testing** skill:
1. Resolves workspace IDs from workspace-catalog.yaml
2. Fetches schemas from all three environments via Power BI Remote
3. Runs DAX queries for row counts, key metrics, and data freshness
4. Produces a structured diff with PASS/WARN/FAIL verdicts
5. Flags schema drift, row count variances >5%, and metric variances >0.1%

| Metric | Value |
| :--- | :--- |
| **Time** | ~5 min |
| **Cognitive effort** | Low (review a structured report) |

### ROI Summary

| Metric | Before | After | Savings |
| :--- | :--- | :--- | :--- |
| Time per occurrence | 48 min | 5 min | **43 min** |
| Frequency | 2–3 times/week (pre-deployment) | Same | — |
| Weekly savings | — | — | **~1.4–2.1 hours/week** |
| Error reduction | Manual comparison misses subtle drift | Agent compares every table/column/measure systematically | **Catches what humans miss** |
| Dependencies eliminated | "What DAX do I write for row counts?" "What are the dataset IDs?" | All codified in catalog and query library | **Self-service validation** |

---

## Use Case 5: Pipeline Failure Investigation

**Who benefits:** Data Engineers, On-Call Support

### Before (Manual)

| Step | Tool | Time | Cognitive Effort |
| :--- | :--- | :--- | :--- |
| Get notified of failure (email/Teams) | Outlook/Teams | 1 min | Low |
| Open Fabric portal, navigate to workspace | Fabric portal | 2 min | Low |
| Find the failed pipeline/notebook | Fabric portal | 3 min | Medium |
| Open run history, find the failed run | Fabric portal | 2 min | Medium |
| Read error messages and logs | Fabric portal | 5 min | High |
| Trace upstream dependencies to find root cause | Fabric portal + mental model | 10 min | Very High |
| Determine fix and whether other items are affected | Brain | 5 min | Very High |
| **Total** | **2–3 tools** | **~28 min** | **Very High** |

### After (Agentic)

```
User: @orchestrator Why did the Bronze_DataProcessing pipeline fail in DEV?
```

The Fabric DevOps agent activates **Lakehouse Diagnostics**:
1. Identifies the pipeline and latest failed run
2. Pulls error messages and execution logs
3. Traces upstream dependencies (lakehouse tables, shortcuts, source data)
4. Identifies root cause and affected downstream items
5. Recommends remediation steps

| Metric | Value |
| :--- | :--- |
| **Time** | ~5 min |
| **Cognitive effort** | Low (read diagnosis, decide on fix) |

### ROI Summary

| Metric | Before | After | Savings |
| :--- | :--- | :--- | :--- |
| Time per occurrence | 28 min | 5 min | **23 min** |
| Frequency | 2–4 times/week | Same | — |
| Weekly savings | — | — | **~0.8–1.5 hours/week** |
| Expertise dependency | Requires deep familiarity with pipeline graph | Agent traces dependencies systematically | **Junior members can investigate** |

---

## Use Case 6: Update ADO User Story with Requirements

**Who benefits:** PMs writing requirements, Devs refining stories

### Before (Manual)

| Step | Tool | Time | Cognitive Effort |
| :--- | :--- | :--- | :--- |
| Read the source document/email/conversation | Various | 10 min | Medium |
| Translate requirements into structured description | ADO | 10 min | High |
| Write acceptance criteria (Given/When/Then) | ADO | 10 min | High |
| Add appropriate tags | ADO | 2 min | Low |
| Add comment citing sources | ADO | 3 min | Medium |
| **Total** | **2–3 tools** | **~35 min** | **High** |

### After (Agentic)

```
User: @orchestrator Update user story 12345 with the requirements from the BRD document
```

The Chief of Staff activates **Update User Story**:
1. Fetches the existing user story
2. Reads the referenced BRD document
3. Extracts functional and technical requirements
4. Updates description with Overview/Background/Requirements/Dependencies structure
5. Adds acceptance criteria in Given-When-Then format
6. Adds technology and domain tags
7. Posts a comment citing all sources processed

| Metric | Value |
| :--- | :--- |
| **Time** | ~3 min |
| **Cognitive effort** | Low (review and approve) |

### ROI Summary

| Metric | Before | After | Savings |
| :--- | :--- | :--- | :--- |
| Time per occurrence | 35 min | 3 min | **32 min** |
| Frequency | 3–5 stories/sprint | Same | — |
| Per-sprint savings | — | — | **~1.6–2.7 hours/sprint** |
| Quality improvement | Inconsistent formatting across authors | Standardized structure every time | **Uniform, reviewable user stories** |

---

## Use Case 7: Workspace Inventory & Health Check

**Who benefits:** Team Leads, Data Engineers during sprint planning

### Before (Manual)

| Step | Tool | Time | Cognitive Effort |
| :--- | :--- | :--- | :--- |
| Open Fabric portal, navigate to DEV workspace | Fabric portal | 2 min | Low |
| Manually count and categorize items | Fabric portal | 10 min | Medium |
| Check pipeline/notebook run history for failures | Fabric portal | 10 min | High |
| Cross-reference with UAT/PROD for drift | Fabric portal | 10 min | High |
| Write up summary | Email/OneNote | 5 min | Medium |
| **Total** | **2 tools** | **~37 min** | **High** |

### After (Agentic)

```
User: @orchestrator What's the health of my DEV workspace? Show inventory and any failing jobs.
```

Fabric DevOps activates **Operate & Monitor**:
1. Lists all items by type in the workspace
2. Pulls recent job run status for notebooks and pipelines
3. Highlights failures, retries, and long-running jobs
4. Produces a PASS/WARN/FAIL health summary

| Metric | Value |
| :--- | :--- |
| **Time** | ~3 min |
| **Cognitive effort** | Low |

### ROI Summary

| Metric | Before | After | Savings |
| :--- | :--- | :--- | :--- |
| Time per occurrence | 37 min | 3 min | **34 min** |
| Frequency | Weekly (sprint planning) + ad hoc | Same | — |
| Weekly savings | — | — | **~0.6–1.0 hours/week** |

---

## Use Case 8: Deploy and Promote to UAT

**Who benefits:** Data Engineers, DevOps

### Before (Manual)

| Step | Tool | Time | Cognitive Effort |
| :--- | :--- | :--- | :--- |
| Ensure changes are committed/saved in DEV | Fabric portal | 3 min | Medium |
| Open deployment pipeline in Fabric | Fabric portal | 2 min | Medium |
| Select items and target stage | Fabric portal | 3 min | High (risk of wrong target) |
| Trigger deployment | Fabric portal | 1 min | High (PROD risk) |
| Wait for deployment to complete | Fabric portal | 5 min | Low |
| Validate deployment (schema, row counts, configs) | Multiple tools | 15 min | High |
| **Total** | **2–4 tools** | **~29 min** | **High** |

### After (Agentic)

```
User: @orchestrator Promote my notebook to UAT and validate
```

Fabric DevOps chains **Release & Promote** → **Validate**:
1. Confirms target is UAT (not PROD — guardrails check)
2. Triggers deployment pipeline via Fabric API
3. Waits for completion
4. Runs post-deployment validation automatically
5. Reports PASS/WARN/FAIL with specific findings

| Metric | Value |
| :--- | :--- |
| **Time** | ~5 min |
| **Cognitive effort** | Low (review validation report) |
| **Safety** | Agent blocks PROD writes; requires explicit confirmation for UAT |

### ROI Summary

| Metric | Before | After | Savings |
| :--- | :--- | :--- | :--- |
| Time per occurrence | 29 min | 5 min | **24 min** |
| Frequency | 1–3 times/week | Same | — |
| Weekly savings | — | — | **~0.4–1.2 hours/week** |
| Risk reduction | Manual target selection → PROD accidents possible | Guardrails enforce environment safety | **Eliminates deployment accidents** |

---

## Aggregate ROI Estimate

For a team member performing all of the above workflows regularly:

| Use Case | Weekly Frequency | Time Saved / Occurrence | Weekly Savings |
| :--- | :--- | :--- | :--- |
| Morning triage | 5× | 21 min | 1.75 hrs |
| Create tasks from meetings | 4× | 27 min | 1.80 hrs |
| Daily status email | 5× | 17 min | 1.42 hrs |
| Semantic model validation | 2× | 43 min | 1.43 hrs |
| Pipeline failure investigation | 3× | 23 min | 1.15 hrs |
| Update user stories | 1× | 32 min | 0.53 hrs |
| Health check / inventory | 1× | 34 min | 0.57 hrs |
| Deploy & promote | 2× | 24 min | 0.80 hrs |
| **Total** | | | **~9.4 hours/week** |

> **That's more than a full working day per week recovered per team member.**

### Beyond Time: Qualitative Benefits

| Benefit | Impact |
| :--- | :--- |
| **Faster onboarding** | New team members are productive in hours, not weeks |
| **Reduced risk** | PROD guardrails prevent accidental damage |
| **Better traceability** | Every action is logged in chat history |
| **Standardized quality** | User stories, task descriptions, and validations follow consistent templates |
| **Knowledge preservation** | Institutional knowledge lives in config files, not in someone's head |
| **Junior empowerment** | Team members can execute complex operations with built-in safety nets |

---

## Getting Started

Ready to try it? Here's the fastest path:

1. **Clone the repo:** `git clone <repo-url> copilot-agents`
2. **Run setup:** `.\setup.ps1`
3. **Open in VS Code** and start chatting with `@orchestrator`
4. Try: `@orchestrator Daily triage` for your first agentic workflow

See the [Architecture & Design Thinking](Architecture-and-Design-Thinking.md) page for details on how the system works under the hood.
