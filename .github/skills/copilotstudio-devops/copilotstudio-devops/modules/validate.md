# Validate — Procedure Module

## Overview

Cross-environment validation of Copilot Studio agents. Compare topic coverage, knowledge sources, actions, and configuration between DEV/UAT/PROD.

**Primary method: PAC CLI template extraction + diff** (proven working — extracts full YAML with all components).

---

## URL Parsing

Users typically provide Copilot Studio URLs:
```
https://copilotstudio.preview.microsoft.com/environments/{ENV_ID}/bots/{BOT_ID}/overview
```
Extract `ENV_ID` and `BOT_ID` from each URL. GUIDs can be used directly with PAC CLI flags.

---

## Path 1: PAC CLI Template Extraction + Diff (Primary — PROVEN)

This is the most reliable method. Extracts the full agent definition as YAML, then diffs.

> **Known Limitation:** `pac copilot extract-template` may fail on **Managed** copilots (PROD) due to a PAC CLI bug with `--templateVersion` parsing on empty string. When this happens, fall back to **Path 2** (Solution Export + Diff) for the PROD side, or compare component counts via `pac copilot list` which always works for both Managed and Unmanaged agents.

### Step 1: Extract Template from Source Environment

```bash
pac copilot extract-template \
  --environment <SOURCE_ENV_ID> \
  --bot <SOURCE_BOT_ID> \
  --templateFileName ./temp/agent-source.yaml \
  --overwrite
```

### Step 2: Extract Template from Target Environment

```bash
pac copilot extract-template \
  --environment <TARGET_ENV_ID> \
  --bot <TARGET_BOT_ID> \
  --templateFileName ./temp/agent-target.yaml \
  --overwrite
```

### Step 3: Compare Templates

Parse both YAML files and compare:

```powershell
# Quick line-level diff
$source = Get-Content ./temp/agent-source.yaml
$target = Get-Content ./temp/agent-target.yaml
Compare-Object $source $target | Format-Table -AutoSize
```

For structured comparison, parse the YAML and compare:

1. **Top-level config**: `accessControlPolicy`, `authenticationMode`, `GenerativeActionsEnabled`
2. **Component list**: Count of topics, count matching by `displayName`
3. **Per-topic diff**: Compare `dialog.beginDialog.actions` for logic changes
4. **Flow references**: Compare Power Automate flow IDs
5. **Knowledge sources**: Compare knowledge configurations

### Step 4: Also Compare Solution Versions

```bash
# List solutions in both environments
pac solution list --environment <SOURCE_ENV_ID>
pac solution list --environment <TARGET_ENV_ID>
# Compare solution versions (e.g., IncentraX v1.0.0.19 in both = MATCH)
```

### Step 5: Compare Agent Lists

```bash
# List copilots in both environments
pac copilot list --environment <SOURCE_ENV_ID>
pac copilot list --environment <TARGET_ENV_ID>
# Compare: agent count, names, status, managed vs unmanaged
```

```
## Validation Report — {Agent Name} ({Source} vs {Target})

### Topic Coverage
| Topic | {Source} | {Target} | Status |
|-------|----------|----------|--------|
| Greeting | ✅ Present | ✅ Present | ✅ MATCH |
| Leave Request | ✅ Present | ❌ Missing | ❌ DRIFT |
| IT Password Reset | ✅ Present | ✅ Present | ⚠️ MODIFIED |

### Knowledge Sources
| Source | {Source} | {Target} | Status |
|--------|----------|----------|--------|
| HR Policies PDF | ✅ | ✅ | ✅ MATCH |
| Benefits FAQ | ✅ | ❌ | ❌ DRIFT |

### Actions
| Action | {Source} | {Target} | Status |
|--------|----------|----------|--------|
| Submit Leave | ✅ | ✅ | ✅ MATCH |

### Summary
- Topics: 2/3 match (1 missing in PROD)
- Knowledge: 1/2 match (1 missing in PROD)
- Actions: 1/1 match

**Verdict: FAIL** — Critical drift detected (missing topic + knowledge source)
```

---

## Path 2: Solution Export + Diff (Secondary)

### Step 1: Export Solutions from Both Environments

```bash
# Authenticate to DEV
pac auth create --environment <DEV_URL> --name dev-profile

# Export DEV solution
pac solution export --name <SolutionName> --path ./exports/dev-solution.zip

# Authenticate to PROD
pac auth create --environment <PROD_URL> --name prod-profile

# Export PROD solution
pac solution export --name <SolutionName> --path ./exports/prod-solution.zip
```

### Step 2: Unpack Solutions

```bash
pac solution unpack --zipfile ./exports/dev-solution.zip --folder ./unpacked/dev
pac solution unpack --zipfile ./exports/prod-solution.zip --folder ./unpacked/prod
```

### Step 3: Diff Unpacked Contents

```powershell
# PowerShell diff of unpacked solution directories
$devFiles = Get-ChildItem -Recurse ./unpacked/dev -File | ForEach-Object { $_.FullName -replace '.*\\dev\\', '' }
$prodFiles = Get-ChildItem -Recurse ./unpacked/prod -File | ForEach-Object { $_.FullName -replace '.*\\prod\\', '' }

# Files only in DEV
$devOnly = $devFiles | Where-Object { $_ -notin $prodFiles }

# Files only in PROD
$prodOnly = $prodFiles | Where-Object { $_ -notin $devFiles }

# Files in both — check for content differences
$common = $devFiles | Where-Object { $_ -in $prodFiles }
foreach ($file in $common) {
    $devHash = Get-FileHash "./unpacked/dev/$file"
    $prodHash = Get-FileHash "./unpacked/prod/$file"
    if ($devHash.Hash -ne $prodHash.Hash) {
        Write-Output "MODIFIED: $file"
    }
}
```

---

## Verdict Criteria

| Condition | Verdict |
|-----------|---------|
| All components match between environments | **PASS** |
| Minor differences (e.g., timestamps, non-functional changes) | **WARN** |
| Missing topics, knowledge sources, or actions in target | **FAIL** |
| Different topic content (logic changes) between environments | **FAIL** |
