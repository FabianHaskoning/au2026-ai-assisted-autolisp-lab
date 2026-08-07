# Facilitator guide

For the presenter and the two LAB assistants (Nicolas Carvajal, Sanne
Bogers). This covers running the environment, not the curriculum - what
attendees actually build and how the room is paced is the presenter's call,
decided separately.

## VM access (confirmed)

Author access to LabProfile 219488 is confirmed via **Skillable Studio**
(`labondemand.com/LabProfile/219488`, not `manage.skillable.com` - that
domain doesn't exist). Launching the profile there opens a browser-streamed
desktop (no external RDP/SSH) with a **Capture** button to save changes back
to the template checkpoint. Confirmed real specs on the template VM: 56GB
RAM, 8-core AMD EPYC, NVIDIA Tesla T4 (4GB VRAM) - Ollama, VS Code,
Continue.dev, and git were already present on the image.

**Outstanding:** the profile shows "Security Review Required" - it can't be
launched via API or external link until that review passes. That blocks the
*attendee-facing* launch path, not the author's own manual Launch button.
Resolve this well before Sept 16 (see the "Request Security Review" link on
the profile page).

This repo is public at
`https://github.com/FabianHaskoning/au2026-ai-assisted-autolisp-lab` - clone
it directly onto the VM, no credentials needed:

```powershell
git clone https://github.com/FabianHaskoning/au2026-ai-assisted-autolisp-lab.git
```

## Pre-session validation checklist

Run this on the actual template VM (and again after any change to the
image), in this order:

1. `git pull` in the cloned repo - make sure the VM has the latest.
2. `provisioning\Test-LabVMSpecs.ps1` - confirm the summary is `PASS` (or
   `WARN` with nothing concerning). Note the recommended model(s) and
   whether the local Claude Code CLI is offered on this tier.
3. `provisioning\Provision-LabVM.ps1` (as Administrator) - confirm it
   finishes with `PASS` and lists everything as `Installed` (first run) or
   `Skipped` (a re-run).
4. Open a **new** PowerShell window, run `New-Routine test-routine` -
   confirm it creates a branch and files without error.
5. Run `save "test"` and `undo` - confirm both behave as documented in
   `git-helpers/README.md`.
6. Delete the `test-routine` branch/folder and reset the workspace before
   handing the VM to an attendee.
7. Open VS Code in the workspace, open the Continue.dev chat panel, send a
   trivial prompt ("say hello") - confirm it responds using the local
   Ollama model (check the model name shown in the Continue panel).
8. If the VM tier supports it: open a terminal, run `claude-local`, send a
   trivial prompt - confirm it responds using the local model (no Anthropic
   login prompt should appear). Expect this to be noticeably slower than
   the Continue.dev chat - see `claude-code-config/README.md`.
9. Confirm AutoCAD 2026 and Civil 3D 2026 both launch normally.

Once this passes on one VM, use `facilitator/pre-flight-checklist.md` as the
fast, repeatable version for checking the rest of the fleet.

## Staffing 60-90 attendees with 3 people

- The presenter drives the room from the front (pacing, live demo,
  explaining what's happening).
- The two assistants patrol - physically if in-room, or watching a shared
  chat/question channel if remote - and handle the small number of
  recurring failure classes in `troubleshooting.md` directly rather than
  routing everything through the presenter.
- Agree on a simple, visible "I'm stuck" signal before the session starts
  (raised hand, a specific emoji/word in chat) so assistants can triage at a
  glance across a full room instead of waiting to be flagged down.
- Don't try to debug an attendee's exact problem live in front of everyone
  unless it's clearly common - note it, keep moving, follow up 1:1.

## Timing

The slowest step by far is the first `ollama pull` of the chat model (can
be several minutes depending on model size and network). **Pre-pull the
model into the VM image** via `Provision-LabVM.ps1` ahead of time - never
during the live 90 minutes. `SkipOllamaPull` in
`provisioning/config/provisioning.config.psd1` lets you re-run provisioning
for testing without re-pulling once the model is already cached in the
image.

## Take-home / bring-your-own-account (optional)

Attendees can run this same setup on their own PC afterward (or during the
session, if they brought a laptop) - see
[`take-home/README.md`](../take-home/README.md), which covers the
`-TakeHome` flag on `Provision-LabVM.ps1`, the Mac/Linux manual path, and
how to plug in a Claude/ChatGPT/Gemini/Kimi/Copilot account someone already
has instead of the free local model. A facilitator can also use `-TakeHome`
for a quick local dry-run of a change (e.g. `.\provisioning\
Provision-LabVM.ps1 -TakeHome -WorkspaceRootOverride C:\Scratch\LabWork`)
without needing to be on the actual lab VM. None of this changes what the
default lab-VM provisioning run (no `-TakeHome`) does.

## Out of scope for this document

Curriculum content, exercise pacing, and how the beginner/experienced
audience split is handled live are the presenter's decisions, made
separately - this guide only covers getting the environment itself
reliably working.
