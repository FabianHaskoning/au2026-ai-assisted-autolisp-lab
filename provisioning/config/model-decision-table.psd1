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
            MinRamGB           = 16
            MaxRamGB           = 999
            # Default/fast: small enough to fit fully in a modest GPU's
            # VRAM (confirmed on the real lab VM's 4GB Tesla T4 - no CPU
            # split needed), with solid agent/tool-calling benchmark scores
            # despite being tiny. Used by both Continue.dev and Claude Code
            # by default - this is what most attendees will actually run.
            ChatModel          = 'qwen3.5:4b'
            # Opt-in upgrade: stronger reasoning, but doesn't fit in a
            # small GPU's VRAM so Ollama splits it with the CPU - noticeably
            # slower in practice (confirmed on the real lab VM). Reachable
            # via the `quality-model` command in claude-code-config, for
            # anyone who wants to trade speed for quality.
            QualityChatModel   = 'qwen3-coder:30b'
            SupportsAgenticCli = $true
            # Floor for escalating INTO this tier via a dedicated GPU (see
            # DedicatedGpuMinVramGB below) even when RAM alone wouldn't
            # qualify - the quality model needs ~19GB just for its weights,
            # so a GPU-driven escalation still needs real RAM headroom.
            MinRamGBForGpuEscalation = 24
            Note                     = 'High-RAM or GPU-assisted VM: qwen3.5:4b is the fast default (fits fully in a small GPU, reliable tool-calling despite its size) for both Continue.dev edit mode and the optional local Claude Code CLI experience; qwen3-coder:30b is available as an opt-in "quality" upgrade at the cost of speed - neither is Qwen2.5-Coder, which has unreliable tool-calling.'
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
