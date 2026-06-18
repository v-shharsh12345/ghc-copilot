# Release & Promote — Procedure Module

## Overview

Manage the ALM lifecycle for Copilot Studio agents using Power Platform solutions, PAC CLI, and Pipeline deployments.

---

## ALM Options Comparison

| Method | Complexity | Best For |
|--------|-----------|----------|
| **PAC CLI** (export/import) | Low-Medium | Manual or scripted promotion |
| **Power Platform Pipelines** | Low | In-product deployment with quality gates |
| **Azure DevOps + Build Tools** | High | Enterprise CI/CD with full automation |
| **GitHub Actions** | Medium | GitHub-native CI/CD workflows |

---

## Path 1: PAC CLI Solution Promotion (Primary)

### Step 1: Authenticate to Source Environment

```bash
# Create or select auth profile for source (DEV)
pac auth create --environment <DEV_ENVIRONMENT_URL> --name dev

# Verify auth
pac auth list
pac auth select --name dev
```

### Step 2: Export Solution from Source

```bash
# Export unmanaged (for UAT testing)
pac solution export \
  --name "<SolutionUniqueName>" \
  --path ./exports/agent-solution-unmanaged.zip

# Export managed (for PROD deployment)
pac solution export \
  --name "<SolutionUniqueName>" \
  --path ./exports/agent-solution-managed.zip \
  --managed
```

### Step 3: (Optional) Unpack for Source Control

```bash
# Unpack solution for git tracking
pac solution unpack \
  --zipfile ./exports/agent-solution-unmanaged.zip \
  --folder ./src/agent-solution \
  --processCanvasApps

# Review changes
git diff ./src/agent-solution

# Commit and create PR
git add ./src/agent-solution
git commit -m "release: prepare agent v2.1 for UAT promotion"
git push origin feature/agent-v2.1
```

### Step 4: Authenticate to Target Environment

```bash
# Switch to target (UAT or PROD)
pac auth create --environment <TARGET_ENVIRONMENT_URL> --name uat
pac auth select --name uat
```

### Step 5: Import Solution to Target

```bash
# Import to UAT (unmanaged for testing flexibility)
pac solution import \
  --path ./exports/agent-solution-unmanaged.zip \
  --activate-plugins

# Import to PROD (managed for immutability)
pac solution import \
  --path ./exports/agent-solution-managed.zip \
  --activate-plugins \
  --force-overwrite
```

### Step 6: Verify Import

```bash
# List solutions in target to verify
pac solution list

# Check for import errors
# The import command outputs success/failure status
```

### Step 7: Post-Import Actions

After successful import:

1. **Verify agent appears** in Copilot Studio (target environment)
2. **Reconfigure authentication** — auth settings don't transfer between environments; user must reconfigure
3. **Publish the agent** — navigate to Copilot Studio in target environment and publish
4. **Run evaluation** — use the `copilotstudio-devops-evaluate` skill to test the promoted agent

```
## Promotion Summary

| Step | Status |
|------|--------|
| Export from {Source} | ✅ Complete |
| Import to {Target} | ✅ Complete |
| Solution verified | ✅ Present in solution list |
| Auth reconfigured | ⚠️ Required (manual step in Copilot Studio) |
| Agent published | ⚠️ Required (manual step in Copilot Studio) |
| Post-import evaluation | 🔲 Recommended next step |

**Verdict: PASS** — Solution promoted successfully
**Next: Reconfigure auth → Publish → Run evaluation**
```

---

## Path 2: Power Platform Pipelines (In-Product)

### Prerequisites

- Pipeline host environment configured with the Deployment Pipeline app
- DEV and target environments linked as pipeline stages
- Copilot Studio Kit installed (for automated testing gates)

### Step 1: Configure Pipeline (One-Time)

1. Open Power Platform admin center
2. Navigate to Pipelines
3. Create pipeline linking DEV → UAT → PROD
4. Enable pre-deployment hooks for automated testing

### Step 2: Deploy via Pipeline

Deployments are triggered from:
- **Copilot Studio UI**: Solutions explorer → select solution → Deploy
- **Power Automate flow**: Automated trigger on deployment request
- **PAC CLI**: `pac pipeline deploy --solutionName <name> --stageName <stage>`

### Step 3: Quality Gates (with Copilot Studio Kit)

When configured, the pipeline:
1. Triggers a Power Automate flow on deployment request
2. Runs automated test cases against the agent (Direct Line API)
3. Evaluates test results against pass criteria
4. Approves or rejects the deployment based on test outcomes

---

## Path 3: Azure DevOps Build Tools

### Pipeline YAML Example

```yaml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'windows-latest'

steps:
  - task: PowerPlatformToolInstaller@2
    displayName: 'Install Power Platform Build Tools'

  - task: PowerPlatformExportSolution@2
    displayName: 'Export Solution from DEV'
    inputs:
      authenticationType: 'PowerPlatformSPN'
      PowerPlatformSPN: 'dev-connection'
      SolutionName: 'AgentSolution'
      SolutionOutputFile: '$(Build.ArtifactStagingDirectory)/agent-solution.zip'
      Managed: true

  - task: PowerPlatformImportSolution@2
    displayName: 'Import Solution to UAT'
    inputs:
      authenticationType: 'PowerPlatformSPN'
      PowerPlatformSPN: 'uat-connection'
      SolutionInputFile: '$(Build.ArtifactStagingDirectory)/agent-solution.zip'
      ActivatePlugins: true
```

---

## Promotion Rules

| Rule | Detail |
|------|--------|
| **DEV → UAT** | Unmanaged or managed solution. Auth reconfiguration required. |
| **UAT → PROD** | Managed solution ONLY. Unmanaged not allowed in PROD. |
| **Direct DEV → PROD** | ❌ Not allowed. Must go through UAT. |
| **Rollback** | Delete the managed layer in target, then reimport previous version. |
