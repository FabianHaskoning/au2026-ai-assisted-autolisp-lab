# Running this session yourself

Everything you need is in the public repo, free to reuse:

```text
https://github.com/FabianHaskoning/au2026-ai-assisted-autolisp-lab
```

This page is the honest version - what it costs, what breaks, and what to cut
when you're short on time.

---

## What you actually need

| | Minimum | What this lab uses |
| --- | --- | --- |
| **Machine per attendee** | 8 GB RAM, 15 GB free disk | 56 GB RAM, 8-core, 4 GB GPU |
| **Software** | AutoCAD, VS Code, git, Ollama | Same, plus Civil 3D |
| **AI** | A local Ollama model - free | `qwen3.5:4b` |
| **Network** | Only to install. The model runs offline | Full internet |
| **People** | 1 facilitator per ~25 attendees | 3 for 60-90 |
| **Time** | 90 minutes | 90 minutes |

**The whole point is that there is no per-seat AI cost.** The model runs on the
machine. That's usually what makes this approvable at a company where a
Copilot licence for every designer isn't.

---

## Picking a model for your hardware

`provisioning/config/model-decision-table.psd1` in the repo does this
automatically, but the reasoning is worth understanding because it's the
decision people get wrong:

| RAM | Chat model | Notes |
| --- | --- | --- |
| under 8 GB | `qwen2.5-coder:3b` | CPU-only. Fine for short routines. |
| 8-16 GB | `qwen2.5-coder:7b` | Comfortable, still CPU-viable. |
| 16 GB+ | `qwen3.5:4b` | Small enough to fit fully in a modest GPU, and reliable at tool-calling despite its size. |

Autocomplete always uses `qwen2.5-coder:1.5b`, on every tier, so typing stays
responsive even while the chat model is thinking.

Two traps:

- **Bigger is not better if it doesn't fit.** A 30B model on a 4 GB GPU gets
  split between GPU and CPU and becomes painfully slow. A 4B model that fits
  entirely in VRAM beats it for this workload.
- **Not every small model can call tools.** Qwen2.5-Coder writes fine code but
  is unreliable at agentic tool use, which is why the top tier switches family
  rather than just scaling up.

Run `provisioning/Test-LabVMSpecs.ps1` on a representative machine and it tells
you which tier you're on.

---

## Setting the machines up

`provisioning/Provision-LabVM.ps1`,
run once as Administrator, does the lot: installs git, VS Code, Ollama and
Continue.dev, pulls the right model, writes the assistant config, creates the
attendee workspace as a git repo, installs the `New-Routine`/`save`/`undo`
helpers into both PowerShell versions, and drops these instructions onto the
desktop.

It's **idempotent** - safe to re-run any number of times. Re-running after a
partial failure fixes it rather than breaking things.

**Pull the model into the image beforehand.** This is the single most important
scheduling decision. A first-time `ollama pull` takes minutes; 60 people
downloading simultaneously over conference wifi takes considerably longer than
your entire session.

---

## Timing that works

| Minutes | What |
| --- | --- |
| 0-15 | Talk. Why this matters, one demo, and the three-track split |
| 15-20 | Everyone opens the desktop shortcut and picks a track |
| 20-85 | Hands-on. Facilitators circulate |
| 85-90 | Two or three people show what they built. Where to get the repo |

Everything after the talk - about 75 minutes - is the attendee's hands-on
time, and that's the number the attendee docs quote.

**Split the room into tracks and staff each one.** Expect roughly 50% who've
never tried, 35% who've dabbled, 15% experienced. One facilitator per track,
each visibly stationed in one part of the room, beats three people
firefighting randomly.

**Agree on a "stuck" signal before you start** - a raised hand, a sticky note,
a word in chat. With 60+ people you need to triage the room at a glance.

**Don't debug one person's problem in front of everyone** unless it's clearly
affecting many. Note it, keep moving, follow up individually.

---

## What will actually go wrong

From `facilitator/troubleshooting.md` in the repo, in roughly the order you'll
meet them:

| Problem | Fix |
| --- | --- |
| `New-Routine`/`save`/`undo` not recognised | Their terminal was open before setup finished. New window. |
| The assistant errors immediately | Model tag in the config doesn't match what's pulled. `ollama list`. |
| "Connection refused" | Ollama service isn't running. `ollama serve`. |
| Everything is very slow | AutoCAD + VS Code + model all at once. Close things, shorter prompts. |
| `APPLOAD` refuses the file | Usually genuine unbalanced brackets. Read the error text. |
| The assistant invents a menu that isn't there | Small-model limitation. Correct it in chat and move on. |

The last one deserves a slide of its own. **Tell people up front that the model
will confidently make things up.** Framed as a known property it's a teaching
moment about validation; discovered by surprise it reads as the workshop being
broken.

---

## What to cut if you have less than 90 minutes

- **60 minutes:** talk for 10, Track 1 only, skip the "change one thing" step.
- **45 minutes:** demo instead of hands-on for the first routine, then let
  people modify a working example. Skip git entirely - they can't absorb both.
- **Under 45:** don't. People need enough time to fail once and recover, or
  they leave thinking it only works when an expert drives.

The one thing never to cut is **loading a routine into AutoCAD themselves**. An
attendee who has watched it but not done it hasn't learned anything they'll act
on.

---

## The governance argument

If you need to sell this internally, this is the framing that works:

The risk isn't that engineers write AutoLISP with AI. They already paste code
from forums, from colleagues, from ChatGPT on their phone. The risk is that it
happens **with no version history, no review, and no way to roll back**.

This setup doesn't add risk - it adds the missing half:

- Every routine on a branch, with a full history of what changed and why.
- A review step before anything is shared.
- Instruction files that put the safety practices in by default - `*error*`
  handlers, restoring system variables, confirming before destructive
  operations.
- A model that runs locally, so no drawing data leaves the building.

That last point closes most conversations with IT and legal on its own.
