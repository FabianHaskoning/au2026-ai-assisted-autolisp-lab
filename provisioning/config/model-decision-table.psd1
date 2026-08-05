@{
    # Tiers are evaluated in order; the first tier where
    # MinRamGB <= detected RAM < MaxRamGB wins.
    Tiers            = @(
        @{ MinRamGB = 0;  MaxRamGB = 8;   ChatModel = 'qwen2.5-coder:3b';  Note = 'Low-RAM safe default: CPU-only, ~8-11B params equivalent quality is out of reach, but reliable for short AutoLISP routines.' }
        @{ MinRamGB = 8;  MaxRamGB = 16;  ChatModel = 'qwen2.5-coder:7b';  Note = 'Comfortable CPU headroom: stronger completions, still CPU-viable (~5GB footprint at Q4).' }
        @{ MinRamGB = 16; MaxRamGB = 999; ChatModel = 'qwen2.5-coder:14b'; Note = 'High-RAM or GPU-assisted VM: best available quality in the Qwen2.5-Coder family for local use.' }
    )

    # Always used for inline autocomplete regardless of tier, to keep
    # typing latency low even on the weakest VM.
    AutocompleteModel = 'qwen2.5-coder:1.5b'

    # If a dedicated GPU with at least this much VRAM is detected,
    # Test-LabVMSpecs.ps1 escalates the chat model one tier up
    # regardless of the RAM-based tier it would otherwise land in.
    DedicatedGpuMinVramGB = 8
}
