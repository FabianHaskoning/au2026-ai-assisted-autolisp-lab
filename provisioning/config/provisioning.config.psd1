@{
    # Where each attendee's actual working git repo lives on the VM.
    # Separate from wherever this staging repo itself ends up.
    WorkspaceRoot         = 'C:\LabWork'

    # Placeholder git identity used if the provisioning script runs
    # non-interactively. An attendee (or the facilitator) can change
    # this later with `git config --global user.name/user.email`.
    GitUserNamePlaceholder  = 'Lab Attendee'
    GitUserEmailPlaceholder = 'attendee@lab.local'

    # Leave empty to auto-detect the model via Test-LabVMSpecs.ps1 /
    # ModelDecision.ps1. Set to an explicit Ollama model tag (e.g.
    # 'qwen2.5-coder:7b') to force it once real VM specs are confirmed.
    ModelOverride         = ''

    # Set to $true on repeat test-provisioning runs where the model(s)
    # are already pulled, to skip the (slow) `ollama pull` step.
    SkipOllamaPull        = $false
}
