<#
    ClaudeSettingsHelpers - shared, merge-safe JSON config helpers for
    Claude Code's settings.json and VS Code's settings.json. Used by
    LocalClaude.psm1 (local-mode/cloud-mode) and LiteLLMGateway.psm1
    (gateway-mode), so all three modes mutate config through one tested
    code path instead of three separate copies.

    Every path-resolving function takes an optional -Root override instead
    of relying on $env:HOME - $env:HOME does NOT override PowerShell's
    $HOME automatic variable on Windows (it's derived from $env:USERPROFILE
    only), so code that assumed otherwise previously mutated a real
    settings.json during testing. Tests must pass -Root explicitly.
#>

function Get-ClaudeSettingsPath {
    param([string]$Root = $HOME)
    Join-Path $Root '.claude\settings.json'
}

function Get-VSCodeSettingsPath {
    param([string]$Root = $env:APPDATA)
    Join-Path $Root 'Code\User\settings.json'
}

function Get-JsonFileSettings {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { return [PSCustomObject]@{} }
    try { return (Get-Content -Path $Path -Raw | ConvertFrom-Json) }
    catch {
        Write-Warning "Could not parse $Path as JSON - leaving it untouched."
        return $null
    }
}

function Write-Utf8NoBom {
    <#
        .SYNOPSIS
        Writes text as UTF-8 WITHOUT a byte-order mark on every PowerShell
        version. `Set-Content -Encoding UTF8` writes a BOM on Windows
        PowerShell 5.1, and Node's JSON.parse (Claude Code, the Continue
        extension) rejects a BOM - so every JSON/YAML config write must go
        through here instead.
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (-not $Content.EndsWith("`n")) { $Content += "`n" }
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Save-JsonFileSettings {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)]$Settings)
    Write-Utf8NoBom -Path $Path -Content ($Settings | ConvertTo-Json -Depth 10)
}

function Set-JsonProperty {
    param($Object, [string]$Name, $Value)
    if ($Object.PSObject.Properties.Name -contains $Name) { $Object.$Name = $Value }
    else { $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value }
}

function Set-JsonPropertyIfUnset {
    <#
        .SYNOPSIS
        Like Set-JsonProperty, but only when the property is absent or
        empty. Exists so provisioning/local-mode can never blank out a
        real value a user already has - most importantly an existing
        ANTHROPIC_API_KEY in ~/.claude/settings.json.
    #>
    param($Object, [string]$Name, $Value)
    if ($Object.PSObject.Properties.Name -contains $Name -and $Object.$Name) { return }
    Set-JsonProperty -Object $Object -Name $Name -Value $Value
}

function Backup-ClaudeSettings {
    <#
        .SYNOPSIS
        Copies ~/.claude/settings.json to a timestamped
        settings.json.pre-lab-*.bak next to it, once: if any pre-lab
        backup already exists, later calls no-op so re-runs can never
        overwrite the pristine pre-lab state. Call before the first
        mutation. No-ops when there is nothing to back up.
    #>
    param([string]$Root = $HOME)
    $settingsPath = Get-ClaudeSettingsPath -Root $Root
    if (-not (Test-Path $settingsPath)) { return }
    $existing = Get-ChildItem -Path (Split-Path -Parent $settingsPath) -Filter 'settings.json.pre-lab-*.bak' -ErrorAction SilentlyContinue
    if ($existing) { return }
    $backupPath = "$settingsPath.pre-lab-$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"
    Copy-Item -Path $settingsPath -Destination $backupPath -Force
    Write-Host "Backed up your existing Claude settings to $backupPath - 'restore-claude-settings' puts them back." -ForegroundColor Yellow
}

function Restore-ClaudeSettings {
    <#
        .SYNOPSIS
        Restores ~/.claude/settings.json byte-identically from the newest
        settings.json.pre-lab-*.bak made by Backup-ClaudeSettings.

        .EXAMPLE
        restore-claude-settings
    #>
    param([string]$Root = $HOME)
    $settingsPath = Get-ClaudeSettingsPath -Root $Root
    $backup = Get-ChildItem -Path (Split-Path -Parent $settingsPath) -Filter 'settings.json.pre-lab-*.bak' -ErrorAction SilentlyContinue |
        Sort-Object Name | Select-Object -Last 1
    if (-not $backup) {
        Write-Error "Restore-ClaudeSettings: no settings.json.pre-lab-*.bak found next to $settingsPath - nothing was ever backed up (a machine with no settings.json before the lab setup has no backup; use cloud-mode to strip the lab keys instead)."
        return
    }
    Copy-Item -Path $backup.FullName -Destination $settingsPath -Force
    Write-Host "Restored $settingsPath from $($backup.Name)." -ForegroundColor Green
}

function Remove-JsonProperty {
    param($Object, [string]$Name)
    if ($Object.PSObject.Properties.Name -contains $Name) { $Object.PSObject.Properties.Remove($Name) }
}

Set-Alias -Name restore-claude-settings -Value Restore-ClaudeSettings

Export-ModuleMember -Function Get-ClaudeSettingsPath, Get-VSCodeSettingsPath, Get-JsonFileSettings, `
    Save-JsonFileSettings, Set-JsonProperty, Set-JsonPropertyIfUnset, Remove-JsonProperty, `
    Write-Utf8NoBom, Backup-ClaudeSettings, Restore-ClaudeSettings `
    -Alias restore-claude-settings
