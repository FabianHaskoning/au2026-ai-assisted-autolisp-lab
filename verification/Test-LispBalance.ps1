<#
    .SYNOPSIS
    Reports which .lsp files under a path have unbalanced parentheses.

    .DESCRIPTION
    The cheapest possible catch for the single most common way an
    AutoLISP file fails: AutoCAD refuses to load it and says "malformed
    list on input". Shared by Invoke-LabSelfTest.ps1 (checking the
    examples on a VM) and Test-RepoConsistency.ps1 (checking them in CI),
    so an example routine can never reach 80 attendees broken.

    This is a bracket counter, not a parser. It understands string
    literals, escaped characters inside them, and `;` line comments -
    enough to avoid false positives on the files we ship. It cannot tell
    you whether the code is correct, only whether the brackets close.

    Returns an object with Checked (count) and Unbalanced (array of
    relative paths). Writes nothing.

    .EXAMPLE
    .\Test-LispBalance.ps1 -Path ..\attendee
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Path
)

$unbalanced = [System.Collections.Generic.List[string]]::new()
$files = @(Get-ChildItem -Path $Path -Filter '*.lsp' -File -Recurse -ErrorAction SilentlyContinue)

foreach ($file in $files) {
    $depth = 0
    $minDepth = 0
    $inString = $false

    foreach ($line in (Get-Content -Path $file.FullName)) {
        $chars = $line.ToCharArray()
        $i = 0
        while ($i -lt $chars.Length) {
            $c = $chars[$i]
            if ($inString) {
                if ($c -eq '\') { $i++ }          # skip the escaped char, e.g. \" or \n
                elseif ($c -eq '"') { $inString = $false }
            }
            elseif ($c -eq ';') { break }          # rest of the line is a comment
            elseif ($c -eq '"') { $inString = $true }
            elseif ($c -eq '(') { $depth++ }
            elseif ($c -eq ')') {
                $depth--
                # Track the low-water mark separately: a file that closes
                # one bracket too many and then opens one too many still
                # ends at depth 0, and would otherwise look fine.
                if ($depth -lt $minDepth) { $minDepth = $depth }
            }
            $i++
        }
    }

    if ($depth -ne 0 -or $minDepth -lt 0) {
        $relative = $file.FullName.Substring((Resolve-Path $Path).Path.Length).TrimStart('\', '/')
        $reason = if ($depth -gt 0) { "$depth unclosed" } elseif ($depth -lt 0) { "$([math]::Abs($depth)) extra closing" } else { 'a closing bracket appears before its opener' }
        $unbalanced.Add("$relative ($reason)")
    }
}

return [PSCustomObject]@{
    Checked    = $files.Count
    Unbalanced = @($unbalanced)
}
