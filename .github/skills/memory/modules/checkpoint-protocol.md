# Checkpoint Protocol

> Canonical procedure for the WorkFast's §5.5 Session Checkpointing.
> This module provides the backing implementation for checkpoint operations.

## Overview

Session checkpoints preserve cross-turn context within long conversations and across sessions. They are stored as markdown files in `memory/session/checkpoint-{topic}.md`.

## When to Create/Update Checkpoints

| Event | Action |
|-------|--------|
| After context verification (§1.5) | Create checkpoint with confirmed scope |
| After each subagent completes | Update checkpoint with results |
| After write actions | Update checkpoint with created/modified entity IDs |
| After composite workflows | Create end-to-end summary checkpoint |
| User corrections/guidance | Update checkpoint with corrected context |
| Session end | Mark active checkpoints as `Status: paused` |
| Session start | Scan checkpoints; surface `Status: in-progress` or `Status: paused` items |

## Checkpoint File Format

```markdown
# Checkpoint: {topic-slug}
**Time:** {ISO 8601 timestamp}
**Request:** {one-line summary}
**Status:** {in-progress | completed | paused | blocked}
**Agents:** {comma-separated list of agents involved}

## Decisions
- {confirmed scope, environment, entities}

## Results
- {agent-name}: {key outputs — IDs, counts, statuses}
- {agent-name}: {key outputs}

## Errors
- {any failures or warnings}

## Pending
- {next steps or open items for follow-up}
```

## Topic Naming Convention

Use kebab-case slugs derived from the request:

| Request | Topic Slug |
|---------|-----------|
| "Deploy notebook to UAT" | `notebook-deploy-uat` |
| "Board hygiene audit" | `board-hygiene-audit` |
| "Check SSAS model vs Fabric" | `ssas-fabric-comparison` |
| "Daily triage" | `daily-triage-YYYY-MM-DD` |

## Lifecycle Rules

1. **Create** when a multi-agent or write-action workflow begins.
2. **Update** after each significant step — append to Results, update Status.
3. **Complete** when the user confirms the workflow is done. Set `Status: completed`.
4. **Pause** at session end if the workflow isn't finished. Set `Status: paused`.
5. **Resume** at next session start — scan for `paused` checkpoints and surface them.
6. **Purge** checkpoints older than 7 days with `Status: completed`. Keep `paused` indefinitely.

## Integration with WorkFast

The WorkFast's §5.5 references `memory/session/checkpoint-{topic}.md` as the canonical path.

When the WorkFast says "save key results to session memory", it means:
1. Determine the topic slug from the current request.
2. Check if `memory/session/checkpoint-{topic}.md` exists.
3. If yes, read it, update the Results and Pending sections, update the timestamp.
4. If no, create it using the format above.
