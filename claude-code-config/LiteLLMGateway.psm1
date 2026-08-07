<#
    LiteLLMGateway - EXPERIMENTAL. Lets the real Claude Code CLI itself
    (not just Continue.dev) reach a non-Anthropic backend (OpenAI, Gemini,
    or a custom OpenAI-compatible endpoint like Kimi/Moonshot) by running
    a local LiteLLM proxy that speaks the Anthropic Messages API and
    translates to the chosen backend - the same ANTHROPIC_BASE_URL trick
    already used to reach local Ollama, just pointed at a different local
    server.

    This is a real extra dependency this repo has never needed before
    (Python + `pip install 'litellm[proxy]'`, a background process to
    keep running) - never installed by Provision-LabVM.ps1, take-home
    only, and every function here fails loudly with an actionable message
    rather than silently if the prerequisites aren't met. See
    claude-code-config/README.md's "Gateway mode (experimental)" section.

    Shares ClaudeSettingsHelpers.psm1 with LocalClaude.psm1's
    local-mode/cloud-mode, so all three modes mutate
    ~/.claude/settings.json through one tested code path and stay
    naturally mutually exclusive (last write wins).
#>

Import-Module (Join-Path $PSScriptRoot 'ClaudeSettingsHelpers.psm1') -Force

function Test-LiteLLMPrereqs {
    <#
        .SYNOPSIS
        Confirms Python and the litellm[proxy] package are available.
        Throws a clear, actionable error rather than failing silently -
        gateway-mode is optional, so a missing dependency should never be
        mistaken for a bug in this module.
    #>
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
    if (-not $python) {
        throw "Gateway mode requires Python 3.9+, which isn't on PATH. Install it from https://python.org (check 'Add to PATH' during install), then: pip install 'litellm[proxy]'. This is optional/experimental - local-mode and cloud-mode do not need Python."
    }

    $pipShow = & $python.Source -m pip show litellm 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Gateway mode requires the litellm[proxy] package, which isn't installed. Run: $($python.Source) -m pip install 'litellm[proxy]'. This is optional/experimental - local-mode and cloud-mode do not need it."
    }

    return $python.Source
}

function Install-LiteLLMGatewayConfig {
    <#
        .SYNOPSIS
        Renders claude-code-config/litellm-config.yaml.template into
        ~/.claude-lab/litellm-config.yaml for the chosen backend.
    #>
    param(
        [Parameter(Mandatory)][ValidateSet('OpenAI', 'Gemini', 'Anthropic', 'CustomOpenAICompatible')][string]$Backend,
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][string]$ApiKey,
        [string]$ApiBase,
        [string]$MasterKey,
        [string]$OllamaModel = $env:LAB_AGENT_MODEL_FAST,
        [string]$Root = $HOME,
        [string]$RepoRoot
    )

    if ($Backend -eq 'CustomOpenAICompatible' -and -not $ApiBase) {
        throw "Install-LiteLLMGatewayConfig: -ApiBase is required for -Backend CustomOpenAICompatible (e.g. https://api.moonshot.ai/v1 for Kimi)."
    }
    if (-not $OllamaModel) { $OllamaModel = 'qwen3.5:4b' }
    if (-not $MasterKey) { $MasterKey = "lab-$([guid]::NewGuid().ToString('N'))" }

    $litellmPrefix = if ($Backend -eq 'CustomOpenAICompatible') { 'openai' } else { $Backend.ToLower() }
    $backendLiteLLMModel = "$litellmPrefix/$Model"
    $apiBaseLine = if ($ApiBase) { "      api_base: $ApiBase" } else { '' }

    if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent $PSScriptRoot }
    $templatePath = Join-Path $RepoRoot 'claude-code-config\litellm-config.yaml.template'
    if (-not (Test-Path $templatePath)) {
        # Installed modules are self-contained copies (see Provision-LabVM.ps1
        # Steps 9-10) - the template is copied alongside this module too.
        $templatePath = Join-Path $PSScriptRoot 'litellm-config.yaml.template'
    }

    $rendered = (Get-Content -Path $templatePath -Raw) `
        -replace '\{\{OLLAMA_CHAT_MODEL\}\}', $OllamaModel `
        -replace '\{\{BACKEND_MODEL_NAME\}\}', $Model `
        -replace '\{\{BACKEND_LITELLM_MODEL\}\}', $backendLiteLLMModel `
        -replace '\{\{BACKEND_API_KEY\}\}', $ApiKey `
        -replace '\{\{BACKEND_API_BASE_LINE\}\}', $apiBaseLine `
        -replace '\{\{LITELLM_MASTER_KEY\}\}', $MasterKey

    $configPath = Join-Path $Root '.claude-lab\litellm-config.yaml'
    $configDir = Split-Path -Parent $configPath
    if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
    Set-Content -Path $configPath -Value $rendered -Encoding UTF8

    return @{ ConfigPath = $configPath; MasterKey = $MasterKey }
}

function Start-LiteLLMGateway {
    <#
        .SYNOPSIS
        Starts `litellm --config <path>` detached and health-checks it.
        Requires Install-LiteLLMGatewayConfig to have run first.
    #>
    param(
        [string]$ConfigPath = (Join-Path $HOME '.claude-lab\litellm-config.yaml'),
        [int]$Port = 4000
    )

    $python = Test-LiteLLMPrereqs
    if (-not (Test-Path $ConfigPath)) {
        throw "Start-LiteLLMGateway: $ConfigPath doesn't exist - run Install-LiteLLMGatewayConfig first."
    }

    Write-Host "Starting the LiteLLM gateway on port $Port (config: $ConfigPath)..." -ForegroundColor Cyan
    Start-Process -FilePath $python -ArgumentList @('-m', 'litellm', '--config', "`"$ConfigPath`"", '--port', $Port) -WindowStyle Minimized

    $healthy = $false
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Seconds 1
        try {
            $null = Invoke-WebRequest -Uri "http://localhost:$Port/health/liveliness" -TimeoutSec 2 -ErrorAction Stop
            $healthy = $true
            break
        }
        catch { }
    }
    if ($healthy) {
        Write-Host "LiteLLM gateway is up on http://localhost:$Port." -ForegroundColor Green
    }
    else {
        Write-Warning "Start-LiteLLMGateway: gateway didn't respond on http://localhost:$Port within 10s - it may still be starting, or the port may already be in use. Check the LiteLLM window."
    }
}

function Enable-GatewayClaude {
    <#
        .SYNOPSIS
        EXPERIMENTAL. One-command setup: checks prerequisites, renders
        the LiteLLM config for the chosen backend, starts the gateway,
        and points the Claude Code CLI + VS Code extension at it - the
        same env-block mechanism local-mode/cloud-mode already use, so
        switching modes stays mutually exclusive (last write wins).

        .EXAMPLE
        gateway-mode -Backend OpenAI -Model gpt-4.1
        gateway-mode -Backend CustomOpenAICompatible -Model kimi-k2 -ApiBase https://api.moonshot.ai/v1
    #>
    param(
        [Parameter(Mandatory)][ValidateSet('OpenAI', 'Gemini', 'Anthropic', 'CustomOpenAICompatible')][string]$Backend,
        [Parameter(Mandatory)][string]$Model,
        [string]$ApiKey,
        [string]$ApiBase,
        [int]$Port = 4000,
        [string]$Root = $HOME
    )

    Test-LiteLLMPrereqs | Out-Null

    if (-not $ApiKey) {
        $secureKey = Read-Host -Prompt "API key for $Backend" -AsSecureString
        $ApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
        )
    }
    if (-not $ApiKey) {
        Write-Error 'Enable-GatewayClaude: no API key given - aborting.'
        return
    }

    $install = Install-LiteLLMGatewayConfig -Backend $Backend -Model $Model -ApiKey $ApiKey -ApiBase $ApiBase -Root $Root
    Start-LiteLLMGateway -ConfigPath $install.ConfigPath -Port $Port

    $claudeSettingsPath = Get-ClaudeSettingsPath -Root $Root
    $settings = Get-JsonFileSettings -Path $claudeSettingsPath
    if ($settings) {
        if (-not ($settings.PSObject.Properties.Name -contains 'env')) {
            $settings | Add-Member -NotePropertyName 'env' -NotePropertyValue ([PSCustomObject]@{})
        }
        Set-JsonProperty -Object $settings.env -Name 'ANTHROPIC_BASE_URL' -Value "http://localhost:$Port"
        Set-JsonProperty -Object $settings.env -Name 'ANTHROPIC_AUTH_TOKEN' -Value $install.MasterKey
        Set-JsonProperty -Object $settings.env -Name 'ANTHROPIC_API_KEY' -Value ''
        Save-JsonFileSettings -Path $claudeSettingsPath -Settings $settings
    }

    $vscodeSettingsPath = Get-VSCodeSettingsPath
    $vscodeSettings = Get-JsonFileSettings -Path $vscodeSettingsPath
    if ($vscodeSettings) {
        Set-JsonProperty -Object $vscodeSettings -Name 'claudeCode.disableLoginPrompt' -Value $true
        Save-JsonFileSettings -Path $vscodeSettingsPath -Settings $vscodeSettings
    }

    Write-Host "Switched Claude Code to gateway mode: $Backend / $Model via the local LiteLLM proxy." -ForegroundColor Green
    Write-Host "The gateway must keep running for this to work - it does not survive a reboot on its own. Re-run gateway-mode after restarting your PC." -ForegroundColor Yellow
    Write-Host "Switch back to the free local model any time with 'local-mode', or to a real Anthropic account with 'cloud-mode'." -ForegroundColor Yellow
}

Set-Alias -Name gateway-mode -Value Enable-GatewayClaude

Export-ModuleMember -Function Test-LiteLLMPrereqs, Install-LiteLLMGatewayConfig, Start-LiteLLMGateway, Enable-GatewayClaude `
    -Alias gateway-mode
