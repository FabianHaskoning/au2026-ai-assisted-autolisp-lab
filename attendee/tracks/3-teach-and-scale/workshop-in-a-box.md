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
attendee workspace, creates a ready-made work folder per attendee, sets VS
Code up so the instructions open as rendered pages, and drops a START HERE
icon on the desktop.

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
| The instructions open as raw markdown | The workspace VS Code settings did not take. Re-run provisioning, reload the window. |
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
  people modify a working example.
- **Under 45:** don't. People need enough time to fail once and recover, or
  they leave thinking it only works when an expert drives.

The one thing never to cut is **loading a routine into AutoCAD themselves**. An
attendee who has watched it but not done it hasn't learned anything they'll act
on.

---

## The decision that mattered most: no terminal

Earlier versions of this session put git in the middle of it. Attendees ran
`New-Routine` to start, `save` to commit, and compared two files with
`git diff`. It was well-intentioned — nothing you make can be lost — and it was
the wrong call.

Two things happen when you put a black window with a blinking cursor in front
of an engineer who has spent twenty years in AutoCAD. They stop believing the
session is for them, and they spend their scarce minutes on your tooling
instead of on the thing they came for. "I'm not a programmer" is not modesty;
it's a prediction about whether they'll try.

So the whole session now happens in three places — the VS Code editor, the
assistant panel, and the AutoCAD command line — and every capability git was
providing has a click-only equivalent:

| Was | Is now |
| --- | --- |
| `New-Routine <name>` | Folders that already exist, already named, already there when they arrive |
| `save "message"` | File → Save |
| `undo` | The VS Code **Timeline**: right-click an earlier version, Restore Contents |
| `git diff a.lsp b.lsp` | Select both files, right-click, **Compare Selected** |

Nothing was lost. The Timeline is arguably better for this audience than commits
are: it needs no setup, no message, no concept of a repository, and it's per
file. Git is still installed and still documented, in one clearly-labelled
optional page that nobody has to open.

**The same applies to keyboard shortcuts.** Never write one as the only
instruction. Say what to click and where it is, then offer the shortcut in
brackets. You cannot test a shortcut on sixty machines you've never seen, and
the person who needs the instruction most is the one who won't try `Ctrl+L` on
faith.

---

## The governance argument

If you need to sell this internally, this is the framing that works:

The risk isn't that engineers write AutoLISP with AI. They already paste code
from forums, from colleagues, from ChatGPT on their phone. The risk is that it
happens **with no version history, no review, and no way to roll back**.

This setup doesn't add risk - it adds the missing half:

- Instruction files that put the safety practices in by default - `*error*`
  handlers, restoring system variables, confirming before destructive
  operations - versioned and reviewable like any other code.
- A review step before anything is shared, once you're ready for one.
- A history of what changed and why, whenever the team is ready to adopt it.
- A model that runs locally, so no drawing data leaves the building.

That last point closes most conversations with IT and legal on its own.

Note the order. The instruction files are the part that pays off on day one and
needs nothing from anybody; version control is where you go once more than one
person is involved. Leading with git is how these initiatives stall.

---

← [Track 3](README.md) · [Start here](../../START-HERE.md)
