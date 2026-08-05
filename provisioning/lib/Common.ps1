<#
    Shared helpers for the lab provisioning/diagnostics scripts.
    Dot-source this file; it defines functions only, no side effects.
#>

$script:LabLogDir = Join-Path $env:ProgramData 'LabSession\logs'

function Write-LabLog {
    <#
        Writes a timestamped line to both the console and a per-day
        log file under $env:ProgramData\LabSession\logs, so a
        facilitator can check what happened on a VM after the fact.
    #>
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Info', 'Warn', 'Error', 'Success')][string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"

    $color = switch ($Level) {
        'Warn'    { 'Yellow' }
        'Error'   { 'Red' }
        'Success' { 'Green' }
        default   { 'Gray' }
    }
    Write-Host $line -ForegroundColor $color

    if (-not (Test-Path $script:LabLogDir)) {
        New-Item -ItemType Directory -Path $script:LabLogDir -Force | Out-Null
    }
    $logFile = Join-Path $script:LabLogDir "$(Get-Date -Format 'yyyy-MM-dd').log"
    Add-Content -Path $logFile -Value $line
}

function Test-CommandExists {
    <#
        Returns $true if a command is resolvable on PATH. Used to make
        every install step idempotent: skip if already present.
    #>
    param([Parameter(Mandatory)][string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-InstalledVersion {
    <#
        Runs `<command> <versionFlag>` and returns the trimmed output,
        or $null if the command doesn't exist or the call fails.
        Used for reporting only - never assume the output format.
    #>
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$VersionFlag = '--version'
    )

    if (-not (Test-CommandExists $Name)) {
        return $null
    }
    try {
        $output = & $Name $VersionFlag 2>&1
        return ($output | Select-Object -First 1).ToString().Trim()
    }
    catch {
        return $null
    }
}
