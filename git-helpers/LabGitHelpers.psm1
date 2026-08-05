<#
    LabGitHelpers - turns "branch before you start, commit early and
    often" into commands a first-time git user can actually run.

    Reads its workspace/scaffold locations from environment variables
    set by Provision-LabVM.ps1 (with sane fallbacks so this also works
    for local testing outside a fully provisioned VM):
      LAB_WORKSPACE_ROOT     - e.g. C:\LabWork (a git repo)
      LAB_SCAFFOLD_TEMPLATE  - e.g. C:\LabWork\.scaffold-template
#>

function Get-LabWorkspaceRoot {
    if ($env:LAB_WORKSPACE_ROOT) { return $env:LAB_WORKSPACE_ROOT }
    return 'C:\LabWork'
}

function Get-LabScaffoldTemplate {
    if ($env:LAB_SCAFFOLD_TEMPLATE) { return $env:LAB_SCAFFOLD_TEMPLATE }
    return (Join-Path (Get-LabWorkspaceRoot) '.scaffold-template')
}

function New-Routine {
    <#
        .SYNOPSIS
        Starts a new AutoLISP routine: creates a git branch, copies the
        scaffold template with names/placeholders replaced, and makes
        the first commit. One command instead of remembered git syntax.

        .EXAMPLE
        New-Routine -Name fence-layout
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Name
    )

    $safeName = ($Name.ToLower() -replace '[^a-z0-9-]', '-') -replace '-{2,}', '-'
    $safeName = $safeName.Trim('-')
    if (-not $safeName) {
        Write-Error 'New-Routine: give the routine a name, e.g. New-Routine fence-layout'
        return
    }

    $workspaceRoot = Get-LabWorkspaceRoot
    $scaffoldTemplate = Get-LabScaffoldTemplate

    if (-not (Test-Path (Join-Path $workspaceRoot '.git'))) {
        Write-Error "New-Routine: $workspaceRoot is not a git repository yet. Run Provision-LabVM.ps1 first, or 'git init' it yourself."
        return
    }
    if (-not (Test-Path $scaffoldTemplate)) {
        Write-Error "New-Routine: scaffold template not found at $scaffoldTemplate."
        return
    }

    Push-Location $workspaceRoot
    try {
        $existingBranches = git branch --list $safeName
        if ($existingBranches) {
            Write-Error "New-Routine: branch '$safeName' already exists. Pick a different name, or 'git checkout $safeName' to resume it."
            return
        }

        git checkout -b $safeName | Out-Null

        $targetDir = Join-Path $workspaceRoot $safeName
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

        $upperToken = $safeName.ToUpper()
        Get-ChildItem -Path $scaffoldTemplate -Filter '*.lsp' -File | ForEach-Object {
            $newFileName = $_.Name -replace '^TEMPLATE-', "$safeName-" -replace '^prefix-', "$safeName-"
            $newPath = Join-Path $targetDir $newFileName
            (Get-Content -Path $_.FullName -Raw) `
                -replace 'PLACEHOLDER', $upperToken `
                -replace 'prefix', $safeName |
                Set-Content -Path $newPath -Encoding UTF8
        }

        git add -A | Out-Null
        git commit -m "Start routine: $safeName" | Out-Null

        Write-Host "`nStarted '$safeName' on its own branch." -ForegroundColor Green
        Write-Host "Files are in: $targetDir"
        Write-Host "Start editing: $safeName-core.lsp"
        Write-Host "When it works, load $safeName-loader.lsp via APPLOAD."
        Write-Host "Save progress often with: save `"what changed`"`n"
    }
    finally {
        Pop-Location
    }
}

function Save-Progress {
    <#
        .SYNOPSIS
        Commits everything changed in the workspace with a short
        message. Thin wrapper over `git add -A && git commit`.

        .EXAMPLE
        Save-Progress "circle now uses the picked radius"
    #>
    param(
        [Parameter(Position = 0)][string]$Message
    )

    if (-not $Message -or -not $Message.Trim()) {
        Write-Warning 'Save-Progress: describe what changed, e.g. save "circle now uses the picked radius"'
        return
    }

    $workspaceRoot = Get-LabWorkspaceRoot
    Push-Location $workspaceRoot
    try {
        git add -A | Out-Null
        $output = git commit -m $Message 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Saved: $Message" -ForegroundColor Green
        }
        else {
            Write-Host 'Nothing to save - no files have changed since the last save.' -ForegroundColor Yellow
        }
    }
    finally {
        Pop-Location
    }
}

function Undo-LastCommit {
    <#
        .SYNOPSIS
        Safely undoes the last `save`/commit without discarding the file
        changes themselves - `git reset --soft HEAD~1`. Never destructive.

        .EXAMPLE
        Undo-LastCommit
    #>
    $workspaceRoot = Get-LabWorkspaceRoot
    Push-Location $workspaceRoot
    try {
        $lastMessage = git log -1 --pretty=%s 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning 'Undo-LastCommit: no commits yet to undo.'
            return
        }
        git reset --soft HEAD~1 | Out-Null
        Write-Host "Undid the last save ('$lastMessage')." -ForegroundColor Yellow
        Write-Host 'Your file changes are still there, just uncommitted. Fix what you need, then save again.'
    }
    finally {
        Pop-Location
    }
}

Set-Alias -Name save -Value Save-Progress
Set-Alias -Name undo -Value Undo-LastCommit

Export-ModuleMember -Function New-Routine, Save-Progress, Undo-LastCommit -Alias save, undo
