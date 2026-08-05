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
| `New-Routine`/`save`/`undo` not recognized as commands | PowerShell window was open before provisioning finished, so the profile change hasn't loaded | Close and reopen the PowerShell window/terminal. |
| Ribbon/menu names in the assistant's suggestions don't match what's on screen | The model made something up, or is assuming a different AutoCAD version/language | Everything on this VM is AutoCAD/Civil 3D 2026 English - correct the assistant in chat and continue; this is a normal small-model limitation, not a setup problem. |
