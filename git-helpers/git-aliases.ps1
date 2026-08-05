<#
    Plain, portable git aliases - the same save/undo behavior as
    LabGitHelpers.psm1's Save-Progress/Undo-LastCommit, but as three
    `git config` lines that work from any terminal (cmd, bash, another
    machine entirely), with no PowerShell dependency.

    This is what the experienced sub-audience takes home to reproduce
    the workflow at their own company: just these three lines, on any
    git install.

    Run once per machine (or per user account):
        .\git-aliases.ps1
#>

git config --global alias.save '!git add -A && git commit -m'
git config --global alias.undo 'reset --soft HEAD~1'

Write-Host 'Installed git aliases: git save "<message>", git undo' -ForegroundColor Green
