<#
    .SYNOPSIS
    Idempotent provisioning for a lab VM: installs Git, VS Code, Ollama
    and the Continue.dev extension, pulls the right model for this
    VM's hardware, and bootstraps an attendee git workspace with the
    governance rules and git helpers wired in. On VMs with enough RAM,
    also installs the real Claude Code CLI wired to the local Ollama
    model (see claude-code-config/) as an optional, advanced path.

    .DESCRIPTION
    Safe to re-run any number of times - every step checks whether it's
    already done before doing it, so re-running after a partial failure
    (or just to re-test before Sept 16) never breaks anything.

    NOT meant to run against the real Skillable VM yet - author access
    to that VM is still being confirmed. Run this on a local test VM
    first, or hand it to whoever ends up provisioning the real one.

    .EXAMPLE
    .\Provision-LabVM.ps1
#>

[CmdletBinding()]
param()

$repoRoot = Split-Path -Parent $PSScriptRoot

. (Join-Path $PSScriptRoot 'lib\Common.ps1')
. (Join-Path $PSScriptRoot 'lib\ModelDecision.ps1')

$config = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot 'config\provisioning.config.psd1')

$installed = @()
$skipped   = @()
$failed    = @()

# --- Elevation check ---------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-LabLog 'This script needs to run elevated (Run as Administrator) for winget installs. Re-launch PowerShell as Administrator.' -Level Error
    return
}

function Install-ViaWinget {
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
        if (Test-CommandExists $CommandToCheck) {
            Write-LabLog "$DisplayName installed." -Level Success
            $script:installed += $DisplayName
        }
        else {
            Write-LabLog "${DisplayName}: winget reported success but '$CommandToCheck' still isn't on PATH - a new shell/PATH refresh may be needed." -Level Warn
            $script:failed += "$DisplayName (installed but not yet on PATH)"
        }
    }
    catch {
        Write-LabLog "$DisplayName install failed: $($_.Exception.Message)" -Level Error
        $script:failed += $DisplayName
    }
}

# --- Step 1: core tools -------------------------------------------------------
Install-ViaWinget -DisplayName 'Git for Windows' -WingetId 'Git.Git' -CommandToCheck 'git'
Install-ViaWinget -DisplayName 'VS Code'         -WingetId 'Microsoft.VisualStudioCode' -CommandToCheck 'code'
Install-ViaWinget -DisplayName 'Ollama'          -WingetId 'Ollama.Ollama' -CommandToCheck 'ollama'

# --- Step 2: decide which model this VM should run ----------------------------
Write-LabLog 'Running hardware diagnostics to choose a model...' -Level Info
$specs = & (Join-Path $PSScriptRoot 'Test-LabVMSpecs.ps1')

if ($config.ModelOverride) {
    $chatModel = $config.ModelOverride
    Write-LabLog "Using ModelOverride from provisioning.config.psd1: $chatModel" -Level Info
}
else {
    $chatModel = $specs.RecommendedChatModel
}
$autocompleteModel = $specs.RecommendedAutocompleteModel
$supportsAgenticCli = [bool]$specs.SupportsAgenticCli

# --- Step 3: pull the model(s) -------------------------------------------------
if ($config.SkipOllamaPull) {
    Write-LabLog 'SkipOllamaPull is set - not pulling models.' -Level Info
    $skipped += 'Ollama model pull'
}
elseif (-not (Test-CommandExists 'ollama')) {
    Write-LabLog 'Ollama is not on PATH - cannot pull models. Fix the Ollama install and re-run this script.' -Level Error
    $failed += 'Ollama model pull (Ollama not installed)'
}
else {
    $alreadyPulled = & ollama list 2>&1
    foreach ($model in @($chatModel, $autocompleteModel) | Select-Object -Unique) {
        if ($alreadyPulled -match [regex]::Escape($model)) {
            Write-LabLog "Model already pulled: $model" -Level Info
            $skipped += "ollama pull $model"
        }
        else {
            Write-LabLog "Pulling model: $model (this can take a while on first run)..." -Level Info
            try {
                & ollama pull $model
                $installed += "ollama pull $model"
            }
            catch {
                Write-LabLog "Failed to pull $model : $($_.Exception.Message)" -Level Error
                $failed += "ollama pull $model"
            }
        }
    }
}

# --- Step 4: Continue.dev extension --------------------------------------------
if (Test-CommandExists 'code') {
    $extensions = & code --list-extensions 2>&1
    if ($extensions -match 'continue\.continue') {
        Write-LabLog 'Continue.dev extension already installed - skipping.' -Level Info
        $skipped += 'Continue.dev extension'
    }
    else {
        Write-LabLog 'Installing Continue.dev extension...' -Level Info
        try {
            & code --install-extension continue.continue | Out-Null
            $installed += 'Continue.dev extension'
        }
        catch {
            Write-LabLog "Continue.dev extension install failed: $($_.Exception.Message)" -Level Error
            $failed += 'Continue.dev extension'
        }
    }
}
else {
    Write-LabLog 'VS Code is not on PATH - cannot install the Continue.dev extension. Fix the VS Code install and re-run this script.' -Level Error
    $failed += 'Continue.dev extension (VS Code not installed)'
}

# --- Step 5: Claude Code CLI (optional - only on the agentic-capable tier) -----
if (-not $supportsAgenticCli) {
    Write-LabLog 'This VM tier does not support the agentic Claude Code CLI experience (needs the qwen3-coder tool-calling model) - skipping. Continue.dev chat/edit is unaffected.' -Level Info
    $skipped += 'Claude Code CLI (tier does not support it)'
}
elseif (Test-CommandExists 'claude') {
    Write-LabLog 'Claude Code CLI already installed - skipping.' -Level Info
    $skipped += 'Claude Code CLI'
}
else {
    Write-LabLog 'Installing Claude Code CLI...' -Level Info
    try {
        Invoke-Expression (Invoke-RestMethod 'https://claude.ai/install.ps1')
        if (Test-CommandExists 'claude') {
            Write-LabLog 'Claude Code CLI installed.' -Level Success
            $installed += 'Claude Code CLI'
        }
        else {
            Write-LabLog "Claude Code CLI installer ran but 'claude' still isn't on PATH - a new shell/PATH refresh may be needed." -Level Warn
            $failed += 'Claude Code CLI (installed but not yet on PATH)'
        }
    }
    catch {
        Write-LabLog "Claude Code CLI install failed: $($_.Exception.Message)" -Level Error
        $failed += 'Claude Code CLI'
    }
}

# --- Step 6: render the Continue.dev model config (machine-wide) --------------
$continueGlobalDir = Join-Path $HOME '.continue'
if (-not (Test-Path $continueGlobalDir)) { New-Item -ItemType Directory -Path $continueGlobalDir -Force | Out-Null }
$templatePath = Join-Path $repoRoot 'continue-config\config.yaml.template'
$renderedConfig = (Get-Content -Path $templatePath -Raw) `
    -replace '\{\{OLLAMA_CHAT_MODEL\}\}', $chatModel `
    -replace '\{\{OLLAMA_AUTOCOMPLETE_MODEL\}\}', $autocompleteModel
$configOutPath = Join-Path $continueGlobalDir 'config.yaml'
Set-Content -Path $configOutPath -Value $renderedConfig -Encoding UTF8
Write-LabLog "Wrote Continue.dev config to $configOutPath (chat: $chatModel, autocomplete: $autocompleteModel)" -Level Success
$installed += 'Continue.dev config.yaml'

# --- Step 7: bootstrap the attendee workspace ----------------------------------
$workspaceRoot = $config.WorkspaceRoot
if (-not (Test-Path $workspaceRoot)) {
    New-Item -ItemType Directory -Path $workspaceRoot -Force | Out-Null
    Write-LabLog "Created workspace at $workspaceRoot" -Level Info
}

Push-Location $workspaceRoot
try {
    if (-not (Test-Path (Join-Path $workspaceRoot '.git'))) {
        git init | Out-Null
        git config user.name $config.GitUserNamePlaceholder
        git config user.email $config.GitUserEmailPlaceholder
        Write-LabLog "Initialized git repo at $workspaceRoot with placeholder identity." -Level Success
        $installed += 'Workspace git repo'
    }
    else {
        Write-LabLog "$workspaceRoot is already a git repo - skipping git init." -Level Info
        $skipped += 'Workspace git repo'
    }

    $workspaceRulesDir = Join-Path $workspaceRoot '.continue\rules'
    New-Item -ItemType Directory -Path $workspaceRulesDir -Force | Out-Null
    Copy-Item -Path (Join-Path $repoRoot 'continue-config\rules\*.md') -Destination $workspaceRulesDir -Force
    Write-LabLog "Synced governance rules into $workspaceRulesDir" -Level Success

    $scaffoldTemplateDir = Join-Path $workspaceRoot '.scaffold-template'
    New-Item -ItemType Directory -Path $scaffoldTemplateDir -Force | Out-Null
    Copy-Item -Path (Join-Path $repoRoot 'scaffold\*') -Destination $scaffoldTemplateDir -Recurse -Force
    Write-LabLog "Synced scaffold template into $scaffoldTemplateDir" -Level Success

    if (-not (Test-Path (Join-Path $workspaceRoot 'README-git-helpers.md'))) {
        Copy-Item -Path (Join-Path $repoRoot 'git-helpers\README.md') -Destination (Join-Path $workspaceRoot 'README-git-helpers.md')
    }

    if ($supportsAgenticCli) {
        Copy-Item -Path (Join-Path $repoRoot 'claude-code-config\CLAUDE.md') -Destination (Join-Path $workspaceRoot 'CLAUDE.md') -Force
        Write-LabLog 'Synced CLAUDE.md (local Claude Code CLI governance) into the workspace.' -Level Success
    }

    # `git log -1` on a brand-new repo exits non-zero and writes to stderr,
    # which PowerShell 7.3+ can turn into a terminating error even though
    # this is an expected, normal outcome here - catch and ignore it, we
    # only care about $LASTEXITCODE.
    try { git log -1 2>&1 | Out-Null } catch { }
    if ($LASTEXITCODE -ne 0) {
        git add -A | Out-Null
        git commit -m 'Set up lab workspace (governance rules + scaffold template)' | Out-Null
        Write-LabLog 'Made the initial workspace commit.' -Level Success
    }
}
finally {
    Pop-Location
}

# --- Step 8: install git helpers -----------------------------------------------
$psModulePath = ($env:PSModulePath -split ';')[0]
$labModuleDir = Join-Path $psModulePath 'LabGitHelpers'
New-Item -ItemType Directory -Path $labModuleDir -Force | Out-Null
Copy-Item -Path (Join-Path $repoRoot 'git-helpers\LabGitHelpers.psm1') -Destination $labModuleDir -Force
Write-LabLog "Installed LabGitHelpers module to $labModuleDir" -Level Success
$installed += 'LabGitHelpers module'

try {
    & (Join-Path $repoRoot 'git-helpers\git-aliases.ps1') | Out-Null
    $installed += 'Portable git save/undo aliases'
}
catch {
    Write-LabLog "Could not install portable git aliases: $($_.Exception.Message)" -Level Warn
    $failed += 'Portable git save/undo aliases'
}

# --- Step 9: install the local Claude Code CLI helper (optional) --------------
$localClaudeImportLine = ''
if ($supportsAgenticCli) {
    $localClaudeModuleDir = Join-Path $psModulePath 'LocalClaude'
    New-Item -ItemType Directory -Path $localClaudeModuleDir -Force | Out-Null
    Copy-Item -Path (Join-Path $repoRoot 'claude-code-config\LocalClaude.psm1') -Destination $localClaudeModuleDir -Force
    Write-LabLog "Installed LocalClaude module to $localClaudeModuleDir" -Level Success
    $installed += 'LocalClaude module (claude-local)'
    $localClaudeImportLine = "`$env:LAB_AGENT_MODEL = '$chatModel'`nImport-Module LocalClaude"
}

$profileBlockStart = '# LabSession-Helpers-Start'
$profileBlockEnd   = '# LabSession-Helpers-End'
$profileBlock = @"
$profileBlockStart
`$env:LAB_WORKSPACE_ROOT = '$workspaceRoot'
`$env:LAB_SCAFFOLD_TEMPLATE = '$scaffoldTemplateDir'
Import-Module LabGitHelpers
$localClaudeImportLine
$profileBlockEnd
"@

if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}
$profileContent = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
if ($profileContent -and $profileContent.Contains($profileBlockStart)) {
    Write-LabLog 'PowerShell profile already wired up - skipping.' -Level Info
    $skipped += 'PowerShell profile block'
}
else {
    Add-Content -Path $PROFILE -Value "`n$profileBlock`n"
    Write-LabLog "Added LabGitHelpers auto-import to $PROFILE" -Level Success
    $installed += 'PowerShell profile block'
}

# --- Summary --------------------------------------------------------------------
$status = if ($failed.Count -gt 0) { 'FAIL' } else { 'PASS' }
$statusColor = if ($status -eq 'FAIL') { 'Red' } else { 'Green' }

Write-Host "`n=== Provision-LabVM Summary: $status ===" -ForegroundColor $statusColor
Write-Host "Chosen model:  $chatModel (chat/edit), $autocompleteModel (autocomplete)"
Write-Host "Claude Code CLI (local, optional): $(if ($supportsAgenticCli) { "enabled - run 'claude-local' in a new shell" } else { 'not offered on this VM tier' })"
Write-Host "Installed:     $($installed -join ', ')"
Write-Host "Skipped:       $($skipped -join ', ')"
if ($failed.Count -gt 0) {
    Write-Host "Failed:        $($failed -join ', ')" -ForegroundColor Red
}
Write-Host "`nOpen a NEW PowerShell window before using New-Routine/save/undo/claude-local, so the profile change takes effect."
