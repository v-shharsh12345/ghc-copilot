<#
.SYNOPSIS
    Setup script for copilot-agents repository.
    Installs prerequisites and pre-caches MCP server npm packages.

.DESCRIPTION
    Run this script after cloning the repo to ensure all MCP server
    dependencies are available. The .vscode/mcp.json file provides
    workspace-level MCP configuration that VS Code auto-discovers.

.EXAMPLE
    .\setup.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Copilot Agents - Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Check Node.js ──────────────────────────────────────
Write-Host "[1/5] Checking Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>$null
    Write-Host "  Node.js $nodeVersion found" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Node.js is not installed." -ForegroundColor Red
    Write-Host "  Install from https://nodejs.org (LTS recommended)" -ForegroundColor Red
    exit 1
}

$npmVersion = npm --version 2>$null
if (-not $npmVersion) {
    Write-Host "  ERROR: npm is not available." -ForegroundColor Red
    exit 1
}
Write-Host "  npm $npmVersion found" -ForegroundColor Green

# ── 2. Check Azure CLI ────────────────────────────────────
Write-Host "[2/5] Checking Azure CLI..." -ForegroundColor Yellow
try {
    $azVersion = az version 2>$null | ConvertFrom-Json
    Write-Host "  Azure CLI $($azVersion.'azure-cli') found" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Azure CLI not found. Required for Fabric API auth." -ForegroundColor DarkYellow
    Write-Host "  Install from https://learn.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor DarkYellow
}

# ── 3. Check VS Code extensions ──────────────────────────
Write-Host "[3/5] Checking VS Code extensions..." -ForegroundColor Yellow

$requiredExtensions = @(
    @{ Id = "GitHub.copilot";       Name = "GitHub Copilot" },
    @{ Id = "GitHub.copilot-chat";  Name = "GitHub Copilot Chat" },
    @{ Id = "ms-mssql.mssql";      Name = "SQL Server (mssql)" }
)

# Try both 'code' and 'code-insiders'
$codeCmd = $null
if (Get-Command "code-insiders" -ErrorAction SilentlyContinue) { $codeCmd = "code-insiders" }
elseif (Get-Command "code" -ErrorAction SilentlyContinue) { $codeCmd = "code" }

if ($codeCmd) {
    $installed = & $codeCmd --list-extensions 2>$null
    foreach ($ext in $requiredExtensions) {
        if ($installed -contains $ext.Id) {
            Write-Host "  $($ext.Name) ($($ext.Id)) installed" -ForegroundColor Green
        } else {
            Write-Host "  MISSING: $($ext.Name) ($($ext.Id))" -ForegroundColor DarkYellow
            Write-Host "    Install: $codeCmd --install-extension $($ext.Id)" -ForegroundColor DarkYellow
        }
    }
} else {
    Write-Host "  WARNING: VS Code CLI not found. Cannot verify extensions." -ForegroundColor DarkYellow
}

# ── 4. Pre-cache npm-based MCP server packages ───────────
Write-Host "[4/5] Pre-caching MCP server npm packages..." -ForegroundColor Yellow

$packages = @(
    "@azure-devops/mcp@latest",
    "@playwright/mcp@latest",
    "@microsoft/workiq",
    "@upstash/context7-mcp@1.0.31"
)

foreach ($pkg in $packages) {
    Write-Host "  Caching $pkg ..." -NoNewline
    try {
        # npx -y ensures the package is downloaded to the npx cache
        $null = npx -y $pkg --help 2>$null
        Write-Host " OK" -ForegroundColor Green
    } catch {
        # Some packages don't support --help; try a version check instead
        Write-Host " cached (first-run download will occur)" -ForegroundColor DarkYellow
    }
}

# ── 5. Verify .vscode/mcp.json ───────────────────────────
Write-Host "[5/5] Verifying workspace MCP configuration..." -ForegroundColor Yellow

$mcpJsonPath = Join-Path $PSScriptRoot ".vscode" "mcp.json"
if (Test-Path $mcpJsonPath) {
    try {
        $null = Get-Content $mcpJsonPath -Raw | ConvertFrom-Json
        Write-Host "  .vscode/mcp.json is valid" -ForegroundColor Green
    } catch {
        Write-Host "  WARNING: .vscode/mcp.json has invalid JSON" -ForegroundColor Red
    }
} else {
    Write-Host "  ERROR: .vscode/mcp.json not found" -ForegroundColor Red
    exit 1
}

# ── Summary ───────────────────────────────────────────────
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Open this folder in VS Code (or add as workspace folder)" -ForegroundColor White
Write-Host "  2. VS Code will auto-discover MCP servers from .vscode/mcp.json" -ForegroundColor White
Write-Host "  3. On first use, you'll be prompted for:" -ForegroundColor White
Write-Host "     - Azure DevOps org name and domain" -ForegroundColor Gray
Write-Host "     - Power Platform Environment ID" -ForegroundColor Gray
Write-Host "     - Context7 API key" -ForegroundColor Gray
Write-Host "  4. Invoke agents in Copilot Chat: @orchestrator, @chief-of-staff, @fabric-devops" -ForegroundColor White
Write-Host ""
