<#
    .SYNOPSIS
    Validates the repo's own content: links resolve, the folder map is
    current, scripts copy files that exist, model tags agree, and every
    .lsp parses.

    .DESCRIPTION
    Runs in CI on every push and locally before committing. It catches
    the class of mistake that markdownlint and PSScriptAnalyzer can't:
    a document pointing at a file that was renamed, a provisioning step
    copying a module that was deleted, a doc quoting a model tag the
    decision table no longer uses.

    Deliberately contains no list of forbidden feature names. Anything
    removed from the repo already fails the link and copy-target checks
    below, and a hard-coded blocklist would have to be maintained (and
    reverted) alongside every scope change.

    Exits 1 if any check fails.

    .EXAMPLE
    .\Test-RepoConsistency.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$problems = [System.Collections.Generic.List[string]]::new()

function Add-Problem {
    param([Parameter(Mandatory)][string]$Message)
    $problems.Add($Message)
}

function Get-RelativePath {
    param([Parameter(Mandatory)][string]$FullPath)
    return $FullPath.Substring($repoRoot.Length).TrimStart('\', '/') -replace '\\', '/'
}

Write-Host 'Checking repo consistency...' -ForegroundColor Cyan

# --- 1. Every relative markdown link resolves --------------------------------
Write-Host '  [1/5] Relative markdown links'
$markdownFiles = @(Get-ChildItem -Path $repoRoot -Filter '*.md' -File -Recurse |
    Where-Object { $_.FullName -notmatch '\\(\.git|node_modules)\\' })

foreach ($file in $markdownFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    foreach ($match in [regex]::Matches($content, '\[[^\]]*\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value.Trim()
        # Skip absolute URLs, mailto:, and pure in-page anchors.
        if ($target -match '^(https?:|mailto:|#)') { continue }
        # Strip any trailing anchor - we only verify the file exists.
        $target = ($target -split '#')[0]
        if (-not $target) { continue }
        $resolved = Join-Path $file.DirectoryName $target
        if (-not (Test-Path $resolved)) {
            Add-Problem "Broken link in $(Get-RelativePath $file.FullName): [$target] does not exist"
        }
    }
}

# --- 2. The root README folder map matches reality ---------------------------
# The folder map is the first thing anyone reads. A folder missing from it
# is invisible; a row pointing at a deleted folder is a lie.
Write-Host '  [2/5] Root README folder map'
$rootReadme = Get-Content -Path (Join-Path $repoRoot 'README.md') -Raw
$actualFolders = @(Get-ChildItem -Path $repoRoot -Directory |
    Where-Object { $_.Name -notmatch '^(\.git|\.github|\.claude|node_modules)$' } |
    ForEach-Object { $_.Name })

foreach ($folder in $actualFolders) {
    if ($rootReadme -notmatch [regex]::Escape("$folder/")) {
        Add-Problem "Top-level folder '$folder/' is not mentioned in README.md's folder map"
    }
}

# --- 3. Files the provisioning scripts copy actually exist -------------------
# Catches a rename or deletion that would only surface as a provisioning
# failure on the VM, hours before doors open.
Write-Host '  [3/5] Provisioning copy/dot-source targets'
$scripts = @(Get-ChildItem -Path $repoRoot -Include '*.ps1', '*.psm1' -File -Recurse |
    Where-Object { $_.FullName -notmatch '\\\.git\\' })

foreach ($script in $scripts) {
    $content = Get-Content -Path $script.FullName -Raw
    # Matches a Join-Path against the repo-root variable with a literal
    # relative path - the one idiom every provisioning step uses to reach
    # another file in this repo. (Written as a regex rather than shown
    # literally in this comment, so this check doesn't match itself.)
    foreach ($match in [regex]::Matches($content, "Join-Path\s+\`$repoRoot\s+'([^']+)'")) {
        $relative = $match.Groups[1].Value
        # Wildcards mean "the contents of"; check the parent folder instead.
        $probe = if ($relative -match '[*?]') { Split-Path -Parent $relative } else { $relative }
        if (-not $probe) { continue }
        if (-not (Test-Path (Join-Path $repoRoot $probe))) {
            Add-Problem "$(Get-RelativePath $script.FullName) references '$relative', which does not exist"
        }
    }
}

# --- 4. Model tags quoted in docs match the decision table -------------------
# Docs naming a model the table no longer uses send a facilitator chasing a
# model that was never pulled.
Write-Host '  [4/5] Model tags in docs vs the decision table'
$decisionTable = Import-PowerShellDataFile -Path (Join-Path $repoRoot 'provisioning\config\model-decision-table.psd1')
$knownModels = [System.Collections.Generic.HashSet[string]]::new()
foreach ($tier in $decisionTable.Tiers) {
    foreach ($key in @('ChatModel', 'QualityChatModel')) {
        if ($tier[$key]) { [void]$knownModels.Add($tier[$key]) }
    }
}
[void]$knownModels.Add($decisionTable.AutocompleteModel)

foreach ($file in $markdownFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    # Only inspect model-shaped tags inside code spans, to avoid matching
    # prose like "AutoCAD 2026:" or a time such as "11:30".
    foreach ($match in [regex]::Matches($content, '`(qwen[a-z0-9.\-]*:[a-z0-9.]+)`')) {
        $tag = $match.Groups[1].Value
        if (-not $knownModels.Contains($tag)) {
            Add-Problem "$(Get-RelativePath $file.FullName) names model '$tag', which is not in provisioning/config/model-decision-table.psd1"
        }
    }
}

# --- 5. Every .lsp has balanced parentheses ----------------------------------
Write-Host '  [5/5] AutoLISP bracket balance'
foreach ($folder in @('attendee', 'scaffold', 'examples')) {
    $path = Join-Path $repoRoot $folder
    if (-not (Test-Path $path)) { continue }
    $result = & (Join-Path $PSScriptRoot 'Test-LispBalance.ps1') -Path $path
    foreach ($bad in $result.Unbalanced) {
        Add-Problem "Unbalanced parentheses: $folder/$bad"
    }
}

# --- Result -------------------------------------------------------------------
Write-Host ''
if ($problems.Count -eq 0) {
    Write-Host 'Repo consistency: PASS' -ForegroundColor Green
    exit 0
}

Write-Host "Repo consistency: FAIL ($($problems.Count) problem(s))" -ForegroundColor Red
foreach ($problem in $problems) {
    Write-Host "  - $problem" -ForegroundColor Red
}
exit 1
