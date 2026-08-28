<#
    ContinueConfigHelpers - shared, merge-safe editing of ~/.continue/config.yaml.

    Generalizes the marker-block regex span-replace pattern already used
    for the PowerShell $PROFILE block in Provision-LabVM.ps1
    (# LabSession-Helpers-Start/-End) so it also works for inserting a
    named entry under a YAML list key (e.g. "models:") without disturbing
    anything else a user may already have in that file. Each caller picks
    its own -BlockId, so multiple independent blocks (one per provider)
    can coexist under the same parent key.

    Takes an explicit -Root override instead of relying on $env:HOME -
    $env:HOME does NOT override PowerShell's $HOME automatic variable on
    Windows, so tests must pass -Root explicitly rather than mutating that
    env var.
#>

# Write-Utf8NoBom lives in ClaudeSettingsHelpers.psm1. Provisioning copies
# that module alongside this file into the installed module folder (see
# Provision-LabVM.ps1 Steps 9-10), but in the source repo it lives in the
# sibling claude-code-config/ folder - resolve whichever location has it.
$claudeSettingsHelpersPath = Join-Path $PSScriptRoot 'ClaudeSettingsHelpers.psm1'
if (-not (Test-Path $claudeSettingsHelpersPath)) {
    $claudeSettingsHelpersPath = Join-Path $PSScriptRoot '..\claude-code-config\ClaudeSettingsHelpers.psm1'
}
Import-Module $claudeSettingsHelpersPath -Force

function Get-ContinueConfigPath {
    param([string]$Root = $HOME)
    Join-Path $Root '.continue\config.yaml'
}

function Set-ContinueConfigBlock {
    <#
        .SYNOPSIS
        Inserts or refreshes a marker-delimited list of entries under a
        top-level YAML key (default "models") in the config.yaml at $Path,
        creating the file / the parent key / the block itself as needed.
        Re-running with the same -BlockId replaces only that block; other
        blocks and any hand-written content elsewhere in the file survive.

        .PARAMETER Content
        Already-indented YAML lines for this block (e.g. "  - name: ..."
        list entries matching the parent key's list-item indentation).
    #>
    param(
        [Parameter(Mandatory)][string]$BlockId,
        [Parameter(Mandatory)][AllowEmptyString()][string[]]$Content,
        [string]$ParentKey = 'models',
        [Parameter(Mandatory)][string]$Path
    )

    $blockStart = "  # LabSession-$BlockId-Start"
    $blockEnd   = "  # LabSession-$BlockId-End"
    $blockText  = (@($blockStart) + $Content + @($blockEnd)) -join "`n"

    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    if (-not (Test-Path $Path)) {
        Write-Utf8NoBom -Path $Path -Content "${ParentKey}:`n$blockText"
        return
    }

    $fileContent = Get-Content -Path $Path -Raw
    if ($null -eq $fileContent) { $fileContent = '' }

    $blockPattern = [regex]::Escape($blockStart) + '[\s\S]*?' + [regex]::Escape($blockEnd)
    $existingMatch = [regex]::Match($fileContent, $blockPattern)
    if ($existingMatch.Success) {
        $newContent = $fileContent.Remove($existingMatch.Index, $existingMatch.Length).Insert($existingMatch.Index, $blockText)
        Write-Utf8NoBom -Path $Path -Content $newContent
        return
    }

    $parentKeyPattern = "(?m)^${ParentKey}:[ \t]*$"
    $parentMatch = [regex]::Match($fileContent, $parentKeyPattern)
    if ($parentMatch.Success) {
        $insertAt = $parentMatch.Index + $parentMatch.Length
        $newContent = $fileContent.Insert($insertAt, "`n$blockText")
        Write-Utf8NoBom -Path $Path -Content $newContent
        return
    }

    # Parent key isn't present anywhere in the file - append a new one.
    $newContent = $fileContent.TrimEnd() + "`n`n${ParentKey}:`n$blockText`n"
    Write-Utf8NoBom -Path $Path -Content $newContent
}

function Set-ContinueConfigModelTag {
    <#
        .SYNOPSIS
        Updates the "model:" line for an existing named entry (e.g.
        "Lab Assistant (Ollama)") in the config.yaml at $Path, in place.
        No-ops if $Path doesn't exist or the entry isn't found - callers
        that need to guarantee the entry exists should use
        Set-ContinueConfigBlock first.
    #>
    param(
        [Parameter(Mandatory)][string]$EntryName,
        [Parameter(Mandatory)][string]$NewModel,
        [Parameter(Mandatory)][string]$Path
    )
    if (-not (Test-Path $Path)) { return }
    $content = Get-Content -Path $Path -Raw
    $pattern = '(name: ' + [regex]::Escape($EntryName) + '[\s\S]*?model: )"[^"]*"'
    $updated = $content -replace $pattern, "`$1`"$NewModel`""
    if ($updated -ne $content) {
        Write-Utf8NoBom -Path $Path -Content $updated
    }
}

function Remove-ContinueConfigBlock {
    param([Parameter(Mandatory)][string]$BlockId, [Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { return }

    $blockStart = "  # LabSession-$BlockId-Start"
    $blockEnd   = "  # LabSession-$BlockId-End"
    $fileContent = Get-Content -Path $Path -Raw
    $blockPattern = [regex]::Escape($blockStart) + '[\s\S]*?' + [regex]::Escape($blockEnd) + '\n?'
    $existingMatch = [regex]::Match($fileContent, $blockPattern)
    if ($existingMatch.Success) {
        $newContent = $fileContent.Remove($existingMatch.Index, $existingMatch.Length)
        Write-Utf8NoBom -Path $Path -Content $newContent
    }
}

Export-ModuleMember -Function Get-ContinueConfigPath, Set-ContinueConfigBlock, Set-ContinueConfigModelTag, Remove-ContinueConfigBlock
