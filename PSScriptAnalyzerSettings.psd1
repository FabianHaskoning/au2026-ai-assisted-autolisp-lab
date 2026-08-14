@{
    # Rules excluded because they don't apply to what these scripts are.
    # Everything else stays on.
    ExcludeRules = @(
        # Every script here is an interactive console tool whose job is to
        # print a coloured PASS/WARN/FAIL summary to a facilitator standing
        # at a VM. Write-Host is the correct call for that - Write-Output
        # would pollute the return values these scripts deliberately emit
        # (Test-LabVMSpecs.ps1 and Invoke-LabSelfTest.ps1 both return an
        # object the caller consumes).
        'PSAvoidUsingWriteHost'

        # The helpers exist so a first-time git user doesn't have to learn
        # git syntax mid-session. Adding -WhatIf/-Confirm ceremony to
        # `save` and `New-Routine` would defeat the entire point of them.
        'PSUseShouldProcessForStateChangingFunctions'

        # Get-JsonFileSettings / Save-JsonFileSettings and friends operate
        # on a settings collection, and are already load-bearing public
        # names across three modules. Renaming them buys nothing.
        'PSUseSingularNouns'
    )
}
