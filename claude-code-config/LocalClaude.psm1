<#
    LocalClaude - launches the real Claude Code CLI pointed at a local
    Ollama model instead of Anthropic's cloud API, and lets an attendee
    switch between a fast/quality local model, a real Anthropic account,
    or (experimental) a LiteLLM gateway to a non-Anthropic backend - see
    gateway-mode in LiteLLMGateway.psm1. Optional/advanced path, see
    claude-code-config/README.md and claude-code-config/CLAUDE.md.

    LAB_AGENT_MODEL_FAST / LAB_AGENT_MODEL_QUALITY are static facts about
    this VM's hardware tier, set once by Provision-LabVM.ps1 and safe to
    re-set on every new shell. The CURRENTLY SELECTED model is mutable
    state, not a fact - its source of truth is ~/.claude/settings.json's
    "model" field, which Set-LabModel updates and a new shell must not
    silently reset.

    JSON settings helpers live in ClaudeSettingsHelpers.psm1 (shared with
    LiteLLMGateway.psm1's gateway-mode) so all three modes mutate
    ~/.claude/settings.json through one tested code path. Continue.dev
    config helpers live in ContinueConfigHelpers.psm1 (shared with
    ContinueProviders.psm1's continue-provider).
#>

Import-Module (Join-Path $PSScriptRoot 'ClaudeSettingsHelpers.psm1') -Force

# Provisioning copies ContinueConfigHelpers.psm1 alongside this file into
# the installed module folder (see Provision-LabVM.ps1 Steps 9-10), but in
# the source repo it lives in the sibling continue-config/ folder instead -
# resolve whichever location actually has it.
$continueConfigHelpersPath = Join-Path $PSScriptRoot 'ContinueConfigHelpers.psm1'
if (-not (Test-Path $continueConfigHelpersPath)) {
    $continueConfigHelpersPath = Join-Path $PSScriptRoot '..\continue-config\ContinueConfigHelpers.psm1'
}
Import-Module $continueConfigHelpersPath -Force

function Get-CurrentAgentModel {
    param([string]$Root = $HOME)
    $settings = Get-JsonFileSettings -Path (Get-ClaudeSettingsPath -Root $Root)
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
        [Parameter(Mandatory)][ValidateSet('Fast', 'Quality')][string]$Tier,
        [string]$Root = $HOME
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

    $claudeSettingsPath = Get-ClaudeSettingsPath -Root $Root
    $settings = Get-JsonFileSettings -Path $claudeSettingsPath
    if ($settings) {
        Set-JsonProperty -Object $settings -Name 'model' -Value $model
        Save-JsonFileSettings -Path $claudeSettingsPath -Settings $settings
    }

    Set-ContinueConfigModelTag -EntryName 'Lab Assistant (Ollama)' -NewModel $model -Path (Get-ContinueConfigPath -Root $Root)

    Write-Host "Switched to the $Tier model: $model (Claude Code CLI, VS Code extension, and Continue.dev all updated)." -ForegroundColor Green
    if ($Tier -eq 'Quality') {
        Write-Host "This is the bigger model - expect noticeably slower responses on this VM's GPU. Switch back any time with 'fast-model'." -ForegroundColor Yellow
    }
}

function Get-PulledOllamaModelTags {
    <#
        .SYNOPSIS
        Parses `ollama list` into a de-duplicated array of model tags
        (first column, header row skipped). Returns @() if Ollama isn't
        installed, isn't running, or nothing is pulled yet.
    #>
    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) { return @() }
    $raw = & ollama list 2>&1
    if ($LASTEXITCODE -ne 0 -or -not $raw) { return @() }
    $lines = @($raw | ForEach-Object { $_.ToString() } | Where-Object { $_.Trim() })
    if ($lines.Count -le 1) { return @() }
    $tags = $lines | Select-Object -Skip 1 | ForEach-Object { ($_ -split '\s+')[0] } | Where-Object { $_ }
    return @($tags | Select-Object -Unique)
}

function Set-LabModelByTag {
    <#
        .SYNOPSIS
        Switches Claude Code (CLI + VS Code extension) and Continue.dev to
        any locally pulled Ollama model tag, not just the fast/quality
        pair fast-model/quality-model offer. Same underlying mechanism as
        Set-LabModel: ~/.claude/settings.json's "model" field, and the
        "Lab Assistant (Ollama)" block in ~/.continue/config.yaml.

        .PARAMETER Model
        Set an exact tag directly, no prompt - for scripting/testing, or
        a power user who already knows the tag. Without it, lists what's
        locally pulled and prompts for a choice.

        .EXAMPLE
        switch-model
        switch-model -Model qwen2.5-coder:7b
    #>
    param(
        [string]$Model,
        [string]$Root = $HOME
    )

    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        Write-Error 'Set-LabModelByTag: Ollama is not installed.'
        return
    }

    $pulledModels = Get-PulledOllamaModelTags
    if ($pulledModels.Count -eq 0) {
        Write-Error "Set-LabModelByTag: no models are pulled yet ('ollama list' returned none). Run 'ollama pull <tag>' first."
        return
    }

    if ($Model) {
        $chosenModel = $Model
        if ($pulledModels -notcontains $Model) {
            Write-Warning "Set-LabModelByTag: '$Model' isn't in 'ollama list' - continuing anyway; Ollama itself will error if it's genuinely not pulled."
        }
    }
    else {
        Write-Host 'Locally pulled Ollama models:' -ForegroundColor Cyan
        for ($i = 0; $i -lt $pulledModels.Count; $i++) {
            Write-Host ("  [{0}] {1}" -f ($i + 1), $pulledModels[$i])
        }
        $selection = Read-Host "Pick a model (1-$($pulledModels.Count))"
        $index = 0
        if (-not [int]::TryParse($selection, [ref]$index) -or $index -lt 1 -or $index -gt $pulledModels.Count) {
            Write-Error "Set-LabModelByTag: '$selection' is not a valid choice."
            return
        }
        $chosenModel = $pulledModels[$index - 1]
    }

    $claudeSettingsPath = Get-ClaudeSettingsPath -Root $Root
    $settings = Get-JsonFileSettings -Path $claudeSettingsPath
    if ($settings) {
        Set-JsonProperty -Object $settings -Name 'model' -Value $chosenModel
        Save-JsonFileSettings -Path $claudeSettingsPath -Settings $settings
    }

    Set-ContinueConfigModelTag -EntryName 'Lab Assistant (Ollama)' -NewModel $chosenModel -Path (Get-ContinueConfigPath -Root $Root)

    Write-Host "Switched to model: $chosenModel (Claude Code CLI, VS Code extension, and Continue.dev all updated)." -ForegroundColor Green
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
    param([string]$Root = $HOME)

    $claudeSettingsPath = Get-ClaudeSettingsPath -Root $Root
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
    param([string]$Root = $HOME)

    $claudeSettingsPath = Get-ClaudeSettingsPath -Root $Root
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
Set-Alias -Name switch-model -Value Set-LabModelByTag
Set-Alias -Name cloud-mode -Value Enable-CloudClaude
Set-Alias -Name local-mode -Value Enable-LocalClaude

Export-ModuleMember -Function Start-LocalClaude, Set-LabModel, Set-LabModelByTag, Get-PulledOllamaModelTags, Enable-CloudClaude, Enable-LocalClaude, Set-LabModel-Fast, Set-LabModel-Quality `
    -Alias claude-local, fast-model, quality-model, switch-model, cloud-mode, local-mode
