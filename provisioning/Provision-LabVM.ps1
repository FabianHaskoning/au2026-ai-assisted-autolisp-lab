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

    Under -TakeHome, three things are optional and - unless passed
    explicitly or -NonInteractive is set - are asked about interactively:
    installing Git for Windows (-SkipGit), installing VS Code + Continue.dev
    (-SkipVSCode), and whether the goal is AutoLISP routines at all
    (-Purpose Lisp|General - General skips the AutoLISP-specific workspace
    content). Ollama and the Claude Code CLI itself are never optional -
    that's the core of what -TakeHome sets up.

    .EXAMPLE
    .\Provision-LabVM.ps1

    .EXAMPLE
    .\Provision-LabVM.ps1 -TakeHome

    .EXAMPLE
    .\Provision-LabVM.ps1 -TakeHome -SkipGit -Purpose General -NonInteractive
#>

[CmdletBinding()]
param(
    [switch]$TakeHome,
    [string]$WorkspaceRootOverride,
    [switch]$SkipGit,
    [switch]$SkipVSCode,
    [ValidateSet('Lisp', 'General')][string]$Purpose,
    [switch]$NonInteractive
)

$repoRoot = Split-Path -Parent $PSScriptRoot

. (Join-Path $PSScriptRoot 'lib\Common.ps1')
. (Join-Path $PSScriptRoot 'lib\ModelDecision.ps1')

# Shared JSON helpers (BOM-free writes, merge-safe property setters, the
# pre-lab settings.json backup) - one tested code path with
# LocalClaude.psm1/LiteLLMGateway.psm1 instead of a private copy here.
Import-Module (Join-Path $repoRoot 'claude-code-config\ClaudeSettingsHelpers.psm1') -Force

$config = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot 'config\provisioning.config.psd1')

$installed     = @()
$skipped       = @()
$failed        = @()
# Installed successfully, but the running shell's PATH won't see it until a
# new shell starts - Windows doesn't propagate env var changes to already-
# running processes. Expected on every VM's first run, not a real failure.
$needsNewShell = @()

# --- Resolve take-home optional-install choices -------------------------------
# Done BEFORE the elevation check on purpose: the not-elevated + -TakeHome
# path below relaunches an entirely new elevated process and returns, so
# anything placed after the elevation check would either never run in the
# process that does the real work, or would have to prompt twice. Resolve
# once here, then forward the resolved values (plus a forced
# -NonInteractive) into the relaunch so the elevated child re-derives the
# same choices deterministically instead of prompting again.
$skipGitExplicit    = $PSBoundParameters.ContainsKey('SkipGit')
$skipVSCodeExplicit = $PSBoundParameters.ContainsKey('SkipVSCode')
$purposeExplicit    = $PSBoundParameters.ContainsKey('Purpose')

if (-not $TakeHome -and ($skipGitExplicit -or $skipVSCodeExplicit -or $purposeExplicit -or $NonInteractive)) {
    Write-LabLog '-SkipGit/-SkipVSCode/-Purpose/-NonInteractive only apply with -TakeHome - ignored on this run.' -Level Info
}

if ($TakeHome) {
    if ($NonInteractive) {
        $effectiveSkipGit    = [bool]$SkipGit
        $effectiveSkipVSCode = [bool]$SkipVSCode
        $effectivePurpose    = if ($purposeExplicit) { $Purpose } else { 'Lisp' }
    }
    else {
        $effectiveSkipGit = if ($skipGitExplicit) { [bool]$SkipGit } else {
            (Read-Host 'Install Git for Windows as part of this setup? (Y/n)') -match '^(n|no)$'
        }
        $effectiveSkipVSCode = if ($skipVSCodeExplicit) { [bool]$SkipVSCode } else {
            (Read-Host 'Install VS Code + Continue.dev as part of this setup? (Y/n - say n if you only want the Claude Code CLI)') -match '^(n|no)$'
        }
        $effectivePurpose = if ($purposeExplicit) { $Purpose } else {
            if ((Read-Host 'Is your main goal here writing AutoLISP routines for AutoCAD/Civil 3D? (Y/n)') -match '^(n|no)$') { 'General' } else { 'Lisp' }
        }
    }
}
else {
    $effectiveSkipGit    = $false
    $effectiveSkipVSCode = $false
    $effectivePurpose    = 'Lisp'
}

# --- Elevation check ---------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    if ($TakeHome) {
        Write-LabLog 'Take-home mode: not running elevated - relaunching an elevated PowerShell window for the winget installs (you may see a UAC prompt)...' -Level Warn
        $relaunchArgs = @('-NoExit', '-File', "`"$PSCommandPath`"", '-TakeHome', '-NonInteractive')
        if ($WorkspaceRootOverride) { $relaunchArgs += @('-WorkspaceRootOverride', "`"$WorkspaceRootOverride`"") }
        if ($effectiveSkipGit)      { $relaunchArgs += '-SkipGit' }
        if ($effectiveSkipVSCode)   { $relaunchArgs += '-SkipVSCode' }
        $relaunchArgs += @('-Purpose', $effectivePurpose)
        Start-Process -FilePath (Get-Process -Id $PID).Path -Verb RunAs -ArgumentList $relaunchArgs
        return
    }
    Write-LabLog 'This script needs to run elevated (Run as Administrator) for winget installs. Re-launch PowerShell as Administrator.' -Level Error
    return
}

# --- Step 1: core tools -------------------------------------------------------
# Install-ViaWinget lives in lib\Common.ps1 (dot-sourced above) so it can be
# tested in isolation by shadowing a fake `winget` function.
if (-not $effectiveSkipGit) {
    Install-ViaWinget -DisplayName 'Git for Windows' -WingetId 'Git.Git' -CommandToCheck 'git'
}
else {
    Write-LabLog 'Skipping Git for Windows install (you said you already have your own git setup).' -Level Info
    $skipped += 'Git for Windows (skipped by user choice)'
}
if (-not $effectiveSkipVSCode) {
    Install-ViaWinget -DisplayName 'VS Code' -WingetId 'Microsoft.VisualStudioCode' -CommandToCheck 'code'
}
else {
    Write-LabLog 'Skipping VS Code install (you said you only want the Claude Code CLI).' -Level Info
    $skipped += 'VS Code (skipped by user choice)'
}
Install-ViaWinget -DisplayName 'Ollama' -WingetId 'Ollama.Ollama' -CommandToCheck 'ollama'

$gitAvailable = Test-CommandExists 'git'
if (-not $gitAvailable) {
    if ($effectiveSkipGit) {
        Write-LabLog 'Git was skipped by choice - the workspace git repo, save/undo/New-Routine, and the portable git aliases will not be set up. Install git yourself later and re-run this script if you change your mind.' -Level Info
    }
    else {
        Write-LabLog 'Git is not on PATH (install may have failed - see above) - the workspace git repo, save/undo/New-Routine, and the portable git aliases cannot be set up. Fix the Git install and re-run this script.' -Level Error
        $failed += 'Workspace git repo + git helpers (git not available)'
    }
}

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

# --- Step 3b: keep the model warm ---------------------------------------------
# Measured on the real lab VM: the first generate call after a boot took
# 90.7s, ~88s of it loading the model off cold disk. Every later call was
# ~2s, and the model survived an idle gap - so this is a once-per-boot cost.
# It lands on an attendee's very first prompt, which is the one interaction
# that has to feel effortless. Move it into the opening talk instead.
if (Test-Path (Join-Path $env:ProgramData 'LabSession')) { } else { New-Item -ItemType Directory -Path (Join-Path $env:ProgramData 'LabSession') -Force | Out-Null }
$labProgramData = Join-Path $env:ProgramData 'LabSession'

# 110GB of RAM on this VM - there is no reason to ever evict a 3.4GB model.
# Machine-scoped so it survives the template being captured and re-launched
# under a different account.
if ([Environment]::GetEnvironmentVariable('OLLAMA_KEEP_ALIVE', 'Machine') -ne '-1') {
    [Environment]::SetEnvironmentVariable('OLLAMA_KEEP_ALIVE', '-1', 'Machine')
    Write-LabLog 'Set OLLAMA_KEEP_ALIVE=-1 machine-wide so the model is never unloaded (takes effect when Ollama next restarts).' -Level Success
    $installed += 'OLLAMA_KEEP_ALIVE=-1'
}
else {
    $skipped += 'OLLAMA_KEEP_ALIVE=-1 (already set)'
}
$env:OLLAMA_KEEP_ALIVE = '-1'

$warmScriptPath = Join-Path $labProgramData 'Warm-OllamaModel.ps1'
Copy-Item -Path (Join-Path $PSScriptRoot 'Warm-OllamaModel.ps1') -Destination $warmScriptPath -Force
Write-Utf8NoBom -Path (Join-Path $labProgramData 'warm-model.json') -Content (@{ Model = $chatModel } | ConvertTo-Json)

try {
    # Runs as whoever logs in, hidden, 30s after logon so it doesn't fight
    # the rest of the boot. Re-registered on every provisioning run because
    # the model tier can change between runs.
    $taskName = 'LabSession-WarmOllamaModel'
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$warmScriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $trigger.Delay = 'PT30S'
    $principal = New-ScheduledTaskPrincipal -GroupId 'BUILTIN\Users' -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 15)
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    Write-LabLog "Registered the '$taskName' logon task - the model loads during the opening talk instead of on an attendee's first prompt." -Level Success
    $installed += 'Ollama warm-up logon task'
}
catch {
    Write-LabLog "Could not register the Ollama warm-up task: $($_.Exception.Message). Not fatal - the first prompt on each VM will just take about 90 seconds." -Level Warn
    $failed += 'Ollama warm-up logon task'
}

# --- Step 4: Continue.dev extension --------------------------------------------
if ($effectiveSkipVSCode) {
    Write-LabLog 'VS Code was skipped - not installing the Continue.dev extension.' -Level Info
    $skipped += 'Continue.dev extension (VS Code skipped)'
}
elseif (Test-CommandExists 'code') {
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
    # Thin wrapper around the shared ClaudeSettingsHelpers functions, kept
    # for the Write-LabLog warning on an unparseable file.
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][scriptblock]$Mutate
    )
    $settings = Get-JsonFileSettings -Path $Path
    if ($null -eq $settings) {
        Write-LabLog "Could not parse existing $Path as JSON - leaving it untouched. Add the Claude Code local-model settings there manually (see claude-code-config/README.md)." -Level Warn
        return $false
    }
    & $Mutate $settings
    Save-JsonFileSettings -Path $Path -Settings $settings
    return $true
}

if ($supportsAgenticCli) {
    if ($effectiveSkipVSCode) {
        Write-LabLog 'VS Code was skipped - not installing the Claude Code VS Code extension. The standalone CLI (claude-local) still works fully.' -Level Info
        $skipped += 'Claude Code VS Code extension (VS Code skipped)'
    }
    elseif (Test-CommandExists 'code') {
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

    # Always runs, VS Code or not - the standalone CLI needs zero VS Code
    # involvement to reach the local Ollama model.
    # One-time safety net, mainly for -TakeHome on a personal PC: whatever
    # settings.json looked like before the lab ever touched it is kept as a
    # timestamped .bak, restorable with 'restore-claude-settings'.
    Backup-ClaudeSettings

    $claudeSettingsPath = Join-Path $HOME '.claude\settings.json'
    $ok = Set-JsonFileSetting -Path $claudeSettingsPath -Mutate {
        param($settings)
        if (-not ($settings.PSObject.Properties.Name -contains 'env')) {
            $settings | Add-Member -NotePropertyName 'env' -NotePropertyValue ([PSCustomObject]@{})
        }
        Set-JsonProperty -Object $settings.env -Name 'ANTHROPIC_AUTH_TOKEN' -Value 'ollama'
        # IfUnset: never blank out a real API key someone already has (a
        # take-home machine!) - ANTHROPIC_BASE_URL routes to Ollama anyway.
        Set-JsonPropertyIfUnset -Object $settings.env -Name 'ANTHROPIC_API_KEY' -Value ''
        Set-JsonProperty -Object $settings.env -Name 'ANTHROPIC_BASE_URL' -Value 'http://localhost:11434'
        Set-JsonProperty -Object $settings -Name 'model' -Value $chatModel
    }
    if ($ok) {
        Write-LabLog "Configured $claudeSettingsPath to route Claude Code (CLI + VS Code extension) to local Ollama." -Level Success
        $installed += 'Claude Code local-model settings (~/.claude/settings.json)'
    }

    if (-not $effectiveSkipVSCode) {
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
    try {
        Set-ContinueConfigBlock -BlockId 'Ollama' -Content $ollamaBlockContent -ParentKey 'models' -Path $configOutPath
        Write-LabLog "Merged the local-Ollama block into $configOutPath (chat: $chatModel, autocomplete: $autocompleteModel) - any other content in that file was left untouched." -Level Success
        $installed += 'Continue.dev config.yaml (Ollama block merged)'
    }
    catch {
        Write-LabLog "Could not merge the local-Ollama block into ${configOutPath}: $($_.Exception.Message). Re-run '.\Provision-LabVM.ps1 -TakeHome' to retry, or paste this block under 'models:' in $configOutPath yourself:`n$($ollamaBlockContent -join "`n")" -Level Error
        $failed += 'Continue.dev config.yaml (Ollama block merge failed)'
    }
}
else {
    $templatePath = Join-Path $repoRoot 'continue-config\config.yaml.template'
    $renderedConfig = (Get-Content -Path $templatePath -Raw) `
        -replace '\{\{OLLAMA_CHAT_MODEL\}\}', $chatModel `
        -replace '\{\{OLLAMA_AUTOCOMPLETE_MODEL\}\}', $autocompleteModel
    Write-Utf8NoBom -Path $configOutPath -Content $renderedConfig
    Write-LabLog "Wrote Continue.dev config to $configOutPath (chat: $chatModel, autocomplete: $autocompleteModel)" -Level Success
    $installed += 'Continue.dev config.yaml'
}

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
    if ($gitAvailable) {
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
    }
    else {
        $skipped += 'Workspace git repo (git not available)'
    }

    if ($effectivePurpose -eq 'Lisp') {
        $workspaceRulesDir = Join-Path $workspaceRoot '.continue\rules'
        New-Item -ItemType Directory -Path $workspaceRulesDir -Force | Out-Null
        # Copy-Item overwrites but never deletes, so a rule file that was
        # renamed in the repo (02-git-workflow.md -> 02-saving-your-work.md)
        # would otherwise survive here and be loaded alongside its replacement.
        # Only the numbered files we ship are cleared - an attendee's own
        # 07-*.md from the Track 2 exercise is deliberately left alone.
        $shippedRuleNames = @(Get-ChildItem -Path (Join-Path $repoRoot 'continue-config\rules') -Filter '*.md' -File | Select-Object -ExpandProperty Name)
        # -Filter goes to the Win32 API, which understands * and ? but not
        # character ranges - the numbering test has to be a -match.
        Get-ChildItem -Path $workspaceRulesDir -Filter '*.md' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^0[1-6]-' -and $shippedRuleNames -notcontains $_.Name } |
            ForEach-Object {
                Remove-Item -Path $_.FullName -Force
                Write-LabLog "Removed a stale rules file left by an earlier provisioning run: $($_.Name)" -Level Info
            }
        Copy-Item -Path (Join-Path $repoRoot 'continue-config\rules\*.md') -Destination $workspaceRulesDir -Force
        Write-LabLog "Synced governance rules into $workspaceRulesDir" -Level Success

        $scaffoldTemplateDir = Join-Path $workspaceRoot '.scaffold-template'
        New-Item -ItemType Directory -Path $scaffoldTemplateDir -Force | Out-Null
        # Only the .lsp files: they are all that gets expanded into my-work\.
        # scaffold\README.md is repo documentation whose relative links point
        # at folders that don't exist in the workspace.
        Copy-Item -Path (Join-Path $repoRoot 'scaffold\*.lsp') -Destination $scaffoldTemplateDir -Force
        Remove-Item -Path (Join-Path $scaffoldTemplateDir 'README.md') -Force -ErrorAction SilentlyContinue
        Write-LabLog "Synced scaffold template into $scaffoldTemplateDir" -Level Success

        # The three-track instructions attendees actually read (see
        # attendee/README.md). Copied in, not linked, so the workspace is
        # self-contained and the files land in the attendee's own first
        # commit - which is what makes Track 2's `git diff` exercise work.
        # Always overwritten: this repo is the source of truth, and a VM
        # carrying an older copy from a previous provisioning run is exactly
        # the failure this avoids.
        Copy-Item -Path (Join-Path $repoRoot 'attendee\START-HERE.md') -Destination (Join-Path $workspaceRoot 'START-HERE.md') -Force
        Copy-Item -Path (Join-Path $repoRoot 'attendee\choose-your-assistant.md') -Destination (Join-Path $workspaceRoot 'choose-your-assistant.md') -Force
        Copy-Item -Path (Join-Path $repoRoot 'attendee\boilerplate-prompt.md') -Destination (Join-Path $workspaceRoot 'boilerplate-prompt.md') -Force
        foreach ($contentFolder in @('tracks', 'showcase', 'how-to', 'optional')) {
            $targetFolder = Join-Path $workspaceRoot $contentFolder
            New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
            Copy-Item -Path (Join-Path $repoRoot "attendee\$contentFolder\*") -Destination $targetFolder -Recurse -Force
        }
        Write-LabLog "Synced attendee instructions into $workspaceRoot (START-HERE.md + assistant pages + tracks\ + showcase\ + how-to\ + optional\)" -Level Success
        $installed += 'Attendee instructions (START-HERE.md + assistant pages + tracks + showcase + how-to + optional)'

        # A git-helpers README in the workspace root put version control in
        # front of people who never asked for it. The same content now lives in
        # optional\git-if-you-want-it.md, reached only from the "optional
        # extras" line on START-HERE.md.
        $legacyGitReadme = Join-Path $workspaceRoot 'README-git-helpers.md'
        if (Test-Path $legacyGitReadme) {
            Remove-Item -Path $legacyGitReadme -Force
            Write-LabLog 'Removed README-git-helpers.md from the workspace root - it now lives in optional\git-if-you-want-it.md.' -Level Info
        }

        # --- Ready-made routine folders -------------------------------------
        # Attendees never run New-Routine, so their folders have to exist
        # before they arrive: correct filenames, prefix already substituted,
        # nothing to create or rename. NEVER overwritten - after the session
        # starts this is the attendee's own work.
        $myWorkDir = Join-Path $workspaceRoot 'my-work'
        New-Item -ItemType Directory -Path $myWorkDir -Force | Out-Null
        $createdRoutineFolders = @()
        foreach ($routineName in @('routine-1', 'routine-2', 'routine-3')) {
            $routineDir = Join-Path $myWorkDir $routineName
            if (Test-Path $routineDir) { continue }
            New-Item -ItemType Directory -Path $routineDir -Force | Out-Null
            $upperToken = $routineName.ToUpper()
            Get-ChildItem -Path $scaffoldTemplateDir -Filter '*.lsp' -File | ForEach-Object {
                $newFileName = $_.Name -replace '^TEMPLATE-', "$routineName-" -replace '^prefix-', "$routineName-"
                $renderedLisp = (Get-Content -Path $_.FullName -Raw) `
                    -replace 'PLACEHOLDER', $upperToken `
                    -replace 'prefix', $routineName
                Write-Utf8NoBom -Path (Join-Path $routineDir $newFileName) -Content $renderedLisp
            }
            $createdRoutineFolders += $routineName
        }

        # Track 2's exercise compares two files side by side, so both have to
        # exist for "Compare Selected" to be selectable at all.
        $rulesExperimentDir = Join-Path $myWorkDir 'rules-experiment'
        New-Item -ItemType Directory -Path $rulesExperimentDir -Force | Out-Null
        foreach ($experimentFile in @('baseline.lsp', 'after.lsp')) {
            $experimentPath = Join-Path $rulesExperimentDir $experimentFile
            if (-not (Test-Path $experimentPath)) {
                Write-Utf8NoBom -Path $experimentPath -Content (@(
                    ';; Track 2 exercise - paste the assistant''s answer here, then File > Save.',
                    ';; See tracks\2-better-results\exercise.md.'
                ) -join "`n")
                $createdRoutineFolders += "rules-experiment\$experimentFile"
            }
        }

        if ($createdRoutineFolders.Count -gt 0) {
            Write-LabLog "Created ready-made work folders under $myWorkDir : $($createdRoutineFolders -join ', ')" -Level Success
            $installed += 'Ready-made routine folders (my-work)'
        }
        else {
            Write-LabLog "Work folders under $myWorkDir already exist - left untouched (they may hold an attendee's work)." -Level Info
            $skipped += 'Ready-made routine folders (already present)'
        }

        # --- VS Code workspace settings -------------------------------------
        # Instruction pages open as a rendered page with clickable links
        # instead of raw markdown, so nobody has to know Ctrl+Shift+V exists.
        # Scoped by path: .continue\rules\*.md stays a normal text file,
        # because Track 2 has attendees edit one.
        $vscodeDir = Join-Path $workspaceRoot '.vscode'
        New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null
        $workspaceSettings = [ordered]@{
            'workbench.editorAssociations' = [ordered]@{
                '**/START-HERE.md'            = 'vscode.markdown.preview.editor'
                '**/choose-your-assistant.md' = 'vscode.markdown.preview.editor'
                '**/boilerplate-prompt.md'    = 'vscode.markdown.preview.editor'
                '**/tracks/**/*.md'           = 'vscode.markdown.preview.editor'
                '**/how-to/**/*.md'           = 'vscode.markdown.preview.editor'
                '**/optional/**/*.md'         = 'vscode.markdown.preview.editor'
                '**/showcase/**/*.md'         = 'vscode.markdown.preview.editor'
            }
            'workbench.startupEditor'      = 'none'
            'explorer.compactFolders'      = $false
            # The workshop is deliberately git-free: a "49" on the Source
            # Control icon and U/M letters on every file read as "you broke
            # something" to this audience. Git itself stays fully working
            # for optional\ and the Timeline.
            'git.countBadge'               = 'off'
            'git.decorations.enabled'      = $false
        }
        Write-Utf8NoBom -Path (Join-Path $vscodeDir 'settings.json') -Content ($workspaceSettings | ConvertTo-Json -Depth 4)
        Write-LabLog "Wrote $vscodeDir\settings.json - instruction pages open rendered, with clickable links." -Level Success
        $installed += 'VS Code workspace settings (rendered instructions)'

        if ($supportsAgenticCli) {
            Copy-Item -Path (Join-Path $repoRoot 'claude-code-config\CLAUDE.md') -Destination (Join-Path $workspaceRoot 'CLAUDE.md') -Force
            Write-LabLog 'Synced CLAUDE.md (local Claude Code CLI governance) into the workspace.' -Level Success
        }
    }
    else {
        Write-LabLog 'Purpose=General - skipping the AutoLISP-specific workspace bootstrap (.continue/rules, .scaffold-template, my-work, .vscode/settings.json, CLAUDE.md). The git workspace itself is still set up for save/undo.' -Level Info
        $skipped += 'AutoLISP workspace bootstrap (rules/scaffold/instructions/my-work/CLAUDE.md) - Purpose=General'
    }

    if ($gitAvailable) {
        # `git log -1` on a brand-new repo exits non-zero and writes to stderr,
        # which PowerShell 7.3+ can turn into a terminating error even though
        # this is an expected, normal outcome here - catch and ignore it, we
        # only care about $LASTEXITCODE.
        try { git log -1 2>&1 | Out-Null } catch { }
        $hasCommits = ($LASTEXITCODE -eq 0)
        # Commit on EVERY run that changed something, not only the first:
        # a re-provisioned VM that only committed on its first-ever run left
        # ~49 uncommitted files, which VS Code's Source Control badge then
        # showed to every attendee.
        $dirty = @(git status --porcelain 2>$null | Where-Object { $_ })
        if (-not $hasCommits -or $dirty.Count -gt 0) {
            git add -A | Out-Null
            $commitMessage = if ($hasCommits) { 'Refresh lab workspace (provisioning re-run)' } else { 'Set up lab workspace' }
            git commit -m $commitMessage | Out-Null
            Write-LabLog "Committed the workspace content ('$commitMessage') - the Source Control badge stays clean." -Level Success
        }
    }
}
finally {
    Pop-Location
}

# --- Step 8b: "START HERE" desktop shortcut ------------------------------------
# 60-90 attendees have 90 minutes and no reason to know what C:\LabWork is.
# One obvious icon on the desktop opens VS Code on the workspace with the
# instructions already showing. Written to the ALL USERS desktop so it
# survives the VM being handed to a different user account than the one
# provisioning ran under.
#
# Targets Code.exe directly rather than the `code` shim on PATH: the shim is
# a .cmd, and a shortcut to it flashes a console window on every launch.
function Resolve-VSCodeExecutable {
    $candidates = @(
        (Join-Path $env:ProgramFiles 'Microsoft VS Code\Code.exe')
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft VS Code\Code.exe')
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe')
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) { return $candidate }
    }
    # Fall back to wherever `code` on PATH lives: <install>\bin\code.cmd,
    # so Code.exe is two levels up.
    $codeCmd = (Get-Command code -ErrorAction SilentlyContinue).Source
    if ($codeCmd) {
        $exe = Join-Path (Split-Path -Parent (Split-Path -Parent $codeCmd)) 'Code.exe'
        if (Test-Path $exe) { return $exe }
    }
    return $null
}

$startHerePath = Join-Path $workspaceRoot 'START-HERE.md'
if ($effectiveSkipVSCode -or $effectivePurpose -ne 'Lisp') {
    Write-LabLog 'Skipping the START HERE desktop shortcut (VS Code skipped, or Purpose is not Lisp).' -Level Info
    $skipped += 'START HERE desktop shortcut'
}
elseif (-not (Test-Path $startHerePath)) {
    Write-LabLog "Skipping the START HERE desktop shortcut - $startHerePath was not created." -Level Warn
    $skipped += 'START HERE desktop shortcut (START-HERE.md missing)'
}
else {
    $vscodeExe = Resolve-VSCodeExecutable
    if (-not $vscodeExe) {
        Write-LabLog 'Could not locate Code.exe - skipping the START HERE desktop shortcut. Attendees can still open C:\LabWork\START-HERE.md manually.' -Level Warn
        $failed += 'START HERE desktop shortcut (Code.exe not found)'
    }
    else {
        $shortcutPath = Join-Path (Join-Path $env:PUBLIC 'Desktop') 'START HERE.lnk'
        $shortcutExisted = Test-Path $shortcutPath
        try {
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath       = $vscodeExe
            $shortcut.Arguments        = "`"$workspaceRoot`" `"$startHerePath`""
            $shortcut.WorkingDirectory = $workspaceRoot
            $shortcut.IconLocation     = "$vscodeExe,0"
            $shortcut.Description      = 'Open the AutoLISP lab workspace and the workshop instructions'
            $shortcut.Save()
            # Rewritten on every run, like the $PROFILE block below - a stale
            # shortcut pointing at a path an earlier run used is worse than
            # no shortcut at all.
            $installed += if ($shortcutExisted) { 'START HERE desktop shortcut (refreshed)' } else { 'START HERE desktop shortcut' }
            Write-LabLog "Created the START HERE desktop shortcut at $shortcutPath" -Level Success
        }
        catch {
            Write-LabLog "Could not create the START HERE desktop shortcut: $($_.Exception.Message)" -Level Error
            $failed += 'START HERE desktop shortcut'
        }
    }
}

# --- Step 8c: optional AI assistant apps + web shortcuts -----------------------
# Attendees with their own ChatGPT/Claude/etc. account may use it (see
# attendee/choose-your-assistant.md). Desktop apps where they exist, an
# "AI Assistants" desktop folder of Edge-openable .url shortcuts for the
# rest. Everything here is optional and best-effort: a blocked msstore or
# missing winget must never fail provisioning. Skipped under -TakeHome -
# installing chat apps on someone's personal machine is not our call.
if ($TakeHome) {
    Write-LabLog 'Skipping the optional AI assistant apps/shortcuts (-TakeHome).' -Level Info
    $skipped += 'AI assistant apps + shortcuts (-TakeHome)'
}
else {
    if (Test-CommandExists 'winget') {
        foreach ($app in $config.DesktopAiApps) {
            Install-OptionalWingetApp -DisplayName $app.DisplayName -WingetId $app.WingetId -Source $app.Source
        }
    }
    else {
        Write-LabLog 'winget not available - skipping the optional AI assistant desktop apps.' -Level Warn
        $skipped += 'AI assistant desktop apps (winget not available)'
    }

    # Rewritten on every run, same rationale as the START HERE shortcut.
    $aiShortcutDir = Join-Path (Join-Path $env:PUBLIC 'Desktop') 'AI Assistants'
    try {
        New-Item -ItemType Directory -Path $aiShortcutDir -Force | Out-Null
        foreach ($site in $config.WebAiShortcuts) {
            $urlFile = Join-Path $aiShortcutDir "$($site.Name).url"
            Set-Content -Path $urlFile -Value @(
                '[InternetShortcut]'
                "URL=$($site.Url)"
            ) -Encoding ASCII
        }
        Write-LabLog "Wrote $($config.WebAiShortcuts.Count) AI assistant web shortcuts into $aiShortcutDir" -Level Success
        $installed += 'AI Assistants desktop folder'
    }
    catch {
        Write-LabLog "Could not write the AI Assistants desktop folder: $($_.Exception.Message) - optional, continuing." -Level Warn
        $skipped += 'AI Assistants desktop folder (write failed)'
    }
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

if ($gitAvailable) {
    try {
        & (Join-Path $repoRoot 'git-helpers\git-aliases.ps1') | Out-Null
        $installed += 'Portable git save/undo aliases'
    }
    catch {
        Write-LabLog "Could not install portable git aliases: $($_.Exception.Message)" -Level Warn
        $failed += 'Portable git save/undo aliases'
    }
}
else {
    $skipped += 'Portable git save/undo aliases (git not available)'
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
    # ContinueConfigHelpers.psm1 imports Write-Utf8NoBom from
    # ClaudeSettingsHelpers.psm1 at load time - without this copy, every new
    # terminal errors on the profile's Import-Module ContinueProviders and
    # continue-provider cannot write config.yaml.
    Copy-Item -Path (Join-Path $repoRoot 'claude-code-config\ClaudeSettingsHelpers.psm1') -Destination $continueProvidersModuleDir -Force
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

    # $scaffoldTemplateDir is only assigned in Step 8 when
    # $effectivePurpose -eq 'Lisp' - guard it the same way
    # $localClaudeImportLine already is, rather than writing an empty
    # LAB_SCAFFOLD_TEMPLATE for a folder that was never created.
    $scaffoldEnvLine = if ($effectivePurpose -eq 'Lisp') { "`$env:LAB_SCAFFOLD_TEMPLATE = '$scaffoldTemplateDir'" } else { '' }

    $profileBlockStart = '# LabSession-Helpers-Start'
    $profileBlockEnd   = '# LabSession-Helpers-End'
    $profileBlock = @"
$profileBlockStart
`$env:LAB_WORKSPACE_ROOT = '$workspaceRoot'
$scaffoldEnvLine
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
    # Both branches build the complete new profile text in memory and write
    # it once through Write-Utf8NoBom - Add-Content (ANSI on 5.1) mixed with
    # Set-Content -Encoding UTF8 (BOM on 5.1) previously left the same file
    # with two different encodings depending on which path last touched it.
    if ($profileContent -and $profileContent.Contains($profileBlockStart)) {
        # Re-run: refresh the block in place (model tier facts can change
        # across re-runs, e.g. after a ModelOverride edit) rather than
        # skipping - a stale, never-updated profile is exactly the bug
        # that motivated this rewrite.
        $blockPattern = [regex]::Escape($profileBlockStart) + '[\s\S]*?' + [regex]::Escape($profileBlockEnd)
        $existingBlockMatch = [regex]::Match($profileContent, $blockPattern)
        if ($existingBlockMatch.Success) {
            $newContent = $profileContent.Remove($existingBlockMatch.Index, $existingBlockMatch.Length).Insert($existingBlockMatch.Index, $profileBlock)
            Write-Utf8NoBom -Path $target.ProfilePath -Content $newContent
            $installed += "PowerShell profile block refreshed ($($target.Name))"
        }
        else {
            Write-LabLog "Found '$profileBlockStart' in $($target.ProfilePath) but no matching '$profileBlockEnd' - leaving it untouched rather than risk corrupting it. Remove the stray marker line manually and re-run." -Level Warn
            $failed += "PowerShell profile block ($($target.Name), corrupted marker)"
        }
    }
    else {
        if ($null -eq $profileContent) { $profileContent = '' }
        Write-Utf8NoBom -Path $target.ProfilePath -Content ($profileContent.TrimEnd() + "`n`n$profileBlock")
        $installed += "PowerShell profile block ($($target.Name))"
    }
}

# --- Summary --------------------------------------------------------------------
$status = if ($failed.Count -gt 0) { 'FAIL' } elseif ($needsNewShell.Count -gt 0) { 'PASS (new shell needed)' } else { 'PASS' }
$statusColor = if ($failed.Count -gt 0) { 'Red' } elseif ($needsNewShell.Count -gt 0) { 'Yellow' } else { 'Green' }

Write-Host "`n=== Provision-LabVM Summary: $status ===" -ForegroundColor $statusColor
Write-Host "Workspace:     $workspaceRoot - attendees start from the 'START HERE' desktop shortcut"
Write-Host "Chosen model:  $chatModel (chat/edit, fast default), $autocompleteModel (autocomplete)"
if ($qualityModel) {
    Write-Host "Quality model (opt-in, slower): $qualityModel - switch with 'quality-model' / back with 'fast-model'"
}
Write-Host "Claude Code CLI (local, optional): $(if ($supportsAgenticCli) { "enabled - run 'claude-local' in a new shell" } else { 'not offered on this VM tier' })"
if ($supportsAgenticCli) {
    Write-Host "Pulled something else with 'ollama pull'? Run 'switch-model' in a new shell to pick from any locally pulled model, not just fast/quality."
}
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
