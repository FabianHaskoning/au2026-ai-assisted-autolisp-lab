# Facilitator guide

For the presenter and the two LAB assistants (Nicolas Carvajal, Sanne
Bogers). This covers running the environment, not the curriculum - what
attendees actually build and how the room is paced is the presenter's call,
decided separately.

## Before anything else: confirm real VM access

This repo builds and tests everything locally. It has **not** been deployed
to the real Skillable VM (LabProfile 219488) yet. Before Sept 16:

1. Log in to `manage.skillable.com` (or `cloud.skillable.com`) with the
   account tied to the AU submission.
2. Find LabProfile 219488 under "My Content"/"My Classes".
3. Look for an **Edit** or **Author** option (not just "Launch"/"Register").
   That opens *Lab Architect*, which allows RDP into the template VM in
   checkpoint-editing mode.
4. If only an attendee-facing link is available, the real VM has to be
   configured through Autodesk's AU logistics/Skillable production contact
   instead - hand them `provisioning/Provision-LabVM.ps1` and this repo.

## Pre-session validation checklist

Run this on the actual template VM once author access is confirmed (and
again after any change to the image), in this order:

1. `provisioning\Test-LabVMSpecs.ps1` - confirm the summary is `PASS` (or
   `WARN` with nothing concerning). Note the recommended model.
2. `provisioning\Provision-LabVM.ps1` (as Administrator) - confirm it
   finishes with `PASS` and lists everything as `Installed` (first run) or
   `Skipped` (a re-run).
3. Open a **new** PowerShell window, run `New-Routine test-routine` -
   confirm it creates a branch and files without error.
4. Run `save "test"` and `undo` - confirm both behave as documented in
   `git-helpers/README.md`.
5. Delete the `test-routine` branch/folder and reset the workspace before
   handing the VM to an attendee.
6. Open VS Code in the workspace, open the Continue.dev chat panel, send a
   trivial prompt ("say hello") - confirm it responds using the local
   Ollama model (check the model name shown in the Continue panel).
7. Confirm AutoCAD 2026 and Civil 3D 2026 both launch normally.

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

## Out of scope for this document

Curriculum content, exercise pacing, and how the beginner/experienced
audience split is handled live are the presenter's decisions, made
separately - this guide only covers getting the environment itself
reliably working.
