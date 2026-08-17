<#
    .SYNOPSIS
    Loads the lab's chat model into memory so the first real prompt of the
    session doesn't have to.

    .DESCRIPTION
    Measured on the lab VM: the first generate call after a boot took 90.7
    seconds, of which ~88 was loading the model off cold disk. Every call
    after that was ~2 seconds, and the model stayed resident across an idle
    gap - so this is a once-per-boot cost, not a recurring one.

    That cost lands in exactly the wrong place. An attendee boots their VM
    and the first thing Track 1 asks them to do is prompt the assistant.
    Ninety seconds of apparent nothing, on the one interaction that has to
    feel effortless.

    Provisioning installs this under $env:ProgramData\LabSession and runs it
    from a scheduled task at logon, so the load happens while the room is
    still listening to the opening talk.

    Deliberately silent and failure-tolerant: it runs unattended, and a
    warm-up that can't reach Ollama yet must never surface an error dialog
    to an attendee. It logs, and gives up.

    .EXAMPLE
    .\Warm-OllamaModel.ps1
#>

[CmdletBinding()]
param(
    [string]$Model,
    [int]$MaxWaitSeconds = 180
)

$ErrorActionPreference = 'Stop'
$labRoot = Join-Path $env:ProgramData 'LabSession'
$logFile = Join-Path $labRoot 'warm-model.log'

function Write-WarmLog {
    param([string]$Message)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    try {
        if (-not (Test-Path $labRoot)) { New-Item -ItemType Directory -Path $labRoot -Force | Out-Null }
        Add-Content -Path $logFile -Value $line
    }
    catch { }
    Write-Verbose $line
}

try {
    if (-not $Model) {
        # Written by Provision-LabVM.ps1 next to this script, so the warm-up
        # follows whatever model this VM's hardware tier actually chose.
        $configPath = Join-Path $labRoot 'warm-model.json'
        if (Test-Path $configPath) {
            $Model = (Get-Content -Path $configPath -Raw | ConvertFrom-Json).Model
        }
    }
    if (-not $Model) {
        Write-WarmLog 'No model configured - nothing to warm. Re-run Provision-LabVM.ps1.'
        return
    }

    # Ollama's service may not be listening yet this early after logon.
    # Poll rather than assume; giving up quietly is fine, the only cost is
    # that the first prompt pays the load itself.
    $deadline = (Get-Date).AddSeconds($MaxWaitSeconds)
    $ready = $false
    while ((Get-Date) -lt $deadline) {
        try {
            Invoke-RestMethod -Uri 'http://localhost:11434/api/tags' -Method Get -TimeoutSec 5 | Out-Null
            $ready = $true
            break
        }
        catch {
            Start-Sleep -Seconds 5
        }
    }
    if (-not $ready) {
        Write-WarmLog "Ollama did not answer within ${MaxWaitSeconds}s - skipping warm-up."
        return
    }

    Write-WarmLog "Warming $Model..."
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # An empty prompt makes Ollama load the model without generating - the
    # part that actually costs 90 seconds. keep_alive -1 pins it in memory
    # for the rest of the session.
    $body = @{ model = $Model; prompt = ''; stream = $false; keep_alive = -1 } | ConvertTo-Json
    Invoke-RestMethod -Uri 'http://localhost:11434/api/generate' -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 600 | Out-Null

    $stopwatch.Stop()
    Write-WarmLog "$Model resident after $([math]::Round($stopwatch.Elapsed.TotalSeconds, 1))s. First attendee prompt will not pay this."
}
catch {
    Write-WarmLog "Warm-up failed: $($_.Exception.Message). Not fatal - the first prompt will just be slow."
}
