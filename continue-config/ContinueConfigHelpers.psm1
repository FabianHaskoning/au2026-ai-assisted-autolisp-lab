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
        [Parameter(Mandatory)][string[]]$Content,
        [string]$ParentKey = 'models',
        [Parameter(Mandatory)][string]$Path
    )

    $blockStart = "  # LabSession-$BlockId-Start"
    $blockEnd   = "  # LabSession-$BlockId-End"
    $blockText  = (@($blockStart) + $Content + @($blockEnd)) -join "`n"

    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    if (-not (Test-Path $Path)) {
        Set-Content -Path $Path -Value "${ParentKey}:`n$blockText`n" -Encoding UTF8
        return
    }

    $fileContent = Get-Content -Path $Path -Raw
    if ($null -eq $fileContent) { $fileContent = '' }

    $blockPattern = [regex]::Escape($blockStart) + '[\s\S]*?' + [regex]::Escape($blockEnd)
    $existingMatch = [regex]::Match($fileContent, $blockPattern)
    if ($existingMatch.Success) {
        $newContent = $fileContent.Remove($existingMatch.Index, $existingMatch.Length).Insert($existingMatch.Index, $blockText)
        Set-Content -Path $Path -Value $newContent -Encoding UTF8
        return
    }

    $parentKeyPattern = "(?m)^${ParentKey}:[ \t]*$"
    $parentMatch = [regex]::Match($fileContent, $parentKeyPattern)
    if ($parentMatch.Success) {
        $insertAt = $parentMatch.Index + $parentMatch.Length
        $newContent = $fileContent.Insert($insertAt, "`n$blockText")
        Set-Content -Path $Path -Value $newContent -Encoding UTF8
        return
    }

    # Parent key isn't present anywhere in the file - append a new one.
    $newContent = $fileContent.TrimEnd() + "`n`n${ParentKey}:`n$blockText`n"
    Set-Content -Path $Path -Value $newContent -Encoding UTF8
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
        Set-Content -Path $Path -Value $newContent -Encoding UTF8
    }
}

Export-ModuleMember -Function Get-ContinueConfigPath, Set-ContinueConfigBlock, Remove-ContinueConfigBlock
