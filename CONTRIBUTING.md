# Contributing to Copilot Agents

Guidelines for adding or modifying agents, skills, config, and MCP servers in this repository.

---

## Table of Contents

- [Repository Structure](#repository-structure)
- [Branching & PR Workflow](#branching--pr-workflow)
- [File Format Conventions](#file-format-conventions)
- [Adding an Agent](#adding-an-agent)
- [Adding a Skill](#adding-a-skill)
  - [Standalone Skills](#standalone-skills)
  - [Capability Skills (under a domain agent)](#capability-skills-under-a-domain-agent)
- [Modifying Shared Config](#modifying-shared-config)
- [Adding an MCP Server](#adding-an-mcp-server)
- [Version History Convention](#version-history-convention)
- [Naming Conventions](#naming-conventions)
- [Frontmatter Reference](#frontmatter-reference)
- [Safety & Guardrails](#safety--guardrails)
- [Testing Your Changes](#testing-your-changes)
- [Evaluation Framework](#evaluation-framework)
- [Documentation](#documentation)
- [Common Mistakes](#common-mistakes)

---

## Repository Structure

```
copilot-agents/
├── README.md                          ← Landing page
├── CONTRIBUTING.md                    ← You are here
├── setup.ps1                          ← Setup script
├── .gitignore
├── config/
│   ├── user-context.template.yaml     ← Template (committed)
│   └── user-context.yaml              ← Personal values (gitignored)
├── docs/                              ← Public documentation
│   ├── 1-Why.md
│   ├── 2-Architecture.md
│   ├── 3-Use-Cases-and-ROI.md
│   ├── 4-Setup-Guide.md
│   └── agents/                        ← Per-agent deep-dive docs
│       ├── chief-of-staff/
│       │   └── architecture.md
│       └── fab-devops/
│           └── architecture.md
├── .vscode/
│   └── mcp.json                       ← MCP server registry (committed)
└── .github/
    ├── agents/                        ← Agent definitions (.agent.md)
    │   ├── orchestrator.agent.md
    │   ├── chief-of-staff.agent.md
    │   ├── ado-devops.agent.md
    │   ├── fabric-devops.agent.md
    │   ├── databricks-devops.agent.md
    │   ├── wiki-devops.agent.md
    │   └── composite-patterns.md      ← Multi-agent composition reference
    ├── evaluations/                   ← Agent evaluation framework
    │   ├── EVAL-FRAMEWORK.md
    │   ├── baseline.yaml
    │   └── eval-manifest.yaml
    └── skills/                        ← Skill definitions (SKILL.md)
        ├── create-task/SKILL.md
        ├── daily-status-email/SKILL.md
        ├── update-user-story/SKILL.md
        ├── compare-semantic-models/
        │   ├── SKILL.md
        │   ├── dataset-catalog.yaml
        │   └── comparison-queries.md
        ├── fabric-devops/             ← Shared resource layer
        │   ├── SKILL.md
        │   ├── config/
        │   │   ├── workspace-catalog.yaml
        │   │   ├── execution-router.yaml
        │   │   └── intent-router.yaml
        │   └── modules/
        │       ├── safety-guardrails.md
        │       ├── develop.md
        │       ├── operate-monitor.md
        │       └── ...
        ├── fabric-devops-develop/SKILL.md
        ├── fabric-devops-operate-monitor/SKILL.md
        ├── fabric-devops-*/SKILL.md     ← Capability skills
        ├── databricks-devops/           ← Shared resource layer
        ├── databricks-devops-*/SKILL.md ← Capability skills
        ├── ado-board-hygiene/SKILL.md   ← ADO board hygiene skill
        ├── wiki-devops/SKILL.md         ← Wiki operations skill
        └── agent-eval-runner/SKILL.md   ← Evaluation runner skill
```

**Key rules:**
- Agents live in `.github/agents/` as `<name>.agent.md`
- Skills live in `.github/skills/<name>/SKILL.md`
- Shared config lives under the parent skill folder (e.g., `fabric-devops/config/`)
- `config/user-context.yaml` is gitignored — never commit personal values
- `config/user-context.template.yaml` is committed — update it when adding new config fields

---

## Branching & PR Workflow

1. Create a feature branch from `main`:
   ```
   git checkout -b feature/<short-description>
   ```
2. Make changes following the conventions below.
3. Test in VS Code Copilot Chat (see [Testing](#testing-your-changes)).
4. Commit with a clear message:
   ```
   git commit -m "Add fabric-devops-<capability> skill for <purpose>"
   ```
5. Push and open a PR against `main`.
6. PR description should state: what was added/changed, which agents/skills are affected, and how you tested it.

---

## File Format Conventions

### Markdown with YAML Frontmatter

All agents and skills use Markdown files with YAML frontmatter delimited by `---`:

```md
---
name: my-agent
description: One-line description of what this agent does.
tools: ['server/tool_name', ...]
---

# Agent Title

Body content in Markdown.
```

### YAML Config Files

- Use `.yaml` extension (not `.yml`)
- Include `version:` and `updatedOn:` fields at the top
- Use comments to explain non-obvious fields
- Keep workspace IDs and secrets out of committed files

### General Formatting

- Use **tables** for structured reference data (triggers, engines, thresholds)
- Use **numbered lists** for sequential procedures
- Use **code blocks** for YAML examples, CLI commands, and API payloads
- Use **relative links** when referencing other files in the repo (e.g., `[safety-guardrails.md](../fabric-devops/modules/safety-guardrails.md)`)

---

## Adding an Agent

Agents are thin dispatchers. They route requests to skills — they don't implement business logic.

### 1. Create the agent file

Create `.github/agents/<name>.agent.md` with this structure:

```md
---
name: <name>
description: <one-line purpose>
argument-hint: '<usage hint for the orchestrator>'
user-invokable: false
tools: ['<server>/<tool>', ...]
---

# <Agent Title>

## Version History

| Date | Version | Description |
| --- | --- | --- |
| YYYY-MM-DD | 1.0 | Initial version. |

## Mission

<1–2 sentences: what this agent owns and how it delegates.>

## Skill Activation Table

| Capability | Skill | Declared Triggers | Weight |
| --- | --- | --- | --- |
| <capability> | [<skill-name>](../skills/<skill-name>/SKILL.md) | <trigger keywords> | <weight> |

## Routing Protocol

<How the agent selects skills — weighted triggers, confidence thresholds, ambiguity rules.>

## Safety Guardrails (Mandatory)

<Environment protections — PROD read-only, confirmation rules, etc.>

## Execution Contract

<What the agent returns for every request — structured response format.>
```

### 2. Required frontmatter fields

| Field | Required | Description |
| :--- | :--- | :--- |
| `name` | Yes | Unique agent identifier (kebab-case) |
| `description` | Yes | One-line description shown in agent registry |
| `tools` | Yes | Array of MCP tools this agent can access (least-privilege) |
| `user-invokable` | No | Set `false` for subagents only reachable via orchestrator |
| `argument-hint` | No | Usage hint displayed to the orchestrator |
| `agents` | No | List of subagents this agent can delegate to (orchestrator only) |
| `handoffs` | No | Quick-action buttons for the orchestrator |

### 3. Register the agent

- **In the orchestrator**: Add the agent to `orchestrator.agent.md`:
  - Add to the `agents:` frontmatter list
  - Add a `handoffs:` entry
  - Add to the Agent Registry table in the body
  - Add trigger keywords to the Trigger Reference section
- **In docs**: Update `docs/2-Architecture.md` Agents table

### 4. Design rules

1. **Agents are thin dispatchers.** Heavy logic belongs in skills.
2. **Least-privilege tools.** Only list tools the agent actually needs.
3. **Agents own context; skills own procedure.** The agent resolves the *environment* and *guardrails*; the skill knows *how to execute*.
4. **Server-side default.** Agents should operate via MCP/API, not local file I/O, unless the user provides explicit local context.

---

## Adding a Skill

### Standalone Skills

For skills consumed directly by an agent (e.g., `create-task`, `daily-status-email`):

1. Create `.github/skills/<name>/SKILL.md`:

```md
---
name: '<skill-name>'
description: '<one-line description of what this skill does>'
---

# <Skill Title>

## Version History

| Date | Version | Description |
| --- | --- | --- |
| YYYY-MM-DD | 1.0 | Initial version. |

## Default Configuration

> **Configuration:** Read `config/user-context.yaml` at runtime to resolve <what>.

| Setting | Value |
| --- | --- |
| **<setting>** | Resolve from `config/user-context.yaml` → `<path>` |

## When to Use This Skill

Invoke this skill when:
- `"<example prompt 1>"`
- `"<example prompt 2>"`

## Prerequisites

| Requirement | Purpose |
| --- | --- |
| <MCP server or tool> | <Why it's needed> |

## Procedure

1. <Step 1>
2. <Step 2>
3. ...

## Guardrails

<Safety rules specific to this skill.>
```

2. Add supporting files alongside `SKILL.md` if needed (query templates, catalogs, etc.)

### Capability Skills (under a domain agent)

For skills that form part of a domain agent's capability set (e.g., `fabric-devops-validate`, `databricks-devops-security`):

1. Create `.github/skills/<domain>-<capability>/SKILL.md` with **self-declaring intent**:

```md
---
name: <domain>-<capability>
description: '<one-line description>'
---

# Skill Instructions

## Version History

| Date | Version | Description |
| --- | --- | --- |
| YYYY-MM-DD | 1.0 | Initial version. |

## Intent

| Property | Value |
| --- | --- |
| Triggers | `<keyword1>`, `<keyword2>`, ... |
| Weight | <0.0–2.0> |
| Minimum Confidence | <0.45 default, 0.60 for destructive actions> |

## Ambiguity Rules

<Optional. When this skill competes with another, which one wins and under what conditions.>

## Scope

<Bullet list of what this skill can do.>

## Engine Preference

| Order | Engine | Use Case |
| --- | --- | --- |
| Primary | `<engine-id>` | <when to use> |
| Secondary | `<engine-id>` | <when to use> |
| Guidance | `context7-guidance` | Advisory when tooling is unavailable |

## Procedure

<Numbered steps. Reference the canonical procedure module:>

Canonical procedure reference: [<module>.md](../fabric-devops/modules/<module>.md)

## Inputs

<What the skill needs from the user/agent.>

## Outputs

<What the skill returns.>

## Guardrails

<Environment protections. Always reference the shared safety policy:>

Full safety policy: [safety-guardrails.md](../fabric-devops/modules/safety-guardrails.md)
```

2. **Create the procedure module** in the parent's `modules/` directory:
   ```
   .github/skills/<domain>/modules/<capability>.md
   ```

3. **Register in shared config** (recommended but not required — skills self-declare):
   - Add a route entry to `config/intent-router.yaml`
   - Add an execution profile to `config/execution-router.yaml`
   - Add ambiguity rules if the new skill's triggers overlap with existing skills

4. **Update the parent agent's Skill Activation Table** in its `.agent.md` body.

### Self-Declaring Skill Pattern

The critical pattern: **skills declare their own triggers and weights**. The agent reads these at runtime. This means:

- Adding a new capability = creating a new `SKILL.md` + procedure module
- No changes to agent code are required for basic routing
- The `intent-router.yaml` is a reference index; skills are authoritative

Required self-declaration fields in capability skills:

| Field | Purpose | Location |
| :--- | :--- | :--- |
| `Triggers` | Keywords that activate this skill | `## Intent` table |
| `Weight` | Multiplier for scoring (default 1.0) | `## Intent` table |
| `Minimum Confidence` | Threshold to activate (default 0.45) | `## Intent` table |
| `Engine Preference` | Ordered engine list | `## Engine Preference` table |
| `Canonical Procedure` | Link to the shared procedure module | `## Procedure` section |
| `Guardrails` | Link to shared safety policy | `## Guardrails` section |

---

## Modifying Shared Config

### `config/workspace-catalog.yaml`

When adding a new workspace:

```yaml
- environment: <DEV|UAT|PROD>
  name: "<Friendly Name>"
  workspaceId: "<GUID>"
  writeAllowed: <true|false>          # MUST be false for PROD
  defaultLakehouseName: "<name>"
  defaultLakehouseId: "<GUID>"
```

- Always set `writeAllowed: false` for PROD workspaces.
- All seven capability skills consume this file — it's the single source of truth.

### `config/execution-router.yaml`

When adding a new engine or changing engine preferences:

1. Add the engine definition under `engines:` with `id`, `type`, `strengths`, and `constraints`.
2. Add or update the `executionProfiles:` entry for each intent that should use the engine.
3. Add event overrides under `eventOverrides:` if specific lifecycle events need a different engine order.
4. Update `routePolicy:` if the engine should be in the default write/read/analytics cascade.

### `config/intent-router.yaml`

When adding a new route or ambiguity rule:

1. Add a `routes:` entry with `intent`, `triggers`, `primarySkill`, `module`, `executionProfile`, and `weight`.
2. If the new skill's triggers overlap with an existing skill, add an `ambiguityRules:` entry specifying which skill wins under which prompt keywords.
3. The skill's `SKILL.md` is authoritative — keep this file in sync as a reference.

### `config/user-context.template.yaml`

When your changes introduce new config fields that users need to fill in:

1. Add the field with a `<PLACEHOLDER>` value to the template.
2. Add a comment explaining what the field is and where to find the value.
3. Update `docs/4-Setup-Guide.md` with instructions and a discovery prompt.
4. **Never** add real values to the template.

### `modules/safety-guardrails.md`

Changes to safety rules affect ALL capability skills. Treat this as a breaking change:

- Require explicit team review before merging.
- Document the rationale in the PR description.
- Update the Version History in the module file.

---

## Adding an MCP Server

1. **Add the server definition** to `.vscode/mcp.json`:

   ```json
   "<server-id>": {
     "type": "stdio|http",
     "command": "npx",                    // for stdio
     "args": ["-y", "@scope/package"],    // for stdio
     "url": "https://..."                 // for http
   }
   ```

2. **Add input prompts** if the server requires user-provided values (API keys, org names). Add to the `inputs` array:

   ```json
   {
     "id": "<input_id>",
     "type": "promptString",
     "description": "<what to enter>",
     "password": false
   }
   ```

3. **Grant tools to agents** — add the specific tool names to the target agent's `tools:` frontmatter in `.agent.md`. Only grant tools the agent needs (least-privilege).

4. **Pre-cache npm packages** (for stdio/npx servers) — add the package to the `$packages` array in `setup.ps1`.

5. **Document the server** in:
   - `docs/2-Architecture.md` → MCP Server table
   - `docs/4-Setup-Guide.md` → MCP Server Reference and Auth sections

---

## Version History Convention

Every agent and skill must maintain a version history table at the top of the document body:

```md
## Version History

| Date | Version | Description |
| --- | --- | --- |
| 2026-02-19 | 1.1 | Added <what changed>. |
| 2026-02-18 | 1.0 | Initial version. |
```

Rules:
- Dates use `YYYY-MM-DD` format.
- Versions are `major.minor` — increment major for breaking changes, minor for additions.
- Newest entry goes on top.
- One line per meaningful change (not per commit).

---

## Naming Conventions

| Component | Pattern | Examples |
| :--- | :--- | :--- |
| Agent file | `<name>.agent.md` | `fabric-devops.agent.md` |
| Agent name | kebab-case | `chief-of-staff`, `fabric-devops` |
| Skill folder | `<name>/` | `create-task/`, `fabric-devops-validate/` |
| Skill file | `SKILL.md` (always uppercase) | `SKILL.md` |
| Capability skill folder | `<domain>-<capability>/` | `fabric-devops-develop/`, `databricks-devops-security/` |
| Config files | kebab-case `.yaml` | `workspace-catalog.yaml`, `execution-router.yaml` |
| Procedure modules | kebab-case `.md` | `operate-monitor.md`, `release-promote.md` |
| Intent names | kebab-case | `operate-monitor`, `lakehouse-diagnostics` |
| Engine IDs | kebab-case | `fabric-api`, `fabric-sempy`, `context7-guidance` |

---

## Frontmatter Reference

### Agent Frontmatter (`.agent.md`)

```yaml
---
name: <kebab-case-name>                  # Required. Unique identifier.
description: <one-line description>       # Required. Shown in agent registry.
argument-hint: '<usage hint>'             # Optional. Helps orchestrator construct prompts.
user-invokable: false                     # Optional. false = subagent only (default: true).
tools: ['<server>/<tool>', ...]           # Required. Least-privilege MCP tool list.
agents: ['<subagent-name>', ...]          # Optional. Subagents this agent can delegate to.
handoffs:                                 # Optional. Quick-action buttons (orchestrator only).
  - label: <Button Label>
    agent: <target-agent>
    prompt: <structured prompt>
    send: false
---
```

### Skill Frontmatter (`SKILL.md`)

```yaml
---
name: '<skill-name>'                     # Required. Unique identifier.
description: '<one-line description>'     # Required. Used for skill discovery.
---
```

Capability skills additionally declare intent in the body (not frontmatter):

```md
## Intent

| Property | Value |
| --- | --- |
| Triggers | `keyword1`, `keyword2`, ... |
| Weight | 1.0 |
| Minimum Confidence | 0.45 |
```

---

## Safety & Guardrails

### Non-Negotiable Rules

1. **PROD workspaces are read-only.** `writeAllowed: false` in workspace-catalog.yaml. No exceptions without explicit team approval.
2. **Never commit secrets.** API keys, tokens, and personal config go in gitignored files only.
3. **Never commit personal user-context.yaml.** Only the `.template.yaml` is committed.
4. **Capability skills must reference shared safety-guardrails.md.** Do not create per-skill safety rules that contradict the shared policy.
5. **Destructive skill intents require higher confidence.** Set `Minimum Confidence: 0.60` for skills that write, delete, or deploy.

### When Modifying Guardrails

- Changes to `modules/safety-guardrails.md` affect all capability skills and require review.
- Changes to `workspace-catalog.yaml` that set `writeAllowed: true` on a PROD workspace are **prohibited**.
- New agents must declare least-privilege `tools:` lists — do not grant blanket access.

---

## Testing Your Changes

There are no automated tests — all testing is done interactively in VS Code Copilot Chat.

### Before submitting a PR:

1. **Open the workspace** in VS Code with the MCP servers active.
2. **Test routing** — use prompts that should trigger your new skill/agent and verify the correct one activates:
   ```
   @orchestrator <prompt with your skill's trigger keywords>
   ```
3. **Test edge cases** — use prompts that could match multiple skills and verify ambiguity rules resolve correctly.
4. **Test safety** — if your skill writes data, test with a PROD environment reference and confirm it blocks:
   ```
   @fabric-devops Create a notebook in PROD
   ```
   This should be refused.
5. **Test the full chain** — if your skill is invoked via the orchestrator, test the end-to-end flow (orchestrator → agent → skill → MCP tool → response).

### Verification prompts by component type:

| Added/Changed | Test Prompt |
| :--- | :--- |
| New capability skill | `@<domain-agent> <prompt matching new triggers>` |
| New standalone skill | `@<agent-with-skill> <prompt matching skill description>` |
| New agent | `@orchestrator <prompt that should route to new agent>` |
| Updated triggers/weights | Test prompts for old and new trigger keywords |
| Updated engine preference | Run a skill and verify the expected engine is selected |
| New MCP server | `@<agent> <prompt that requires the new server's tools>` |
| Updated workspace catalog | `@fabric-devops List items in <new-environment>` |
| Updated safety rules | Attempt a write in PROD — it should be blocked |

---

## Evaluation Framework

The repo includes an evaluation framework for testing agent routing, skill activation, and interaction quality. All evaluation files live in `.github/evaluations/`.

### Structure

| File | Purpose |
| :--- | :--- |
| `EVAL-FRAMEWORK.md` | Scoring dimensions, weights, and pass thresholds |
| `baseline.yaml` | Baseline scores from dry-run classification runs |
| `eval-manifest.yaml` | Test scenario definitions (54 scenarios across 12 categories) |

### Scoring Dimensions (v2)

| Dimension | Weight |
| :--- | :--- |
| Routing Accuracy | 22% |
| Skill Activation | 18% |
| Prompt Quality | 15% |
| Execution Success | 10% |
| Guardrail Enforcement | 10% |
| Context Verification | 10% |
| Write Gate | 10% |
| Interaction Quality | 5% |

### Running Evaluations

```
@orchestrator Run the evaluation suite
```

Or run a specific category:
```
@orchestrator Run the routing accuracy evaluations
```

### Adding New Test Scenarios

1. Add a scenario entry to `eval-manifest.yaml` with `id`, `category`, `prompt`, `expectedBehavior`, `difficulty`, and `criteria`.
2. Run the eval suite to generate a baseline score for the new scenario.
3. Update `baseline.yaml` with the new scenario's score (or mark as `score: null` for pending baselining).

### When to Update Evaluations

| Change | Update |
| :--- | :--- |
| New orchestrator routing behavior | Add test scenarios to `eval-manifest.yaml`, rebaseline |
| New agent or skill | Add routing + skill activation scenarios |
| Modified safety rules | Add guardrail enforcement scenarios |
| Changed scoring weights | Update `EVAL-FRAMEWORK.md` and `eval-manifest.yaml` thresholds |

---

## Documentation

### When to update docs

| Change | Update |
| :--- | :--- |
| New agent | `README.md` (Agents table), `docs/2-Architecture.md` (Agents section + diagram), evaluation manifest |
| New skill | `README.md` (Skills table), `docs/2-Architecture.md` (Skills section), evaluation manifest |
| New MCP server | `docs/2-Architecture.md` (MCP Servers table), `docs/4-Setup-Guide.md` (MCP reference + auth) |
| New config field | `config/user-context.template.yaml`, `docs/4-Setup-Guide.md` (Personal Config section) |
| New capability skill | Parent agent's Skill Activation Table, `docs/2-Architecture.md`, agent-specific docs under `docs/agents/` |
| Architecture change | `docs/2-Architecture.md`, relevant `docs/agents/` files |

### Doc structure

- `docs/` contains numbered files for progressive reading (1-Why, 2-Architecture, 3-Use-Cases, 4-Setup)
- `docs/agents/<short-name>/` contains deep-dive architecture docs for complex agents
- Keep docs tightly coupled to the actual config/code — don't let them drift

---

## Common Mistakes

| Mistake | Fix |
| :--- | :--- |
| Committing `config/user-context.yaml` | It's gitignored. If you see it staged, remove: `git rm --cached config/user-context.yaml` |
| Agent does too much work directly | Move logic into a skill. Agents dispatch; skills execute. |
| Skill doesn't self-declare triggers | All capability skills must have the `## Intent` section with Triggers, Weight, and Minimum Confidence. |
| Granting all tools to an agent | Only list tools the agent actually uses in its `tools:` frontmatter. Least-privilege. |
| PROD workspace with `writeAllowed: true` | PROD must always be `writeAllowed: false`. |
| Adding a skill without a procedure module | Capability skills need a corresponding module in `<domain>/modules/<name>.md`. |
| Not updating the orchestrator | New agents must be registered in `orchestrator.agent.md` (frontmatter + body). |
| Ambiguity between skills with overlapping triggers | Add an `ambiguityRules:` entry to `intent-router.yaml` and declare `## Ambiguity Rules` in the skill. |
| Creating per-skill safety rules that contradict shared policy | Reference `modules/safety-guardrails.md` — don't create independent PROD write permissions. |
| No version history entry | Every change to an agent or skill must add a row to the Version History table. |
| Not updating evaluation manifest | New agents/skills need corresponding test scenarios in `eval-manifest.yaml`. |
| Skipping rebaseline after orchestrator changes | After modifying routing, scoring, or interaction behaviors, run the eval suite and update `baseline.yaml`. |
