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

    # Optional AI assistant desktop apps (Step 8c). Account-based and
    # strictly optional for attendees, so an install failure is non-fatal
    # by design: enterprise images commonly block the msstore source.
    # Attendees fall back to the web shortcuts below either way.
    DesktopAiApps         = @(
        @{ DisplayName = 'ChatGPT (desktop app)'; WingetId = '9PLM9XGG6VKS';    Source = 'msstore' }
        @{ DisplayName = 'Claude (desktop app)';  WingetId = 'Anthropic.Claude'; Source = 'winget' }
    )

    # Web shortcuts written into the "AI Assistants" desktop folder
    # (Step 8c) and documented in attendee/choose-your-assistant.md -
    # keep the two lists in sync.
    WebAiShortcuts        = @(
        @{ Name = 'ChatGPT';           Url = 'https://chatgpt.com' }
        @{ Name = 'Claude';            Url = 'https://claude.ai' }
        @{ Name = 'Microsoft Copilot'; Url = 'https://copilot.microsoft.com' }
        @{ Name = 'Gemini';            Url = 'https://gemini.google.com' }
        @{ Name = 'Le Chat (Mistral)'; Url = 'https://chat.mistral.ai' }
        @{ Name = 'Kimi';              Url = 'https://kimi.com' }
        @{ Name = 'Lumo (Proton)';     Url = 'https://lumo.proton.me' }
        @{ Name = 'DeepSeek';          Url = 'https://chat.deepseek.com' }
        @{ Name = 'Perplexity';        Url = 'https://perplexity.ai' }
        @{ Name = 'Qwen Chat';         Url = 'https://chat.qwen.ai' }
    )
}
