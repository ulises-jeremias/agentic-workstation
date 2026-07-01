# Post-install layout assertions for the Windows install-methods CI matrix.
# Mirrors scripts/ci/assert-install-layout.sh.
#
# Usage:
#   pwsh -File scripts/ci/assert-install-layout.ps1 <profile> [tool]
#
# Profiles: gitbash | skills
# Tool (skills only): all | claude | opencode | cursor | windsurf | copilot

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet("gitbash", "skills")][string]$Profile,
    [ValidateSet("all", "claude", "opencode", "cursor", "windsurf", "copilot")]
    [string]$Tool = "all"
)

$ErrorActionPreference = 'Stop'

function Write-AssertOk   { param($msg) Write-Host "[assert-install-layout] OK: $msg" }
function Write-AssertFail {
    param($msg)
    Write-Host "[assert-install-layout] FAIL: $msg" -ForegroundColor Red
    exit 1
}

function Require-Dir { param($Path)
    if (-not (Test-Path -Path $Path -PathType Container)) {
        Write-AssertFail "missing directory: $Path"
    }
    Write-AssertOk "dir present: $Path"
}

function Require-DirNonEmpty { param($Path)
    Require-Dir $Path
    $children = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue
    if ($null -eq $children -or $children.Count -eq 0) {
        Write-AssertFail "directory exists but is empty: $Path"
    }
    Write-AssertOk "dir non-empty: $Path"
}

function Require-File { param($Path)
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-AssertFail "missing file: $Path"
    }
    Write-AssertOk "file present: $Path"
}

$LocalBin     = Join-Path $env:USERPROFILE ".local\bin"
$SkillsDir    = Join-Path $env:USERPROFILE ".local\share\agentic-workstation\skills"
$ClaudeAgents = Join-Path $env:USERPROFILE ".claude\agents"
$OpenCode     = Join-Path $env:APPDATA     "opencode\agents"
$CursorRules  = Join-Path $env:USERPROFILE ".cursor\rules"
$WindsurfDir  = Join-Path $env:USERPROFILE ".windsurf\rules"
$Copilot      = Join-Path $env:USERPROFILE ".github\copilot-instructions.md"

switch ($Profile) {
    "gitbash" {
        # install.ps1 -Mode GitBash deploys dots-* and AI assets only.
        Require-Dir $LocalBin
        $nanScripts = Get-ChildItem -Path $LocalBin -Filter "dots-*" -ErrorAction SilentlyContinue
        if ($null -eq $nanScripts -or $nanScripts.Count -lt 3) {
            Write-AssertFail "expected several dots-* scripts in $LocalBin"
        }
        Write-AssertOk "found $($nanScripts.Count) dots-* scripts in $LocalBin"
        Require-DirNonEmpty (Join-Path $env:USERPROFILE ".local\share\agentic-workstation")
    }
    "skills" {
        Require-DirNonEmpty $SkillsDir
        switch ($Tool) {
            "cursor"   { Require-DirNonEmpty $CursorRules }
            "claude"   { Require-DirNonEmpty $ClaudeAgents }
            "opencode" { Require-DirNonEmpty $OpenCode }
            "windsurf" { Require-DirNonEmpty $WindsurfDir }
            "copilot"  { Require-File         $Copilot }
            "all"      {
                Require-DirNonEmpty $CursorRules
                Require-DirNonEmpty $ClaudeAgents
                Require-DirNonEmpty $OpenCode
                Require-DirNonEmpty $WindsurfDir
                Require-File         $Copilot
            }
        }
    }
}

Write-AssertOk "layout assertions passed (profile=$Profile tool=$Tool)"
