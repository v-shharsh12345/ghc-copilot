# Demo Guide — Source Gold/Silver Data Validation Tool

> One-page companion for the team demo. Read top-to-bottom; the **Live Demo Script** is the part you run on screen.

---

## 1. The 30-second pitch

This is an **AI-assisted data reconciliation tool**. It takes a Fabric/Power BI **notebook query**, runs the **same logic across two data sources** (e.g. PPR Warehouse vs Azure, Gold vs Silver), and produces a **percentage-difference Excel** that highlights mismatches in red. What used to be manual cross-system checking is now a repeatable, version-controlled script the agent drives.

**Business value:** find where ACR / revenue numbers diverge between systems in seconds, with an auditable trail.

---

## 2. What powers it (concepts in plain words)

| Term | What it means here |
|---|---|
| **Agent** | The AI worker in VS Code. The `WorkFast` agent orchestrates; it can delegate to the `fabric-devops` subagent. |
| **Skill** | A Markdown playbook the agent loads on demand. Our core one is `azure-source-notebook-compare` — it defines every comparison mode and the table mappings. |
| **`.md` file** | Markdown — human- and machine-readable text. All our rules/skills/docs are `.md` so they're reviewable in a PR. |
| **MCP server** | Model Context Protocol — a standard way to give the agent tools (DevOps, Power BI, M365, browser). 11 configured in `.vscode/mcp.json`. |
| **Memory** | Persistent notes so the agent remembers conventions (CSP normalization, table mappings) across sessions. |

---

## 3. Repo at a glance

| Area | Purpose |
|---|---|
| `.github/agents/` | Agent definitions — `WorkFast` (orchestrator), `fabric-devops` (subagent). |
| `.github/skills/` | The playbooks — `azure-source-notebook-compare` is the core validation skill. |
| `.vscode/mcp.json` | The 11 MCP server connections. |
| `config/user-context.yaml` | Single source of truth: identity, ADO project, team, Fabric workspace/lakehouse IDs (gitignored). |
| `memory/` | Long-term + session memory store. |
| `scripts/` | PowerShell validation runners + their CSV/Excel outputs. |
| Root `*.xlsx` | The deliverables — one workbook per validation type. |

**Star scripts to mention:**
- `scripts/ppr-vs-azure-validate.ps1` — PPR vs Azure, same-query cross-source.
- `scripts/ppr-vs-sales-validate.ps1` — PPR vs Sales.
- `scripts/azure-gold-vs-silver-validate.ps1` — Gold vs Silver.
- `scripts/azure-latest-vs-previous-gold-validate.ps1` — latest Gold vs previous Gold.

---

## 4. How it works (the validation flow)

1. **Fetch the live notebook** from Fabric API and decode its SQL (never hardcoded).
2. **Run the exact query on side A** (e.g. PPR Warehouse `Gold`).
3. **Run the identical query on side B** — only the database/schema names change.
4. **Source the time dimension** (`DimIntegrationTime`) from `POSOT_Integration`, joined in-memory.
5. **Apply standing rules automatically:** normalize `CSP Tier 1`→`CSP Tier1`, exclude TPOR-DIR/IND/SOA.
6. **Compute `%Diff`** per shared grain and write a timestamped Excel to `Downloads` (mismatches bold-red).

---

## 5. Authentication (one line each)

- **Fabric SQL:** `az account get-access-token` mints a short-lived Entra token → attached to an encrypted SQL connection. **No stored passwords.** Runs as the signed-in user.
- **MCP (M365/Agent 365):** OAuth2 identity passthrough — acts as you, no secrets.
- **Everything is least-privilege + short-lived.**

---

## 6. Live Demo Script (run this on screen)

**Setup (do before the call):** `az login` once; have VS Code open on the repo.

1. **Show the skill** — open `.github/skills/azure-source-notebook-compare/SKILL.md`. Point at the PPR↔Azure mapping table and the "always applied" normalization rule. *"This is the playbook the agent follows."*

2. **Show the config** — open `config/user-context.yaml`. *"Personal + Fabric resource IDs live here, gitignored — nothing secret in the repo."*

3. **Run a validation** — in the terminal:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "scripts\ppr-vs-azure-validate.ps1"
   ```
   Narrate as it runs: resolves latest Gold snapshot → runs identical query both sides → writes Excel.

4. **Open the Excel** from `Downloads` (`PPRWarehouse_vs_Azure_Validation_*.xlsx`). Show the two sheets (By FiscalMonth, By AssociationType) and the red `%Diff` cells.

5. **Tell the reconciliation story** (the impressive part):
   *"First pass showed ~−54%. We traced it to two things: the wrong Azure tables, and the script auto-picking the newest Gold snapshot — which was mid-refresh and double-counted ~2×. We added a guard that rejects an anomalous snapshot and falls back to the aligned one. Now closed months reconcile to ~−4% to −8%."*

---

## 7. Anticipated Q&A

**Q: What's a skill vs an agent vs MCP?**
Skill = on-demand Markdown playbook. Agent = the AI worker. MCP = tool connections to external systems.

**Q: Which MCP servers?**
11 total — Azure DevOps, Playwright, WorkIQ, Context7 (local npx) + Mail/Calendar/Teams/Word/M365Copilot, Power BI remote, MS Learn docs (HTTP). The SQL validations themselves use direct `az` token access, not MCP.

**Q: Why isn't the diff exactly 0%?**
PPR↔Sales is the same fact copied across → ~0%. PPR↔Azure compares a *derived reporting* fact against an aligned Gold snapshot → small steady gap expected; in-progress month is wider (partial data).

**Q: Earlier it was −54%, now −5%. What changed?**
Wrong table mapping + an anomalous latest Gold snapshot inflating ~2×. Fixed with correct PPR-equivalent tables and an anomaly guard.

**Q: Is it secure / where are the credentials?**
No stored credentials. Short-lived Entra tokens + OAuth identity passthrough; everything runs as the signed-in user.

**Q: Can someone reproduce a result?**
Yes — every run is a committed script with a clear commit message. Clone, `az login`, run the `.ps1`.

**Q: How does it remember rules like CSP normalization?**
Persistent memory + the SKILL.md defaults — applied every run automatically, never re-asked.

---

## 8. If something goes wrong live (fallback)

- **Token expired** → `az login`, re-run.
- **OneDrive lock on Excel** → output already goes to local `Downloads` to avoid this.
- **Script fails mid-run** → show the previously generated Excel in `Downloads` instead; the CSVs in `scripts/` also hold the last results.
