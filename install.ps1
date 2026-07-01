# agentic-workstation — Windows Installer
#
# Supports two modes:
#   1. WSL2 (recommended) — Full workstation setup inside Ubuntu on WSL2
#   2. Git Bash only       — dots-* scripts available in Git Bash without full toolchain
#
# Usage (run in PowerShell as Administrator):
#   irm https://raw.githubusercontent.com/ulises-jeremias/agentic-workstation/main/install.ps1 | iex
#
# Or clone and run locally:
#   .\install.ps1
#   .\install.ps1 -Mode GitBash
#   .\install.ps1 -Mode WSL2
#
# Git Bash mode against a private GitHub repo: set DOTS_WORKSTATION_GITBASH_REPO_ROOT to
# a local clone path (must contain home\dot_local\bin), or run with GITHUB_TOKEN
# so the installer can fall back to the GitHub zipball API.

param(
    [ValidateSet("auto", "wsl2", "gitbash")]
    [string]$Mode = "auto",
    [string]$Profile = "technical",
    [switch]$SkillsOnly
)

$ErrorActionPreference = "Stop"
$RepoUrl = "https://github.com/ulises-jeremias/agentic-workstation"
$RawBase  = "https://raw.githubusercontent.com/ulises-jeremias/agentic-workstation/main"

function Write-Log  { param($msg) Write-Host "[dots-workstation-install] $msg" }
function Write-Ok   { param($msg) Write-Host "[dots-workstation-install] OK: $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Warning "[dots-workstation-install] $msg" }
function Write-Fail { param($msg) Write-Host "[dots-workstation-install] ERROR: $msg" -ForegroundColor Red; exit 1 }
function Write-Sep  { Write-Host ("-" * 60) }

Write-Sep
Write-Log "agentic-workstation — Windows Setup"
Write-Sep

# ---------------------------------------------------------------------------
# Detect WSL2 availability
# ---------------------------------------------------------------------------
function Test-WSL2Available {
    try {
        $wslOutput = wsl --status 2>&1
        return ($wslOutput -match "Default Distribution" -or $LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Test-WSL2HasUbuntu {
    try {
        $distros = wsl --list --quiet 2>&1
        return ($distros -match "Ubuntu")
    } catch {
        return $false
    }
}

function Test-GitBashAvailable {
    $gitBashPaths = @(
        "C:\Program Files\Git\bin\bash.exe",
        "C:\Program Files (x86)\Git\bin\bash.exe",
        "${env:ProgramFiles}\Git\bin\bash.exe"
    )
    foreach ($path in $gitBashPaths) {
        if (Test-Path $path) { return $true }
    }
    return (Get-Command git -ErrorAction SilentlyContinue) -ne $null
}

# ---------------------------------------------------------------------------
# Mode: WSL2 full install
# ---------------------------------------------------------------------------
function Install-ViaWSL2 {
    Write-Log "Installing via WSL2 (Ubuntu)..."

    if (-not (Test-WSL2Available)) {
        Write-Log ""
        Write-Log "WSL2 is not installed or not enabled. To install:"
        Write-Log "  1. Open PowerShell as Administrator"
        Write-Log "  2. Run: wsl --install"
        Write-Log "  3. Restart your machine"
        Write-Log "  4. Open Ubuntu from the Start Menu and complete setup"
        Write-Log "  5. Re-run this installer"
        Write-Log ""
        Write-Log "Alternatively, install Git for Windows and use -Mode GitBash:"
        Write-Log "  https://git-scm.com/download/win"
        Write-Fail "WSL2 not available"
    }

    if (-not (Test-WSL2HasUbuntu)) {
        Write-Warn "WSL2 is available but Ubuntu is not installed."
        Write-Log "Installing Ubuntu via wsl --install -d Ubuntu..."
        wsl --install -d Ubuntu
        Write-Log ""
        Write-Log "After Ubuntu setup is complete, run inside Ubuntu:"
        Write-Log "  bash <(curl -fsSL ${RawBase}/install.sh)"
        Write-Sep
        return
    }

    Write-Ok "WSL2 + Ubuntu detected"
    Write-Log "Running full workstation install inside WSL2 Ubuntu..."
    Write-Log "This will install: chezmoi, toolchain, AI agents, and dots-* scripts"
    Write-Log ""

    $installCmd = "bash <(curl -fsSL ${RawBase}/install.sh)"
    wsl bash -c $installCmd

    if ($LASTEXITCODE -eq 0) {
        Write-Sep
        Write-Ok "Workstation installed successfully inside WSL2!"
        Write-Log ""
        Write-Log "Next steps:"
        Write-Log "  1. Open Ubuntu (WSL2) terminal"
        Write-Log "  2. Run: dots-doctor"
        Write-Log "  3. Launch your AI tool (Claude Code, OpenCode, Cursor, Windsurf)"
        Write-Sep
    } else {
        Write-Fail "WSL2 install failed — check the output above for errors"
    }
}

# ---------------------------------------------------------------------------
# Mode: Git Bash only (dots-* scripts without full toolchain)
# ---------------------------------------------------------------------------
function Install-ViaGitBash {
    Write-Log "Installing dots-* scripts for Git Bash..."

    if (-not (Test-GitBashAvailable)) {
        Write-Log ""
        Write-Log "Git for Windows is required. Download from:"
        Write-Log "  https://git-scm.com/download/win"
        Write-Log ""
        Write-Log "Or install via winget:"
        Write-Log "  winget install Git.Git"
        Write-Log ""
        Write-Log "After installing Git, re-run this installer."
        Write-Fail "Git Bash not available"
    }

    # Find git bash
    $gitBash = "C:\Program Files\Git\bin\bash.exe"
    if (-not (Test-Path $gitBash)) {
        $gitBash = "${env:ProgramFiles}\Git\bin\bash.exe"
    }

    $LocalBin    = "${env:USERPROFILE}\.local\bin"
    $LocalLib    = "${env:USERPROFILE}\.local\lib\agentic-workstation\easy-options"
    $agentic-workstationShare = "${env:USERPROFILE}\.local\share\agentic-workstation"

    New-Item -ItemType Directory -Force -Path $LocalBin    | Out-Null
    New-Item -ItemType Directory -Force -Path $LocalLib    | Out-Null
    New-Item -ItemType Directory -Force -Path $agentic-workstationShare | Out-Null

    Write-Log "Resolving agentic-workstation repository source..."

    $TempDir = Join-Path $env:TEMP "dots-workstation-gitbash-install"
    New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

    $RepoPath = $null
    $checkoutHint = $env:DOTS_WORKSTATION_GITBASH_REPO_ROOT
    $homeBinProbe = if ($checkoutHint) { Join-Path $checkoutHint "home\dot_local\bin" } else { $null }
    if ($checkoutHint -and (Test-Path -LiteralPath $homeBinProbe)) {
        $RepoPath = (Resolve-Path -LiteralPath $checkoutHint).Path
        Write-Log "Using DOTS_WORKSTATION_GITBASH_REPO_ROOT (no zip download): $RepoPath"
    } else {
        # Default: GitHub archive of main (public repos). Private repos: set
        # DOTS_WORKSTATION_GITBASH_REPO_ROOT to a checkout, or run with GITHUB_TOKEN so
        # the zipball fallback below can authenticate.
        $RepoZipUrl = "${RepoUrl}/archive/refs/heads/main.zip"
        $RepoZip = Join-Path $TempDir "repo.zip"
        $tok = $env:GITHUB_TOKEN
        $hdr = @{}
        if ($tok) {
            $hdr["Authorization"] = "Bearer $tok"
        }
        try {
            Invoke-WebRequest -Uri $RepoZipUrl -OutFile $RepoZip -UseBasicParsing -Headers $hdr
        } catch {
            if (-not $tok) {
                Write-Fail "Could not download repository: $_"
            }
            $slug = ($RepoUrl -replace '^https://github\.com/', '' -replace '\.git$', '')
            $apiUrl = "https://api.github.com/repos/${slug}/zipball/main"
            try {
                Invoke-WebRequest -Uri $apiUrl -OutFile $RepoZip -UseBasicParsing -Headers $hdr
            } catch {
                Write-Fail "Could not download repository (archive or API zipball): $_"
            }
        }

        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($RepoZip, $TempDir)
        $RepoDir = Get-ChildItem -Path $TempDir -Directory | Where-Object {
            Test-Path -LiteralPath (Join-Path $_.FullName "home\dot_local\bin")
        } | Select-Object -First 1

        if (-not $RepoDir) {
            Write-Fail "Could not extract repository files (expected home\dot_local\bin under one top-level directory)"
        }

        $RepoPath = $RepoDir.FullName
    }

    if (-not $RepoPath) {
        Write-Fail "Could not resolve repository path"
    }
    $DotsBinDir = Join-Path $RepoPath "home\dot_local\bin"
    $DotsLibDir = Join-Path $RepoPath "home\dot_local\lib\agentic-workstation\easy-options"

    # Copy dots-* scripts (strip executable_ prefix)
    Get-ChildItem -Path $DotsBinDir -Filter "executable_dots-*" | ForEach-Object {
        $destName = $_.Name -replace '^executable_', ''
        $destPath = Join-Path $LocalBin $destName
        Copy-Item -Path $_.FullName -Destination $destPath -Force
        Write-Ok "installed: $destName"
    }

    # Copy easy-options library
    if (Test-Path $DotsLibDir) {
        Copy-Item -Path "$DotsLibDir\*" -Destination $LocalLib -Force -Recurse
        Write-Ok "installed: easy-options library"
    }

    # Copy agentic-workstation AI assets (skills, prompts, templates)
    $agentic-workstationAssets = Join-Path $RepoPath "home\dot_local\share\agentic-workstation"
    if (Test-Path $agentic-workstationAssets) {
        Copy-Item -Path "$agentic-workstationAssets\*" -Destination $agentic-workstationShare -Force -Recurse
        Write-Ok "installed: agentic-workstation AI assets (skills, prompts, templates)"
    }

    # Add ~/.local/bin to PATH if not already there
    $UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($UserPath -notlike "*$LocalBin*") {
        [Environment]::SetEnvironmentVariable(
            "PATH", "$LocalBin;$UserPath", "User"
        )
        Write-Ok "added $LocalBin to PATH"
        Write-Warn "Restart your terminal for PATH changes to take effect"
    }

    # Cleanup
    Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue

    Write-Sep
    Write-Ok "dots-* scripts installed for Git Bash!"
    Write-Log ""
    Write-Log "Open Git Bash and run:"
    Write-Log "  dots-doctor"
    Write-Log ""
    Write-Log "Note: Full workstation toolchain (chezmoi apply) requires WSL2."
    Write-Log "For complete setup: run this installer with -Mode WSL2 after installing WSL2."
    Write-Sep
}

# ---------------------------------------------------------------------------
# Skills-only mode (no toolchain, just AI skills/agents)
# ---------------------------------------------------------------------------
function Install-SkillsOnly {
    Write-Log "Installing agentic-workstation AI skills and agents only..."
    Write-Log "Downloading install-skills.ps1..."

    $TempScript = Join-Path $env:TEMP "dots-workstation-install-skills.ps1"
    try {
        Invoke-WebRequest -Uri "$RepoUrl/releases/latest/download/install-skills.ps1" `
            -OutFile $TempScript -UseBasicParsing
    } catch {
        Write-Fail "Could not download install-skills.ps1 from ${RepoUrl}/releases/latest/download: $_"
    }
    try {
        & $TempScript -Tool all
    } catch {
        Write-Fail "install-skills.ps1 failed: $_"
    } finally {
        Remove-Item $TempScript -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if ($SkillsOnly) {
    Install-SkillsOnly
    exit 0
}

# Auto-detect mode
if ($Mode -eq "auto") {
    if (Test-WSL2Available) {
        Write-Log "Auto-detected: WSL2 available — using WSL2 mode (recommended)"
        $Mode = "wsl2"
    } elseif (Test-GitBashAvailable) {
        Write-Log "Auto-detected: Git Bash available — using Git Bash mode"
        Write-Log "(WSL2 not found — for full workstation setup, install WSL2 first)"
        $Mode = "gitbash"
    } else {
        Write-Log ""
        Write-Log "Neither WSL2 nor Git Bash was detected."
        Write-Log ""
        Write-Log "Recommended: Install WSL2 for full workstation support:"
        Write-Log "  wsl --install"
        Write-Log ""
        Write-Log "Alternative: Install Git for Windows for basic dots-* script support:"
        Write-Log "  winget install Git.Git"
        Write-Log ""
        Write-Log "After installing one of the above, re-run this installer."
        Write-Fail "No supported runtime detected"
    }
}

switch ($Mode.ToLower()) {
    "wsl2"    { Install-ViaWSL2 }
    "gitbash" { Install-ViaGitBash }
    default   { Write-Fail "Unknown mode: $Mode. Use: auto, wsl2, gitbash" }
}
