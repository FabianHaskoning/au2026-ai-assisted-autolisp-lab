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

function Save-JsonFileSettings {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)]$Settings)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $Settings | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
}

function Set-JsonProperty {
    param($Object, [string]$Name, $Value)
    if ($Object.PSObject.Properties.Name -contains $Name) { $Object.$Name = $Value }
    else { $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value }
}

function Remove-JsonProperty {
    param($Object, [string]$Name)
    if ($Object.PSObject.Properties.Name -contains $Name) { $Object.PSObject.Properties.Remove($Name) }
}

Export-ModuleMember -Function Get-ClaudeSettingsPath, Get-VSCodeSettingsPath, Get-JsonFileSettings, `
    Save-JsonFileSettings, Set-JsonProperty, Remove-JsonProperty
