---
name: update-user-story
description: Update Azure DevOps (ADO) user stories in OneMW project based on references and requirements. Use this skill when the user provides a user story ID and wants to (1) update the description with detailed requirements, (2) add or update acceptance criteria, (3) add comments with implementation details or clarifications, (4) add appropriate tags for categorization and tracking. This skill processes referenced materials (documents, conversations, specifications) to enrich the user story with comprehensive details. Requires ADO MCP server access.
---

# Update ADO User Story Skill

## Table of Contents
- [Prerequisites](#prerequisites)
- [Execution Steps](#execution-steps)
- [Field Update Templates](#field-update-templates)
- [Tag Guidelines](#tag-guidelines)
- [Example Output](#example-output)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before executing this skill, verify:
- ADO MCP server is available and configured
- User has provided the **User Story ID** from OneMW project
- User has provided or referenced materials containing requirements/details
- Access to relevant context (documents, conversations, specifications)

## Execution Steps

### Step 1: Retrieve the Existing User Story

Use ADO MCP tools to fetch the current user story:

1. Query the work item by ID in the **OneMW** project
2. Review existing fields:
   - Title
   - Description
   - Acceptance Criteria
   - Tags
   - State
   - Assigned To
   - Area Path
   - Iteration Path

**Tool to use:** `mcp_microsoft_azu_search_workitem` or get work item by ID

```text
Project: OneMW
Work Item ID: [provided by user]
```

### Step 2: Gather Context from References

Process all referenced materials provided by the user:

1. **Documents/Files**: Read and extract key requirements
2. **Conversation History**: Review Copilot chat for context
3. **Specifications**: Identify functional and technical requirements
4. **Meeting Notes**: Extract action items and decisions (use `mcp_workiq_ask_work_iq` if applicable)

Organize extracted information into:
- **Functional Requirements**: What the feature should do
- **Technical Requirements**: How it should be implemented
- **Constraints**: Limitations or dependencies
- **Success Criteria**: Measurable outcomes

### Step 3: Update User Story Description

Craft a comprehensive description following this structure:

```markdown
## Overview
[High-level summary of the user story purpose]

## Background
[Context and motivation for this work item]

## Requirements
### Functional Requirements
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

### Technical Requirements
- [Technical spec 1]
- [Technical spec 2]

## Dependencies
- [Dependency 1]
- [Dependency 2]

## Out of Scope
- [Items explicitly not included]

## References
- [Links to related documents, PRs, or other work items]
```

**Tool to use:** Update work item description field

### Step 4: Update Acceptance Criteria

Add or update acceptance criteria using the Given-When-Then format:

```markdown
## Acceptance Criteria

### AC1: [Criteria Name]
**Given** [initial context/precondition]
**When** [action is performed]
**Then** [expected outcome]

### AC2: [Criteria Name]
**Given** [initial context/precondition]
**When** [action is performed]
**Then** [expected outcome]

### AC3: [Criteria Name]
**Given** [initial context/precondition]
**When** [action is performed]
**Then** [expected outcome]

## Definition of Done
- [ ] Code complete and peer reviewed
- [ ] Unit tests written and passing
- [ ] Documentation updated
- [ ] QA sign-off obtained
- [ ] Deployed to staging environment
```

**Tool to use:** Update work item Acceptance Criteria field

### Step 5: Add Comment with Implementation Details

Add a comment documenting:
- Source of requirements (references processed)
- Key decisions or clarifications
- Any assumptions made
- Open questions for the team

**Comment Structure:**
```text
📝 **User Story Updated**

**Sources Processed:**
- [Reference 1: description]
- [Reference 2: description]

**Key Updates Made:**
1. Description: [summary of changes]
2. Acceptance Criteria: [number of ACs added/updated]
3. Tags: [tags added]

**Assumptions:**
- [Assumption 1]
- [Assumption 2]

**Open Questions:**
- [ ] [Question 1]
- [ ] [Question 2]

**Updated by:** GitHub Copilot Skill
**Date:** [current date]
```

**Tool to use:** `mcp_microsoft_azu_wit_add_work_item_comment`

### Step 6: Add Appropriate Tags

Add tags based on the user story content:

| Category | Tags |
|----------|------|
| **Technology** | `Fabric`, `Power BI`, `Databricks`, `SQL`, `Python`, `ADF` |
| **Type** | `Feature`, `Enhancement`, `Tech-Debt`, `Bug-Fix` |
| **Priority** | `P0-Critical`, `P1-High`, `P2-Medium`, `P3-Low` |
| **Domain** | `Data-Engineering`, `Reporting`, `Analytics`, `Infrastructure` |
| **Team** | `Data-Platform`, `Incentive-Reporting`, `DevOps` |

**Tool to use:** Update work item Tags field

## Field Update Templates

### Description Template (HTML Format)
```html
<div>
  <h2>Overview</h2>
  <p>[Summary]</p>
  
  <h2>Background</h2>
  <p>[Context]</p>
  
  <h2>Requirements</h2>
  <h3>Functional Requirements</h3>
  <ul>
    <li>[Requirement 1]</li>
    <li>[Requirement 2]</li>
  </ul>
  
  <h3>Technical Requirements</h3>
  <ul>
    <li>[Tech spec 1]</li>
    <li>[Tech spec 2]</li>
  </ul>
  
  <h2>Dependencies</h2>
  <ul>
    <li>[Dependency]</li>
  </ul>
  
  <h2>References</h2>
  <ul>
    <li><a href="[url]">[Reference name]</a></li>
  </ul>
</div>
```

### Acceptance Criteria Template (HTML Format)
```html
<div>
  <h3>AC1: [Name]</h3>
  <p><strong>Given</strong> [context]<br/>
  <strong>When</strong> [action]<br/>
  <strong>Then</strong> [outcome]</p>
  
  <h3>AC2: [Name]</h3>
  <p><strong>Given</strong> [context]<br/>
  <strong>When</strong> [action]<br/>
  <strong>Then</strong> [outcome]</p>
  
  <h2>Definition of Done</h2>
  <ul>
    <li>☐ Code complete and peer reviewed</li>
    <li>☐ Unit tests written and passing</li>
    <li>☐ Documentation updated</li>
    <li>☐ QA sign-off obtained</li>
  </ul>
</div>
```

## Tag Guidelines

### When to Add Each Tag

| Condition | Tag to Add |
|-----------|------------|
| Involves Fabric/Lakehouse | `Fabric` |
| Involves Power BI reports/semantic models | `Power BI` |
| Involves Databricks notebooks | `Databricks` |
| Involves SQL scripts or stored procedures | `SQL` |
| Involves Python development | `Python` |
| Involves ADF pipelines | `ADF` |
| New feature development | `Feature` |
| Improving existing functionality | `Enhancement` |
| Addressing technical debt | `Tech-Debt` |
| Fixing a bug | `Bug-Fix` |
| Production-blocking | `P0-Critical` |
| High business impact | `P1-High` |
| Standard priority | `P2-Medium` |
| Nice to have | `P3-Low` |

## Example Output

### Before Update
```text
Title: Implement data refresh automation
Description: (empty)
Acceptance Criteria: (empty)
Tags: (none)
```

### After Update

**Description:**
```html
<div>
  <h2>Overview</h2>
  <p>Implement automated data refresh for the IncentiveReporting Lakehouse to ensure timely data availability for downstream reports.</p>
  
  <h2>Background</h2>
  <p>Currently, data refreshes are triggered manually, causing delays in report availability. Stakeholders require data to be refreshed every 6 hours to meet SLA requirements.</p>
  
  <h2>Requirements</h2>
  <h3>Functional Requirements</h3>
  <ul>
    <li>Automated refresh every 6 hours (00:00, 06:00, 12:00, 18:00 UTC)</li>
    <li>Email notification on refresh completion or failure</li>
    <li>Retry logic for transient failures (3 attempts with exponential backoff)</li>
  </ul>
  
  <h3>Technical Requirements</h3>
  <ul>
    <li>Use Fabric Data Pipeline for orchestration</li>
    <li>Implement using existing token_utilities.py for authentication</li>
    <li>Log refresh status to audit table</li>
  </ul>
  
  <h2>Dependencies</h2>
  <ul>
    <li>MWS_Staging_MCAP Lakehouse must be available</li>
    <li>Service principal with Fabric API permissions</li>
  </ul>
  
  <h2>References</h2>
  <ul>
    <li>Confluence: Data Refresh SLA Requirements</li>
    <li>PR #245: Token utilities implementation</li>
  </ul>
</div>
```

**Acceptance Criteria:**
```html
<div>
  <h3>AC1: Scheduled Refresh Execution</h3>
  <p><strong>Given</strong> the automated refresh is configured<br/>
  <strong>When</strong> the scheduled time is reached<br/>
  <strong>Then</strong> the Lakehouse refresh is triggered automatically</p>
  
  <h3>AC2: Failure Notification</h3>
  <p><strong>Given</strong> the refresh job fails after all retry attempts<br/>
  <strong>When</strong> the failure is detected<br/>
  <strong>Then</strong> an email notification is sent to the configured recipients</p>
  
  <h3>AC3: Audit Logging</h3>
  <p><strong>Given</strong> a refresh job completes (success or failure)<br/>
  <strong>When</strong> the job status is determined<br/>
  <strong>Then</strong> the status is logged to the audit table with timestamp and details</p>
  
  <h2>Definition of Done</h2>
  <ul>
    <li>☐ Pipeline deployed to DEV and tested</li>
    <li>☐ Pipeline deployed to PROD</li>
    <li>☐ Monitoring dashboard configured</li>
    <li>☐ Documentation updated</li>
  </ul>
</div>
```

**Tags:**
```text
Fabric; Data-Engineering; Feature; P1-High; Incentive-Reporting
```

**Comment Added:**
```text
📝 **User Story Updated**

**Sources Processed:**
- Confluence page: Data Refresh SLA Requirements
- Copilot conversation: Technical implementation discussion
- Email thread: Stakeholder requirements confirmation

**Key Updates Made:**
1. Description: Added overview, background, functional/technical requirements, dependencies, and references
2. Acceptance Criteria: Added 3 ACs with Given-When-Then format plus Definition of Done
3. Tags: Added Fabric, Data-Engineering, Feature, P1-High, Incentive-Reporting

**Assumptions:**
- Service principal already has required permissions
- Audit table schema exists in MWSDataWarehouse

**Open Questions:**
- [ ] Confirm exact notification recipients list
- [ ] Verify retry delay intervals with platform team

**Updated by:** GitHub Copilot Skill
**Date:** February 3, 2026
```

## Troubleshooting

| Issue | Resolution |
|-------|------------|
| User story not found | Verify the work item ID and confirm it exists in OneMW project |
| Permission denied | Ensure ADO MCP server has write access to the project |
| Tags not applying | Check that tag format is semicolon-separated |
| HTML not rendering | Verify HTML is well-formed and use supported tags only |
| References not accessible | Ask user to provide content directly if links are inaccessible |
| Existing content overwritten | Always APPEND to existing description/criteria unless user confirms replacement |

## Notes

- **Always preserve existing content**: When updating, append new information rather than replacing unless explicitly instructed
- **Verify before updating**: Show the user what will be updated and get confirmation for significant changes
- **Use consistent formatting**: Follow the HTML templates for proper rendering in ADO
- **Reference all sources**: Always cite where information came from in the comment
- **Project**: Always use **OneMW** as the project name
- **Ask for clarification**: If references are ambiguous, ask the user for clarification before updating
