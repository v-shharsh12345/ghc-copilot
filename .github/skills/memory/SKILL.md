---
name: 'memory'
description: 'Persistent cross-session memory — search past context, store decisions, update user profile, flush session state. Backed by QMD (BM25 keyword search) over indexed markdown files.'
---

# Memory Skill

## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-03-04 | 1.0 | Initial memory system — MEMORY.md, daily logs, session checkpoints, QMD search, memory flush. |

---

## Overview

The memory system provides **persistent cross-session context** for all agents. It has three layers:

| Layer | Storage | Auto-Loaded | Purpose |
|-------|---------|-------------|---------|
| **Semantic Memory** | `memory/MEMORY.md` | Yes (every session) | Permanent user facts — profile, preferences, contacts, active projects, platform context |
| **Episodic Memory** | `memory/daily/YYYY-MM-DD.md` | Today + yesterday | Daily context logs — decisions, progress, blockers, next steps |
| **Session Checkpoints** | `memory/session/checkpoint-{topic}.md` | On demand | Cross-request context within a conversation (backs WorkFast §5.5) |

A fourth layer — **Knowledge Retrieval** — enables searching across all memory content plus skill documentation via QMD.

---

## Default Configuration

> **Configuration:** QMD MCP server must be registered in `.vscode/mcp.json`. Run `scripts/setup-memory.ps1` for first-time setup.

| Setting | Value |
| --- | --- |
| **Semantic memory file** | `memory/MEMORY.md` (max ~200 lines) |
| **Daily log directory** | `memory/daily/` |
| **Session checkpoint directory** | `memory/session/` |
| **Knowledgebase directory** | `memory/knowledgebase/` |
| **QMD MCP server** | `qmd` in `.vscode/mcp.json` |

---

## When to Use This Skill

Invoke this skill when:
- `"search my memory"`, `"find past decisions"`, `"what did we discuss about <topic>"`, `"recall <something>"`
- `"remember this"`, `"update my profile"`, `"save this preference"`
- `"goodbye"`, `"end session"`, `"save context"`, `"flush memory"`
- `"re-index memory"`, `"update memory index"`
- Any query that requires searching across daily logs, session checkpoints, or knowledgebase content

---

## Prerequisites

| Requirement | Purpose |
| --- | --- |
| QMD MCP server (`qmd`) | BM25 keyword search over indexed markdown files |
| Node.js 18+ | Required for QMD installation (`npm install -g @tobilu/qmd`) |
| `memory/MEMORY.md` | Semantic memory file (created from template by `setup-memory.ps1`) |

---

## QMD Collections

QMD indexes markdown files into searchable collections:

| Collection | Path | What's Indexed |
|-----------|------|---------------|
| `memory-root` | `memory/*.md` + `memory/daily/*.md` | MEMORY.md and daily context logs |
| `session-checkpoints` | `memory/session/*.md` | Session checkpoint files (WorkFast §5.5) |
| `knowledgebase` | `memory/knowledgebase/**/*.md` | Curated knowledge articles, reference material |
| `skills-docs` | `.github/skills/**/SKILL.md` | All skill definitions and procedures |

---

## MCP Tools

QMD exposes these tools via the `qmd` MCP server:

| Tool | Description | Use When |
|------|-------------|----------|
| `qmd_search` | BM25 keyword search (fast, instant) | Exact terms, names, IDs, dates, error strings |
| `qmd_get` | Retrieve full document by path | Read a specific file found via search |
| `qmd_multi_get` | Retrieve multiple documents | Read several related files at once |
| `qmd_status` | Index health and collection info | Verify QMD is running and indexed |

### CLI Fallback

If the QMD MCP server is unavailable, use CLI commands:

```powershell
# Keyword search (fast)
qmd search "lakehouse pipeline failure" -n 5

# Search within a specific collection
qmd search "sprint status" -c memory-root -n 10

# Get a specific document
qmd get "memory/daily/2026-03-04.md" --full

# Check index status
qmd status

# Re-index after content changes
qmd update
```

---

## Procedures

### 1. Session Start Protocol

At the beginning of every session, load context:

1. **Read `memory/MEMORY.md`** — permanent user facts, preferences, platform context.
2. **Read today's daily log** (`memory/daily/YYYY-MM-DD.md`) — if it exists, resume context. If not, create it with a header.
3. **Read yesterday's daily log** — for continuity on overnight gaps.
4. **Check `memory/session/`** — if relevant checkpoints exist from prior requests, load them.

### 2. Memory Search

**When to search:** Before answering questions about:
- Past decisions, discussions, or context from previous sessions
- Knowledge articles, specifications, or technical details
- Historical daily logs or progress notes
- Any topic where the `memory/` directories might have relevant content

**Search workflow:**

1. **Determine search type:**
   - Known exact terms (names, IDs, dates) → Use `qmd_search` MCP tool (BM25 keyword, instant)
   - Broad or conceptual queries → Use `qmd_search` with multiple keyword variations

2. **Scope the search:**
   - Daily logs → collection: `memory-root`
   - Session checkpoints → collection: `session-checkpoints`
   - Knowledge articles → collection: `knowledgebase`
   - Skill workflows → collection: `skills-docs`
   - Cross-cutting topics → omit collection (searches all)

3. **Inject results as context:**
   - Include top search results in your reasoning
   - Cite the source file path when referencing retrieved content
   - If results are insufficient, try different keywords or broader query

### 3. Updating Semantic Memory (MEMORY.md)

When the user shares permanent facts (preferences, contacts, project changes):

1. Read current `memory/MEMORY.md`
2. Classify the new information:
   - **Profile/preference** → Update the relevant section
   - **New contact** → Add to Key Contacts table
   - **Platform context** → Update Platform Context section
   - **Learned preference** → Append to Learned Preferences with date
3. Check for contradictions — new info replaces old
4. Ensure file stays under ~200 lines
5. Write the updated file

### 4. Daily Context Logs

Store session summaries, decisions, and working context as dated files in `memory/daily/`.

**Format:**

```markdown
# YYYY-MM-DD

## Summary
Brief overview of the day's work.

## Decisions
- Decision made and rationale

## Progress
- What was accomplished

## Blockers
- Any open issues

## Next Steps
- What to pick up next
```

**Rules:**
- Auto-load today + yesterday only; search older logs via QMD
- Append notable context throughout the session
- Keep entries scannable, not exhaustive transcripts

### 5. Session Checkpoints

Session checkpoints back the WorkFast's §5.5 protocol. They preserve context across long conversations.

**File pattern:** `memory/session/checkpoint-{topic}.md`

**Format:**

```markdown
# Checkpoint: {topic}
**Time:** {timestamp}
**Request:** {one-line summary}

## Decisions
- {confirmed scope, environment, entities}

## Results
- {agent}: {key outputs}

## Pending
- {next steps or open items}
```

**Rules:**
- Always checkpoint after multi-agent workflows (2+ agents)
- Always checkpoint after write actions (creates, deploys, sends)
- Update existing checkpoints rather than creating new files when continuing the same task
- Review existing checkpoints at the start of each new request

### 6. Memory Flush (Session End)

When the user says "goodbye", "end session", "save context", or similar:

1. **Review session for unsaved context:**
   - Decisions made but not yet written to daily log
   - New permanent facts not yet in MEMORY.md
   - Action items or next steps discussed but not recorded

2. **Write to daily log** (`memory/daily/YYYY-MM-DD.md`):
   - Append a `## Session Summary` section with key decisions, outcomes, next steps
   - Include action items with owners and deadlines

3. **Update MEMORY.md** if permanent facts changed

4. **Re-index QMD:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/memory-flush.ps1
   ```

---

## Knowledgebase (`memory/knowledgebase/`)

Store long-term curated knowledge as markdown files. Organized by topic:

```
memory/knowledgebase/
├── fabric/                    # Fabric-specific knowledge
├── databricks/                # Databricks-specific knowledge
├── ado/                       # ADO process knowledge
├── architecture/              # Architecture decisions, diagrams
└── runbooks/                  # Operational runbooks
```

**Rules:**
- Not auto-loaded — search via QMD, then retrieve what's relevant
- Use descriptive kebab-case filenames (e.g., `lakehouse-refresh-troubleshooting.md`)
- If an article already exists for a topic, update it rather than creating a new one

---

## Re-indexing

After adding significant new content:

```powershell
# Re-index all collections (fast, local)
qmd update
```

QMD also auto-reindexes every 5 minutes when running as an MCP server.

---

## Rules

### Search Rules
- **ALWAYS** search QMD before answering questions about past context — do not rely on conversation history alone
- **ALWAYS** cite the source file path when using retrieved content
- **ALWAYS** prefer MCP tools (`qmd_search`, `qmd_get`) over CLI when the QMD MCP server is available
- Start with `qmd_search` (fast BM25 keyword) and try different keywords if initial results are insufficient
- When contradictions are found between memory sources, prefer more recent content

### Memory Maintenance Rules
- **ALWAYS** load `memory/MEMORY.md` at session start
- **ALWAYS** create/update today's daily log. Auto-load today + yesterday only
- **ALWAYS** flush memory before ending a session
- **NEVER** store secrets, credentials, or sensitive data in memory files
- **NEVER** store temporary/episodic facts in MEMORY.md — use daily logs instead
- Daily logs should be scannable, not exhaustive transcripts

---

## Guardrails

- Memory files are **local and personal** — they are gitignored and not committed to the repo
- `memory/MEMORY.template.md` is the committed template; `memory/MEMORY.md` is the personal copy
- Never write secrets, tokens, or credentials to any memory file
- Session checkpoints may contain sensitive operation results — they are gitignored
