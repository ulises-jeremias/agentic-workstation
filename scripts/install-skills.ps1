# agentic-workstation Skills Installer for Windows
# Downloads and installs agentic-workstation AI skills and agents
# Compatible with: Windows 10/11 (PowerShell 5.1+)
#
# Usage (run in PowerShell):
#   irm https://github.com/ulises-jeremias/agentic-workstation/releases/latest/download/install-skills.ps1 | iex
#
# Or with tool selection:
#   $env:DOTS_WORKSTATION_TOOL = "claude"
#   irm https://github.com/ulises-jeremias/agentic-workstation/releases/latest/download/install-skills.ps1 | iex
#
# Hermetic CI / private mirrors:
#   $env:DOTS_WORKSTATION_SKILLS_VERSION = "v0.1.4"   # must match zip names under $ReleaseBase
#
# Or locally:
#   .\scripts\install-skills.ps1
#   .\scripts\install-skills.ps1 -Tool claude

param(
    [ValidateSet("all", "claude", "opencode", "cursor", "windsurf", "copilot")]
    [string]$Tool = $(if ($env:DOTS_WORKSTATION_TOOL) { $env:DOTS_WORKSTATION_TOOL } else { "all" }),
    [switch]$Guided = $(if ($env:DOTS_WORKSTATION_GUIDED -eq "1") { $true } else { $false }),
    [switch]$DryRun = $(if ($env:DOTS_WORKSTATION_DRY_RUN -eq "1") { $true } else { $false })
)

$ErrorActionPreference = "Stop"
$GithubRepo = "ulises-jeremias/agentic-workstation"
$ReleaseBase = "https://github.com/$GithubRepo/releases/latest/download"
$TempDir = Join-Path $env:TEMP "dots-workstation-skills-install-$(Get-Random)"
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

function Write-NLog  { param($msg) Write-Host "[install-skills] $msg" }
function Write-NOk   { param($msg) Write-Host "[install-skills] OK: $msg" -ForegroundColor Green }
function Write-NWarn { param($msg) Write-Host "[install-skills] WARNING: $msg" -ForegroundColor Yellow }
function Write-NFail { param($msg) Write-Host "[install-skills] ERROR: $msg" -ForegroundColor Red; throw $msg }

function Get-ReleaseVersion {
    if ($env:DOTS_WORKSTATION_SKILLS_VERSION -and $env:DOTS_WORKSTATION_SKILLS_VERSION.Trim().Length -gt 0) {
        return $env:DOTS_WORKSTATION_SKILLS_VERSION.Trim()
    }
    # If RELEASE_BASE already has a pinned version, extract it
    if ($ReleaseBase -match 'releases/download/(v\d+\.\d+\.\d+(?:-[A-Za-z0-9_.-]+)?)') {
        return $Matches[1]
    }
    # Otherwise detect from redirect
    try {
        $resp = Invoke-WebRequest -Uri "https://github.com/$GithubRepo/releases/latest" `
            -MaximumRedirection 0 -UseBasicParsing -ErrorAction SilentlyContinue
    } catch {
        $resp = $_.Exception.Response
    }
    $location = ""
    if ($null -ne $resp -and $null -ne $resp.Headers) {
        if ($resp.Headers -is [System.Collections.Hashtable]) {
            $location = $resp.Headers["Location"]
        } elseif ($resp.Headers -is [System.Net.WebHeaderCollection]) {
            $location = $resp.Headers["Location"]
        }
    }
    if ($location -match 'v\d+\.\d+\.\d+') { return $Matches[0] }
    return "latest"
}

function Expand-ZipTo {
    param([string]$ZipPath, [string]$Dest)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $Dest)
}

function Copy-DirContents {
    param([string]$Src, [string]$Dst)
    if (-not (Test-Path -LiteralPath $Src)) {
        Write-NWarn "source directory not found: $Src"
        return
    }
    New-Item -ItemType Directory -Force -Path $Dst | Out-Null
    # Build targets with explicit relative paths — string .Replace() breaks on
    # case / prefix edge cases and can produce source == destination paths.
    $srcRoot = (Resolve-Path -LiteralPath $Src).Path.TrimEnd('\', '/')
    Get-ChildItem -LiteralPath $srcRoot -Recurse -File -Force | ForEach-Object {
        $rel = $_.FullName.Substring($srcRoot.Length).TrimStart('\', '/')
        $target = Join-Path $Dst $rel
        $targetDir = [System.IO.Path]::GetDirectoryName($target)
        if ($targetDir) {
            New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
        }
        Copy-Item -LiteralPath $_.FullName -Destination $target -Force
    }
}

function Get-Package {
    param([string]$Url, [string]$OutFile)
    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
        return $true
    } catch {
        return $false
    }
}

function Get-Asset {
    param([string]$Name, [string]$OutFile)
    $newUrl = "$ReleaseBase/dots-workstation-$Name-$Version.zip"
    if (Get-Package $newUrl $OutFile) { return $true }
    Write-NLog "dots-workstation-$Name-$Version.zip not found, trying dots-ai- prefix..."
    $oldUrl = "$ReleaseBase/dots-ai-$Name-$Version.zip"
    return (Get-Package $oldUrl $OutFile)
}

$Version = Get-ReleaseVersion
Write-NLog "version: $Version"

# ---- Guided (interactive) mode ----------------------------------------
# Only prompt when running interactively. If stdin is redirected (e.g.
# `irm ... | iex` in a CI context), silently fall back to the given -Tool.
if ($Guided) {
    $interactive = $Host.UI.RawUI -and -not [Console]::IsInputRedirected
    if ($interactive) {
        Write-Host ""
        Write-Host "[install-skills] Guided mode" -ForegroundColor Cyan
        Write-Host "  Which AI tool do you use?"
        Write-Host "    [1] all (default)"
        Write-Host "    [2] claude"
        Write-Host "    [3] cursor"
        Write-Host "    [4] opencode"
        Write-Host "    [5] windsurf"
        Write-Host "    [6] copilot"
        $choice = Read-Host "  Your choice"
        switch ($choice) {
            "1"         { $Tool = "all" }
            ""          { $Tool = "all" }
            "2"         { $Tool = "claude" }
            "claude"    { $Tool = "claude" }
            "3"         { $Tool = "cursor" }
            "cursor"    { $Tool = "cursor" }
            "4"         { $Tool = "opencode" }
            "opencode"  { $Tool = "opencode" }
            "5"         { $Tool = "windsurf" }
            "windsurf"  { $Tool = "windsurf" }
            "6"         { $Tool = "copilot" }
            "copilot"   { $Tool = "copilot" }
            default     {
                Write-NWarn "unknown choice '$choice', defaulting to 'all'"
                $Tool = "all"
            }
        }
        $confirm = Read-Host "  Proceed with tool=$Tool and version=$Version? [Y/n]"
        if ($confirm -match '^(n|no)$') {
            Write-NFail "aborted by user"
        }
    } else {
        Write-NWarn "-Guided requested but no interactive host (piped install); continuing with -Tool $Tool"
    }
}

if ($DryRun) {
    Write-NLog "DRY RUN - no files will be modified"
    Write-NLog "  tool: $Tool"
    Write-NLog "  release base: $ReleaseBase"
    Write-NLog "  version: $Version"
    Write-NLog ("  skills dir (target): {0}" -f (Join-Path $env:USERPROFILE ".local\share\agentic-workstation\skills"))
    Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
    exit 0
}

# Skill paths for Windows (following XDG-style conventions)
$SkillsDir    = Join-Path $env:USERPROFILE ".local\share\agentic-workstation\skills"
$ClaudeDir    = Join-Path $env:USERPROFILE ".claude"
$ClaudeAgents = Join-Path $ClaudeDir "agents"
$OpenCodeDir  = Join-Path $env:APPDATA "opencode"
$CursorDir    = Join-Path $env:USERPROFILE ".cursor"
$WindsurfDir  = Join-Path $env:USERPROFILE ".windsurf"
$WindsurfCfg  = Join-Path $env:APPDATA "windsurf\rules"
$GithubUserDir = Join-Path $env:USERPROFILE ".github"

function Install-Skills {
    Write-NLog "downloading skills package..."
    $zipPath = Join-Path $TempDir "skills.zip"
    if (-not (Get-Asset "skills" $zipPath)) {
        Write-NFail "could not download skills package from $ReleaseBase"
    }
    $extractPath = Join-Path $TempDir "skills-extracted"
    New-Item -ItemType Directory -Force -Path $extractPath | Out-Null
    Expand-ZipTo $zipPath $extractPath
    New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
    $nested = Join-Path $extractPath ".local\share\agentic-workstation\skills"
    $flat = Join-Path $extractPath "skills"
    if (Test-Path $nested -PathType Container) {
        Copy-DirContents $nested $SkillsDir
    } elseif (Test-Path $flat -PathType Container) {
        Copy-DirContents $flat $SkillsDir
    } else {
        Write-NFail "skills zip had unexpected layout (expected .local\share\agentic-workstation\skills or skills)"
    }
    Write-NOk "skills installed to $SkillsDir"
}

function Install-ForClaude {
    Write-NLog "installing agents for Claude Code / Claude Desktop..."
    $zipPath = Join-Path $TempDir "claude.zip"
    if (-not (Get-Asset "agents-claude" $zipPath)) {
        Write-NWarn "could not download claude agents — skipping"
        return
    }
    $extractPath = Join-Path $TempDir "claude-extracted"
    New-Item -ItemType Directory -Force -Path $extractPath | Out-Null
    Expand-ZipTo $zipPath $extractPath
    New-Item -ItemType Directory -Force -Path $ClaudeAgents | Out-Null
    Copy-DirContents (Join-Path $extractPath ".claude\agents") $ClaudeAgents
    $settingsJson  = Join-Path $extractPath ".claude\settings.json"
    $targetSettings = Join-Path $ClaudeDir "settings.json"
    if ((Test-Path $settingsJson) -and (-not (Test-Path $targetSettings))) {
        Copy-Item $settingsJson $targetSettings
        Write-NOk "claude settings.json installed"
    }
    Write-NOk "Claude agents installed to $ClaudeAgents"
}

function Install-ForOpenCode {
    Write-NLog "installing agents for OpenCode..."
    $zipPath = Join-Path $TempDir "opencode.zip"
    if (-not (Get-Asset "agents-opencode" $zipPath)) {
        Write-NWarn "could not download opencode agents — skipping"
        return
    }
    $extractPath = Join-Path $TempDir "opencode-extracted"
    New-Item -ItemType Directory -Force -Path $extractPath | Out-Null
    Expand-ZipTo $zipPath $extractPath
    $agentsTarget = Join-Path $OpenCodeDir "agents"
    New-Item -ItemType Directory -Force -Path $agentsTarget | Out-Null
    Copy-DirContents (Join-Path $extractPath ".config\opencode\agents") $agentsTarget
    Write-NOk "OpenCode agents installed to $agentsTarget"
}

function Install-ForCursor {
    Write-NLog "installing agents for Cursor..."
    $zipPath = Join-Path $TempDir "cursor.zip"
    if (-not (Get-Asset "agents-cursor" $zipPath)) {
        Write-NWarn "could not download cursor agents — skipping"
        return
    }
    $extractPath = Join-Path $TempDir "cursor-extracted"
    New-Item -ItemType Directory -Force -Path $extractPath | Out-Null
    Expand-ZipTo $zipPath $extractPath
    $rulesTarget  = Join-Path $CursorDir "rules"
    New-Item -ItemType Directory -Force -Path $rulesTarget | Out-Null
    Copy-DirContents (Join-Path $extractPath ".cursor\rules") $rulesTarget
    Write-NOk "Cursor rules installed to $CursorDir\rules"
}

function Install-ForWindsurf {
    Write-NLog "installing agents for Windsurf..."
    $zipPath = Join-Path $TempDir "windsurf.zip"
    if (-not (Get-Asset "agents-windsurf" $zipPath)) {
        Write-NWarn "could not download windsurf agents — skipping"
        return
    }
    $extractPath = Join-Path $TempDir "windsurf-extracted"
    New-Item -ItemType Directory -Force -Path $extractPath | Out-Null
    Expand-ZipTo $zipPath $extractPath
    $rulesTarget = Join-Path $WindsurfDir "rules"
    New-Item -ItemType Directory -Force -Path $rulesTarget | Out-Null
    New-Item -ItemType Directory -Force -Path $WindsurfCfg | Out-Null
    Copy-DirContents (Join-Path $extractPath ".windsurf\rules") $rulesTarget
    $cfgRules = Join-Path $extractPath ".config\windsurf\rules"
    if (Test-Path $cfgRules) {
        Copy-DirContents $cfgRules $WindsurfCfg
    }
    Write-NOk "Windsurf agents installed to $WindsurfDir"
}

function Install-ForCopilot {
    Write-NLog "installing GitHub Copilot custom instructions..."
    $zipPath = Join-Path $TempDir "copilot.zip"
    if (-not (Get-Asset "agents-copilot" $zipPath)) {
        Write-NWarn "could not download copilot agents — skipping"
        return
    }
    $extractPath = Join-Path $TempDir "copilot-extracted"
    New-Item -ItemType Directory -Force -Path $extractPath | Out-Null
    Expand-ZipTo $zipPath $extractPath
    $srcInstructions = Join-Path $extractPath ".github\copilot-instructions.md"
    if (Test-Path $srcInstructions) {
        New-Item -ItemType Directory -Force -Path $GithubUserDir | Out-Null
        Copy-Item $srcInstructions (Join-Path $GithubUserDir "copilot-instructions.md") -Force
        Write-NOk "GitHub Copilot instructions installed to $GithubUserDir\copilot-instructions.md"
    } else {
        Write-NWarn "copilot zip missing .github/copilot-instructions.md — skipping"
    }
}

try {
    # Always install the skills library first
    Install-Skills

    switch ($Tool) {
        "all" {
            Install-ForClaude
            Install-ForOpenCode
            Install-ForCursor
            Install-ForWindsurf
            Install-ForCopilot
        }
        "claude"   { Install-ForClaude }
        "opencode" { Install-ForOpenCode }
        "cursor"   { Install-ForCursor }
        "windsurf" { Install-ForWindsurf }
        "copilot"  { Install-ForCopilot }
    }

    Write-NLog ""
    Write-NLog "Installation complete."
    Write-NLog "  Skills: $SkillsDir"
    Write-NLog "  Restart your AI tool for changes to take effect."
} finally {
    # Always cleanup temp dir
    Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
}
