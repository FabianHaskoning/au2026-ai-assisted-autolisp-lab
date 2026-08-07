<#
    ContinueProviders - lets an attendee add their own AI backend to
    Continue.dev (Anthropic/OpenAI/Gemini, or a generic OpenAI-compatible
    endpoint for things like Kimi/Moonshot) alongside the free local
    Ollama model that's already configured. This is ADDITIVE, not a
    replacement: Ollama keeps working as the free fallback, and Continue's
    own chat-panel model-picker dropdown is how you switch between "Lab
    Assistant (Ollama)" and whatever you add here.

    GitHub Copilot is deliberately not an option - it doesn't expose an
    API Continue.dev can call into, so there's nothing to configure here.
    If you have Copilot, just use its own Copilot Chat panel side by side
    (optionally paste continue-config/rules/*.md into Copilot's own
    custom-instructions if you want the same governance rules).

    See continue-config/README.md for details and examples.
#>

Import-Module (Join-Path $PSScriptRoot 'ContinueConfigHelpers.psm1') -Force

function Add-ContinueProvider {
    <#
        .SYNOPSIS
        Adds (or refreshes) a model block in ~/.continue/config.yaml for
        an AI backend you already have access to, alongside the local
        Ollama default. Prompts for an API key if not supplied - never
        echoed or logged.

        .PARAMETER Provider
        Anthropic (Claude.ai/Console API key), OpenAI (ChatGPT Plus's own
        API key, or any OpenAI account), Gemini (Google AI Studio API
        key), or CustomOpenAICompatible for anything else that speaks the
        OpenAI Chat Completions API shape - this covers Kimi/Moonshot and
        similar services; pass -ApiBase for that one.

        .PARAMETER Model
        The exact model name/ID your account can use (e.g.
        "claude-sonnet-4-5", "gpt-4.1", "gemini-2.5-flash",
        "kimi-k2"). Required - these change over time, so this module
        deliberately doesn't guess a default that could go stale.

        .EXAMPLE
        continue-provider -Provider Anthropic -Model claude-sonnet-4-5

        .EXAMPLE
        continue-provider -Provider CustomOpenAICompatible -Model kimi-k2 -ApiBase https://api.moonshot.ai/v1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Anthropic', 'OpenAI', 'Gemini', 'CustomOpenAICompatible')]
        [string]$Provider,

        [Parameter(Mandatory)][string]$Model,
        [string]$ApiKey,
        [string]$ApiBase,
        [string]$Name,
        [string]$Root = $HOME
    )

    if ($Provider -eq 'CustomOpenAICompatible' -and -not $ApiBase) {
        Write-Error "Add-ContinueProvider: -ApiBase is required for -Provider CustomOpenAICompatible (e.g. https://api.moonshot.ai/v1 for Kimi)."
        return
    }

    if (-not $ApiKey) {
        $secureKey = Read-Host -Prompt "API key for $Provider" -AsSecureString
        $ApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
        )
    }
    if (-not $ApiKey) {
        Write-Error 'Add-ContinueProvider: no API key given - aborting, nothing was written.'
        return
    }

    $continueProvider = if ($Provider -eq 'CustomOpenAICompatible') { 'openai' } else { $Provider.ToLower() }
    $displayName = if ($Name) { $Name } else { "$Provider ($Model)" }

    $lines = @(
        "  - name: $displayName"
        "    provider: $continueProvider"
        "    model: `"$Model`""
        "    apiKey: `"$ApiKey`""
    )
    if ($ApiBase) { $lines += "    apiBase: $ApiBase" }
    $lines += '    roles:'
    $lines += '      - chat'
    $lines += '      - edit'

    $configPath = Get-ContinueConfigPath -Root $Root
    Set-ContinueConfigBlock -BlockId "Provider-$Provider" -Content $lines -ParentKey 'models' -Path $configPath

    Write-Host "Added '$displayName' to $configPath." -ForegroundColor Green
    Write-Host "Ollama remains available as a free fallback - switch models anytime via the model-picker dropdown in Continue's chat panel." -ForegroundColor Yellow
    Write-Host "The API key is stored in plain text in that file, same as Continue.dev normally does for a local config - it's your own file on your own machine." -ForegroundColor Yellow
}

Set-Alias -Name continue-provider -Value Add-ContinueProvider

Export-ModuleMember -Function Add-ContinueProvider -Alias continue-provider
