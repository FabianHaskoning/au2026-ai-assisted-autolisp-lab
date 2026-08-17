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
# module paths or profiles. An attendee opening the "wrong" one and finding
# New-Routine missing is a real, previously-hit failure.
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
        Add-Check -Name 'Helper commands in both shells' -Status FAIL -Detail "$($problems -join '; '). Re-run Provision-LabVM.ps1." -Data @{ Problems = $problems }
    }
}

# --- 8. The attendee workspace has everything the instructions promise --------
Invoke-Check 'Attendee workspace' {
    $config = Import-PowerShellDataFile -Path (Join-Path $repoRoot 'provisioning\config\provisioning.config.psd1')
    $workspaceRoot = if ($env:LAB_WORKSPACE_ROOT) { $env:LAB_WORKSPACE_ROOT } else { $config.WorkspaceRoot }
    $required = @(
        @{ Path = '.git';                                              What = 'git repo' }
        @{ Path = '.scaffold-template';                                What = 'scaffold template (New-Routine needs it)' }
        @{ Path = 'START-HERE.md';                                     What = 'START-HERE.md' }
        @{ Path = 'tracks\1-first-routine\README.md';                  What = 'Track 1' }
        @{ Path = 'tracks\2-better-results\README.md';                 What = 'Track 2' }
        @{ Path = 'tracks\3-teach-and-scale\README.md';                What = 'Track 3' }
        @{ Path = 'tracks\1-first-routine\examples\hello-world.lsp';   What = 'the routine Track 1 step 2 tells attendees to APPLOAD' }
    )
    $missing = @($required | Where-Object { -not (Test-Path (Join-Path $workspaceRoot $_.Path)) } | ForEach-Object { $_.What })

    $rulesDir = Join-Path $workspaceRoot '.continue\rules'
    $ruleCount = if (Test-Path $rulesDir) { @(Get-ChildItem -Path $rulesDir -Filter '*.md' -File).Count } else { 0 }
    if ($ruleCount -lt 6) { $missing += "governance rules ($ruleCount of 6 present in .continue\rules)" }

    $shortcut = Join-Path (Join-Path $env:PUBLIC 'Desktop') 'START HERE.lnk'
    if (-not (Test-Path $shortcut)) { $missing += 'START HERE desktop shortcut' }

    if ($missing.Count -eq 0) {
        Add-Check -Name 'Attendee workspace' -Status PASS -Detail "$workspaceRoot is complete: git repo, $ruleCount rules, scaffold, all three tracks, desktop shortcut." -Data @{ WorkspaceRoot = $workspaceRoot; RuleCount = $ruleCount }
    }
    else {
        Add-Check -Name 'Attendee workspace' -Status FAIL -Detail "Missing from ${workspaceRoot}: $($missing -join '; '). Re-run Provision-LabVM.ps1." -Data @{ WorkspaceRoot = $workspaceRoot; Missing = $missing }
    }
}

# --- 9. Do the helpers actually work? ----------------------------------------
# Against a throwaway temp workspace, never the attendee's. The old manual
# checklist created a branch in C:\LabWork and relied on remembering to
# delete it; a VM handed over with a stray preflight-check branch is
# confusing at best.
Invoke-Check 'Git helpers smoke test' {
    $moduleManifest = Join-Path $HOME 'Documents\PowerShell\Modules\LabGitHelpers\LabGitHelpers.psm1'
    if (-not (Test-Path $moduleManifest)) {
        $moduleManifest = Join-Path $HOME 'Documents\WindowsPowerShell\Modules\LabGitHelpers\LabGitHelpers.psm1'
    }
    if (-not (Test-Path $moduleManifest)) {
        Add-Check -Name 'Git helpers smoke test' -Status FAIL -Detail 'LabGitHelpers module not installed in either shell - cannot test New-Routine.'
        return
    }
    if (-not (Test-CommandExists 'git')) {
        Add-Check -Name 'Git helpers smoke test' -Status FAIL -Detail 'git is not on PATH.'
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
            Add-Check -Name 'Git helpers smoke test' -Status FAIL -Detail "New-Routine did not behave as expected: branch is '$branch' (expected 'selftest-routine'), $($createdFiles.Count) .lsp files created (expected at least 4)." -Data @{ Branch = $branch; FileCount = $createdFiles.Count }
        }
    }
    finally {
        Remove-Module LabGitHelpers -Force -ErrorAction SilentlyContinue
        Remove-Item Env:\LAB_WORKSPACE_ROOT -ErrorAction SilentlyContinue
        Remove-Item Env:\LAB_SCAFFOLD_TEMPLATE -ErrorAction SilentlyContinue
        Remove-Item -Path $sandbox -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- 10. Every example routine still parses ----------------------------------
Invoke-Check 'Example routines parse' {
    $result = & (Join-Path $PSScriptRoot 'Test-LispBalance.ps1') -Path (Join-Path $repoRoot 'attendee')
    if ($result.Unbalanced.Count -eq 0) {
        Add-Check -Name 'Example routines parse' -Status PASS -Detail "$($result.Checked) example .lsp file(s) have balanced parentheses." -Data @{ Checked = $result.Checked }
    }
    else {
        Add-Check -Name 'Example routines parse' -Status FAIL -Detail "Unbalanced parentheses in: $($result.Unbalanced -join ', '). AutoCAD will refuse to load these." -Data @{ Unbalanced = $result.Unbalanced }
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
Write-Host "`nSend it back to the team:  .\Publish-LabReport.ps1`n"

return $report
