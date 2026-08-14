<#
    .SYNOPSIS
    Fleet view: fetches every VM self-test report and shows which
    machines are ready and which aren't.

    .DESCRIPTION
    The other end of the feedback loop. Run this from your own machine -
    it reads the `vm-reports` branch without checking it out, so it never
    disturbs whatever you're working on.

    Shows the most recent report per VM by default. Exits with code 1 if
    any VM's latest run is FAIL, so it can gate a "are we ready?"
    decision rather than just informing one.

    .PARAMETER All
    Show every report, not just the newest per VM.

    .PARAMETER Detailed
    List the individual failing and warning checks, with their reasons.

    .PARAMETER NoFetch
    Skip the network fetch and read what's already local.

    .EXAMPLE
    .\Get-LabReports.ps1

    .EXAMPLE
    .\Get-LabReports.ps1 -Detailed
#>

[CmdletBinding()]
param(
    [switch]$All,
    [switch]$Detailed,
    [switch]$NoFetch,
    [string]$Remote = 'origin'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$reportBranch = 'vm-reports'

Push-Location $repoRoot
try {
    if (-not $NoFetch) {
        Write-Host "Fetching $Remote/$reportBranch..." -ForegroundColor Gray
        git fetch $Remote "${reportBranch}:refs/remotes/$Remote/$reportBranch" 2>&1 | Out-Null
    }

    $ref = "$Remote/$reportBranch"
    git rev-parse --verify --quiet "$ref^{commit}" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "No '$reportBranch' branch on $Remote yet - no VM has published a report." -ForegroundColor Yellow
        Write-Host "Run verification\Publish-LabReport.ps1 on a VM to create it."
        return
    }

    # Read the branch through git rather than checking it out, so this is
    # safe to run mid-edit on any branch.
    $files = @(git ls-tree -r --name-only $ref 2>&1 | Where-Object { $_ -like 'reports/*.json' })
    if ($files.Count -eq 0) {
        Write-Host "The '$reportBranch' branch exists but holds no reports yet." -ForegroundColor Yellow
        return
    }

    $reports = foreach ($file in $files) {
        try {
            $json = (git show "${ref}:$file" 2>&1 | Out-String) | ConvertFrom-Json
            [PSCustomObject]@{
                Vm        = $json.VmName
                WhenUtc   = [datetime]$json.TimestampUtc
                Overall   = $json.Overall
                Fails     = $json.FailCount
                Warns     = $json.WarnCount
                Commit    = $json.RepoCommit
                Checks    = $json.Checks
                File      = $file
            }
        }
        catch {
            Write-Warning "Could not read $file - skipping ($($_.Exception.Message))"
        }
    }

    $shown = if ($All) { $reports | Sort-Object Vm, WhenUtc } else {
        $reports | Group-Object Vm | ForEach-Object { $_.Group | Sort-Object WhenUtc | Select-Object -Last 1 } | Sort-Object Vm
    }

    Write-Host ''
    Write-Host ("{0,-20} {1,-8} {2,-6} {3,-6} {4,-20} {5}" -f 'VM', 'RESULT', 'FAIL', 'WARN', 'WHEN (UTC)', 'REPO') -ForegroundColor Cyan
    Write-Host ('-' * 78) -ForegroundColor DarkGray
    foreach ($report in $shown) {
        $color = switch ($report.Overall) { 'FAIL' { 'Red' } 'WARN' { 'Yellow' } default { 'Green' } }
        Write-Host ("{0,-20} {1,-8} {2,-6} {3,-6} {4,-20} {5}" -f
            $report.Vm, $report.Overall, $report.Fails, $report.Warns,
            $report.WhenUtc.ToString('yyyy-MM-dd HH:mm'), $report.Commit) -ForegroundColor $color

        if ($Detailed) {
            foreach ($check in @($report.Checks | Where-Object { $_.Status -ne 'PASS' })) {
                $checkColor = if ($check.Status -eq 'FAIL') { 'Red' } else { 'Yellow' }
                Write-Host ("    {0,-6} {1}: {2}" -f $check.Status, $check.Name, $check.Detail) -ForegroundColor $checkColor
            }
        }
    }

    $failing = @($shown | Where-Object { $_.Overall -eq 'FAIL' })
    $warning = @($shown | Where-Object { $_.Overall -eq 'WARN' })
    Write-Host ''
    Write-Host ("{0} VM(s) reporting: {1} ready, {2} with warnings, {3} FAILING." -f
        $shown.Count, ($shown.Count - $failing.Count - $warning.Count), $warning.Count, $failing.Count)

    if ($failing.Count -gt 0) {
        Write-Host "Not ready: $(($failing.Vm) -join ', ')" -ForegroundColor Red
        if (-not $Detailed) { Write-Host 'Re-run with -Detailed to see why.' -ForegroundColor Red }
        exit 1
    }
}
finally {
    Pop-Location
}
