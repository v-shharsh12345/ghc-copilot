# Setup Guide

> **End-to-end setup time: ~15 minutes** (assuming GitHub Copilot is already installed and you have your credentials ready).

| Phase | What you do | Time |
|---|---|---|
| **1. Prerequisites** | Install Node.js + Azure CLI (if missing) | 5 min |
| **2. Clone & run setup** | One-time script | 2 min |
| **3. Authenticate** | `az login` + approve MCP consent prompts | 3 min |
| **4. Personal config** | Fill in `user-context.yaml` + workspace IDs | 5 min |
| **5. Verify** | Send a test prompt | < 1 min |

---

## 1. Prerequisites

You need three things installed locally. GitHub Copilot + Chat are assumed to be present already.

| Requirement | Purpose | One-liner install |
|---|---|---|
| **Node.js 18+** | Runs npm-based MCP servers | [nodejs.org](https://nodejs.org) (LTS) |
| **Azure CLI** | Auth for Fabric, Power BI, and ADO APIs | [Install Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) |
| **SQL Server extension** | MSSQL tools for Fabric DevOps | `code --install-extension ms-mssql.mssql` |

> Already have these? Skip straight to **Clone & Setup**.

---

## 2. Clone & Setup

```powershell
git clone <repo-url> copilot-agents
cd copilot-agents
.\setup.ps1          # validates prereqs, caches MCP packages, creates config file
code .               # open in VS Code
```

The script:
- Verifies Node.js, npm, and Azure CLI
- Checks that required VS Code extensions are present
- Pre-caches all npm MCP server packages (Azure DevOps, Playwright, WorkIQ, Context7)
- Creates `config/user-context.yaml` from the template if it doesn't exist
- Validates `.vscode/mcp.json`

---

## 3. Authenticate — MCP Servers

Every MCP server in this repo authenticates through one of two mechanisms. You do **not** need separate API keys or service principals for most servers — your existing Microsoft identity covers them.

### 3a. Azure CLI login (covers most servers)

```powershell
az login            # browser-based sign-in with your @microsoft.com account
az account show     # confirm the right tenant/subscription is active
```

This single login provides tokens for:

| Server | Auth mechanism | What `az login` covers |
|---|---|---|
| **Power BI Remote** | Azure AD token via Azure CLI | Fabric REST API / DAX queries |
| **Mail / Calendar / Teams / Word / M365 Copilot** | Microsoft Entra (OAuth) | M365 data — consent prompt on first use |
| **Azure DevOps** | Azure AD (PAT fallback) | Work items, repos, pipelines, wiki |
| **Microsoft Docs** | Public (no auth) | No login needed |
| **nl2dab** (custom) | Public / Azure Container Apps | No login needed (team-internal endpoint) |

### 3b. First-use consent prompts

When VS Code first activates an MCP server, it will prompt for configuration values. Have these ready:

| Prompt | Where to find it | Example value |
|---|---|---|
| **Azure DevOps org** | Your ADO URL slug | `msit` (from `msit.visualstudio.com`) |
| **ADO domains** | Comma-separated list of API domains | `core, work, work-items, repositories, pipelines, wiki, search, test-plans, advanced-security` |
| **Team name** | ADO → Project Settings → Teams | `Data and Reporting POD` |
| **Power Platform Environment ID** | [Power Platform Admin Center](https://admin.powerplatform.microsoft.com) → Environments → your env → Details | `64ccd25c-fa91-e1d7-...` |
| **Context7 API key** | [upstash.com/context7](https://upstash.com) → Dashboard → API Keys | `ctx7_...` |

> **Tip:** These values are stored in VS Code's input memory — you only enter them once per workspace.

### 3c. Auth troubleshooting

| Problem | Fix |
|---|---|
| MCP server fails with 401/403 | Run `az login` again — token may have expired |
| M365 tools (Mail/Calendar/Teams) return empty | Approve the OAuth consent popup that VS Code shows on first connect |
| ADO MCP won't start | Confirm your org name matches exactly (e.g., `msit` not `msit.visualstudio.com`) |
| Power BI Remote returns "Unauthorized" | Ensure `az account show` points to the correct tenant; run `az login --tenant <tenant-id>` if needed |

---

## 4. Personal Config — What to Fill In and Why

The config files below tell agents *who you are*, *what you work on*, and *where your resources live*. The more complete your config, the less you need to type in every prompt.

> **Speed tip:** You don't need to look up most values manually. Use the Copilot Chat discovery prompts below to auto-populate each section via MCP tools.

### Step 1: Personal Context (`config/user-context.yaml`)

This is the **single most important file** — agents read it on every invocation. Copy from the template and fill in your values:

```yaml
# ── Identity (required) ──────────────────────────────────
user:
  displayName: "Jane Doe"              # Your name as it appears in emails/ADO
  email: "janedoe@microsoft.com"       # Used for status emails and lookups

# ── Status Email (optional but recommended) ──────────────
statusEmail:
  recipient: "manager@microsoft.com"   # Who gets your daily status email
  subjectPrefix: "Jane Doe"            # Prefix in subject line
  autoSend: true                       # true = send without confirmation
  sections:                            # Group bullets by workstream
    - name: "Data Engineering POD"
      bulletCount: 6
      topics: ["pipeline optimization", "schema migration", "Fabric notebooks"]
    - name: "Analytics POD"
      bulletCount: 6
      topics: ["report validation", "semantic model testing"]

# ── Azure DevOps (required for task/story agents) ─────────
ado:
  organization: "msit.visualstudio.com"          # Your ADO org
  projects:
    taskCreation:
      name: "MyProject-DevOps"                   # Project where tasks are created
      defaultAreaPath: "MyProject-DevOps\\MyTeam" # Backslash-escaped area path
    userStories:
      name: "OneMW"                               # Project where user stories live
      defaultAreaPath: "OneMW\\MyOrg\\MyTeam"
  team: "My Team Name"
  defaultParentWorkItemId: null                   # Optional: default parent work item

# ── Team Members (helps agents assign/mention) ────────────
team:
  members: ["Alice", "Bob", "Carol"]

# ── Business Domain (makes prompts context-aware) ─────────
domain:
  shortName: "Analytics"                          # Short label for your domain
  exampleEntities:
    factTables: ["FactOrders", "FactRevenue"]
    dimTables: ["DimCustomer", "DimProduct"]
    reports: ["Sales Dashboard", "Executive Summary"]
    pipelines: ["Master_Refresh", "Daily_ETL"]
    lakehouses: ["MainLakehouse", "StagingLakehouse"]
    semanticModels: ["SalesModel", "FinanceModel"]

# ── Infrastructure (required for M365 tools) ──────────────
infrastructure:
  powerPlatformEnvironmentId: "<GUID>"            # From Power Platform Admin Center
```

**Why each section matters:**

| Section | What agents use it for |
|---|---|
| `user` | Identifies you in emails, ADO assignments, and lookups |
| `statusEmail` | Auto-generates daily status emails grouped by your workstreams |
| `ado` | Creates tasks and user stories in the right project/area without you specifying each time |
| `team` | Enables "@mention Alice" style references when creating tasks |
| `domain` | Agents autocomplete table names, report names, and pipelines from your domain context |
| `infrastructure` | Routes M365 MCP calls to your Power Platform environment |

---

### Discovery Prompts — Let Copilot Fill In Your Config

Instead of hunting through portals for GUIDs and names, paste these prompts into Copilot Chat. Each one uses MCP tools to discover the exact values you need, then tells you where to paste them.

#### 1. Discover your identity and timezone

```
Get my user profile and timezone settings from Calendar, then show me the YAML
I should paste into the `user:` section of config/user-context.yaml.
```

> **MCP tools used:** `GetUserDateAndTimeZoneSettings` (Calendar)

#### 2. Discover your ADO projects, teams, and area paths

```
List all Azure DevOps projects I have access to. For each project, list the teams
I'm a member of (use mine=true). Then for the project I use for task creation,
show the current sprint iteration. Format the output as the `ado:` YAML block
I should paste into config/user-context.yaml.
```

> **MCP tools used:** `list_projects`, `list_project_teams(mine=true)`, `list_team_iterations(timeframe=current)` (Azure DevOps)

If you already know your project name, use this faster variant:

```
List the teams I belong to in the "<YOUR_PROJECT>" ADO project (mine=true only),
and show the current sprint. Give me the ado: YAML block for user-context.yaml.
```

#### 3. Discover your team members from recent work items

```
Get the last 20 work items assigned to me in the "<YOUR_PROJECT>" ADO project,
plus the last 20 from my activity feed. Extract the unique set of people
(assignees, creators, changed-by) and format them as the `team.members:` YAML list
for config/user-context.yaml.
```

> **MCP tools used:** `my_work_items(type=assignedtome)`, `my_work_items(type=myactivity)` (Azure DevOps)

#### 4. Discover Fabric workspaces and lakehouses

```
Search Power BI for all semantic models that match my team's domain (e.g., "Incentive"
or "Investments"). For each result, note the workspace name and artifact ID.
Then format the results as workspace-catalog.yaml entries with environment, name,
and workspaceId fields. Mark PROD workspaces as writeAllowed: false.
```

> **MCP tools used:** `DiscoverArtifacts(artifactTypes=["SemanticModel"])` (Power BI Remote)

#### 5. Discover semantic model dataset IDs and schema

```
Search Power BI for semantic models matching "<YOUR_DOMAIN>" (e.g., "Azure Investments").
For each model found, get its schema and extract the key fact tables, dimension tables,
and measures. Format the output as:
1. A dataset-catalog.yaml entry with datasetId, summary, keyTables, and keyMeasures
2. The domain.exampleEntities YAML block for user-context.yaml
```

> **MCP tools used:** `DiscoverArtifacts`, `GetSemanticModelSchema` (Power BI Remote)

#### 6. Discover your reports

```
Search Power BI for reports matching "<YOUR_DOMAIN>". List each report name and
artifact ID. Format as a YAML list I can paste into domain.exampleEntities.reports
in config/user-context.yaml.
```

> **MCP tools used:** `DiscoverArtifacts(artifactTypes=["Report"])` (Power BI Remote)

#### 7. Discover your recurring meetings and workstreams (for statusEmail sections)

```
List my calendar events for the past 2 weeks. Identify recurring meetings that
look like standups, syncs, or POD meetings. Group them by workstream/topic and
suggest a statusEmail.sections YAML block for config/user-context.yaml with
section names and topic keywords.
```

> **MCP tools used:** `ListCalendarView` (Calendar)

---

### Step 2: Fabric Workspace Catalog

Edit `.github/skills/fabric-devops/config/workspace-catalog.yaml`:

```yaml
workspaces:
  - environment: DEV
    name: "My Team [DEV]"
    workspaceId: "<GUID>"              # Fabric portal → Workspace → Settings → Workspace ID
    writeAllowed: true
    defaultLakehouseName: "MyLakehouse"
    defaultLakehouseId: "<GUID>"       # Fabric portal → Lakehouse → Settings

  - environment: UAT
    name: "My Team [UAT]"
    workspaceId: "<GUID>"
    writeAllowed: true

  - environment: PROD
    name: "My Team [PROD]"
    workspaceId: "<GUID>"
    writeAllowed: false                 # Safety: blocks accidental writes to PROD
```

> **Manual fallback:** Open [app.fabric.microsoft.com](https://app.fabric.microsoft.com) → select the workspace → Settings (gear icon) → copy the Workspace ID.
>
> **Or use this prompt** to discover workspace IDs via Copilot Chat:
> ```
> Search Power BI for semantic models in my workspaces. List each unique workspace
> name and ID. Format them as workspace-catalog.yaml entries, grouping by DEV/UAT/PROD
> based on the workspace name.
> ```

### Step 3: Semantic Model Dataset IDs

Edit `.github/skills/compare-semantic-models/dataset-catalog.yaml` with your dataset GUIDs per environment:

```yaml
datasets:
  MyModel:
    summary: "Description of what this model contains"
    keyTables: [FactOrders, DimCustomer]
    keyMeasures: [Total Revenue, Active Customers]
    environments:
      DEV:
        datasetId: "<GUID>"
      UAT:
        datasetId: "<GUID>"
      PROD:
        datasetId: "<GUID>"
```

> **Manual fallback:** Open [app.powerbi.com](https://app.powerbi.com) → navigate to the dataset → the GUID is in the URL: `datasets/<GUID>/details`.
>
> **Or use this prompt** to discover all dataset IDs at once:
> ```
> Search Power BI for all semantic models matching "<YOUR_DOMAIN>". For each model,
> get its artifact ID (this is the datasetId) and the workspace it belongs to.
> Format the output as a complete dataset-catalog.yaml file, grouping each model's
> environments by the workspace name (DEV/UAT/PROD). Include the schema summary
> by calling GetSemanticModelSchema on each.
> ```

### Step 4 (Optional): Databricks Workspace Catalog

If you use Databricks, edit `.github/skills/databricks-devops/config/workspace-catalog.yaml`:

```yaml
workspaces:
  - environment: DEV
    host: "https://adb-XXXXX.XX.azuredatabricks.net"
    profile: "dev-profile"             # Databricks CLI profile name
    writeAllowed: true
    defaultCatalog: "dev_catalog"
```

Authenticate each profile once:
```powershell
databricks auth login --host https://adb-XXXXX.XX.azuredatabricks.net --profile dev-profile
```

---

## 5. Verify Setup

Test each agent layer with a quick prompt in Copilot Chat:

| Prompt | What it validates |
|---|---|
| `@orchestrator Daily triage` | M365 tools + ADO + status email config |
| `@orchestrator What's the health of my DEV workspace?` | Fabric MCP + workspace catalog |
| `@chief-of-staff Create a task for testing the setup` | ADO MCP + task creation config |
| `@fabric-devops List items in DEV` | Fabric REST API auth + workspace ID |

If any prompt fails, check the **Auth troubleshooting** table in Section 3.

---

## Repository Structure

```
copilot-agents/
├── README.md                          ← Landing page
├── setup.ps1                          ← Setup script
├── config/
│   └── user-context.yaml              ← Your personal config (gitignored)
├── docs/                              ← Documentation
│   ├── 1-Why.md
│   ├── 2-Architecture.md
│   ├── 3-Use-Cases-and-ROI.md
│   └── 4-Setup-Guide.md              ← You are here
├── .vscode/
│   └── mcp.json                       ← MCP server config (auto-discovered)
└── .github/
    ├── agents/                        ← Agent definitions
    │   ├── orchestrator.agent.md
    │   ├── chief-of-staff.agent.md
    │   ├── fabric-devops.agent.md
    │   └── databricks-devops.agent.md
    └── skills/                        ← Skill definitions + config
        ├── create-task/
        ├── daily-status-email/
        ├── update-user-story/
        ├── compare-semantic-models/
        ├── fabric-devops/             ← Shared resource layer
        ├── fabric-devops-*/           ← Capability skills
        └── databricks-devops-*/       ← Capability skills
```

## MCP Server Reference

| Server | Type | Auth | Used By |
|---|---|---|---|
| **Azure DevOps** | stdio (npx) | Azure AD via `az login` | Chief of Staff, Create Task |
| **Playwright** | stdio (npx) | None (local browser) | Browser automation |
| **WorkIQ** | stdio (npx) | Microsoft Entra (OAuth popup) | Chief of Staff (M365 signals) |
| **Context7** | stdio (npx) | API key (prompted once) | Fabric DevOps (library docs) |
| **Mail / Calendar / Teams / Word** | HTTP | Microsoft Entra (OAuth consent) | Chief of Staff, Create Task |
| **M365 Copilot** | HTTP | Microsoft Entra (OAuth consent) | Chief of Staff |
| **Power BI Remote** | HTTP | Azure AD via `az login` | Semantic model queries |
| **Microsoft Docs** | HTTP | Public (none) | Fabric DevOps |

> **HTTP-based servers** require no local install — they connect directly to cloud endpoints.
> **stdio (npx) servers** are downloaded automatically on first use; `setup.ps1` pre-caches them.

## Adding New Components

| Want To... | Do This |
|---|---|
| Add a new agent | Create `.github/agents/<name>.agent.md` |
| Add a new skill | Create `.github/skills/<name>/SKILL.md` |
| Add a new MCP server | Add entry to `.vscode/mcp.json` |
| Add a workspace | Edit `skills/fabric-devops/config/workspace-catalog.yaml` |

## Contributing

1. Create a feature branch from `main`
2. Add or update agents/skills following existing patterns
3. Test in VS Code Copilot Chat
4. Submit a PR
