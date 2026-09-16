# Taking it home

Everything from the session, on your own machine - during the session if
you brought a laptop, or any time afterward. Nothing here needs the
Skillable lab VM.

> **Only want the local-model + Claude Code part?** There's a stripped-down
> standalone version - one setup script that wires Ollama into the Claude
> Code panel in VS Code on any Windows PC, nothing else:
> <https://github.com/FabianHaskoning/claude-code-on-ollama>. This page is
> the full workshop setup instead.

## 1. Get the repo

```powershell
git clone -b facilitator https://github.com/FabianHaskoning/au2026-ai-assisted-autolisp-lab.git
```

## 2. Set it up

- **Windows**: run `provisioning\Provision-LabVM.ps1 -TakeHome` from an
  elevated PowerShell (or let it relaunch elevated itself). This is the
  same script the lab VM uses, with a few differences for a personal
  machine: it asks for elevation instead of requiring it up front, your
  workspace lands under `$HOME\LabWork` instead of `C:\LabWork`, a missing
  AutoCAD/Civil 3D install is a warning instead of a failure, and any
  Continue.dev config you already have is merged into rather than
  overwritten. Ollama and the Claude Code CLI are always installed - that's
  the point - but it'll ask you three quick questions first: whether to
  install Git for Windows too, whether to install VS Code + Continue.dev
  too (say no if you only want the Claude Code CLI), and whether you're
  actually here to write AutoLISP routines (say no and it skips copying the
  AutoCAD-specific `CLAUDE.md`/scaffold/rules into your workspace). Answer
  ahead of time instead of being asked with `-SkipGit`, `-SkipVSCode`,
  `-Purpose Lisp`/`-Purpose General`, and skip the questions entirely with
  `-NonInteractive` (defaults to "yes to everything" for anything you
  didn't pass explicitly - useful for a repeatable/scripted run).
- **Mac/Linux**: no automated script - follow
  [`mac-linux-setup.md`](mac-linux-setup.md) (a handful of commands, same
  end result for the VS Code + Continue.dev workflow).

## Your existing Claude settings are safe

If your machine already had a `~/.claude/settings.json` (say, with a real
`ANTHROPIC_API_KEY` in it), the setup backs it up **before touching it** to
a timestamped file next to it: `settings.json.pre-lab-<date>.bak`. Only the
first run makes a backup, so re-runs can never overwrite the pristine copy.
The setup also never blanks an existing non-empty `ANTHROPIC_API_KEY` — it
only adds what's missing. To put everything back exactly as it was, run
`restore-claude-settings` in a new shell (or copy the `.bak` over
`settings.json` yourself).

## 3. Smoke test

Open a **new** terminal after setup finishes:

- Open VS Code on the workspace and check `my-work\routine-1\` exists with its
  four `.lsp` files - confirms the workspace bootstrap ran.
- Open the Continue.dev chat panel and send a trivial prompt - confirms the
  local Ollama model responds.
- Optional, if you want the git workflow too: `New-Routine test-routine` (or
  the plain-git aliases from `git-helpers/README.md` on Mac/Linux). Nothing in
  the workshop content needs this.
- If your machine's tier supports it: `claude-local` - confirms the
  optional Claude Code CLI path.

## 4. Already have your own AI access? Use it

You don't have to use the free local model if you already have something
better:

- **Claude.ai / Anthropic account**: run `cloud-mode` to switch the Claude
  Code CLI to your own account. Switch back with `local-mode`.
- **Pulled a different local model yourself with `ollama pull`**: run
  `switch-model` to pick from any locally pulled model, not just the
  `fast-model`/`quality-model` pair this VM's tier recommends.
- **ChatGPT/OpenAI, Google Gemini, or an OpenAI-compatible service like
  Kimi/Moonshot, inside Continue.dev**: run `continue-provider` (see
  [`continue-config/README.md`](../continue-config/README.md)) to add it
  alongside the free local model - both stay available in Continue's
  model-picker dropdown.
- **GitHub Copilot**: not a Continue.dev integration (Copilot doesn't
  expose a compatible API) - just use the separate Copilot Chat panel side
  by side. Paste `continue-config/rules/*.md` into Copilot's own
  custom-instructions if you want the same governance rules there too.
- **ChatGPT/Gemini/Kimi for the Claude Code CLI itself (experimental)**:
  `gateway-mode` (see
  [`claude-code-config/README.md`](../claude-code-config/README.md#gateway-mode-experimental))
  routes the CLI through a local LiteLLM proxy. This needs Python and an
  extra background process, and isn't installed by default - only reach
  for it if `continue-provider` doesn't cover what you need.

## Troubleshooting

[`facilitator/troubleshooting.md`](../facilitator/troubleshooting.md) -
the "Take-home / advanced (optional)" section covers the failure modes
specific to a personal machine (elevation prompts, a pre-existing Continue
config, gateway-mode issues).
