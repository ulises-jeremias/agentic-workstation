# agentic-workstation AI install - prerequisite checker (Windows PowerShell)
#
# Read-only script: verifies that a Windows machine is ready to run
# install-skills.ps1 and reports whether the AI layer is already installed.
#
# Usage (remote):
#   irm https://raw.githubusercontent.com/ulises-jeremias/agentic-workstation/main/scripts/check-ai-install-prereqs.ps1 | iex
#
# Usage (local):
#   .\scripts\check-ai-install-prereqs.ps1
#
# Exit codes:
#   0  READY
#   1  NOT READY
#   2  ERROR (unexpected)

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$script:Missing = 0
$script:Warns   = 0

function Write-NNote { param($msg) Write-Host "[check-ai-install-prereqs] $msg" }
function Write-NOk   { param($msg) Write-Host "[check-ai-install-prereqs] OK: $msg" -ForegroundColor Green }
function Write-NWarn {
    param($msg)
    Write-Host "[check-ai-install-prereqs] WARN: $msg" -ForegroundColor Yellow
    $script:Warns += 1
}
function Write-NMiss {
    param($msg)
    Write-Host "[check-ai-install-prereqs] MISSING: $msg" -ForegroundColor Red
    $script:Missing += 1
}

try {
    Write-NNote "starting AI install prerequisite check"
    Write-NNote ("PowerShell version: {0}" -f $PSVersionTable.PSVersion)
    Write-NNote ("OS: {0}" -f [System.Environment]::OSVersion.VersionString)

    # ---- PowerShell version -------------------------------------------------
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        Write-NOk ("PowerShell >= 5.1 satisfied ({0})" -f $PSVersionTable.PSVersion)
    } else {
        Write-NMiss ("PowerShell >= 5.1 required (found {0})" -f $PSVersionTable.PSVersion)
    }

    # ---- Execution policy ---------------------------------------------------
    try {
        $policy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction Stop
    } catch {
        $policy = "Unknown"
    }
    if ($policy -in @("Restricted", "AllSigned")) {
        Write-NWarn ("execution policy is '{0}'. If 'irm | iex' fails, run once with: powershell -ExecutionPolicy Bypass -Command `"irm ... | iex`"" -f $policy)
    } else {
        Write-NOk ("execution policy: {0}" -f $policy)
    }

    # ---- Required cmdlets ---------------------------------------------------
    foreach ($cmd in @("Invoke-WebRequest", "Expand-Archive", "New-Item", "Copy-Item")) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            Write-NOk ("cmdlet available: {0}" -f $cmd)
        } else {
            Write-NMiss ("cmdlet missing: {0}" -f $cmd)
        }
    }

    # ---- Network reachability (soft) ---------------------------------------
    function Test-Url {
        param([string]$Url, [string]$Label)
        try {
            $resp = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 8 -UseBasicParsing -ErrorAction Stop
            if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400) {
                Write-NOk ("{0}: reachable ({1})" -f $Label, $Url)
                return
            }
            Write-NWarn ("{0}: unexpected status {1} for {2}" -f $Label, $resp.StatusCode, $Url)
        } catch {
            Write-NWarn ("{0}: not reachable from this shell (proxy/VPN/offline?) - {1}" -f $Label, $Url)
        }
    }
    Test-Url "https://github.com" "GitHub"
    Test-Url "https://api.github.com" "GitHub API"

    # ---- User profile writability ------------------------------------------
    if (-not $env:USERPROFILE) {
        Write-NMiss "USERPROFILE env var is not set"
    } elseif (-not (Test-Path $env:USERPROFILE)) {
        Write-NMiss ("USERPROFILE does not exist: {0}" -f $env:USERPROFILE)
    } else {
        $probe = Join-Path $env:USERPROFILE (".dots-workstation-prereq-probe-" + (Get-Random))
        try {
            Set-Content -Path $probe -Value "probe" -ErrorAction Stop
            Remove-Item $probe -ErrorAction SilentlyContinue
            Write-NOk ("USERPROFILE writable: {0}" -f $env:USERPROFILE)
        } catch {
            Write-NMiss ("USERPROFILE not writable: {0}" -f $env:USERPROFILE)
        }
    }

    # ---- Existing AI install footprint (informational) ---------------------
    $skillsDir = Join-Path $env:USERPROFILE ".local\share\agentic-workstation\skills"
    if (Test-Path $skillsDir) {
        $count = (Get-ChildItem -Path $skillsDir -Directory -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-NOk ("existing skills install detected: {0} ({1} top-level entries)" -f $skillsDir, $count)
    } else {
        Write-NNote ("no existing skills install at {0} (will be created by install-skills)" -f $skillsDir)
    }

    $toolDirs = @(
        (Join-Path $env:USERPROFILE ".claude\agents"),
        (Join-Path $env:APPDATA     "opencode\agents"),
        (Join-Path $env:USERPROFILE ".cursor\rules"),
        (Join-Path $env:USERPROFILE ".windsurf\rules")
    )
    foreach ($d in $toolDirs) {
        if (Test-Path $d) {
            Write-NOk ("existing tool dir: {0}" -f $d)
        }
    }
    $copilotFile = Join-Path $env:USERPROFILE ".github\copilot-instructions.md"
    if (Test-Path $copilotFile) {
        Write-NOk ("existing Copilot instructions: {0}" -f $copilotFile)
    }

    # ---- Summary ------------------------------------------------------------
    Write-NNote ""
    if ($script:Missing -eq 0) {
        Write-NNote ("AI install prereq check: READY (warnings: {0})" -f $script:Warns)
        exit 0
    } else {
        Write-NNote "AI install prereq check: NOT READY - fix MISSING items above"
        exit 1
    }
} catch {
    Write-Host ("[check-ai-install-prereqs] ERROR: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 2
}
