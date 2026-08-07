<#
    LocalClaude - launches the real Claude Code CLI pointed at a local
    Ollama model instead of Anthropic's cloud API, and lets an attendee
    switch between a fast/quality local model or a real Anthropic account.
    Optional/advanced path, see claude-code-config/README.md and
    claude-code-config/CLAUDE.md.

    LAB_AGENT_MODEL_FAST / LAB_AGENT_MODEL_QUALITY are static facts about
    this VM's hardware tier, set once by Provision-LabVM.ps1 and safe to
    re-set on every new shell. The CURRENTLY SELECTED model is mutable
    state, not a fact - its source of truth is ~/.claude/settings.json's
    "model" field, which Set-LabModel updates and a new shell must not
    silently reset.
#>

function Get-ClaudeSettingsPath { Join-Path $HOME '.claude\settings.json' }
function Get-VSCodeSettingsPath { Join-Path $env:APPDATA 'Code\User\settings.json' }
function Get-ContinueConfigPath { Join-Path $HOME '.continue\config.yaml' }

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

function Get-CurrentAgentModel {
    $settings = Get-JsonFileSettings -Path (Get-ClaudeSettingsPath)
    if ($settings -and $settings.PSObject.Properties.Name -contains 'model' -and $settings.model) {
        return $settings.model
    }
    if ($env:LAB_AGENT_MODEL_FAST) { return $env:LAB_AGENT_MODEL_FAST }
    return 'qwen3.5:4b'
}

function Start-LocalClaude {
    <#
        .SYNOPSIS
        Runs `claude` with ANTHROPIC_* environment variables pointed at
        this VM's local Ollama server, so no Anthropic account or API
        key is used or needed. Uses whichever model is currently selected
        (see Set-LabModel / fast-model / quality-model).

        .EXAMPLE
        claude-local
    #>
    param(
        [Parameter(ValueFromRemainingArguments)][string[]]$RemainingArgs
    )

    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Error 'Start-LocalClaude: the claude CLI is not installed. Run Provision-LabVM.ps1, or install it yourself: irm https://claude.ai/install.ps1 | iex'
        return
    }
    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        Write-Error 'Start-LocalClaude: Ollama is not installed - it needs to be running for this to work.'
        return
    }

    $model = Get-CurrentAgentModel

    $pulledModels = & ollama list 2>&1
    if ($pulledModels -notmatch [regex]::Escape($model)) {
        Write-Warning "Start-LocalClaude: '$model' isn't pulled yet - this may hang or fail. Run: ollama pull $model"
    }

    Write-Host "Starting Claude Code with local model: $model (via Ollama, no Anthropic account used)" -ForegroundColor Cyan

    $env:ANTHROPIC_AUTH_TOKEN = 'ollama'
    $env:ANTHROPIC_API_KEY = ''
    $env:ANTHROPIC_BASE_URL = 'http://localhost:11434'

    & claude --model $model @RemainingArgs
}

function Set-LabModel {
    <#
        .SYNOPSIS
        Switches the model used by Claude Code (CLI + VS Code extension)
        and Continue.dev between the fast default and the quality opt-in
        for this VM's tier. Persists across new shells.

        .EXAMPLE
        fast-model
        quality-model
    #>
    param(
        [Parameter(Mandatory)][ValidateSet('Fast', 'Quality')][string]$Tier
    )

    $model = if ($Tier -eq 'Fast') { $env:LAB_AGENT_MODEL_FAST } else { $env:LAB_AGENT_MODEL_QUALITY }
    if (-not $model) {
        Write-Error "Set-LabModel: no $Tier model is configured for this VM tier (LAB_AGENT_MODEL_$($Tier.ToUpper()) is empty) - open a new shell, or this tier may not offer a quality upgrade."
        return
    }

    $pulledModels = & ollama list 2>&1
    if ($pulledModels -notmatch [regex]::Escape($model)) {
        Write-Warning "Set-LabModel: '$model' isn't pulled yet. Pulling now (this can take a while)..."
        & ollama pull $model
    }

    $claudeSettingsPath = Get-ClaudeSettingsPath
    $settings = Get-JsonFileSettings -Path $claudeSettingsPath
    if ($settings) {
        Set-JsonProperty -Object $settings -Name 'model' -Value $model
        Save-JsonFileSettings -Path $claudeSettingsPath -Settings $settings
    }

    $continueConfigPath = Get-ContinueConfigPath
    if (Test-Path $continueConfigPath) {
        $content = Get-Content -Path $continueConfigPath -Raw
        $updated = $content -replace '(name: Lab Assistant \(Ollama\)[\s\S]*?model: )"[^"]*"', "`$1`"$model`""
        Set-Content -Path $continueConfigPath -Value $updated -Encoding UTF8
    }

    Write-Host "Switched to the $Tier model: $model (Claude Code CLI, VS Code extension, and Continue.dev all updated)." -ForegroundColor Green
    if ($Tier -eq 'Quality') {
        Write-Host "This is the bigger model - expect noticeably slower responses on this VM's GPU. Switch back any time with 'fast-model'." -ForegroundColor Yellow
    }
}

function Enable-CloudClaude {
    <#
        .SYNOPSIS
        Switches Claude Code (CLI + VS Code extension) to Anthropic's real
        cloud API instead of the local Ollama model - for anyone who has,
        or wants to sign up for, their own Anthropic account. Does not
        affect Continue.dev, which stays local/Ollama-only.

        .EXAMPLE
        cloud-mode
    #>
    $claudeSettingsPath = Get-ClaudeSettingsPath
    $settings = Get-JsonFileSettings -Path $claudeSettingsPath
    if ($settings -and ($settings.PSObject.Properties.Name -contains 'env')) {
        foreach ($key in @('ANTHROPIC_AUTH_TOKEN', 'ANTHROPIC_API_KEY', 'ANTHROPIC_BASE_URL')) {
            Remove-JsonProperty -Object $settings.env -Name $key
        }
        Save-JsonFileSettings -Path $claudeSettingsPath -Settings $settings
    }

    $vscodeSettingsPath = Get-VSCodeSettingsPath
    $vscodeSettings = Get-JsonFileSettings -Path $vscodeSettingsPath
    if ($vscodeSettings) {
        Set-JsonProperty -Object $vscodeSettings -Name 'claudeCode.disableLoginPrompt' -Value $false
        Save-JsonFileSettings -Path $vscodeSettingsPath -Settings $vscodeSettings
    }

    Write-Host "Switched to Anthropic's cloud API. Open the Claude Code panel in VS Code (or run 'claude' in a new terminal) and sign in with your own account." -ForegroundColor Green
    Write-Host "Note: this only affects Claude Code, not Continue.dev - Continue.dev always uses the local Ollama model." -ForegroundColor Yellow
    Write-Host "Switch back any time with 'local-mode'." -ForegroundColor Yellow
}

function Enable-LocalClaude {
    <#
        .SYNOPSIS
        Switches Claude Code (CLI + VS Code extension) back to the local
        Ollama model, undoing Enable-CloudClaude.

        .EXAMPLE
        local-mode
    #>
    $claudeSettingsPath = Get-ClaudeSettingsPath
    $settings = Get-JsonFileSettings -Path $claudeSettingsPath
    if ($settings) {
        if (-not ($settings.PSObject.Properties.Name -contains 'env')) {
            $settings | Add-Member -NotePropertyName 'env' -NotePropertyValue ([PSCustomObject]@{})
        }
        Set-JsonProperty -Object $settings.env -Name 'ANTHROPIC_AUTH_TOKEN' -Value 'ollama'
        Set-JsonProperty -Object $settings.env -Name 'ANTHROPIC_API_KEY' -Value ''
        Set-JsonProperty -Object $settings.env -Name 'ANTHROPIC_BASE_URL' -Value 'http://localhost:11434'
        Save-JsonFileSettings -Path $claudeSettingsPath -Settings $settings
    }

    $vscodeSettingsPath = Get-VSCodeSettingsPath
    $vscodeSettings = Get-JsonFileSettings -Path $vscodeSettingsPath
    if ($vscodeSettings) {
        Set-JsonProperty -Object $vscodeSettings -Name 'claudeCode.disableLoginPrompt' -Value $true
        Save-JsonFileSettings -Path $vscodeSettingsPath -Settings $vscodeSettings
    }

    Write-Host "Switched back to the local Ollama model - no account needed." -ForegroundColor Green
}

function Set-LabModel-Fast { Set-LabModel -Tier Fast }
function Set-LabModel-Quality { Set-LabModel -Tier Quality }

Set-Alias -Name claude-local -Value Start-LocalClaude
Set-Alias -Name fast-model -Value Set-LabModel-Fast
Set-Alias -Name quality-model -Value Set-LabModel-Quality
Set-Alias -Name cloud-mode -Value Enable-CloudClaude
Set-Alias -Name local-mode -Value Enable-LocalClaude

Export-ModuleMember -Function Start-LocalClaude, Set-LabModel, Enable-CloudClaude, Enable-LocalClaude, Set-LabModel-Fast, Set-LabModel-Quality `
    -Alias claude-local, fast-model, quality-model, cloud-mode, local-mode
