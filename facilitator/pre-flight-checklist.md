# Pre-flight checklist

Run per VM (or per representative sample of a batch) shortly before doors
open. Designed to be skimmable in under two minutes. See
`facilitator/README.md` for the full explanation of each step the first
time through.

- [ ] `provisioning\Test-LabVMSpecs.ps1` → summary is `PASS` (or `WARN`
      with nothing concerning)
- [ ] Chosen model matches what's expected for this VM's hardware tier
- [ ] `ollama list` shows both the chat and autocomplete models already
      pulled (not pulling live)
- [ ] New PowerShell window → `New-Routine preflight-check` succeeds
- [ ] `save "test"` succeeds
- [ ] `undo` succeeds and explains itself
- [ ] Clean up: delete the `preflight-check` branch and its folder
- [ ] VS Code opens the workspace with no error banners
- [ ] Continue.dev chat panel responds to a trivial prompt, using the
      local Ollama model (check the model name shown in the panel)
- [ ] AutoCAD 2026 launches normally
- [ ] Civil 3D 2026 launches normally
- [ ] Sign off: initials + timestamp

Any unchecked box → see `facilitator/troubleshooting.md` before marking
this VM ready.
