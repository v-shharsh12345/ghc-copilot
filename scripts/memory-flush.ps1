<#
.SYNOPSIS
    Flush memory — re-index QMD text after session-end writes.

.DESCRIPTION
    Run this script at the end of a session after the agent has written
    daily logs, updated MEMORY.md, or saved session checkpoints.
    It triggers a QMD text re-index so new content is searchable
    in the next session.

.PARAMETER Quiet
    Suppress non-error output.

.EXAMPLE
    .\scripts\memory-flush.ps1
    .\scripts\memory-flush.ps1 -Quiet
#>

param(
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    if (-not $Quiet) {
        Write-Host "[$timestamp] $Message" -ForegroundColor $Color
    }
}

# ── Helper: resolve QMD node entry point ──────────────────
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
    & node $entry @QmdArgs 2>&1
}

# ── Step 1: QMD text re-index ─────────────────────────────

Write-Log "Memory Flush — starting re-index" "Cyan"

$entry = Get-QmdEntryPoint
if (-not $entry) {
    Write-Log "ERROR: QMD not found. Run scripts/setup-memory.ps1 first." "Red"
    exit 1
}

Write-Log "Running qmd update (text re-index)..." "Yellow"
Invoke-Qmd update | ForEach-Object {
    if (-not $Quiet) { Write-Host "  $_" }
}

if ($LASTEXITCODE -eq 0) {
    Write-Log "Text re-index complete." "Green"
} else {
    Write-Log "WARNING: qmd update returned exit code $LASTEXITCODE" "DarkYellow"
}

# ── Done ──────────────────────────────────────────────────

Write-Log "Memory flush complete." "Cyan"
