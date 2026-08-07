# Mac/Linux take-home setup (manual)

`provisioning/Provision-LabVM.ps1 -TakeHome` only runs on Windows
(PowerShell + winget). There's no automated equivalent for macOS/Linux -
this page is the manual version of the same setup: a few commands, no
script to maintain. It gets you the same local-model chat/edit/autocomplete
experience in VS Code, plus the optional Claude Code CLI local-mode.
AutoCAD/Civil 3D themselves are Windows-only, so this is for continuing the
AI-assisted-AutoLISP-authoring workflow, not for running AutoCAD.

## 1. Prerequisites

macOS (Homebrew):

```bash
brew install git ollama
brew install --cask visual-studio-code
```

Linux (Debian/Ubuntu-family; adjust for your distro):

```bash
sudo apt install git
curl -fsSL https://ollama.com/install.sh | sh
# VS Code: https://code.visualstudio.com/download
```

## 2. Pull a model

Pick a tag based on your machine's RAM - same tiers used by
`provisioning/config/model-decision-table.psd1`:

| RAM | Chat/edit model | Autocomplete |
| --- | --- | --- |
| < 8GB | `qwen2.5-coder:3b` | `qwen2.5-coder:1.5b` |
| 8-16GB | `qwen2.5-coder:7b` | `qwen2.5-coder:1.5b` |
| 16GB+, or a GPU with 8GB+ VRAM | `qwen3.5:4b` | `qwen2.5-coder:1.5b` |

```bash
ollama pull qwen3.5:4b
ollama pull qwen2.5-coder:1.5b
```

## 3. Continue.dev

Install the Continue.dev extension in VS Code, then create
`~/.continue/config.yaml`:

```yaml
name: Lab VM Assistant
version: 1.0.0
schema: v1

models:
  - name: Lab Assistant (Ollama)
    provider: ollama
    model: "qwen3.5:4b"
    apiBase: http://localhost:11434
    roles:
      - chat
      - edit

  - name: Autocomplete (Ollama)
    provider: ollama
    model: "qwen2.5-coder:1.5b"
    apiBase: http://localhost:11434
    roles:
      - autocomplete
```

Copy `continue-config/rules/*.md` into a `.continue/rules/` folder inside
whatever project folder you're working in, so the same governance rules
apply.

## 4. Claude Code CLI (optional, advanced)

Install: `curl -fsSL https://claude.ai/install.sh | bash` (see
[Anthropic's docs](https://docs.claude.com/en/docs/claude-code) if that
changes). Then, in place of this repo's `local-mode`/`cloud-mode`
PowerShell aliases, set the same three environment variables by hand:

**Local (free, no account):**

```bash
export ANTHROPIC_BASE_URL=http://localhost:11434
export ANTHROPIC_AUTH_TOKEN=ollama
export ANTHROPIC_API_KEY=
claude --model qwen3.5:4b
```

**Cloud (your own Anthropic account):**

```bash
unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY
claude
# sign in when prompted
```

## 5. Gateway mode (experimental) - skip unless you want it

`claude-code-config/LiteLLMGateway.psm1`'s `gateway-mode` (Windows-only
PowerShell) lets the Claude Code CLI itself reach OpenAI/Gemini/Kimi via a
local [LiteLLM](https://docs.litellm.ai/docs/tutorials/claude_non_anthropic_models)
proxy. On Mac/Linux, follow LiteLLM's own "Claude Code with non-Anthropic
models" tutorial directly - the mechanism is the same three environment
variables above, just pointed at `http://localhost:4000` (or wherever your
LiteLLM proxy listens) instead of Ollama. `claude-code-config/
litellm-config.yaml.template` in this repo is a reasonable starting point
for the LiteLLM config file itself. This is experimental and not something
this repo maintains a script for outside Windows.

## Troubleshooting

Same failure modes as the Windows path - see
[`facilitator/troubleshooting.md`](../facilitator/troubleshooting.md),
particularly the "Take-home / advanced (optional)" section.
