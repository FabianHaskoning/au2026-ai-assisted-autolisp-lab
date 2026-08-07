<#
    .SYNOPSIS
    Idempotent provisioning for a lab VM: installs Git, VS Code, Ollama
    and the Continue.dev extension, pulls the right model for this
    VM's hardware, and bootstraps an attendee git workspace with the
    governance rules and git helpers wired in. On VMs with enough RAM,
    also installs the real Claude Code CLI and its VS Code extension,
    both wired to the local Ollama model (see claude-code-config/) as
    an optional, advanced path - no Anthropic account needed.

    .DESCRIPTION
    Safe to re-run any number of times - every step checks whether it's
    already done before doing it, so re-running after a partial failure
    (or just to re-test before Sept 16) never breaks anything.

    NOT meant to run against the real Skillable VM yet - author access
    to that VM is still being confirmed. Run this on a local test VM
    first, or hand it to whoever ends up provisioning the real one.

    Pass -TakeHome when running this on an attendee's own Windows PC
    instead of the disposable lab VM: elevation is requested rather than
    required outright, the workspace defaults under the user's own
    profile instead of C:\, a missing AutoCAD/Civil 3D install is a
    warning rather than a hard failure, and any pre-existing
    ~/.continue/config.yaml is merged into rather than overwritten. See
    take-home/README.md.

    .EXAMPLE
    .\Provision-LabVM.ps1

    .EXAMPLE
    .\Provision-LabVM.ps1 -TakeHome
#>

[CmdletBinding()]
param(
    [switch]$TakeHome,
    [string]$WorkspaceRootOverride
)

$repoRoot = Split-Path -Parent $PSScriptRoot

. (Join-Path $PSScriptRoot 'lib\Common.ps1')
. (Join-Path $PSScriptRoot 'lib\ModelDecision.ps1')

$config = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot 'config\provisioning.config.psd1')

$installed     = @()
$skipped       = @()
$failed        = @()
# Installed successfully, but the running shell's PATH won't see it until a
# new shell starts - Windows doesn't propagate env var changes to already-
# running processes. Expected on every VM's first run, not a real failure.
$needsNewShell = @()

# --- Elevation check ---------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    if ($TakeHome) {
        Write-LabLog 'Take-home mode: not running elevated - relaunching an elevated PowerShell window for the winget installs (you may see a UAC prompt)...' -Level Warn
        $relaunchArgs = @('-NoExit', '-File', "`"$PSCommandPath`"", '-TakeHome')
        if ($WorkspaceRootOverride) { $relaunchArgs += @('-WorkspaceRootOverride', "`"$WorkspaceRootOverride`"") }
        Start-Process -FilePath (Get-Process -Id $PID).Path -Verb RunAs -ArgumentList $relaunchArgs
        return
    }
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
            Write-LabLog "${DisplayName}: winget reported success but '$CommandToCheck' still isn't on PATH in this shell - expected, will resolve in a new shell." -Level Warn
            $script:installed += $DisplayName
            $script:needsNewShell += $DisplayName
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
$specs = & (Join-Path $PSScriptRoot 'Test-LabVMSpecs.ps1') -TakeHome:$TakeHome

if ($config.ModelOverride) {
    $chatModel = $config.ModelOverride
    Write-LabLog "Using ModelOverride from provisioning.config.psd1: $chatModel" -Level Info
}
else {
    $chatModel = $specs.RecommendedChatModel
}
$qualityModel = $specs.RecommendedQualityChatModel
$autocompleteModel = $specs.RecommendedAutocompleteModel
$supportsAgenticCli = [bool]$specs.SupportsAgenticCli

# --- Step 3: pull the model(s) -------------------------------------------------
# Pulls both the fast default and the quality opt-in (if this tier has one),
# so switching between them later (fast-model / quality-model) is instant -
# no surprise multi-GB download mid-session.
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
    $modelsToPull = @($chatModel, $autocompleteModel)
    if ($qualityModel) { $modelsToPull += $qualityModel }
    foreach ($model in $modelsToPull | Select-Object -Unique) {
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
# The Windows installer does NOT reliably add its install dir to the
# persistent User PATH by itself (confirmed on the real lab VM - it prints
# manual System Properties instructions instead of doing it). Fix that
# proactively, idempotently, whether or not we're about to (re)install -
# this also repairs a VM from an earlier run that hit this exact problem.
$claudeLocalBin = Join-Path $HOME '.local\bin'
if (Test-Path $claudeLocalBin) {
    $userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
    if ($userPath -notlike "*$claudeLocalBin*") {
        [Environment]::SetEnvironmentVariable('PATH', "$userPath;$claudeLocalBin", 'User')
        Write-LabLog "Added $claudeLocalBin to the persistent User PATH." -Level Success
    }
    if ($env:PATH -notlike "*$claudeLocalBin*") {
        $env:PATH = "$env:PATH;$claudeLocalBin"
    }
}

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
        $installed += 'Claude Code CLI'

        $claudeLocalBin = Join-Path $HOME '.local\bin'
        if ((Test-Path $claudeLocalBin) -and ($env:PATH -notlike "*$claudeLocalBin*")) {
            $userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
            if ($userPath -notlike "*$claudeLocalBin*") {
                [Environment]::SetEnvironmentVariable('PATH', "$userPath;$claudeLocalBin", 'User')
            }
            $env:PATH = "$env:PATH;$claudeLocalBin"
            Write-LabLog "Added $claudeLocalBin to PATH (persistent + this session)." -Level Success
        }

        if (Test-CommandExists 'claude') {
            Write-LabLog 'Claude Code CLI installed.' -Level Success
        }
        else {
            Write-LabLog "Claude Code CLI installed, but 'claude' still isn't found - installer may have used a different install location than expected ($claudeLocalBin)." -Level Warn
            $needsNewShell += 'Claude Code CLI'
        }
    }
    catch {
        Write-LabLog "Claude Code CLI install failed: $($_.Exception.Message)" -Level Error
        $failed += 'Claude Code CLI'
    }
}

# --- Step 6: point Claude Code (CLI + VS Code extension) at local Ollama ------
# The VS Code extension bundles its OWN copy of the CLI for its chat panel -
# it does NOT inherit LocalClaude.psm1's per-invocation environment
# variables, and by default wants an Anthropic account sign-in. The
# officially documented fix is ~/.claude/settings.json's "env" block, which
# Claude Code's own docs confirm is shared by both the standalone CLI and
# the extension's bundled process - plus disabling the extension's login
# prompt in VS Code's own settings. Merges into any existing settings files
# rather than overwriting them (VS Code's settings.json in particular holds
# real user preferences, not just our config).
function Set-JsonFileSetting {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][scriptblock]$Mutate
    )
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $settings = if (Test-Path $Path) {
        try { Get-Content -Path $Path -Raw | ConvertFrom-Json }
        catch {
            Write-LabLog "Could not parse existing $Path as JSON - leaving it untouched. Add the Claude Code local-model settings there manually (see claude-code-config/README.md)." -Level Warn
            return $false
        }
    }
    else {
        [PSCustomObject]@{}
    }
    & $Mutate $settings
    $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
    return $true
}

function Set-JsonProperty {
    param($Object, [string]$Name, $Value)
    if ($Object.PSObject.Properties.Name -contains $Name) {
        $Object.$Name = $Value
    }
    else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

if ($supportsAgenticCli) {
    if (Test-CommandExists 'code') {
        $extensions = & code --list-extensions 2>&1
        if ($extensions -match 'anthropic\.claude-code') {
            Write-LabLog 'Claude Code VS Code extension already installed - skipping.' -Level Info
            $skipped += 'Claude Code VS Code extension'
        }
        else {
            Write-LabLog 'Installing Claude Code VS Code extension...' -Level Info
            try {
                & code --install-extension anthropic.claude-code | Out-Null
                $installed += 'Claude Code VS Code extension'
            }
            catch {
                Write-LabLog "Claude Code VS Code extension install failed: $($_.Exception.Message)" -Level Error
                $failed += 'Claude Code VS Code extension'
            }
        }
    }

    $claudeSettingsPath = Join-Path $HOME '.claude\settings.json'
    $ok = Set-JsonFileSetting -Path $claudeSettingsPath -Mutate {
        param($settings)
        if (-not ($settings.PSObject.Properties.Name -contains 'env')) {
            $settings | Add-Member -NotePropertyName 'env' -NotePropertyValue ([PSCustomObject]@{})
        }
        Set-JsonProperty -Object $settings.env -Name 'ANTHROPIC_AUTH_TOKEN' -Value 'ollama'
        Set-JsonProperty -Object $settings.env -Name 'ANTHROPIC_API_KEY' -Value ''
        Set-JsonProperty -Object $settings.env -Name 'ANTHROPIC_BASE_URL' -Value 'http://localhost:11434'
        Set-JsonProperty -Object $settings -Name 'model' -Value $chatModel
    }
    if ($ok) {
        Write-LabLog "Configured $claudeSettingsPath to route Claude Code (CLI + VS Code extension) to local Ollama." -Level Success
        $installed += 'Claude Code local-model settings (~/.claude/settings.json)'
    }

    $vscodeSettingsPath = Join-Path $env:APPDATA 'Code\User\settings.json'
    $ok = Set-JsonFileSetting -Path $vscodeSettingsPath -Mutate {
        param($settings)
        Set-JsonProperty -Object $settings -Name 'claudeCode.disableLoginPrompt' -Value $true
    }
    if ($ok) {
        Write-LabLog "Disabled the Claude Code extension's Anthropic sign-in prompt in $vscodeSettingsPath." -Level Success
        $installed += 'VS Code claudeCode.disableLoginPrompt setting'
    }
}

# --- Step 7: render the Continue.dev model config (machine-wide) --------------
$continueGlobalDir = Join-Path $HOME '.continue'
if (-not (Test-Path $continueGlobalDir)) { New-Item -ItemType Directory -Path $continueGlobalDir -Force | Out-Null }
$configOutPath = Join-Path $continueGlobalDir 'config.yaml'

if ($TakeHome) {
    # A personal machine may already have its own Continue.dev config (its
    # own providers, models, or settings) - merge our Ollama block into it
    # via the same marker-block pattern used for the $PROFILE block below,
    # instead of the lab VM's unconditional overwrite. Ollama stays the
    # free fallback; continue-provider (see continue-config/) can add other
    # providers alongside it without disturbing this block.
    Import-Module (Join-Path $repoRoot 'continue-config\ContinueConfigHelpers.psm1') -Force
    $ollamaBlockContent = @(
        '  - name: Lab Assistant (Ollama)'
        '    provider: ollama'
        "    model: `"$chatModel`""
        '    apiBase: http://localhost:11434'
        '    roles:'
        '      - chat'
        '      - edit'
        ''
        '  - name: Autocomplete (Ollama)'
        '    provider: ollama'
        "    model: `"$autocompleteModel`""
        '    apiBase: http://localhost:11434'
        '    roles:'
        '      - autocomplete'
    )
    Set-ContinueConfigBlock -BlockId 'Ollama' -Content $ollamaBlockContent -ParentKey 'models' -Path $configOutPath
    Write-LabLog "Merged the local-Ollama block into $configOutPath (chat: $chatModel, autocomplete: $autocompleteModel) - any other content in that file was left untouched." -Level Success
}
else {
    $templatePath = Join-Path $repoRoot 'continue-config\config.yaml.template'
    $renderedConfig = (Get-Content -Path $templatePath -Raw) `
        -replace '\{\{OLLAMA_CHAT_MODEL\}\}', $chatModel `
        -replace '\{\{OLLAMA_AUTOCOMPLETE_MODEL\}\}', $autocompleteModel
    Set-Content -Path $configOutPath -Value $renderedConfig -Encoding UTF8
    Write-LabLog "Wrote Continue.dev config to $configOutPath (chat: $chatModel, autocomplete: $autocompleteModel)" -Level Success
}
$installed += 'Continue.dev config.yaml'

# --- Step 8: bootstrap the attendee workspace ----------------------------------
$workspaceRoot = if ($WorkspaceRootOverride) {
    $WorkspaceRootOverride
}
elseif ($TakeHome) {
    # Avoid requiring write access to C:\ root on a personal machine.
    Join-Path $HOME 'LabWork'
}
else {
    $config.WorkspaceRoot
}
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

# --- Step 9+10: install git helpers + the local Claude Code CLI helper --------
# This VM has BOTH Windows PowerShell 5.1 and PowerShell 7+ installed
# (confirmed live - an attendee could open either one), and they do NOT
# share module paths or $PROFILE. Installing only into whichever shell
# happens to run this script would silently break New-Routine/save/undo/
# claude-local for anyone who opens the other one. Install into both
# well-known per-user locations explicitly, regardless of which shell is
# currently running.
$shellTargets = @(
    @{ Name = 'Windows PowerShell 5.1'; ModulesDir = Join-Path $HOME 'Documents\WindowsPowerShell\Modules'; ProfilePath = Join-Path $HOME 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1' }
    @{ Name = 'PowerShell 7+';          ModulesDir = Join-Path $HOME 'Documents\PowerShell\Modules';          ProfilePath = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1' }
)

try {
    & (Join-Path $repoRoot 'git-helpers\git-aliases.ps1') | Out-Null
    $installed += 'Portable git save/undo aliases'
}
catch {
    Write-LabLog "Could not install portable git aliases: $($_.Exception.Message)" -Level Warn
    $failed += 'Portable git save/undo aliases'
}

foreach ($target in $shellTargets) {
    $labModuleDir = Join-Path $target.ModulesDir 'LabGitHelpers'
    New-Item -ItemType Directory -Path $labModuleDir -Force | Out-Null
    Copy-Item -Path (Join-Path $repoRoot 'git-helpers\LabGitHelpers.psm1') -Destination $labModuleDir -Force
    $installed += "LabGitHelpers module ($($target.Name))"

    # ContinueProviders (continue-provider) lets an attendee add their own
    # Anthropic/OpenAI/Gemini/custom-OpenAI-compatible model into
    # Continue.dev alongside the free local Ollama default - offered on
    # every tier, since it only needs Continue.dev, not the agentic CLI.
    $continueProvidersModuleDir = Join-Path $target.ModulesDir 'ContinueProviders'
    New-Item -ItemType Directory -Path $continueProvidersModuleDir -Force | Out-Null
    Copy-Item -Path (Join-Path $repoRoot 'continue-config\ContinueProviders.psm1') -Destination $continueProvidersModuleDir -Force
    Copy-Item -Path (Join-Path $repoRoot 'continue-config\ContinueConfigHelpers.psm1') -Destination $continueProvidersModuleDir -Force
    $installed += "ContinueProviders module - continue-provider ($($target.Name))"

    # LAB_AGENT_MODEL_FAST/_QUALITY are static facts about this VM's tier
    # (safe to re-set on every new shell). The CURRENTLY SELECTED model is
    # mutable state, not a fact - its source of truth is
    # ~/.claude/settings.json's "model" field (see Set-LabModel in
    # LocalClaude.psm1), which fast-model/quality-model update and which a
    # new shell must NOT silently reset.
    $localClaudeImportLine = ''
    if ($supportsAgenticCli) {
        $localClaudeModuleDir = Join-Path $target.ModulesDir 'LocalClaude'
        New-Item -ItemType Directory -Path $localClaudeModuleDir -Force | Out-Null
        Copy-Item -Path (Join-Path $repoRoot 'claude-code-config\LocalClaude.psm1') -Destination $localClaudeModuleDir -Force
        Copy-Item -Path (Join-Path $repoRoot 'claude-code-config\ClaudeSettingsHelpers.psm1') -Destination $localClaudeModuleDir -Force
        Copy-Item -Path (Join-Path $repoRoot 'continue-config\ContinueConfigHelpers.psm1') -Destination $localClaudeModuleDir -Force
        $installed += "LocalClaude module - claude-local/fast-model/quality-model/cloud-mode/local-mode ($($target.Name))"
        $localClaudeImportLine = "`$env:LAB_AGENT_MODEL_FAST = '$chatModel'`n`$env:LAB_AGENT_MODEL_QUALITY = '$qualityModel'`nImport-Module LocalClaude"

        # Gateway mode (experimental, take-home only): lets the Claude Code
        # CLI itself reach a non-Anthropic backend via a local LiteLLM
        # proxy. Never installed on the disposable lab VM - it's an extra
        # Python dependency and background process, not validated at
        # 60-90-attendee scale. See claude-code-config/README.md.
        if ($TakeHome) {
            $liteLLMGatewayModuleDir = Join-Path $target.ModulesDir 'LiteLLMGateway'
            New-Item -ItemType Directory -Path $liteLLMGatewayModuleDir -Force | Out-Null
            Copy-Item -Path (Join-Path $repoRoot 'claude-code-config\LiteLLMGateway.psm1') -Destination $liteLLMGatewayModuleDir -Force
            Copy-Item -Path (Join-Path $repoRoot 'claude-code-config\ClaudeSettingsHelpers.psm1') -Destination $liteLLMGatewayModuleDir -Force
            Copy-Item -Path (Join-Path $repoRoot 'claude-code-config\litellm-config.yaml.template') -Destination $liteLLMGatewayModuleDir -Force
            $installed += "LiteLLMGateway module - gateway-mode, experimental ($($target.Name))"
            $localClaudeImportLine += "`nImport-Module LiteLLMGateway"
        }
    }

    $profileBlockStart = '# LabSession-Helpers-Start'
    $profileBlockEnd   = '# LabSession-Helpers-End'
    $profileBlock = @"
$profileBlockStart
`$env:LAB_WORKSPACE_ROOT = '$workspaceRoot'
`$env:LAB_SCAFFOLD_TEMPLATE = '$scaffoldTemplateDir'
Import-Module LabGitHelpers
Import-Module ContinueProviders
$localClaudeImportLine
$profileBlockEnd
"@

    $profileDir = Split-Path -Parent $target.ProfilePath
    if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
    if (-not (Test-Path $target.ProfilePath)) {
        New-Item -ItemType File -Path $target.ProfilePath -Force | Out-Null
    }
    $profileContent = Get-Content -Path $target.ProfilePath -Raw -ErrorAction SilentlyContinue
    if ($profileContent -and $profileContent.Contains($profileBlockStart)) {
        # Re-run: refresh the block in place (model tier facts can change
        # across re-runs, e.g. after a ModelOverride edit) rather than
        # skipping - a stale, never-updated profile is exactly the bug
        # that motivated this rewrite.
        $blockPattern = [regex]::Escape($profileBlockStart) + '[\s\S]*?' + [regex]::Escape($profileBlockEnd)
        $existingBlockMatch = [regex]::Match($profileContent, $blockPattern)
        if ($existingBlockMatch.Success) {
            $newContent = $profileContent.Remove($existingBlockMatch.Index, $existingBlockMatch.Length).Insert($existingBlockMatch.Index, $profileBlock)
            Set-Content -Path $target.ProfilePath -Value $newContent -Encoding UTF8
            $installed += "PowerShell profile block refreshed ($($target.Name))"
        }
        else {
            Write-LabLog "Found '$profileBlockStart' in $($target.ProfilePath) but no matching '$profileBlockEnd' - leaving it untouched rather than risk corrupting it. Remove the stray marker line manually and re-run." -Level Warn
            $failed += "PowerShell profile block ($($target.Name), corrupted marker)"
        }
    }
    else {
        Add-Content -Path $target.ProfilePath -Value "`n$profileBlock`n"
        $installed += "PowerShell profile block ($($target.Name))"
    }
}

# --- Summary --------------------------------------------------------------------
$status = if ($failed.Count -gt 0) { 'FAIL' } elseif ($needsNewShell.Count -gt 0) { 'PASS (new shell needed)' } else { 'PASS' }
$statusColor = if ($failed.Count -gt 0) { 'Red' } elseif ($needsNewShell.Count -gt 0) { 'Yellow' } else { 'Green' }

Write-Host "`n=== Provision-LabVM Summary: $status ===" -ForegroundColor $statusColor
Write-Host "Chosen model:  $chatModel (chat/edit, fast default), $autocompleteModel (autocomplete)"
if ($qualityModel) {
    Write-Host "Quality model (opt-in, slower): $qualityModel - switch with 'quality-model' / back with 'fast-model'"
}
Write-Host "Claude Code CLI (local, optional): $(if ($supportsAgenticCli) { "enabled - run 'claude-local' in a new shell" } else { 'not offered on this VM tier' })"
Write-Host "Continue.dev provider picker: run 'continue-provider' in a new shell to add your own Anthropic/OpenAI/Gemini/custom-OpenAI-compatible model alongside the free local one."
if ($TakeHome -and $supportsAgenticCli) {
    Write-Host "Gateway mode (experimental): run 'gateway-mode' in a new shell to point the Claude Code CLI at a non-Anthropic backend via a local LiteLLM proxy - see claude-code-config/README.md."
}
Write-Host "Installed:     $($installed -join ', ')"
Write-Host "Skipped:       $($skipped -join ', ')"
if ($needsNewShell.Count -gt 0) {
    Write-Host "Needs new shell to appear on PATH: $($needsNewShell -join ', ')" -ForegroundColor Yellow
}
if ($failed.Count -gt 0) {
    Write-Host "Failed:        $($failed -join ', ')" -ForegroundColor Red
}
Write-Host "`nOpen a NEW PowerShell window (Windows PowerShell 5.1 or PowerShell 7+, both are wired up) before using New-Routine/save/undo/claude-local, so the profile change takes effect."
