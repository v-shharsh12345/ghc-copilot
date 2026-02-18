---
name: 'create-daily-status-email'
description: 'Generate a comprehensive daily status email for your manager with Action Items and Key Meetings tables, pulling context from WorkIQ (Outlook, Teams, Calendar) and GitHub Copilot chat history. Automatically sends the email to the configured recipient.'
---

# Daily Status Email Generator

Generate a professional daily status email summarizing your accomplishments, action items, and key meetings for your manager. **The email is automatically sent to the configured recipient after generation.**

## Version History

| Date | Version | Description |
|------|---------|-------------|
| 2026-01-20 | 1.1 | Added auto-send capability with default recipient |
| 2026-01-20 | 1.0 | Initial skill with action items and meetings tables |

---

## Default Configuration

| Setting | Value |
|---------|-------|
| **Default Recipient** | arnavl@maqsoftware.com |
| **Subject Format** | Arnav Loonker: Daily Status Update as of [MM/DD/YYYY] |
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

### Step 3: Synthesize Action Items

For each significant activity discovered:

1. **What was accomplished** - Specific deliverable or decision
2. **Who was involved** - Key stakeholders
3. **What's next** - Committed follow-ups or deadlines

### Step 4: Synthesize Meeting Summary

For each meeting attended:

1. **Meeting name** - Official calendar title
2. **Attendees** - All participants (comma-separated)
3. **Follow-Up Tasks** - Bulleted list of action items, decisions, next steps

### Step 5: Generate Status Email

Use the output template below to format the final email.

### Step 6: Review for Quality

Before sending, review the email for:
- Spelling and grammar errors
- Consistent formatting and punctuation
- Clear, concise language
- Accurate names and dates
- Professional tone

### Step 7: Send the Email

After generating the email content, automatically send it using the Mail MCP tool:

```
Use: mcp_mcp_mailtools_SendEmailWithAttachmentsAsync
Parameters:
  to: ["arnavl@maqsoftware.com"]
  subject: "Daily Status Email as of [MM/DD/YYYY]"
  body: [Generated email content in HTML format]
```

**Example Tool Call:**
```json
{
  "to": ["arnavl@maqsoftware.com"],
  "subject": "Daily Status Email as of 01/20/2026",
  "body": "<h2>Action Items</h2><table>...</table><h2>Key Meetings</h2><table>...</table>"
}
```

---

## Output Template

```markdown
To: arnavl@maqsoftware.com
Subject: Arnav Loonker: Daily Status Update as of [MM/DD/YYYY]

## Tasks Completed

• [Concise task with outcome and next steps]
• [Task with stakeholders and timeline]

## Key Meetings

| Meeting | Key Participants | Follow-Up Tasks |
|---------|------------------|-----------------|
| [Meeting Name] | [Name1], [Name2], [Name3] | [Task]; [Decision] |
```

---

## Extraction Rules

### Action Item Extraction

| Source | What to Extract |
|--------|-----------------|
| **Email sent** | Summaries, decisions communicated, commitments made |
| **Email received** | Requests fulfilled, approvals obtained, information provided |
| **Teams chat** | Quick decisions, confirmations, coordination completed |
| **Meeting** | Decisions made, tasks assigned, deadlines agreed |
| **Copilot chat** | Code analyzed, solutions provided, technical issues resolved |

### Meeting Extraction

| Field | Extraction Logic |
|-------|------------------|
| **Meeting** | Calendar event title |
| **Attendees** | All participants from calendar invite |
| **Follow-Up Tasks** | Decisions, assigned actions, commitments (from notes, transcript, or recap) |

---

## Writing Guidelines

### Action Items Style

- **Lead with the action verb** (Finalized, Investigated, Resolved, Agreed, Confirmed, Validated, Shared)
- **Include context** - What problem was solved, what decision was made
- **Name stakeholders** - Who you coordinated with
- **State outcome** - What was delivered or committed
- **Mention timeline** - When it will be done (if applicable)

**Good Example:**
> Finalized taxonomy updates for immersion briefing eligibility reports, agreeing to rename confusing fields and split one-to-one vs. one-to-many views. Committed to complete changes in Sprint 141 and validate impact dashboard promotion this week.

**Bad Example:**
> Worked on taxonomy stuff for reports.

### Follow-Up Tasks Style

- Use bullet points (•)
- Start with action verb
- Be specific about deliverables
- Include owners if assigned to others

**Good Example:**
> • Clarified taxonomy for eligibility fields and agreed to split one-to-one vs. one-to-many reports.
> • Discussed adding attendee count card and dynamic impact dashboard features.
> • Reviewed phased rollout for performance measurement and potential midyear acceleration for Biz Apps.

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
3. Synthesize 5-10 action items from all sources
4. Extract all meetings with attendees and follow-ups
5. Format using the output template
6. Present the complete email ready to send
7. Confirm and send

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
Subject: Arnav Loonker: Daily Status Update as of 01/20/2026

---

## Tasks Completed

• Resolved Copilot usage discrepancy; validated flat files and confirmed stability
• Created user stories for CSP renewal updates; UI update by Feb 6 (Harsh)
• Compared eligibility metrics with FD&E (90% match); documenting in BRD
• Formed 4-member team for modeling standardization
• Automating refresh/pull shortcuts across tables by week's end
• Agreed on -7 days incremental refresh logic for CSPMR pipeline
• Proposed PowerShell-based Dev-to-UAT deployment
• Copilot MAU data refresh needed for free/paid metrics
• Entra P1 data access from IDEAs unresolved; may remove SMB criterion

---

## Key Meetings

| Meeting | Attendees | Follow-Up Tasks |
|---------|-----------|-----------------|
| [ABS]: PPM LT view handover | Arnav, Akshat, Rohan | • Security Accelerate reporting review • Immersion briefing mapping logic |
| Daily sync: Data & Reporting | Arnav, Krishna, Harsh, Jai Kishan, Gagandeep, Deepika | • Copilot stability email (Krishna) • CSP UI review (Nomula) • URT PR (Harsh) |
| Incentive Reporting Huddle | Arnav, Team | • PMO notes update • Copilot MAU refresh |
| ABS Workshop Eligibility | Arnav, Team | • Entra P1 data access follow-up • Bug tracking pending (Chris) |
| EA Security Accelerate CSI | Arnav, SI Team | • Partner conversion discrepancies • ESA dashboard enhancements |
| Cross SA PPM Governance | Arnav, Stakeholders | • Earning cap extension finalized • Bad actor investigation framework |

## Training

| Course | Due Date | Status
|--------| ---------| ------
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
│  • Action Items table (numbered, detailed)                      │
│  • Key Meetings table (name, attendees, follow-ups)             │
│  • Professional email format                                    │
└─────────────────────────────────────────────────────────────────┘
```
