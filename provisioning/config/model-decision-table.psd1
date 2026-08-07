@{
    # Tiers are evaluated in order; the first tier where
    # MinRamGB <= detected RAM < MaxRamGB wins.
    Tiers = @(
        @{
            MinRamGB           = 0
            MaxRamGB           = 8
            ChatModel          = 'qwen2.5-coder:3b'
            SupportsAgenticCli = $false
            Note               = 'Low-RAM safe default: CPU-only, ~8-11B params equivalent quality is out of reach, but reliable for short AutoLISP routines. Too small/unreliable at tool-calling for the Claude Code CLI experience - Continue.dev chat/edit only.'
        }
        @{
            MinRamGB           = 8
            MaxRamGB           = 16
            ChatModel          = 'qwen2.5-coder:7b'
            SupportsAgenticCli = $false
            Note               = 'Comfortable CPU headroom: stronger completions, still CPU-viable (~5GB footprint at Q4). Still Qwen2.5-Coder, so tool-calling stays unreliable - Continue.dev chat/edit only.'
        }
        @{
            MinRamGB                 = 16
            MaxRamGB                 = 999
            ChatModel                = 'qwen3-coder:30b'
            SupportsAgenticCli       = $true
            # Floor for escalating INTO this tier via a dedicated GPU (see
            # DedicatedGpuMinVramGB below) even when RAM alone wouldn't
            # qualify - qwen3-coder:30b needs ~19GB just for its weights,
            # so a GPU-driven escalation still needs real RAM headroom.
            MinRamGBForGpuEscalation = 24
            Note                     = 'High-RAM or GPU-assisted VM: qwen3-coder:30b (MoE, ~3.3B active params of 30B total) has reliable tool-calling, needed for both Continue.dev edit mode and the optional local Claude Code CLI experience - unlike Qwen2.5-Coder. The MoE architecture keeps inference reasonably fast despite the larger (~19GB) download.'
        }
    )

    # Always used for inline autocomplete regardless of tier, to keep
    # typing latency low even on the weakest VM. Autocomplete doesn't need
    # tool-calling, so the small Qwen2.5-Coder model is still the right fit.
    AutocompleteModel = 'qwen2.5-coder:1.5b'

    # If a dedicated GPU with at least this much VRAM is detected,
    # Test-LabVMSpecs.ps1 escalates the chat model one tier up -
    # bounded by that tier's MinRamGBForGpuEscalation (if set) so a
    # GPU alone can't push a low-RAM VM into a model too big to fit.
    DedicatedGpuMinVramGB = 8
}
