# Facilitator guide

For the presenter and the two LAB assistants (Nicolas Carvajal, Sanne
Bogers). Covers both getting the environment working and running the room.
What attendees actually read and do is in [`attendee/`](../attendee/).

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

## Pre-session validation

Run this on the actual template VM, and again after any change to the image:

```powershell
git pull                                   # make sure the VM has the latest
.\provisioning\Provision-LabVM.ps1         # as Administrator; expect PASS
.\verification\Invoke-LabSelfTest.ps1      # expect PASS
.\verification\Publish-LabReport.ps1       # send the result back to the team
```

The self-test replaces what used to be eight manual steps here. It checks
hardware and tooling, that Ollama is serving, that every expected model is
pulled by exact tag, that **the model actually generates a response** (and how
long it took), that the Continue.dev and Claude Code configs point at models
that exist, and that the workspace and desktop shortcut are complete - now
including the `how-to/` cards, both showcases, the ready-made `my-work\`
folders and the `.vscode\settings.json` that makes the instructions open
rendered. The two git-helper checks still run but are WARN-only, since no
attendee path depends on them any more.

**One thing the self-test cannot check: the click paths.** Every instruction is
written as "click here, then here", and those were written against the standard
VS Code menus rather than observed on this image. Section 2b of
[`pre-flight-checklist.md`](pre-flight-checklist.md) walks them mouse-only - do
it once, properly, on a real VM.

**A FAIL means do not hand this VM to an attendee.** Each failure names its own
fix. See [`verification/README.md`](../verification/README.md) for the full
list and for publishing credentials.

From your own machine, `verification\Get-LabReports.ps1` shows every VM that
has reported and exits non-zero if any of them is failing - that is the
go/no-go signal for the fleet.

Then work through [`pre-flight-checklist.md`](pre-flight-checklist.md) for the
handful of things no script can check.

## The three tracks

The opening talk sets up the split; attendees self-select in about a minute
from the table in [`attendee/START-HERE.md`](../attendee/START-HERE.md). All
three run in parallel for the same ~75 minutes.

| Track | Audience | Expected share | Where it can go wrong |
| --- | --- | --- | --- |
| [1 - First routine](../attendee/tracks/1-first-routine/) | Never written AutoLISP, or never used AI to write code | ~50% | Overruns. It is the track that must not - protect steps 2 and 3, drop step 5. |
| [2 - Better results](../attendee/tracks/2-better-results/) | Has tried it; results are inconsistent | ~35% | A disappointing before/after, usually because they reused the old chat instead of starting a new one. Second most likely: only one file selected, so **Compare Selected** isn't in the right-click menu. |
| [3 - Teach and scale](../attendee/tracks/3-teach-and-scale/) | Does this regularly; wants to spread it | ~15% | Part D (`optional/pair-workflow.md`) is the only git in the whole session and it's marked optional - if GitHub auth misbehaves, route people to its offline Path B or just drop the part. |

**The session is terminal-free.** Tracks 1 and 2 never mention PowerShell or
git; saving is File → Save, recovery is the VS Code Timeline, and the Track 2
before/after is **Compare Selected** in the Explorer. Keyboard shortcuts are
never given as the only instruction - every step names what to click. If an
attendee asks about version control, `attendee/optional/git-if-you-want-it.md`
is the answer; the helpers are still installed and still work.

**And browser-first, for a tested reason.** The local stack (Continue.dev,
Claude Code, Ollama) is installed on every VM and was exercised there while
building this session: on the hosted lab VMs it did not respond reliably, and
the browser assistants just worked. So every track runs in the browser, and no
attendee step depends on the installed stack - it stays on the image as
take-home material. `attendee/choose-your-assistant.md` section 3 is the
attendee-facing version of this paragraph. If you see someone typing into the
Continue panel, move them to the browser rather than debugging the panel.

Self-selection is deliberately loose. Moving someone mid-session costs nothing:
no track depends on having done another one.

## Staffing 60-90 attendees with 3 people

- **One facilitator per track**, each visibly stationed in one part of the
  room, beats three people firefighting randomly. Say which corner is which
  when you announce the split.
- The presenter drives the room from the front (pacing, explaining what's
  happening) and floats Track 1, which is both the largest group and the one
  where being stuck is most demoralising.
- Assistants handle the recurring failure classes in `troubleshooting.md`
  directly rather than routing everything through the presenter.
- Agree on a simple, visible "I'm stuck" signal before the session starts
  (raised hand, a specific emoji/word in chat) so assistants can triage at a
  glance across a full room instead of waiting to be flagged down.
- Don't try to debug an attendee's exact problem live in front of everyone
  unless it's clearly common - note it, keep moving, follow up 1:1.
- **Say up front that the model will confidently make things up.** Framed as a
  known property it becomes the session's point about validation; discovered
  by surprise it reads as the workshop being broken.

## Timing

| Minutes | What |
| --- | --- |
| 0-15 | Talk: why this matters, and the three-track split |
| 15-20 | Everyone opens the **START HERE** desktop shortcut and picks a track |
| 20-80 | Hands-on. Facilitators hold their tracks |
| 80-90 | Two or three attendees show what they built; where to get the repo |

The slowest setup step by far is the first `ollama pull` of the chat model
(several minutes depending on model size and network). **Pre-pull the models
into the VM image** via `Provision-LabVM.ps1` ahead of time - never during the
live 90 minutes. `SkipOllamaPull` in
`provisioning/config/provisioning.config.psd1` lets you re-run provisioning
for testing without re-pulling once they're cached in the image. Self-test
check 3 is what confirms it actually happened on a given VM.

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

## Afterwards

Attendees keep the repo, not the VM. Point them at
[`attendee/tracks/3-teach-and-scale/workshop-in-a-box.md`](../attendee/tracks/3-teach-and-scale/workshop-in-a-box.md)
regardless of which track they were on - it's the "how do I do this at my
company" page, and it's the one thing most likely to be read on the flight
home.

Contributions come back as pull requests against the public repo. The most
useful are corrections to `attendee/` from people who used it under real
conditions - we only get to observe that once.
