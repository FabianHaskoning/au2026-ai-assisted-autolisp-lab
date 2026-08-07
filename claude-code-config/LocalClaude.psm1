<#
    LocalClaude - launches the real Claude Code CLI pointed at a local
    Ollama model instead of Anthropic's cloud API. Optional/advanced path,
    see claude-code-config/README.md and claude-code-config/CLAUDE.md.

    Reads the model tag from LAB_AGENT_MODEL (set by Provision-LabVM.ps1
    based on this VM's hardware), falling back to qwen3-coder:30b so this
    also works for local testing outside a fully provisioned VM.
#>

function Start-LocalClaude {
    <#
        .SYNOPSIS
        Runs `claude` with ANTHROPIC_* environment variables pointed at
        this VM's local Ollama server, so no Anthropic account or API
        key is used or needed.

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

    $model = if ($env:LAB_AGENT_MODEL) { $env:LAB_AGENT_MODEL } else { 'qwen3-coder:30b' }

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

Set-Alias -Name claude-local -Value Start-LocalClaude

Export-ModuleMember -Function Start-LocalClaude -Alias claude-local
