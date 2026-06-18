<#
.SYNOPSIS
    Setup QMD memory search for the copilot-agents repository.
    Installs QMD, creates collections, and runs initial indexing.

.DESCRIPTION
    Run this script after cloning the repo to enable persistent memory search.
    QMD (Query Markup Documents) provides BM25 full-text search over markdown files,
    exposed as an MCP server that GitHub Copilot Chat can use.

.PARAMETER ProjectRoot
    Root path of the copilot-agents repository. Defaults to the parent of this script's directory.

.PARAMETER SkipInstall
    Skip the npm global install of QMD (useful if already installed).

.EXAMPLE
    .\scripts\setup-memory.ps1
    .\scripts\setup-memory.ps1 -SkipInstall
#>

param(
    [string]$ProjectRoot,
    [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"

# Resolve project root
if (-not $ProjectRoot) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  QMD Memory Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── Helper: resolve QMD node entry point ──────────────────
# QMD bin wrapper is a bash script (broken on Windows).
# We call dist/qmd.js directly via Node.
function Get-QmdEntryPoint {
    $npmRoot = (npm root -g 2>$null)
    if (-not $npmRoot) { return $null }
    $qmdJs = Join-Path (Join-Path (Join-Path (Join-Path $npmRoot.Trim() "@tobilu") "qmd") "dist") "qmd.js"
    if (Test-Path $qmdJs) { return $qmdJs }
    return $null
}

function Invoke-Qmd {
    param([Parameter(ValueFromRemainingArguments)]$QmdArgs)
    $entry = Get-QmdEntryPoint
    if (-not $entry) {
        Write-Error "QMD entry point not found. Run: npm install -g @tobilu/qmd"
        return
    }
    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & node $entry @QmdArgs 2>&1
    $ErrorActionPreference = $prevPref
}

# ── 1. Install QMD ───────────────────────────────────────
if (-not $SkipInstall) {
    Write-Host "[1/5] Installing QMD globally..." -ForegroundColor Yellow
    npm install -g @tobilu/qmd 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install QMD. Ensure Node.js 18+ and npm are available. On Windows, VS Build Tools may be required for native compilation."
        exit 1
    }
}

$entry = Get-QmdEntryPoint
if (-not $entry) {
    Write-Error "QMD dist/qmd.js not found. Installation may have failed."
    exit 1
}
$ver = & node $entry --version 2>&1
Write-Host "  QMD $ver installed" -ForegroundColor Green

# ── 2. Create memory directories ─────────────────────────
Write-Host "[2/5] Creating memory directories..." -ForegroundColor Yellow

$memoryDirs = @(
    (Join-Path $ProjectRoot "memory"),
    (Join-Path $ProjectRoot "memory\daily"),
    (Join-Path $ProjectRoot "memory\session"),
    (Join-Path $ProjectRoot "memory\knowledgebase")
)

foreach ($dir in $memoryDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Green
    } else {
        Write-Host "  Exists: $dir" -ForegroundColor Green
    }
}

# ── 2b. Create MEMORY.md from template if needed ─────────
$templatePath = Join-Path $ProjectRoot "memory\MEMORY.template.md"
$memoryPath = Join-Path $ProjectRoot "memory\MEMORY.md"

if (-not (Test-Path $memoryPath) -and (Test-Path $templatePath)) {
    Copy-Item $templatePath $memoryPath
    Write-Host "  Created memory/MEMORY.md from template" -ForegroundColor Green
    Write-Host "  ACTION REQUIRED: Edit memory/MEMORY.md with your values" -ForegroundColor DarkYellow
} elseif (Test-Path $memoryPath) {
    Write-Host "  memory/MEMORY.md exists" -ForegroundColor Green
}

# ── 3. Create QMD collections ────────────────────────────
Write-Host "[3/5] Creating QMD collections..." -ForegroundColor Yellow

$collections = @(
    @{ Name = "memory-root";          Path = "$ProjectRoot\memory";              Mask = "**/*.md" },
    @{ Name = "session-checkpoints";  Path = "$ProjectRoot\memory\session";      Mask = "*.md" },
    @{ Name = "knowledgebase";        Path = "$ProjectRoot\memory\knowledgebase"; Mask = "**/*.md" },
    @{ Name = "skills-docs";          Path = "$ProjectRoot\.github\skills";       Mask = "**/SKILL.md" }
)

foreach ($col in $collections) {
    if (Test-Path $col.Path) {
        Write-Host "  Adding collection: $($col.Name) -> $($col.Path)"
        Invoke-Qmd collection add $col.Path --name $col.Name --mask $col.Mask | Out-Null
    } else {
        Write-Host "  Skipping $($col.Name) (path not found: $($col.Path))" -ForegroundColor DarkYellow
    }
}

# ── 4. Add context descriptions ──────────────────────────
Write-Host "[4/5] Adding context descriptions..." -ForegroundColor Yellow

$contexts = @(
    @{ Path = "qmd://memory-root";         Desc = "MEMORY.md and daily context logs - user profile, decisions, progress, blockers, next steps." },
    @{ Path = "qmd://session-checkpoints"; Desc = "Session checkpoint files - cross-request context preservation for multi-agent workflows." },
    @{ Path = "qmd://knowledgebase";       Desc = "Curated knowledge articles - Fabric, Databricks, ADO, architecture decisions, runbooks." },
    @{ Path = "qmd://skills-docs";         Desc = "Skill definitions and procedures - triggers, engine preferences, canonical procedures." }
)

foreach ($ctx in $contexts) {
    Write-Host "  Context: $($ctx.Path)"
    Invoke-Qmd context add $ctx.Path $ctx.Desc | Out-Null
}

# ── 5. Initial indexing ──────────────────────────────────
Write-Host "[5/5] Running initial text indexing..." -ForegroundColor Yellow

Invoke-Qmd update
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Text indexing complete." -ForegroundColor Green
} else {
    Write-Warning "Text indexing returned non-zero exit code"
}

# ── Verify ────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Index status:" -ForegroundColor Yellow
Invoke-Qmd status

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  QMD Memory Setup Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. QMD MCP server is already configured in .vscode/mcp.json" -ForegroundColor White
Write-Host "  2. Edit memory/MEMORY.md with your personal context" -ForegroundColor White
Write-Host "  3. Restart VS Code to pick up the QMD MCP server" -ForegroundColor White
Write-Host "  4. Try: @WorkFast Search my memory for past decisions" -ForegroundColor White
Write-Host ""
