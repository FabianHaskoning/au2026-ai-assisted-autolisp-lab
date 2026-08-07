# Troubleshooting

Symptom → likely cause → fix, for the failure modes expected at this scale.
Ordered roughly by how often they're likely to come up.

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Continue.dev chat says model not found / errors immediately | Model tag in `~/.continue/config.yaml` doesn't match what's actually pulled | Run `ollama list` to see the exact tag, compare to the config; re-run `Provision-LabVM.ps1` to re-render the config, or pull the missing tag with `ollama pull <tag>`. |
| Continue.dev can't reach the model at all / "connection refused" | The Ollama service isn't running | Run `ollama serve` in a terminal (or restart the Ollama background service), then retry. |
| Responses are very slow or the VM seems frozen | CPU-bound inference under load (AutoCAD + VS Code + Ollama all running at once) | Close redundant AutoCAD instances/other apps; shorten the prompt (see `04-context-and-token-economy.md`); confirm the VM matches the RAM tier the chosen model expects. |
| `git commit` fails with an identity error | Placeholder `user.name`/`user.email` never got set for this repo | `git config user.name "..."` and `git config user.email "..."` inside the workspace folder (not `--global`, so it doesn't affect other repos). |
| AutoCAD's APPLOAD says it can't load the file | Wrong file path, or a genuine syntax error in the generated `.lsp` | Read the exact AutoCAD command-line error text - it usually names the problem. Try loading the loader file specifically, not a module file directly. |
| `New-Routine` errors "not a git repository" | Workspace wasn't initialized (provisioning didn't complete, or ran against the wrong folder) | Re-run `Provision-LabVM.ps1`; confirm `$env:LAB_WORKSPACE_ROOT` points at the right folder. |
| VS Code extension install fails / marketplace unreachable | Unlikely given confirmed full internet access, but possible transient network/proxy issue | Retry `code --install-extension continue.continue`; as a fallback, sideload a downloaded `.vsix` with `code --install-extension <path>.vsix`. |
| `New-Routine`/`save`/`undo`/`claude-local` not recognized as commands | PowerShell window was open before provisioning finished, so the profile change hasn't loaded | Close and reopen the PowerShell window/terminal. |
| Ribbon/menu names in the assistant's suggestions don't match what's on screen | The model made something up, or is assuming a different AutoCAD version/language | Everything on this VM is AutoCAD/Civil 3D 2026 English - correct the assistant in chat and continue; this is a normal small-model limitation, not a setup problem. |
| `claude-local`/`fast-model`/`quality-model`/`cloud-mode`/`local-mode` aren't available at all | This VM tier doesn't support the agentic CLI (only offered above the RAM threshold in `model-decision-table.psd1`) | Expected on lower-spec VMs - it's optional. Continue.dev chat/edit is unaffected. |
| `claude-local` hangs or times out | The current model isn't pulled yet, or Ollama isn't running | Run `ollama list` to confirm the model is present; `quality-model`/`fast-model` auto-pull if missing, or run `ollama pull <tag>` manually; confirm `ollama serve` is running. |
| Responses are slow even on the fast model | Expected to some degree - this is still a local, GPU/CPU-bound assistant, not a hosted one | Not a bug. If it's the *quality* model, that's the known slow one - switch back with `fast-model`. If even the fast model feels too slow for a live demo, consider `cloud-mode` for a presenter machine with a real account. |
| `quality-model` responses are very slow | Expected - this VM's GPU (4GB VRAM) can't hold the whole 30B-class quality model, so Ollama splits it with the CPU | Not a bug, this is why it's opt-in. Switch back to the fast default with `fast-model`. |
| `cloud-mode` doesn't seem to do anything | It only affects Claude Code, not Continue.dev - Continue.dev always uses the local Ollama model, there's no cloud switch for it | Expected. Open the Claude Code panel (not Continue.dev) and sign in there. |
| `git branch -D <name>` says "branch not found" | Run from the wrong repo - `New-Routine`/branches live in `$env:LAB_WORKSPACE_ROOT` (`C:\LabWork` by default), not the staging repo clone folder | `cd C:\LabWork` (or wherever `$env:LAB_WORKSPACE_ROOT` points) first, then delete the branch. |
| VS Code Claude Code panel still shows an Anthropic sign-in screen | `claudeCode.disableLoginPrompt` didn't get set, or VS Code was already open when `Provision-LabVM.ps1` ran | Check VS Code settings (`Ctrl+,`) → Extensions → Claude Code → **Disable Login Prompt** is checked; if not, re-run `Provision-LabVM.ps1` then reload the VS Code window (**Developer: Reload Window**). |
| VS Code Claude Code panel signs in fine but doesn't use the local model | `~/.claude/settings.json` wasn't written (parse error on an existing file - check the provisioning log for a warning) | Open `~/.claude/settings.json` and confirm the `env`/`model` keys from `claude-code-config/README.md` are present; add them manually if the file had to be skipped. |

## Take-home / advanced (optional)

These only come up on a personal machine (`-TakeHome`) or with the
provider-picker/gateway features - not on the standard lab VM flow.

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `Provision-LabVM.ps1 -TakeHome` opens a UAC prompt / a second window | Expected - the script relaunches itself elevated when not already running as admin, since a personal PC is less likely to already be in an elevated shell | Approve the UAC prompt; the original window can be closed once the elevated one finishes. |
| `continue-provider` says "no API key given - aborting" | The `Read-Host -AsSecureString` prompt was skipped or empty (e.g. piped/non-interactive shell) | Re-run interactively, or pass `-ApiKey` directly. |
| A hand-edited `~/.continue/config.yaml` looks corrupted after `continue-provider` or take-home provisioning runs again | The `# LabSession-Provider-*-Start/-End` (or `-Ollama-Start/-End`) marker block got partially hand-edited, breaking the automatic block-replace | Delete the affected marked block manually (including both marker comment lines), then re-run `continue-provider` or `Provision-LabVM.ps1 -TakeHome` to regenerate it. Content outside marker blocks is never touched. |
| `gateway-mode` fails with "requires Python 3.9+" or "requires the litellm\[proxy\] package" | Expected - `gateway-mode` is experimental and never installs its own Python dependency | Follow the exact command the error prints (`pip install 'litellm[proxy]'`), then retry. This is why it's opt-in, not part of default provisioning. |
| `gateway-mode` says the gateway didn't respond within 10s | Port already in use, LiteLLM slow to start, or a firewall prompt waiting for a response | Check the LiteLLM window it opened; try a different `-Port`; approve any Windows Firewall prompt for Python. |
| `claude-local`/`claude` works, then stops working after a reboot (in gateway-mode) | The LiteLLM proxy process doesn't survive a restart on its own | Re-run `gateway-mode` (same backend/model) after rebooting, or switch to `local-mode`/`cloud-mode` if you don't need it every session. |
