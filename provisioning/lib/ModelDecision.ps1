<#
    Turns detected VM hardware into an Ollama model recommendation.
    Dot-source this file; it defines Get-RecommendedOllamaModel only.
#>

function Get-RecommendedOllamaModel {
    <#
        .SYNOPSIS
        Reads provisioning/config/model-decision-table.psd1 and returns
        the recommended chat + autocomplete model for the given hardware.

        .OUTPUTS
        Hashtable with ChatModel, AutocompleteModel, SupportsAgenticCli,
        and Reasoning.
    #>
    param(
        [Parameter(Mandatory)][double]$RamGB,
        [bool]$HasDedicatedGpu = $false,
        [double]$VramGB = 0,
        [string]$DecisionTablePath = (Join-Path $PSScriptRoot '..\config\model-decision-table.psd1')
    )

    $table = Import-PowerShellDataFile -Path $DecisionTablePath

    $tierIndex = -1
    for ($i = 0; $i -lt $table.Tiers.Count; $i++) {
        $tier = $table.Tiers[$i]
        if ($RamGB -ge $tier.MinRamGB -and $RamGB -lt $tier.MaxRamGB) {
            $tierIndex = $i
            break
        }
    }
    if ($tierIndex -eq -1) {
        # RAM below every tier's minimum (shouldn't happen with a 0-floor
        # first tier, but fail safe to the lowest tier rather than error).
        $tierIndex = 0
    }

    $reasoning = $table.Tiers[$tierIndex].Note
    $escalated = $false
    if ($HasDedicatedGpu -and $VramGB -ge $table.DedicatedGpuMinVramGB -and $tierIndex -lt ($table.Tiers.Count - 1)) {
        $nextTier = $table.Tiers[$tierIndex + 1]
        $escalationFloor = if ($nextTier.ContainsKey('MinRamGBForGpuEscalation')) { $nextTier.MinRamGBForGpuEscalation } else { $nextTier.MinRamGB }
        if ($RamGB -ge $escalationFloor) {
            $tierIndex++
            $escalated = $true
            $reasoning = "Dedicated GPU with ${VramGB}GB VRAM detected (>= $($table.DedicatedGpuMinVramGB)GB threshold) and enough RAM (>= ${escalationFloor}GB) to hold the bigger model - escalated one tier up. $($table.Tiers[$tierIndex].Note)"
        }
    }

    return @{
        ChatModel          = $table.Tiers[$tierIndex].ChatModel
        AutocompleteModel  = $table.AutocompleteModel
        SupportsAgenticCli = [bool]$table.Tiers[$tierIndex].SupportsAgenticCli
        Reasoning          = $reasoning
        Escalated          = $escalated
    }
}
