<#
    .SYNOPSIS
    Pushes a self-test report from this VM back to the repo, so the team
    can see the state of the whole fleet without visiting every machine.

    .DESCRIPTION
    Reports land on a dedicated `vm-reports` branch under
    reports/<vm-name>/<timestamp>.{json,md}. That branch is orphaned: it
    shares no history with master and holds no source, so it can never be
    merged in by accident and can be pruned at any time. It is a mailbox,
    not code.

    All of the git work happens in a temporary worktree under $env:TEMP,
    driven with `git -C`. Your checkout is never switched, stashed or
    cleaned - which matters, because building an orphan branch in place
    means emptying the working tree, and a facilitator running this on a
    VM shouldn't have to trust that nothing went wrong halfway through.

    Runs the self-test first unless -UseExistingReport is passed.

    Facilitator-run. Attendees never push anything.

    .PARAMETER DryRun
    Commit into the temporary worktree but don't push, and leave the
    worktree in place so you can inspect it.

    .PARAMETER UseExistingReport
    Publish the report already in the output directory instead of
    re-running the self-test. Use this after a failed push.

    .EXAMPLE
    .\Publish-LabReport.ps1

    .EXAMPLE
    .\Publish-LabReport.ps1 -UseExistingReport -DryRun
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$UseExistingReport,
    [string]$Remote = 'origin',
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $repoRoot 'provisioning\lib\Common.ps1')

$reportBranch = 'vm-reports'
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $PSScriptRoot 'out' }
$jsonPath = Join-Path $OutputDirectory 'report.json'
$mdPath = Join-Path $OutputDirectory 'report.md'

if (-not (Test-CommandExists 'git')) {
    Write-LabLog 'git is not on PATH - cannot publish.' -Level Error
    return
}

if (-not $UseExistingReport) {
    Write-LabLog 'Running the self-test before publishing...' -Level Info
    & (Join-Path $PSScriptRoot 'Invoke-LabSelfTest.ps1') -OutputDirectory $OutputDirectory | Out-Null
}

if (-not (Test-Path $jsonPath)) {
    Write-LabLog "No report at $jsonPath. Run Invoke-LabSelfTest.ps1 first, or drop -UseExistingReport." -Level Error
    return
}

$report = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
$vmName = ($report.VmName -replace '[^A-Za-z0-9\-_]', '-')
$stamp = ([datetime]$report.TimestampUtc).ToString('yyyy-MM-dd_HHmmss')

Write-LabLog "Publishing $($report.Overall) report for $vmName ($stamp) to the '$reportBranch' branch..." -Level Info

$worktree = Join-Path ([System.IO.Path]::GetTempPath()) "lab-reports-$([guid]::NewGuid().ToString('N').Substring(0,8))"
$worktreeCreated = $false

try {
    # Prefer the remote's version of the branch if there is one, so two
    # facilitators publishing from different VMs don't fork it.
    git -C $repoRoot fetch $Remote $reportBranch 2>&1 | Out-Null
    $remoteBranchExists = ($LASTEXITCODE -eq 0)

    if ($remoteBranchExists) {
        Write-LabLog "Attaching a temporary worktree to $Remote/$reportBranch..." -Level Info
        git -C $repoRoot worktree add --detach $worktree FETCH_HEAD 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Could not create a worktree from $Remote/$reportBranch." }
        $worktreeCreated = $true
        # Land on the branch name so `git push` has something to push.
        git -C $worktree switch -C $reportBranch 2>&1 | Out-Null
    }
    else {
        Write-LabLog "No '$reportBranch' branch on $Remote yet - creating it (first report from this fleet)." -Level Info
        git -C $repoRoot worktree add --detach $worktree 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Could not create a temporary worktree.' }
        $worktreeCreated = $true
        git -C $worktree checkout --orphan $reportBranch 2>&1 | Out-Null
        # Empties this worktree only - the real checkout is untouched.
        git -C $worktree rm -rf . --quiet 2>&1 | Out-Null
        Set-Content -Path (Join-Path $worktree 'README.md') -Encoding UTF8 -Value @'
# VM self-test reports

Automated output from `verification/Invoke-LabSelfTest.ps1`, pushed here by
`verification/Publish-LabReport.ps1`. One folder per VM, newest last.

This branch is orphaned: it contains no source code, shares no history with
`master`, and is never merged. Read it with `verification/Get-LabReports.ps1`
from a normal checkout - you do not need to check this branch out.
'@
    }

    $targetDir = Join-Path $worktree "reports\$vmName"
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Copy-Item -Path $jsonPath -Destination (Join-Path $targetDir "$stamp.json") -Force
    if (Test-Path $mdPath) { Copy-Item -Path $mdPath -Destination (Join-Path $targetDir "$stamp.md") -Force }

    git -C $worktree add -A 2>&1 | Out-Null
    git -C $worktree commit -m "$($report.Overall): $vmName self-test $stamp" --quiet 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-LabLog 'Nothing new to commit - this exact report was already published.' -Level Warn
        return
    }

    if ($DryRun) {
        Write-LabLog "-DryRun: committed but NOT pushed. Inspect it at $worktree - remove it afterwards with: git -C `"$repoRoot`" worktree remove --force `"$worktree`"" -Level Warn
        return
    }

    Write-LabLog "Pushing to $Remote/$reportBranch..." -Level Info
    $pushOutput = git -C $worktree push $Remote $reportBranch 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-LabLog 'Published. The team can now see this VM with Get-LabReports.ps1.' -Level Success
    }
    else {
        # Almost always credentials. Say exactly what to do, rather than
        # dumping git's output and leaving the facilitator to interpret it.
        Write-LabLog @"
Push failed. Git output:
$pushOutput
The report is safe - it is still in $OutputDirectory and nothing was lost.

Most likely this VM has no push credentials yet. Either:
  1. Authenticate once with the GitHub CLI:  gh auth login
     (choose HTTPS and 'Login with a web browser' - it prints a code to paste
     into the browser on this VM)
  2. Or configure a personal access token for HTTPS pushes.

Then re-run:  .\Publish-LabReport.ps1 -UseExistingReport
"@ -Level Error
    }
}
catch {
    Write-LabLog "Publishing failed: $($_.Exception.Message). Your checkout was not modified - the report is still in $OutputDirectory." -Level Error
}
finally {
    if ($worktreeCreated -and -not $DryRun) {
        git -C $repoRoot worktree remove --force $worktree 2>&1 | Out-Null
        if (Test-Path $worktree) { Remove-Item -Path $worktree -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
