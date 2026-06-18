---
name: 'daily-status-email'
description: 'Generate a comprehensive daily status email for your manager with Key Meetings, Items Completed, Upcoming Milestones, Need Help, and LDP Goals sections, pulling context from WorkIQ (Outlook, Teams, Calendar) and GitHub Copilot chat history. Automatically sends the email to the configured recipient.'
---

# Daily Status Email Generator

Generate a professional daily status email summarizing your key meetings, items completed, upcoming milestones, blockers, and LDP goals for your manager. **The email is automatically sent to the configured recipient after generation.**

## Version History

| Date | Version | Description |
|------|---------|-------------|
| 2026-02-23 | 2.0 | Overhauled format: Key Meetings with Follow-up Actions, Items Completed with ADO links, Upcoming Milestones, Need Help, LDP Goals, status legend |
| 2026-02-20 | 1.2 | Aligned format with actual email: added Time column, Blockers & Risks, Next Steps sections |
| 2026-01-20 | 1.1 | Added auto-send capability with default recipient |
| 2026-01-20 | 1.0 | Initial skill with action items and meetings tables |

---

## Default Configuration

> **Configuration:** Read `config/user-context.yaml` at runtime to resolve recipient, subject prefix, and section structure.

| Setting | Value |
|---------|-------|
| **Default Recipient** | Resolve from `config/user-context.yaml` → `statusEmail.recipient` |
| **Subject Format** | `Daily status update for [Date]` (e.g., "Daily status update for Feb 2nd, 2026") |
| **Auto-Send** | Enabled |

---

## When to Use This Skill

Invoke this skill when:

- `"Generate my daily status email"`
- `"Draft status update for my manager"`
- `"What did I accomplish today?"`
- `"Summarize today's meetings and actions"`
- `"Create end-of-day status report"`
- `"Daily status for [date]"`

---

## Prerequisites

| Requirement | Purpose |
|-------------|---------|
| WorkIQ MCP Server | Access to Outlook, Teams, Calendar via `mcp_workiq_ask_work_iq` |
| Calendar Access | Retrieve today's meeting details and attendees |
| Email Access | Pull email threads for context on discussions |
| Teams Access | Review chats and channel messages |
| GitHub Copilot Chat | Recent conversation history for coding/technical work |

---

## How to Execute

### Step 1: Gather Context from WorkIQ

```
# Query today's calendar events
Use: mcp_workiq_ask_work_iq
Query: "What meetings did I have today? Include attendees and any notes."

# Query recent emails
Use: mcp_workiq_ask_work_iq  
Query: "What important emails did I send or receive today?"

# Query Teams chats
Use: mcp_workiq_ask_work_iq
Query: "What were my Teams conversations about today?"
```

### Step 2: Gather Context from Copilot Chat (if available)

Review recent GitHub Copilot chat conversations for:
- Code reviews performed
- Technical problems solved
- Development tasks completed
- Analysis shared

### Step 3: Synthesize Key Meetings

For each meeting attended, produce a table row with:

1. **Meeting** — Calendar event title (in square brackets with colon), e.g., `[Partner OSOT Sales, Consumption and CSP + PPR]: Daily Status Call`
2. **Summary** — Detailed bullet-point list of discussion topics, then a `Follow up Actions:` sub-section with bullets prefixed by "I will..."
3. **Attendees** — Short label for the attendee group (e.g., "PPR + CSP team", "GPS PMs")

### Step 4: Synthesize Items Completed

Gather all ADO work item IDs that were worked on today.
List them as bullets in the first column (e.g., `• 19255`).
In the second column, provide detailed bullet-point summaries of all work accomplished across those items.

### Step 5: Synthesize Upcoming Milestones

Identify upcoming milestones such as:
- Weekly meetings
- Critical releases
- Customer in-person meetings
- MBRs (Monthly Business Reviews)

Format as a table with Milestones and Timeline/ETA columns.

### Step 6: Synthesize Need Help

Identify items where help is needed:
- Blocked or waiting on external decisions
- At risk of missing deadlines
- Dependent on unresolved issues

Format as a table with Topic, Summary, and Owner columns.

### Step 7: Include LDP Goals

Pull the user's LDP (Learning & Development Plan) goals.
Format as a table with Goal, Timeline, Status, and Progress columns.
Use status values from the legend: Not Started, On Track, Recoverable Delay, Irrecoverable delay, Completed, On Hold.

### Step 8: Generate Status Email

Use the output template below to format the final email.

### Step 9: Review for Quality

Before sending, review the email for:
- Spelling and grammar errors
- Consistent formatting and punctuation
- Clear, concise language
- Accurate names and dates
- Professional tone
- All sections present in correct order
- Status legend at the bottom

### Step 10: Send the Email

After generating the email content, automatically send it using the Mail MCP tool:

```
Use: mcp_mcp_mailtools_SendEmailWithAttachments
Parameters:
  to: ["<recipient from config/user-context.yaml>"]
  subject: "Daily status update for [Date]"
  body: [Generated email content in HTML format]
```

**Example Tool Call:**
```json
{
  "to": ["manager@contoso.com"],
  "subject": "Daily status update for Feb 2nd, 2026",
  "body": "<p>This is my daily status update for Feb 2nd, 2026:</p><p>Task 33500 CSP Reporting...</p><h2>Key Meetings:</h2><table>...</table><h2>Items Completed:</h2><table>...</table>..."
}
```

---

## Output Template

```markdown
To: <recipient from config/user-context.yaml>
Subject: Daily status update for [Date]

This is my daily status update for [Month Day, Year]:
Task [ADO ID] [Task Title]

Key Meetings:
| Meeting | Summary | Attendees |
|---------|---------|----------|
| [Meeting Category]: [Meeting Title] | • [Discussion point 1]<br>• [Discussion point 2]<br>• [Discussion point N]<br>Follow up Actions:<br>• I will [action 1].<br>• I will [action 2].<br>• I will [action N]. | [Attendee group] |

Items Completed:
| ADO Link / Title | Summary |
|------------------|--------|
| • [ADO ID 1]<br>• [ADO ID 2]<br>• [ADO ID N] | • [Detailed accomplishment 1]<br>• [Detailed accomplishment 2]<br>• [Detailed accomplishment N] |

Upcoming Milestones: (Can be weekly meeting, some critical release, customer in-person meeting, MBR, etc.)
| Milestones | Timeline/ETA |
|-----------|-------------|
| [Milestone name] | [Month Year] |

Need Help:
| Topic | Summary | Owner |
|-------|---------|------|
| [Topic] | [Summary] | [Owner] |

LDP Goals:
| Goal | Timeline | Status | Progress |
|------|----------|--------|----------|
| [Goal name] | [Month Year] | [Status] | [Progress] |

     Not Started  	   On Track  	   Recoverable Delay	    Irrecoverable delay 	  Completed 	     On Hold  
```

---

## Extraction Rules

### Items Completed Extraction

| Source | What to Extract |
|--------|-----------------|
| **Email sent** | Summaries, decisions communicated, commitments made |
| **Email received** | Requests fulfilled, approvals obtained, information provided |
| **Teams chat** | Quick decisions, confirmations, coordination completed |
| **Meeting** | Decisions made, tasks assigned, deadlines agreed |
| **Copilot chat** | Code analyzed, solutions provided, technical issues resolved |
| **ADO work items** | Work item IDs actively worked on today — list as bullets |

### Meeting Extraction

| Field | Extraction Logic |
|-------|------------------|
| **Meeting** | Calendar event title — format as `[Category]: Title` |
| **Summary** | Detailed bullet-point list of discussion topics, followed by `Follow up Actions:` sub-section with "I will..." prefixed bullets |
| **Attendees** | Short group label (e.g., "PPR + CSP team", "GPS PMs") |

### Upcoming Milestones Extraction

| Source | What to Extract |
|--------|------------------|
| **Meetings** | Upcoming deadlines, sprint dates, release milestones |
| **Emails** | Scheduled reviews, delivery dates |
| **ADO** | Sprint end dates, milestone work items |

### Need Help Extraction

| Source | What to Extract |
|--------|------------------|
| **Meetings** | Blocked decisions, unresolved issues, slipped timelines |
| **Emails** | Escalations, dependency requests, pending approvals |
| **Teams chats** | Flagged risks, resource constraints, technical blockers |

### LDP Goals Extraction

| Source | What to Extract |
|--------|------------------|
| **User context** | Learning goals, certification targets, training deadlines |
| **Previous emails** | Last reported LDP status and progress |

---

## Writing Guidelines

### Items Completed Style

- **Lead with the action verb** (Reviewed, Investigated, Resolved, Validated, Confirmed, Shared, Continued, Coordinated)
- **Include context** - What problem was solved, what decision was made
- **Name stakeholders** - Who you coordinated with
- **State outcome** - What was delivered or committed
- **Mention timeline** - When it will be done (if applicable)

**Good Example:**
> • Reviewed and responded to multiple CSP revenue and authorization escalation threads, providing detailed analysis on tenant attribution gaps and recommending corrective mappings.
> • Continued maintaining high visibility communication with Microsoft stakeholders on CSP status derivation issues.

**Bad Example:**
> Worked on schema stuff for reports.

### Meeting Summary Style

- Use bullet points (•) for each discussion topic
- Be detailed and specific about what was discussed
- Include a `Follow up Actions:` sub-section after the discussion points
- Each follow-up action starts with "I will"
- Be specific about deliverables

**Good Example:**
> • Discussed ongoing data validation and logic issues identified in recent CSP production runs.
> • Reviewed missing records associated with blank tenant scenarios.
> Follow up Actions:
> • I will continue validating tenant to MPN mapping fixes in Azure.
> • I will coordinate with CFAR on anniversary date logic alignment.

---

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `date` | No | Today | Date for status report (MM/DD/YYYY or "today", "yesterday") |
| `recipient` | No | Manager | Who the email is for (affects formality) |
| `includeCopilot` | No | true | Include GitHub Copilot chat activities |
| `minMeetings` | No | 0 | Minimum meetings to include (skip if fewer) |
| `maxActionItems` | No | 10 | Maximum action items to include |

---

## Example Conversations

### User: "Generate my daily status email"

**Expected Behavior:**

1. Query WorkIQ for today's calendar, emails, and Teams chats
2. Review any recent Copilot chat history for technical work
3. Determine the primary ADO task ID and title for the day
4. Extract all meetings with summary bullets, follow-up actions, and attendees
5. Gather ADO work item IDs and synthesize detailed items completed
6. Identify upcoming milestones with timeline/ETA
7. Identify any items needing help (topic, summary, owner)
8. Include LDP goals with status and progress
9. Add status legend at the bottom
10. Format using the output template
11. Present the complete email ready to send
12. Confirm and send

---

### User: "Daily status for yesterday"

**Expected Behavior:**

Same workflow but with date parameter set to yesterday's date.

---

### User: "Status update focusing on the Azure Accelerate project"

**Expected Behavior:**

Filter action items and meetings to only those related to Azure Accelerate, then generate the email.


## Troubleshooting

| Issue | Solution |
|-------|----------|
| No meetings found | Check calendar permissions, verify date parameter |
| Missing follow-ups | Manually review meeting transcripts if available |
| Incomplete action items | Query emails/chats with specific keywords |
| Copilot context missing | Note that Copilot chat history may have limited retention |

---

## Sample Output

```
Subject: Sai Chaitanya Chaganti: Daily Status Report - 2/20/2026

---

## Tasks Completed

• Reviewed and validated **CSP Exemption Logic Dev Build** — Received dev build from Shivangi Chaudhary (MAQ) with report link, validation Excel, and PR #6312 for exemption logic updates. Sign-off review in progress.
• Confirmed weekly status for **CSP Eligibility & Offboarding Reporting** — Overall status: On Track. UAT build shared today (02/20); exemption logic standardized and consolidated. ACR Solution Area analysis initiated. Prod target: 02/27.
• Clarified **FY27 Channel Motion logic** position across multiple teams — Confirmed no channel motion logic change is finalized for FY27. Communicated FYI-only posture to CDS and GPSHub teams. Earliest possible timeline for changes: May–June.
• Agreed to move **Power BI refresh for offboarding** from monthly to weekly cadence — Coordinated with Vamsidhar Kavi and CSP Offboarding team. Weekly refresh (Monday mornings) to support T0 notification timelines.
• Provided architectural guidance on **DimUnifiedPartner usage** — Clarified that DimUnifiedPartner is GPSMart-specific and not a general-purpose partner dimension.
• Resolved **Channel Motion Logic documentation access issues** — Provided corrected SharePoint share-enabled links after access issues were flagged.
• Coordinated on **ACR data clarification for Solution Area grain** — Engaged on technical thread regarding solution area mapping derivation from AIP tables.
• Reviewed **CSP Authorization automation decision request** — Tracked urgent decision request on Support Plan dependency. Option 1 (Partial Automation) recommended.

---

## Key Meetings

| Meeting | Time | Key Participants | Follow-Up Tasks |
|---------|------|------------------|-----------------|
| **Offboarding Critical Open Issues & DCRs — Daily Triage** | 8:30–9:30 AM | Savvy Him, Hema Sathyanarayanan, Molly Halfin, Nick Thain, Prasham Ajmera, Anshul Gupta | • Go/No-Go decision pushed to next Friday due to unresolved blockers<br>• Suspend bug fix ETA: Feb 23 EOD; revoke bug regressed (no ETA)<br>• Clean test accounts needed for suspend/revoke validation |
| **CSP Partner Offboarding** | 10:30–11:00 AM | Savvy Him, Pavan Marella, Sai Krishna Manduva, Kexin Chi, Ryan McDonald, Hans Loland, Nick Thain | • Implement weekly Power BI + OCI refresh cadence (Monday mornings)<br>• Resolve data count discrepancies between Power BI and OCI<br>• Automation work paused due to code freeze; resume after UAT |
| **Channel Motion Updates – Planning Alignment** | 11:00–11:30 AM | Savvy Him, Vasagiri Guruteja, Prasanna Polisetti, Pedro Dagnino, Brittany Lewis, Sanjay Kondrakunta | • No channel motion logic change for FY27 at this time<br>• Provide FY23 Q4 actuals by mid-March<br>• Review shared channel logic flow and update user stories |
| **GPS Cross Team Huddle** | 11:00–11:25 AM | Kexin Chi, Shane Fretwell, Shivaraj Akula, Amar Sadashiva, Arnav Loonker, Annie French, Pallabi Majumdar | • Cross-team coordination sync (no transcript captured) |

---

## Blockers & Risks

• **CSP Authorization Automation Blocked** — Support Plan data unreliable; manual reviews continue until GA of UfP. Executive decision pending on Option 1 (Partial Automation).
• **Offboarding Go/No-Go Delayed** — Pushed to next Friday. Suspend bug fix targeting Feb 23; revoke bug regressed with no ETA.
• **Automation Code Freeze** — Automated case creation paused; expected to resume after UAT readiness.

---

## Next Steps

• Complete sign-off review for **Exemption Logic Dev Build (PR #6312)**
• Validate and prepare for **Prod deployment (target: 02/27)**
• Begin **T90/T60/T30 offboarding actions** next Monday
• Deliver **FY23 Q4 actuals** for Planning alignment by mid-March
• Monitor suspend/revoke bug fixes and reassess Go/No-Go timeline
---
```

---

## Appendix: Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        INPUT SOURCES                            │
├─────────────────┬─────────────────┬─────────────────────────────┤
│  WorkIQ Calendar│  WorkIQ Email   │  WorkIQ Teams               │
│  (Meetings)     │  (Threads)      │  (Chats)                    │
├─────────────────┼─────────────────┼─────────────────────────────┤
│  Copilot Chat   │  ADO (optional) │  Meeting Transcripts        │
│  (Technical)    │  (Work items)   │  (via Chief of Staff)       │
└────────┬────────┴────────┬────────┴─────────────┬───────────────┘
         │                 │                      │
         ▼                 ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EXTRACTION ENGINE                            │
│  • Identify significant activities                              │
│  • Extract meeting metadata                                     │
│  • Correlate discussions across sources                         │
│  • Deduplicate related items                                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    OUTPUT GENERATION                            │
│  • Tasks Completed (bold topic + detailed description)          │
│  • Key Meetings table (name, time, participants, follow-ups)    │
│  • Blockers & Risks (bold topic + status description)           │
│  • Next Steps (forward-looking actions with deadlines)          │
└─────────────────────────────────────────────────────────────────┘
```
