# claude-code-config

An **optional, advanced path**: the real Claude Code CLI and its official
VS Code extension, running against a local Ollama model instead of
Anthropic's cloud API by default - no account, no API key, zero cost. The
main 90-minute lab exercise uses Continue.dev inside VS Code (see
`continue-config/`); this is for attendees who want to go further, and
especially for the experienced sub-audience who want to take the exact same
pattern home to their own company.

## Commands

Installed by `Provision-LabVM.ps1` on VM tiers that support it (see below):

| Command | Does |
| --- | --- |
| `claude-local` | Runs `claude` with the local Ollama model, one-off, regardless of the persistent settings below. |
| `fast-model` | Switches Claude Code + Continue.dev to the fast default model. |
| `quality-model` | Switches Claude Code + Continue.dev to the bigger, slower, higher-quality model. |
| `cloud-mode` | Switches Claude Code (not Continue.dev) to Anthropic's real cloud API - for anyone with, or willing to sign up for, their own account. |
| `local-mode` | Switches Claude Code back to the local Ollama model. |

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
claude --model qwen3.5:4b
```

`claude-local` (from `LocalClaude.psm1`) sets these for just one invocation.
For anything persistent - the VS Code extension, or a bare `claude` typed
in a new terminal - the source of truth is `~/.claude/settings.json`.

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
     "model": "qwen3.5:4b"
   }
   ```

   Provisioning merges these keys in rather than overwriting the file, in
   case something else (an MCP server config, permissions) is already there.
2. **`claudeCode.disableLoginPrompt`** in VS Code's own `settings.json` -
   without this, the extension still shows an Anthropic sign-in screen on
   first open, even though it will use the local model once you get past it.

With both in place, opening the Claude Code panel in VS Code (the spark icon
in the editor toolbar) talks to local Ollama immediately - no sign-in
screen, no API key prompt. `fast-model`/`quality-model`/`cloud-mode`/
`local-mode` all update this same file, so the CLI and the extension always
stay in sync with each other.

## Fast vs. quality model

Confirmed on the real lab VM hardware (8-core AMD EPYC, 56GB RAM, NVIDIA
Tesla T4 with only 4GB VRAM):

- **`qwen3.5:4b` (fast, default)** - small enough to fit entirely in a
  modest GPU's VRAM, so no CPU fallback is needed. Strong agent/tool-calling
  benchmark scores for its size (BFCL-V4 72.9, TAU2-Bench 86.7). This is
  what most attendees should just use.
- **`qwen3-coder:30b` (quality, opt-in)** - MoE model (30B total
  parameters, ~3.3B active per token), stronger reasoning, 256K context.
  Doesn't fit in a small GPU's VRAM, so Ollama splits it with the CPU -
  noticeably slower in practice. Reach it with `quality-model`, switch back
  with `fast-model`.

Neither is Qwen2.5-Coder (used elsewhere in this repo for autocomplete) -
that family has unreliable tool-calling, which an agentic CLI like Claude
Code depends on to read/edit files and run commands. Both models are
pre-pulled by `Provision-LabVM.ps1` so switching is instant, no surprise
multi-GB download mid-session. Only VMs on the top hardware tier get either
(see `provisioning/config/model-decision-table.psd1`) - lower tiers stick to
Continue.dev chat/edit only.

## Using a real Anthropic account instead

Some attendees may already have a Claude.ai Pro/Max/Team/Enterprise
subscription, or want to sign up for one. `cloud-mode` removes the local
model override from `~/.claude/settings.json` and re-enables the extension's
normal sign-in screen; `local-mode` puts it back. This only affects Claude
Code - Continue.dev always uses the local Ollama model, there's no cloud
toggle for it.

**Deliberately not built into the default provisioning flow for everyone**:
new Anthropic Console accounts get a one-time ~$5 free-credit trial (no
credit card, but SMS phone verification required) - workable for one
person trying it individually, but risky to rely on for 60-90 people
signing up simultaneously from the same conference network (SMS delivery
issues for international numbers, anti-fraud rate-limiting when many new
accounts appear from one place at once, and $5 doesn't go far for agentic
usage). `cloud-mode` makes it available to anyone who wants to try anyway,
without the environment forcing everyone through it.

## Performance expectations

Even on the fast model, this is a local, CPU/GPU-bound assistant, not a
hosted one - `claude-code-config/CLAUDE.md` (copied into the attendee
workspace by provisioning) sets this expectation and coaches small, focused
prompts to work well within it.

## Taking it home

Nothing here is specific to this lab. Any machine with Ollama installed and
a tool-calling-capable model pulled can run real Claude Code the same way -
just those three environment variables, no lab infrastructure required.
