<#
    .SYNOPSIS
    Diagnostics for a Skillable lab VM: hardware, installed tooling,
    and AutoCAD/Civil 3D presence, plus a resulting Ollama model
    recommendation. Safe to run standalone, any number of times.

    .DESCRIPTION
    Run this first on any VM - before Provision-LabVM.ps1, and again
    afterward to confirm the result. Prints a PASS/WARN/FAIL summary
    and writes a timestamped JSON + text report under
    $env:ProgramData\LabSession\diagnostics\ so a facilitator can
    screenshot or archive it.

    .EXAMPLE
    .\Test-LabVMSpecs.ps1
#>

[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot 'lib\Common.ps1')
. (Join-Path $PSScriptRoot 'lib\ModelDecision.ps1')

$results = [ordered]@{
    Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
}
$warnings = @()
$failures = @()

Write-LabLog 'Starting lab VM diagnostics...' -Level Info

# --- CPU -----------------------------------------------------------------
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$results.CpuName            = $cpu.Name
$results.CpuPhysicalCores   = $cpu.NumberOfCores
$results.CpuLogicalProcessors = $cpu.NumberOfLogicalProcessors
if ($cpu.NumberOfCores -lt 4) {
    $warnings += "Only $($cpu.NumberOfCores) physical CPU cores - local model inference will be slow."
}

# --- RAM -------------------------------------------------------------------
$cs = Get-CimInstance Win32_ComputerSystem
$totalRamGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
$results.TotalRamGB = $totalRamGB
try {
    $availMB = (Get-Counter '\Memory\Available MBytes' -ErrorAction Stop).CounterSamples[0].CookedValue
    $results.AvailableRamGB = [math]::Round($availMB / 1024, 1)
}
catch {
    $results.AvailableRamGB = $null
    $warnings += 'Could not read current available RAM (Get-Counter failed).'
}
if ($totalRamGB -lt 8) {
    $warnings += "Only ${totalRamGB}GB total RAM - stick to the smallest model tier and expect a tight session with AutoCAD + VS Code + Ollama all running."
}

# --- GPU -------------------------------------------------------------------
$gpus = Get-CimInstance Win32_VideoController
$hasDedicatedGpu = $false
$vramGB = 0
$gpuNames = @()
foreach ($gpu in $gpus) {
    $gpuNames += $gpu.Name
    if ($gpu.AdapterRAM -and $gpu.AdapterRAM -gt 0) {
        $thisVramGB = [math]::Round($gpu.AdapterRAM / 1GB, 1)
        if ($gpu.Name -notmatch 'Microsoft (Basic|Remote) Display|RDP|Citrix|Parsec') {
            $hasDedicatedGpu = $true
            if ($thisVramGB -gt $vramGB) { $vramGB = $thisVramGB }
        }
    }
}
$results.GpuNames = $gpuNames -join ', '
$results.HasDedicatedGpu = $hasDedicatedGpu
$results.VramGB = $vramGB
if (-not $hasDedicatedGpu) {
    Write-LabLog 'No dedicated GPU detected - CPU inference only (expected on most Skillable VMs).' -Level Info
}

# --- Disk ------------------------------------------------------------------
$sysDrive = Get-PSDrive -Name ($env:SystemDrive.TrimEnd(':')) -ErrorAction SilentlyContinue
$freeDiskGB = if ($sysDrive) { [math]::Round($sysDrive.Free / 1GB, 1) } else { $null }
$results.FreeDiskGB = $freeDiskGB
if ($null -ne $freeDiskGB -and $freeDiskGB -lt 15) {
    $failures += "Only ${freeDiskGB}GB free disk space - Ollama models + VS Code extensions need headroom. Free up space before provisioning."
}

# --- Tooling presence --------------------------------------------------------
$results.OllamaVersion  = Get-InstalledVersion -Name 'ollama' -VersionFlag '-v'
$results.VSCodeVersion  = Get-InstalledVersion -Name 'code' -VersionFlag '--version'
$results.GitVersion     = Get-InstalledVersion -Name 'git' -VersionFlag '--version'
$results.ClaudeCodeVersion = Get-InstalledVersion -Name 'claude' -VersionFlag '--version'
$results.ContinueInstalled = $false
if (Test-CommandExists 'code') {
    try {
        $extensions = & code --list-extensions 2>&1
        $results.ContinueInstalled = ($extensions -match 'continue\.continue').Count -gt 0
    }
    catch {
        $results.ContinueInstalled = $false
    }
}

foreach ($tool in @('OllamaVersion', 'VSCodeVersion', 'GitVersion')) {
    if (-not $results[$tool]) {
        $warnings += "$tool not detected - run Provision-LabVM.ps1 to install it."
    }
}
if (-not $results.ContinueInstalled) {
    $warnings += 'Continue.dev VS Code extension not detected.'
}

# --- AutoCAD / Civil 3D presence --------------------------------------------
function Test-AutodeskProductInstalled {
    param([Parameter(Mandatory)][string]$NameMatch)
    $uninstallPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($path in $uninstallPaths) {
        $hit = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "*$NameMatch*" } |
            Select-Object -First 1
        if ($hit) { return $hit.DisplayName }
    }
    return $null
}

$results.AutoCADDetected  = Test-AutodeskProductInstalled -NameMatch 'AutoCAD 2026'
$results.Civil3DDetected  = Test-AutodeskProductInstalled -NameMatch 'Civil 3D 2026'
if (-not $results.AutoCADDetected) { $failures += 'AutoCAD 2026 not detected via registry - confirm this is the correct lab VM image.' }
if (-not $results.Civil3DDetected) { $failures += 'Civil 3D 2026 not detected via registry - confirm this is the correct lab VM image.' }

# --- Model recommendation ---------------------------------------------------
$recommendation = Get-RecommendedOllamaModel -RamGB $totalRamGB -HasDedicatedGpu $hasDedicatedGpu -VramGB $vramGB
$results.RecommendedChatModel         = $recommendation.ChatModel
$results.RecommendedQualityChatModel  = $recommendation.QualityChatModel
$results.RecommendedAutocompleteModel = $recommendation.AutocompleteModel
$results.ModelReasoning               = $recommendation.Reasoning
$results.SupportsAgenticCli           = $recommendation.SupportsAgenticCli

if ($results.SupportsAgenticCli -and -not $results.ClaudeCodeVersion) {
    $warnings += 'Claude Code CLI not detected - run Provision-LabVM.ps1 to install it (optional, only offered on this VM tier).'
}

# --- Report ------------------------------------------------------------------
$status = if ($failures.Count -gt 0) { 'FAIL' } elseif ($warnings.Count -gt 0) { 'WARN' } else { 'PASS' }
$statusColor = switch ($status) { 'FAIL' { 'Red' }; 'WARN' { 'Yellow' }; default { 'Green' } }

Write-Host "`n=== Lab VM Diagnostics Summary: $status ===" -ForegroundColor $statusColor
Write-Host "CPU:              $($results.CpuName) ($($results.CpuPhysicalCores) cores / $($results.CpuLogicalProcessors) logical)"
Write-Host "RAM:              $($results.TotalRamGB) GB total, $($results.AvailableRamGB) GB available now"
Write-Host "GPU:              $($results.GpuNames) [dedicated: $($results.HasDedicatedGpu), VRAM: $($results.VramGB) GB]"
Write-Host "Free disk:        $($results.FreeDiskGB) GB"
Write-Host "Ollama:           $(if ($results.OllamaVersion) { $results.OllamaVersion } else { 'NOT INSTALLED' })"
Write-Host "VS Code:          $(if ($results.VSCodeVersion) { $results.VSCodeVersion } else { 'NOT INSTALLED' })"
Write-Host "Continue.dev:     $(if ($results.ContinueInstalled) { 'installed' } else { 'NOT INSTALLED' })"
Write-Host "Git:              $(if ($results.GitVersion) { $results.GitVersion } else { 'NOT INSTALLED' })"
Write-Host "Claude Code CLI:  $(if ($results.ClaudeCodeVersion) { $results.ClaudeCodeVersion } else { 'not installed (optional)' })"
Write-Host "AutoCAD 2026:     $(if ($results.AutoCADDetected) { 'detected' } else { 'NOT DETECTED' })"
Write-Host "Civil 3D 2026:    $(if ($results.Civil3DDetected) { 'detected' } else { 'NOT DETECTED' })"
Write-Host "`nRecommended chat model (fast, default): $($results.RecommendedChatModel)"
if ($results.RecommendedQualityChatModel) {
    Write-Host "Quality model (opt-in, slower):          $($results.RecommendedQualityChatModel)"
}
Write-Host "Recommended autocomplete model:          $($results.RecommendedAutocompleteModel)"
Write-Host "Local Claude Code CLI offered:            $($results.SupportsAgenticCli)"
Write-Host "Reasoning: $($results.ModelReasoning)`n"

if ($warnings.Count -gt 0) {
    Write-Host '--- Warnings ---' -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}
if ($failures.Count -gt 0) {
    Write-Host '--- Failures ---' -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

$results.Status   = $status
$results.Warnings = $warnings
$results.Failures = $failures

$diagDir = Join-Path $env:ProgramData 'LabSession\diagnostics'
if (-not (Test-Path $diagDir)) { New-Item -ItemType Directory -Path $diagDir -Force | Out-Null }
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$jsonPath = Join-Path $diagDir "specs-$stamp.json"
$results | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath -Encoding UTF8
Write-LabLog "Full diagnostics report written to $jsonPath" -Level Info

return $results
