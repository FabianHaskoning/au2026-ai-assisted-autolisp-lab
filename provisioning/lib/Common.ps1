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

function Install-ViaWinget {
    <#
        .SYNOPSIS
        Idempotent winget install: skips if $CommandToCheck already
        resolves, otherwise installs $WingetId. Distinguishes a genuine
        winget failure from "installed, just not on PATH in this shell
        yet" by checking $LASTEXITCODE - winget is a native command, so a
        real failure returns a non-zero exit code rather than throwing a
        .NET exception, and a plain try/catch around it never catches
        that (confirmed by a real-world run where a silently-failed
        Ollama install was misreported as "just needs a new shell").
        Appends to the caller's $script:installed/skipped/failed/
        needsNewShell collections (works via dot-sourcing, same as
        Write-LabLog's $script:LabLogDir).
    #>
    param(
        [Parameter(Mandatory)][string]$DisplayName,
        [Parameter(Mandatory)][string]$WingetId,
        [Parameter(Mandatory)][string]$CommandToCheck
    )
    if (Test-CommandExists $CommandToCheck) {
        Write-LabLog "$DisplayName already installed - skipping." -Level Info
        $script:skipped += $DisplayName
        return
    }
    Write-LabLog "Installing $DisplayName via winget..." -Level Info
    try {
        winget install --id $WingetId --silent --accept-package-agreements --accept-source-agreements | Out-Null
        $wingetExitCode = $LASTEXITCODE
        if ($wingetExitCode -ne 0) {
            Write-LabLog "$DisplayName install failed (winget exit code $wingetExitCode). Run this yourself to see the full winget output and pick up any interactive prompt it needs: winget install --id $WingetId --accept-package-agreements --accept-source-agreements" -Level Error
            $script:failed += $DisplayName
            return
        }
        if (Test-CommandExists $CommandToCheck) {
            Write-LabLog "$DisplayName installed." -Level Success
            $script:installed += $DisplayName
        }
        else {
            Write-LabLog "${DisplayName}: winget reported success but '$CommandToCheck' still isn't on PATH in this shell - expected, will resolve in a new shell." -Level Warn
            $script:installed += $DisplayName
            $script:needsNewShell += $DisplayName
        }
    }
    catch {
        Write-LabLog "$DisplayName install failed: $($_.Exception.Message)" -Level Error
        $script:failed += $DisplayName
    }
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
