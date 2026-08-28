<#
    .SYNOPSIS
    End-to-end verification that one lab VM is genuinely ready for
    attendees. Writes a machine-readable report that Publish-LabReport.ps1
    pushes back through git.

    .DESCRIPTION
    The manual pre-flight checklist can't scale to a fleet and can't check
    the thing that matters most: that the model actually answers. This
    does both - every check returns PASS/WARN/FAIL with a reason, and the
    result lands in report.json / report.md.

    Read-only apart from its own output and a throwaway temp workspace.
    It never touches the attendee workspace, never pulls a model, and
    never changes any configuration - so it is safe to run on a VM that
    is about to be handed to someone.

    A FAIL means do not hand this VM to an attendee. A WARN means it will
    work but something is off - read the reason.

    .PARAMETER OutputDirectory
    Where report.json / report.md go. Defaults to verification/out/,
    which is git-ignored.

    .PARAMETER SkipGeneration
    Skip the live model-generation check (check 4), the slowest one.
    Use when re-testing something else and you already know the model
    answers.

    .PARAMETER GenerationTimeoutSeconds
    How long to wait for the model's reply before calling it a failure.

    .EXAMPLE
    .\Invoke-LabSelfTest.ps1

    .EXAMPLE
    .\Invoke-LabSelfTest.ps1 -SkipGeneration
#>

[CmdletBinding()]
param(
    [string]$OutputDirectory,
    [switch]$SkipGeneration,
    [int]$GenerationTimeoutSeconds = 120
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

. (Join-Path $repoRoot 'provisioning\lib\Common.ps1')

if (-not $OutputDirectory) { $OutputDirectory = Join-Path $PSScriptRoot 'out' }
if (-not (Test-Path $OutputDirectory)) { New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null }

$checks = [System.Collections.Generic.List[object]]::new()

function Add-Check {
    <#
        Records one check result. $Status is PASS, WARN or FAIL; $Detail
        must explain *why* well enough to act on without re-running
        anything - these reports get read on someone else's laptop.
    #>
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('PASS', 'WARN', 'FAIL')][string]$Status,
        [Parameter(Mandatory)][string]$Detail,
        [hashtable]$Data
    )
    $checks.Add([ordered]@{
        Name   = $Name
        Status = $Status
        Detail = $Detail
        Data   = $Data
    })
    $level = switch ($Status) { 'FAIL' { 'Error' } 'WARN' { 'Warn' } default { 'Success' } }
    Write-LabLog "[$Status] $Name - $Detail" -Level $level
}

function Invoke-Check {
    <#
        Runs a check body and turns any unexpected exception into a FAIL
        rather than aborting the whole run. One broken check must never
        cost us the other nine - a partial report is still useful, a
        crashed script is not.
    #>
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$Body
    )
    try { & $Body }
    catch { Add-Check -Name $Name -Status FAIL -Detail "Check threw an unexpected error: $($_.Exception.Message)" }
}

$ollamaApi = 'http://localhost:11434'
Write-LabLog "Starting lab VM self-test on $env:COMPUTERNAME..." -Level Info

# --- 1. Hardware, tooling, AutoCAD/Civil 3D ----------------------------------
# Delegated to the existing diagnostics script rather than duplicated, so
# there is exactly one definition of "is this the right VM image".
$specs = $null
Invoke-Check 'Hardware and tooling' {
    $script:specs = & (Join-Path $repoRoot 'provisioning\Test-LabVMSpecs.ps1')
    $detail = "$($specs.TotalRamGB)GB RAM, $($specs.CpuPhysicalCores) cores, GPU '$($specs.GpuNames)'; AutoCAD $(if ($specs.AutoCADDetected) { 'detected' } else { 'MISSING' }), Civil 3D $(if ($specs.Civil3DDetected) { 'detected' } else { 'MISSING' })"
    $status = switch ($specs.Status) { 'FAIL' { 'FAIL' } 'WARN' { 'WARN' } default { 'PASS' } }
    if ($specs.Failures)  { $detail += " | Failures: $($specs.Failures -join '; ')" }
    if ($specs.Warnings)  { $detail += " | Warnings: $($specs.Warnings -join '; ')" }
    Add-Check -Name 'Hardware and tooling' -Status $status -Detail $detail -Data @{
        RamGB = $specs.TotalRamGB; Cores = $specs.CpuPhysicalCores; Gpu = $specs.GpuNames
        AutoCAD = [bool]$specs.AutoCADDetected; Civil3D = [bool]$specs.Civil3DDetected
        RecommendedChatModel = $specs.RecommendedChatModel
        SupportsAgenticCli = [bool]$specs.SupportsAgenticCli
    }
}

$expectedChatModel = if ($specs) { $specs.RecommendedChatModel } else { $null }
$expectedQualityModel = if ($specs) { $specs.RecommendedQualityChatModel } else { $null }
$expectedAutocompleteModel = if ($specs) { $specs.RecommendedAutocompleteModel } else { $null }
$supportsAgenticCli = if ($specs) { [bool]$specs.SupportsAgenticCli } else { $false }

# --- 2. Is Ollama actually serving? -------------------------------------------
$pulledTags = @()
Invoke-Check 'Ollama reachable' {
    # Caught here rather than left to Invoke-Check's generic handler: a
    # refused connection is the single most likely failure on this check,
    # and "check threw an unexpected error" in a report someone reads on
    # another machine tomorrow is useless. Name the fix in the report.
    try {
        $response = Invoke-RestMethod -Uri "$ollamaApi/api/tags" -Method Get -TimeoutSec 20
    }
    catch {
        Add-Check -Name 'Ollama reachable' -Status FAIL -Detail "Nothing is answering at $ollamaApi ($($_.Exception.Message)). Ollama is either not installed or not running - start it with 'ollama serve', or restart the Ollama background service, then re-run. Every model check below will fail until this does."
        return
    }
    $script:pulledTags = @($response.models | ForEach-Object { $_.name })
    if ($pulledTags.Count -eq 0) {
        Add-Check -Name 'Ollama reachable' -Status FAIL -Detail "Ollama answered at $ollamaApi but reports no pulled models. Run Provision-LabVM.ps1 to pull them."
    }
    else {
        Add-Check -Name 'Ollama reachable' -Status PASS -Detail "$ollamaApi responded; $($pulledTags.Count) model(s) pulled: $($pulledTags -join ', ')" -Data @{ PulledModels = $pulledTags }
    }
}

# --- 3. Are the models this tier expects present, by exact tag? ---------------
Invoke-Check 'Expected models pulled' {
    $expected = @($expectedChatModel, $expectedAutocompleteModel) + @($expectedQualityModel) | Where-Object { $_ }
    if (-not $expected) {
        Add-Check -Name 'Expected models pulled' -Status WARN -Detail 'Could not determine the expected models - the hardware check did not complete.'
        return
    }
    # Ollama reports "name:tag"; a bare "qwen3.5:4b" in the decision table
    # must match "qwen3.5:4b" exactly, not "qwen3.5:4b-instruct".
    $missing = @($expected | Where-Object { $pulledTags -notcontains $_ })
    if ($missing.Count -eq 0) {
        Add-Check -Name 'Expected models pulled' -Status PASS -Detail "All expected models present: $($expected -join ', ')" -Data @{ Expected = $expected }
    }
    else {
        Add-Check -Name 'Expected models pulled' -Status FAIL -Detail "Missing: $($missing -join ', '). Pull them BEFORE the session - a live pull costs minutes. Run: $(($missing | ForEach-Object { "ollama pull $_" }) -join '; ')" -Data @{ Expected = $expected; Missing = $missing }
    }
}

# --- 4. Does the model actually answer? --------------------------------------
# The check the manual checklist cannot do at fleet scale, and the one that
# catches a VM where everything is installed but nothing works.
Invoke-Check 'Model generates a response' {
    if ($SkipGeneration) {
        Add-Check -Name 'Model generates a response' -Status WARN -Detail '-SkipGeneration was passed; the model was never actually exercised on this VM.'
        return
    }
    if (-not $expectedChatModel) {
        Add-Check -Name 'Model generates a response' -Status WARN -Detail 'No chat model determined - skipped.'
        return
    }
    $prompt = 'Reply with exactly one short sentence: what does the AutoLISP function princ do?'

    # think=false matters enormously on the reasoning models in this table.
    # Measured on the real lab VM: qwen3.5:4b spent 222 tokens / 31.8s to
    # answer "hello" with thinking on, and 10 tokens / 2.1s with it off -
    # same visible answer. Ollama rejects the field outright on models that
    # don't support thinking, so fall back rather than assume.
    $attempts = @(
        @{ Label = 'thinking disabled'; Body = @{ model = $expectedChatModel; prompt = $prompt; stream = $false; think = $false } }
        @{ Label = 'default';           Body = @{ model = $expectedChatModel; prompt = $prompt; stream = $false } }
    )

    $reply = $null
    $usedLabel = $null
    $seconds = 0
    $lastError = $null
    foreach ($attempt in $attempts) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $reply = Invoke-RestMethod -Uri "$ollamaApi/api/generate" -Method Post -Body ($attempt.Body | ConvertTo-Json) -ContentType 'application/json' -TimeoutSec $GenerationTimeoutSeconds
            $stopwatch.Stop()
            $seconds = [math]::Round($stopwatch.Elapsed.TotalSeconds, 1)
            $usedLabel = $attempt.Label
            break
        }
        catch {
            $stopwatch.Stop()
            $lastError = $_.Exception.Message
            # A timeout is a real result, not a reason to retry differently -
            # report it plainly instead of letting the generic handler call
            # it "an unexpected error".
            if ($lastError -match 'timed out') {
                Add-Check -Name 'Model generates a response' -Status FAIL -Detail "$expectedChatModel did not answer a one-sentence prompt within ${GenerationTimeoutSeconds}s (attempt: $($attempt.Label)). Attendees would wait at least this long for every reply. Check whether the model is reasoning before answering, and whether it fits in this GPU's VRAM." -Data @{ Model = $expectedChatModel; TimeoutSeconds = $GenerationTimeoutSeconds }
                return
            }
        }
    }

    if (-not $reply) {
        Add-Check -Name 'Model generates a response' -Status FAIL -Detail "$expectedChatModel could not be prompted at all. Last error: $lastError"
        return
    }

    $text = "$($reply.response)".Trim()
    if (-not $text) {
        Add-Check -Name 'Model generates a response' -Status FAIL -Detail "$expectedChatModel accepted the request but returned an empty response after ${seconds}s."
        return
    }

    # Wall-clock alone is ambiguous and blames the wrong thing: measured on
    # the real lab VM, a cold run took 90.7s total of which 2.0s was
    # generation and ~88s was loading the model into VRAM. Those need
    # opposite fixes - one is a model choice, the other is a keep-alive
    # setting - so report them separately.
    $tokens = [int]$reply.eval_count
    $loadSeconds = [math]::Round($reply.load_duration / 1e9, 1)
    $evalSeconds = [math]::Round($reply.eval_duration / 1e9, 1)
    $tokensPerSecond = if ($reply.eval_duration -gt 0) { [math]::Round($tokens / ($reply.eval_duration / 1e9), 1) } else { 0 }
    $excerpt = if ($text.Length -gt 200) { $text.Substring(0, 200) + '...' } else { $text }

    $notes = @()
    $status = 'PASS'
    if ($tokensPerSecond -gt 0 -and $tokensPerSecond -lt 5) {
        $status = 'WARN'
        $notes += "generation is only $tokensPerSecond tok/s, so a full routine will take minutes - check the model fits this GPU's VRAM and that it isn't reasoning before answering"
    }
    if ($loadSeconds -gt 20) {
        $status = 'WARN'
        $notes += "the model took ${loadSeconds}s to load into memory. Generation itself was fine. This is a cold start, and Ollama unloads an idle model after 5 minutes by default - so any attendee who pauses pays it again. Set OLLAMA_KEEP_ALIVE and pre-warm the model at logon"
    }
    $note = if ($notes) { ' - ' + ($notes -join '; ') + '.' } else { '' }

    Add-Check -Name 'Model generates a response' -Status $status -Detail "$expectedChatModel answered in ${seconds}s total (load ${loadSeconds}s, generate ${evalSeconds}s for $tokens tokens = $tokensPerSecond tok/s, $usedLabel)$note Excerpt: $excerpt" -Data @{
        Model = $expectedChatModel; TotalSeconds = $seconds; LoadSeconds = $loadSeconds
        EvalSeconds = $evalSeconds; Tokens = $tokens; TokensPerSecond = $tokensPerSecond
        Mode = $usedLabel; Excerpt = $excerpt
    }
}

# --- 5. Continue.dev config points at models that exist -----------------------
Invoke-Check 'Continue.dev config' {
    $configPath = Join-Path $HOME '.continue\config.yaml'
    if (-not (Test-Path $configPath)) {
        Add-Check -Name 'Continue.dev config' -Status FAIL -Detail "$configPath does not exist. Re-run Provision-LabVM.ps1."
        return
    }
    $content = Get-Content -Path $configPath -Raw
    # Deliberately a regex over `model:` lines rather than a YAML parse -
    # Windows PowerShell 5.1 has no YAML parser and this file is generated
    # from a template we control.
    $referenced = @([regex]::Matches($content, '(?m)^\s*model:\s*"?([^"\r\n]+)"?\s*$') | ForEach-Object { $_.Groups[1].Value.Trim() })
    if ($referenced.Count -eq 0) {
        Add-Check -Name 'Continue.dev config' -Status FAIL -Detail "$configPath contains no model: entries - it was not rendered correctly."
        return
    }
    $dangling = @($referenced | Where-Object { $pulledTags -notcontains $_ })
    if ($dangling.Count -eq 0) {
        Add-Check -Name 'Continue.dev config' -Status PASS -Detail "References $($referenced.Count) model(s), all pulled: $($referenced -join ', ')" -Data @{ Referenced = $referenced }
    }
    else {
        Add-Check -Name 'Continue.dev config' -Status FAIL -Detail "References model(s) that are not pulled: $($dangling -join ', '). Continue.dev will error on the first prompt. Re-run Provision-LabVM.ps1." -Data @{ Referenced = $referenced; Dangling = $dangling }
    }
}

# --- 6. Claude Code settings still point at local Ollama ----------------------
Invoke-Check 'Claude Code local-model settings' {
    if (-not $supportsAgenticCli) {
        Add-Check -Name 'Claude Code local-model settings' -Status PASS -Detail 'This VM tier does not offer the Claude Code CLI - nothing to check.'
        return
    }
    $settingsPath = Join-Path $HOME '.claude\settings.json'
    if (-not (Test-Path $settingsPath)) {
        Add-Check -Name 'Claude Code local-model settings' -Status FAIL -Detail "$settingsPath does not exist - Claude Code would prompt for an Anthropic sign-in. Re-run Provision-LabVM.ps1, or run 'local-mode'."
        return
    }
    $settings = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
    $baseUrl = $settings.env.ANTHROPIC_BASE_URL
    $model = $settings.model
    $problems = @()
    if ($baseUrl -ne $ollamaApi) { $problems += "ANTHROPIC_BASE_URL is '$baseUrl', expected '$ollamaApi'" }
    if (-not $model) { $problems += 'no "model" field set' }
    elseif ($pulledTags -notcontains $model) { $problems += "model '$model' is not pulled" }

    if ($problems.Count -eq 0) {
        Add-Check -Name 'Claude Code local-model settings' -Status PASS -Detail "Routed to local Ollama, model '$model'." -Data @{ Model = $model; BaseUrl = $baseUrl }
    }
    else {
        Add-Check -Name 'Claude Code local-model settings' -Status FAIL -Detail "$($problems -join '; '). Run 'local-mode' in a new shell, or re-run Provision-LabVM.ps1." -Data @{ Model = $model; BaseUrl = $baseUrl }
    }
}

# --- 7. Helper commands available in BOTH PowerShell versions -----------------
# This VM has Windows PowerShell 5.1 and PowerShell 7+, which do not share
# module paths or profiles. WARN rather than FAIL since the workshop went
# terminal-free: the helpers now only back attendee\optional\git-if-you-want-it.md,
# so a facilitator wants to know, but it is not a reason to hold the VM back.
Invoke-Check 'Helper commands in both shells' {
    $targets = @(
        @{ Name = 'Windows PowerShell 5.1'; Profile = Join-Path $HOME 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'; Modules = Join-Path $HOME 'Documents\WindowsPowerShell\Modules' }
        @{ Name = 'PowerShell 7+';          Profile = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1';       Modules = Join-Path $HOME 'Documents\PowerShell\Modules' }
    )
    $problems = @()
    foreach ($target in $targets) {
        if (-not (Test-Path $target.Profile)) { $problems += "$($target.Name): no profile file"; continue }
        $profileContent = Get-Content -Path $target.Profile -Raw
        if ($profileContent -notmatch 'LabSession-Helpers-Start') { $problems += "$($target.Name): profile has no LabSession helper block" }
        if (-not (Test-Path (Join-Path $target.Modules 'LabGitHelpers\LabGitHelpers.psm1'))) { $problems += "$($target.Name): LabGitHelpers module not installed" }
    }
    if ($problems.Count -eq 0) {
        Add-Check -Name 'Helper commands in both shells' -Status PASS -Detail 'New-Routine/save/undo are wired into Windows PowerShell 5.1 and PowerShell 7+.'
    }
    else {
        Add-Check -Name 'Helper commands in both shells' -Status WARN -Detail "$($problems -join '; '). Re-run Provision-LabVM.ps1. Optional: no track sends an attendee to a terminal, so this does not block handing the VM over." -Data @{ Problems = $problems }
    }
}

# --- 7b. Provisioned modules import cleanly in BOTH PowerShell versions -------
# Catches the class of bug where a module folder misses a nested dependency
# (ContinueProviders needs ClaudeSettingsHelpers.psm1 for Write-Utf8NoBom) or
# an exported name trips PowerShell's import-time name check - either one
# prints a banner in every terminal anyone opens on this VM. WARN rather than
# FAIL for the same reason as check 7: the session is terminal-free, so it
# never blocks a handover, but a facilitator must know. Each import runs in a
# child -NoProfile shell of the matching PowerShell version, so 5.1 is
# genuinely exercised rather than assumed.
Invoke-Check 'Provisioned modules import cleanly' {
    $targets = @(
        @{ Name = 'Windows PowerShell 5.1'; Exe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'; Modules = Join-Path $HOME 'Documents\WindowsPowerShell\Modules' }
        @{ Name = 'PowerShell 7+';          Exe = 'pwsh';                                                                     Modules = Join-Path $HOME 'Documents\PowerShell\Modules' }
    )
    $moduleNames = @('LabGitHelpers', 'ContinueProviders', 'LocalClaude', 'LiteLLMGateway')
    # A missing nested dependency surfaces as a NON-terminating error from
    # the inner Import-Module - the outer import still "succeeds" (which is
    # why a VM terminal shows the banner yet keeps working). So the child
    # inspects $Error rather than trusting the exit of -ErrorAction Stop.
    $childScript = '$Error.Clear(); $labImportWarnings = $null; try { Import-Module $env:LAB_SELFTEST_MODULE -WarningVariable labImportWarnings -ErrorAction SilentlyContinue 3>$null 2>$null } catch { "ERROR: $($_.Exception.Message)"; exit 1 }; if ($Error.Count -gt 0) { foreach ($e in $Error) { "ERROR: $e" }; exit 1 }; if ($labImportWarnings) { foreach ($w in $labImportWarnings) { "WARNING: $w" }; exit 2 }; exit 0'
    $problems = @()
    $tested = 0
    try {
        foreach ($target in $targets) {
            if (-not (Get-Command $target.Exe -ErrorAction SilentlyContinue)) { $problems += "$($target.Name): '$($target.Exe)' not found"; continue }
            foreach ($moduleName in $moduleNames) {
                $moduleDir = Join-Path $target.Modules $moduleName
                # Absent is fine here: which modules SHOULD exist is check 7's
                # job, and LocalClaude/LiteLLMGateway are tier/take-home
                # optional. Present-but-broken is what this check is for.
                if (-not (Test-Path $moduleDir)) { continue }
                $env:LAB_SELFTEST_MODULE = $moduleDir
                $output = & $target.Exe -NoProfile -NonInteractive -Command $childScript 2>&1
                $tested++
                if ($LASTEXITCODE -ne 0) { $problems += "$($target.Name): $moduleName - $(($output | Out-String).Trim())" }
            }
        }
    }
    finally {
        Remove-Item Env:\LAB_SELFTEST_MODULE -ErrorAction SilentlyContinue
    }
    if ($tested -eq 0 -and $problems.Count -eq 0) {
        Add-Check -Name 'Provisioned modules import cleanly' -Status WARN -Detail 'No provisioned lab modules found to import - has Provision-LabVM.ps1 run on this machine?'
    }
    elseif ($problems.Count -eq 0) {
        Add-Check -Name 'Provisioned modules import cleanly' -Status PASS -Detail "$tested module import(s) completed with no errors and no warnings across both PowerShell versions." -Data @{ Imports = $tested }
    }
    else {
        Add-Check -Name 'Provisioned modules import cleanly' -Status WARN -Detail "$($problems -join '; '). Every new terminal on this VM shows this as a banner. Fix the module source, re-run Provision-LabVM.ps1, and reopen terminals." -Data @{ Problems = $problems }
    }
}

# --- 8. The attendee workspace has everything the instructions promise --------
Invoke-Check 'Attendee workspace' {
    $config = Import-PowerShellDataFile -Path (Join-Path $repoRoot 'provisioning\config\provisioning.config.psd1')
    $workspaceRoot = if ($env:LAB_WORKSPACE_ROOT) { $env:LAB_WORKSPACE_ROOT } else { $config.WorkspaceRoot }
    $required = @(
        @{ Path = '.git';                                              What = 'git repo' }
        @{ Path = '.scaffold-template';                                What = 'scaffold template (the my-work folders are built from it)' }
        @{ Path = 'START-HERE.md';                                     What = 'START-HERE.md' }
        @{ Path = 'tracks\1-first-routine\README.md';                  What = 'Track 1' }
        @{ Path = 'tracks\2-better-results\README.md';                 What = 'Track 2' }
        @{ Path = 'tracks\3-teach-and-scale\README.md';                What = 'Track 3' }
        @{ Path = 'tracks\1-first-routine\examples\hello-world.lsp';   What = 'the routine Track 1 step 2 tells attendees to APPLOAD' }
        @{ Path = 'choose-your-assistant.md';                          What = 'the AI-options page START-HERE points at' }
        @{ Path = 'boilerplate-prompt.md';                             What = 'the boilerplate prompt for bring-your-own-account tools' }
        @{ Path = 'showcase\roundabout\rdb-loader.lsp';                What = 'the roundabout showcase loader' }
        @{ Path = 'showcase\cadastral-map\eg-loader.lsp';              What = 'the cadastral-map showcase loader' }
        @{ Path = 'tracks\1-first-routine\examples\make-layers.lsp';   What = 'Track 1 layer example' }
        @{ Path = 'tracks\2-better-results\examples\well-behaved-command.lsp'; What = 'Track 2 well-behaved-command specimen' }
        @{ Path = 'tracks\3-teach-and-scale\examples\read-the-drawing.lsp';    What = 'Track 3 read-the-drawing example' }
        # The terminal-free path: reference cards, the optional git corner, the
        # ready-made work folders, and the setting that makes the instructions
        # open rendered instead of as raw markdown.
        @{ Path = 'how-to\load-a-routine.md';                          What = 'the APPLOAD how-to card every track links to' }
        @{ Path = 'how-to\save-your-work.md';                          What = 'the save/Timeline how-to card (replaces the git helpers)' }
        @{ Path = 'how-to\compare-two-files.md';                       What = 'the Compare Selected card Track 2 ends on' }
        @{ Path = 'how-to\open-the-assistant.md';                      What = 'the open-your-assistant card (the browser-first front door)' }
        @{ Path = 'how-to\get-code-into-a-file.md';                    What = 'the paste-save-.lsp card every assistant answer goes through' }
        @{ Path = 'optional\git-if-you-want-it.md';                    What = 'the optional git page START-HERE links to' }
        @{ Path = 'my-work\routine-1\routine-1-loader.lsp';            What = 'the ready-made routine folder Track 1 step 3 opens' }
        @{ Path = 'my-work\rules-experiment\baseline.lsp';             What = "Track 2's baseline file" }
        @{ Path = 'my-work\rules-experiment\after.lsp';                What = "Track 2's after file" }
        @{ Path = '.vscode\settings.json';                             What = 'the workspace settings that open instructions rendered' }
    )
    $missing = @($required | Where-Object { -not (Test-Path (Join-Path $workspaceRoot $_.Path)) } | ForEach-Object { $_.What })

    $rulesDir = Join-Path $workspaceRoot '.continue\rules'
    $ruleCount = if (Test-Path $rulesDir) { @(Get-ChildItem -Path $rulesDir -Filter '*.md' -File).Count } else { 0 }
    if ($ruleCount -lt 6) { $missing += "governance rules ($ruleCount of 6 present in .continue\rules)" }

    $shortcut = Join-Path (Join-Path $env:PUBLIC 'Desktop') 'START HERE.lnk'
    if (-not (Test-Path $shortcut)) { $missing += 'START HERE desktop shortcut' }

    # Regression guard for the "49 changes" Source Control badge: a workspace
    # left dirty by a provisioning re-run shows every file as a pending
    # change to every attendee. Provisioning now commits on every run.
    if ((Test-Path (Join-Path $workspaceRoot '.git')) -and (Get-Command git -ErrorAction SilentlyContinue)) {
        $dirty = @(git -C $workspaceRoot status --porcelain 2>$null | Where-Object { $_ })
        if ($dirty.Count -gt 0) {
            $missing += "a clean git status ($($dirty.Count) uncommitted changes - the Source Control badge will show them; re-run Provision-LabVM.ps1)"
        }
    }

    if ($missing.Count -eq 0) {
        Add-Check -Name 'Attendee workspace' -Status PASS -Detail "$workspaceRoot is complete: git repo, $ruleCount rules, scaffold, all three tracks + examples, how-to cards, optional git page, both showcases, ready-made my-work folders, rendered-markdown settings, desktop shortcut." -Data @{ WorkspaceRoot = $workspaceRoot; RuleCount = $ruleCount }
    }
    else {
        Add-Check -Name 'Attendee workspace' -Status FAIL -Detail "Missing from ${workspaceRoot}: $($missing -join '; '). Re-run Provision-LabVM.ps1." -Data @{ WorkspaceRoot = $workspaceRoot; Missing = $missing }
    }
}

# --- 9. Do the git helpers still work? ---------------------------------------
# Against a throwaway temp workspace, never the attendee's. The old manual
# checklist created a branch in C:\LabWork and relied on remembering to
# delete it; a VM handed over with a stray preflight-check branch is
# confusing at best.
#
# WARN, not FAIL: no attendee runs New-Routine any more. The workshop is
# terminal-free and the helpers only back attendee\optional\, so a VM with a
# broken helper is still a VM you can hand over.
Invoke-Check 'Git helpers smoke test' {
    $moduleManifest = Join-Path $HOME 'Documents\PowerShell\Modules\LabGitHelpers\LabGitHelpers.psm1'
    if (-not (Test-Path $moduleManifest)) {
        $moduleManifest = Join-Path $HOME 'Documents\WindowsPowerShell\Modules\LabGitHelpers\LabGitHelpers.psm1'
    }
    if (-not (Test-Path $moduleManifest)) {
        Add-Check -Name 'Git helpers smoke test' -Status WARN -Detail 'LabGitHelpers module not installed in either shell - cannot test New-Routine. Optional: only the attendee\optional\ git page mentions it.'
        return
    }
    if (-not (Test-CommandExists 'git')) {
        Add-Check -Name 'Git helpers smoke test' -Status WARN -Detail 'git is not on PATH, so the optional git helpers cannot be tested. No track needs them.'
        return
    }

    $sandbox = Join-Path ([System.IO.Path]::GetTempPath()) "lab-selftest-$([guid]::NewGuid().ToString('N').Substring(0,8))"
    New-Item -ItemType Directory -Path $sandbox -Force | Out-Null
    try {
        Push-Location $sandbox
        git init --quiet 2>&1 | Out-Null
        git config user.name 'Lab Self Test' | Out-Null
        git config user.email 'selftest@lab.local' | Out-Null
        New-Item -ItemType File -Path (Join-Path $sandbox 'seed.txt') -Force | Out-Null
        git add -A 2>&1 | Out-Null
        git commit -m 'seed' --quiet 2>&1 | Out-Null
        Pop-Location

        # Copy the real scaffold in, so this exercises the same template
        # New-Routine uses on the VM.
        $sandboxScaffold = Join-Path $sandbox '.scaffold-template'
        New-Item -ItemType Directory -Path $sandboxScaffold -Force | Out-Null
        Copy-Item -Path (Join-Path $repoRoot 'scaffold\*') -Destination $sandboxScaffold -Recurse -Force

        $env:LAB_WORKSPACE_ROOT = $sandbox
        $env:LAB_SCAFFOLD_TEMPLATE = $sandboxScaffold
        Import-Module $moduleManifest -Force

        # 6>&1 as well as 3>&1: New-Routine reports via Write-Host, which is
        # the information stream (6) on PowerShell 5+, not the warning
        # stream - without this its output leaks into the self-test log.
        New-Routine -Name 'selftest-routine' 3>&1 6>&1 | Out-Null

        Push-Location $sandbox
        $branch = (git rev-parse --abbrev-ref HEAD 2>&1).ToString().Trim()
        Pop-Location
        $createdFiles = @(Get-ChildItem -Path (Join-Path $sandbox 'selftest-routine') -Filter '*.lsp' -File -ErrorAction SilentlyContinue)

        if ($branch -eq 'selftest-routine' -and $createdFiles.Count -ge 4) {
            Add-Check -Name 'Git helpers smoke test' -Status PASS -Detail "New-Routine created branch '$branch' and $($createdFiles.Count) scaffold files in a temp workspace (the attendee workspace was not touched)." -Data @{ Branch = $branch; FileCount = $createdFiles.Count }
        }
        else {
            Add-Check -Name 'Git helpers smoke test' -Status WARN -Detail "New-Routine did not behave as expected: branch is '$branch' (expected 'selftest-routine'), $($createdFiles.Count) .lsp files created (expected at least 4)." -Data @{ Branch = $branch; FileCount = $createdFiles.Count }
        }
    }
    finally {
        Remove-Module LabGitHelpers -Force -ErrorAction SilentlyContinue
        Remove-Item Env:\LAB_WORKSPACE_ROOT -ErrorAction SilentlyContinue
        Remove-Item Env:\LAB_SCAFFOLD_TEMPLATE -ErrorAction SilentlyContinue
        Remove-Item -Path $sandbox -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- 10. Is the model warm-start actually configured? ------------------------
# Without this, the first prompt on a freshly booted VM costs ~90s - and
# that first prompt is Track 1's opening step. The check has to run on a
# template VM before capture, so it verifies configuration, not warmth.
Invoke-Check 'Ollama warm-start configured' {
    $problems = @()
    if ([Environment]::GetEnvironmentVariable('OLLAMA_KEEP_ALIVE', 'Machine') -ne '-1') {
        $problems += 'OLLAMA_KEEP_ALIVE is not set to -1 machine-wide'
    }
    $warmScript = Join-Path $env:ProgramData 'LabSession\Warm-OllamaModel.ps1'
    if (-not (Test-Path $warmScript)) { $problems += 'the warm-up script is not installed' }

    $task = Get-ScheduledTask -TaskName 'LabSession-WarmOllamaModel' -ErrorAction SilentlyContinue
    if (-not $task) { $problems += 'the LabSession-WarmOllamaModel logon task is not registered' }

    if ($problems.Count -eq 0) {
        $logPath = Join-Path $env:ProgramData 'LabSession\warm-model.log'
        $lastRun = if (Test-Path $logPath) { (Get-Content -Path $logPath -Tail 1) } else { 'not run yet on this VM' }
        Add-Check -Name 'Ollama warm-start configured' -Status PASS -Detail "Keep-alive set, warm-up task registered. Last warm-up: $lastRun" -Data @{ LastWarmUp = $lastRun }
    }
    else {
        Add-Check -Name 'Ollama warm-start configured' -Status WARN -Detail "$($problems -join '; '). The first prompt on a freshly booted VM will take about 90 seconds - which is exactly Track 1's opening step. Re-run Provision-LabVM.ps1." -Data @{ Problems = $problems }
    }
}

# --- 11. Every example routine still parses ----------------------------------
Invoke-Check 'Example routines parse' {
    $result = & (Join-Path $PSScriptRoot 'Test-LispBalance.ps1') -Path (Join-Path $repoRoot 'attendee')
    if ($result.Unbalanced.Count -eq 0) {
        Add-Check -Name 'Example routines parse' -Status PASS -Detail "$($result.Checked) example .lsp file(s) have balanced parentheses." -Data @{ Checked = $result.Checked }
    }
    else {
        Add-Check -Name 'Example routines parse' -Status FAIL -Detail "Unbalanced parentheses in: $($result.Unbalanced -join ', '). AutoCAD will refuse to load these." -Data @{ Unbalanced = $result.Unbalanced }
    }
}

# --- 12. Optional AI assistant apps + shortcuts -------------------------------
# WARN-only by design: these are account-based extras (see
# attendee/choose-your-assistant.md). A VM without them still runs the
# whole session - the web links/Edge are the documented fallback - so a
# missing app must never block a handover. Reads the same config lists
# Step 8c of provisioning writes from, so the two cannot drift.
Invoke-Check 'Optional AI assistant apps' {
    $config = Import-PowerShellDataFile -Path (Join-Path $repoRoot 'provisioning\config\provisioning.config.psd1')
    $problems = @()

    $aiShortcutDir = Join-Path (Join-Path $env:PUBLIC 'Desktop') 'AI Assistants'
    $urlCount = if (Test-Path $aiShortcutDir) { @(Get-ChildItem -Path $aiShortcutDir -Filter '*.url' -File).Count } else { 0 }
    if ($urlCount -lt $config.WebAiShortcuts.Count) {
        $problems += "AI Assistants desktop folder has $urlCount of $($config.WebAiShortcuts.Count) web shortcuts"
    }

    foreach ($app in $config.DesktopAiApps) {
        # No --source: `winget list` filters installed packages, and msstore
        # IDs correlate unreliably when the source filter is applied.
        winget list --id $app.WingetId --exact --accept-source-agreements 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { $problems += "$($app.DisplayName) is not installed" }
    }

    if ($problems.Count -eq 0) {
        Add-Check -Name 'Optional AI assistant apps' -Status PASS -Detail "All $($config.DesktopAiApps.Count) desktop apps installed and $urlCount web shortcuts present." -Data @{ ShortcutCount = $urlCount }
    }
    else {
        Add-Check -Name 'Optional AI assistant apps' -Status WARN -Detail "$($problems -join '; '). Optional, account-based - attendees without accounts are unaffected and the web links are the fallback. Re-run Provision-LabVM.ps1 to retry." -Data @{ Problems = $problems; ShortcutCount = $urlCount }
    }
}

# --- Report -------------------------------------------------------------------
$failCount = @($checks | Where-Object { $_.Status -eq 'FAIL' }).Count
$warnCount = @($checks | Where-Object { $_.Status -eq 'WARN' }).Count
$overall = if ($failCount -gt 0) { 'FAIL' } elseif ($warnCount -gt 0) { 'WARN' } else { 'PASS' }
$overallColor = switch ($overall) { 'FAIL' { 'Red' } 'WARN' { 'Yellow' } default { 'Green' } }

$report = [ordered]@{
    Schema      = 'lab-selftest/1'
    VmName      = $env:COMPUTERNAME
    User        = $env:USERNAME
    TimestampUtc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    RepoCommit  = (& git -C $repoRoot rev-parse --short HEAD 2>&1 | Out-String).Trim()
    Overall     = $overall
    FailCount   = $failCount
    WarnCount   = $warnCount
    Checks      = $checks
}

$jsonPath = Join-Path $OutputDirectory 'report.json'
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8

$markdown = [System.Collections.Generic.List[string]]::new()
$markdown.Add("# Lab VM self-test - $($report.VmName)")
$markdown.Add('')
$markdown.Add("**Result: $overall** ($failCount failed, $warnCount warned, $($checks.Count) checks)")
$markdown.Add('')
$markdown.Add("- VM: ``$($report.VmName)`` (user ``$($report.User)``)")
$markdown.Add("- Run: $($report.TimestampUtc)")
$markdown.Add("- Repo commit: ``$($report.RepoCommit)``")
$markdown.Add('')
$markdown.Add('| Check | Status | Detail |')
$markdown.Add('| --- | --- | --- |')
foreach ($check in $checks) {
    # Escape table-breaking pipes and flatten newlines - a detail string
    # that splits the row makes the published report unreadable.
    $detail = $check.Detail -replace '\|', '\|' -replace '\r?\n', ' '
    $markdown.Add("| $($check.Name) | $($check.Status) | $detail |")
}
$mdPath = Join-Path $OutputDirectory 'report.md'
$markdown -join "`n" | Set-Content -Path $mdPath -Encoding UTF8

Write-Host "`n=== Lab VM Self-Test: $overall ===" -ForegroundColor $overallColor
foreach ($check in $checks) {
    $color = switch ($check.Status) { 'FAIL' { 'Red' } 'WARN' { 'Yellow' } default { 'Green' } }
    Write-Host ("  {0,-6} {1}" -f $check.Status, $check.Name) -ForegroundColor $color
}
Write-Host "`nReport: $jsonPath"
Write-Host "        $mdPath"
if ($overall -eq 'FAIL') {
    Write-Host "`nDo NOT hand this VM to an attendee until the failures above are fixed." -ForegroundColor Red
}
# Full path, not a bare .\ name - this hint gets copy-pasted from whatever
# folder the self-test happened to be run from (usually the repo root).
Write-Host "`nSend it back to the team:  & '$(Join-Path $PSScriptRoot 'Publish-LabReport.ps1')'`n"

return $report
