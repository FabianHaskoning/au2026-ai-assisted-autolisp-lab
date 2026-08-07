# claude-code-config

An **optional, advanced path**: the real Claude Code CLI, running against a
local Ollama model instead of Anthropic's cloud API - no Anthropic account,
no API key, zero cost. The main 90-minute lab exercise uses Continue.dev
inside VS Code (see `continue-config/`); this is for attendees who want to
go further, and especially for the experienced sub-audience who want to
take the exact same pattern home to their own company.

## How it works

Since January 2026, Ollama speaks the Anthropic Messages API directly.
Claude Code (the `claude` CLI) already respects `ANTHROPIC_BASE_URL` to
redirect its requests - by default it talks to `https://api.anthropic.com`,
but pointed at `http://localhost:11434` it talks to the local Ollama server
instead, no proxy needed:

```powershell
$env:ANTHROPIC_AUTH_TOKEN = "ollama"
$env:ANTHROPIC_API_KEY = ""
$env:ANTHROPIC_BASE_URL = "http://localhost:11434"
claude --model qwen3-coder:30b
```

`Provision-LabVM.ps1` installs the `claude-local` command (from
`LocalClaude.psm1`) so nobody has to remember or type those three
variables - it sets them for just that one invocation and launches
`claude` with the right model.

## VS Code extension

The official Claude Code VS Code extension (`anthropic.claude-code`) bundles
its **own** copy of the CLI for its chat panel - it does not inherit
`claude-local`'s per-invocation environment variables, and by default it
wants you to sign in with a real Anthropic account. Getting the extension to
use the local model instead needs two separate pieces, both handled by
`Provision-LabVM.ps1`:

1. **`~/.claude/settings.json`** - the officially documented, shared config
   file between the standalone CLI and the extension's bundled process:

   ```json
   {
     "env": {
       "ANTHROPIC_AUTH_TOKEN": "ollama",
       "ANTHROPIC_API_KEY": "",
       "ANTHROPIC_BASE_URL": "http://localhost:11434"
     },
     "model": "qwen3-coder:30b"
   }
   ```

   Provisioning merges these keys in rather than overwriting the file, in
   case something else (an MCP server config, permissions) is already there.
2. **`claudeCode.disableLoginPrompt`** in VS Code's own `settings.json` -
   without this, the extension still shows an Anthropic sign-in screen on
   first open, even though it will use the local model once you get past it.

With both in place, opening the Claude Code panel in VS Code (the spark icon
in the editor toolbar) talks to local Ollama immediately - no sign-in
screen, no API key prompt.

## Why qwen3-coder:30b, not the Continue.dev default

Claude Code (like any agentic CLI) needs reliable tool-calling to read/edit
files and run commands. Qwen2.5-Coder (used for autocomplete elsewhere in
this repo) has weak tool-calling support - `qwen3-coder:30b` is a MoE model
(30B total parameters, ~3.3B active per token) specifically built for
agentic/tool-calling use, with a 256K context window. Only VMs on the
top hardware tier get this model (see
`provisioning/config/model-decision-table.psd1`) - it needs ~19GB of disk
for the weights, so it isn't offered on lower-RAM tiers.

## Performance expectations

This VM's GPU (if any) likely doesn't have enough VRAM to hold the whole
model - Ollama runs the rest on CPU. It works, but is noticeably slower
than cloud Claude Code. `claude-code-config/CLAUDE.md` (copied into the
attendee workspace by provisioning) sets this expectation and coaches
small, focused prompts to work well within it.

## Taking it home

Nothing here is specific to this lab. Any machine with Ollama installed and
a tool-calling-capable model pulled can run real Claude Code the same way -
just those three environment variables, no lab infrastructure required.
