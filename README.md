# Source Gold ↔ Silver Validation Tool

A GitHub Copilot **skill + agent** that validates Microsoft Fabric / Azure data sources by comparing
**latest Gold vs Silver** (or **latest Gold vs previous Gold**) directly from a Fabric notebook's SQL.
It runs the queries, computes **percentage differences**, and produces an **Excel report** — one row per
`FiscalMonthID`, percentage differences only.

Supported sources: **POSOT_Azure**, **PPR Warehouse**, **POSOT_Integration**, and **POSOT_Sales**
(including staged Silver → Gold validation through intermediate tables).

---

## What you get

| Component | Path |
|-----------|------|
| Validation skill | [.github/skills/azure-source-notebook-compare/](.github/skills/azure-source-notebook-compare/SKILL.md) |
| Fabric DevOps agent | [.github/agents/fabric-devops.agent.md](.github/agents/fabric-devops.agent.md) |
| WorkFast entrypoint agent | [.github/agents/WorkFast.agent.md](.github/agents/WorkFast.agent.md) |
| Run scripts (SQL + Excel) | [scripts/](scripts/) |

---

## Prerequisites (one-time per machine)

1. **VS Code** with these extensions:
   - GitHub Copilot (`GitHub.copilot`)
   - GitHub Copilot Chat (`GitHub.copilot-chat`)
   - SQL Server (`ms-mssql.mssql`)
2. **Git** — https://git-scm.com/download/win
3. **Node.js (LTS)** — https://nodejs.org (needed for the MCP servers)
4. **Azure CLI** — https://learn.microsoft.com/cli/azure/install-azure-cli
   (used to authenticate to Fabric SQL endpoints)
5. **PowerShell 5.1+** (built into Windows). The scripts auto-install the
   `ImportExcel` module on first run.
6. **Access** to the Fabric workspaces / SQL endpoints in the Microsoft tenant
   (your normal corporate AAD login).

---

## Setup (each team member)

```powershell
# 1. Clone the repo
git clone https://github.com/v-shharsh12345/ghc-copilot.git
cd ghc-copilot

# 2. Set your own git identity
git config user.name  "<your-alias>"
git config user.email "<your-alias>@microsoft.com"

# 3. Run the setup script (checks tools, pre-caches MCP servers)
.\setup.ps1

# 4. Sign in to Azure (needed for Fabric SQL auth)
az login

# 5. Open in VS Code
code .
```

> If `git` is not recognized right after installing it, close and reopen the terminal,
> or reload PATH:
> ```powershell
> $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
> ```

---

## How to run a validation

In VS Code Copilot Chat, invoke the agent and describe what you want:

```
@WorkFast Run latest Sales Gold vs Silver validation from the notebook and give me the Excel with percentage differences only.
```

Other examples:

```
@WorkFast Compare latest Gold vs previous Gold for POSOT_Azure and export the percentage differences.
@WorkFast Run the staged Sales Silver → Gold validation through the intermediate tables.
```

The skill will:
1. Read the SQL from the referenced Fabric notebook.
2. Authenticate via Azure CLI and run the queries against the source endpoints.
3. Compute `%Diff = (Upstream − Downstream) / Downstream`, formatted `0.00%`.
4. Write a CSV + an Excel report (wide format, one row per `FiscalMonthID`).

Non-zero differences are highlighted; zero/empty denominators are handled gracefully.

---

## Output

- Excel reports are written to the repo root and your Desktop (e.g. `Sales_Gold_vs_Silver_Staged_Validation.xlsx`).
- Generated `.xlsx` / `.csv` data files are git-ignored, so they are **not** pushed to the shared repo.

---

## Contributing

1. Create a feature branch from `main`
2. Make changes to the skill or scripts
3. Test in VS Code Copilot Chat
4. Open a pull request
