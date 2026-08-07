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
- [ ] Clean up: **in `$env:LAB_WORKSPACE_ROOT` (`C:\LabWork` by default,
      not the staging repo clone!)** run `git checkout master` then
      `git branch -D preflight-check`, and delete the leftover folder if
      any remains
- [ ] VS Code opens the workspace with no error banners
- [ ] Continue.dev chat panel responds to a trivial prompt, using the
      local Ollama model (check the model name shown in the panel)
- [ ] If this tier supports it: `claude-local` responds to a trivial
      prompt, no Anthropic login prompt appears (optional - skip if
      `Test-LabVMSpecs.ps1` says the tier doesn't support it)
- [ ] If this tier supports it: open the Claude Code panel in VS Code
      (spark icon) - no Anthropic sign-in screen should appear, and a
      trivial prompt should get a response via the local model (optional)
- [ ] AutoCAD 2026 launches normally
- [ ] Civil 3D 2026 launches normally
- [ ] Sign off: initials + timestamp

Any unchecked box → see `facilitator/troubleshooting.md` before marking
this VM ready.
