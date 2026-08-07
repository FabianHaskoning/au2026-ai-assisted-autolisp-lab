# continue-config

The local-model wiring for Continue.dev (the main tool for the 90-minute
exercise) and the governance rules it reads on every prompt.

- `config.yaml.template` - rendered by `Provision-LabVM.ps1` into
  `~/.continue/config.yaml`, wires up the free local Ollama model chosen
  for this VM's hardware (see `provisioning/config/
  model-decision-table.psd1`).
- `rules/*.md` - copied into each attendee's workspace
  (`.continue/rules/`), read by Continue.dev on every prompt.
- `ContinueConfigHelpers.psm1` - shared, merge-safe editing of
  `~/.continue/config.yaml` (a marker-block regex pattern, same idea as
  the `$PROFILE` block in `Provision-LabVM.ps1`), used by both the
  take-home provisioning path and `ContinueProviders.psm1` below.
- `ContinueProviders.psm1` - lets an attendee add their own AI backend.

## Bring your own AI backend

`continue-provider` (installed by `Provision-LabVM.ps1` on every VM tier)
adds a model to Continue.dev alongside the free local one, which stays
available as a fallback - switch between them anytime via the model-picker
dropdown in Continue's chat panel.

```powershell
continue-provider -Provider Anthropic -Model claude-sonnet-4-5
continue-provider -Provider OpenAI -Model gpt-4.1
continue-provider -Provider Gemini -Model gemini-2.5-flash
continue-provider -Provider CustomOpenAICompatible -Model kimi-k2 -ApiBase https://api.moonshot.ai/v1
```

- `-Provider` is one of `Anthropic`, `OpenAI`, `Gemini`, or
  `CustomOpenAICompatible` (covers Kimi/Moonshot and anything else that
  speaks the OpenAI Chat Completions API shape - pass `-ApiBase`).
- `-Model` is required - exact model IDs change over time, so this
  deliberately doesn't guess a default that could go stale. Use whatever
  your account/API key gives you access to.
- If you don't pass `-ApiKey`, it prompts for one (never echoed or
  logged). The key is then stored in plain text in your own
  `~/.continue/config.yaml`, the same way Continue.dev normally stores it
  for a local config - it's your file on your own machine.
- Re-running for the same `-Provider` refreshes just that block (e.g. to
  rotate a key) without touching anything else you've added.

**GitHub Copilot isn't an option here** - it doesn't expose an API
Continue.dev can call into. If you have Copilot, use its own Copilot Chat
panel side by side; optionally paste `rules/*.md` into Copilot's own
custom-instructions if you want the same governance rules there too.

Want the Claude Code CLI itself (not just Continue.dev) on a non-Anthropic
backend? See `gateway-mode` in
[`claude-code-config/README.md`](../claude-code-config/README.md#gateway-mode-experimental),
a heavier, experimental option worth trying only if `continue-provider`
doesn't cover what you need.
