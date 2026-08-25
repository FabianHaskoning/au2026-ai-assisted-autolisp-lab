# Track 3 - Teach and scale

**For:** you already use AI to write AutoLISP and it mostly works. Your problem
isn't getting a routine out of a model — it's everything around that.

**You'll leave with:** not code, and that's deliberate. This track is about
doing all of this easier, nicer and better: a way of working a team can share,
and a concrete plan for running a session like this inside your own
organisation. If you write barely a line of AutoLISP in the next 75 minutes,
the track worked.

**Parts:** [A Encode your standards](#part-a-encode-your-standards-once) ·
[B Read the drawing](#part-b-read-the-drawing-instead-of-drawing) ·
[C Run this session yourself](#part-c-run-this-session-yourself) ·
[D Two people, one routine](#part-d-two-people-one-routine-optional)

About 75 minutes. **Pick two.** All four won't fit, and the rest is a good read
on the plane home.

---

## Why this track exists

The hard part of AI-assisted AutoLISP at scale isn't the AI. Three things break
first, and none of them are model problems:

1. **Everyone re-learns the same lessons.** Each person independently
   discovers that you need an `*error*` handler, that the model assumes the
   wrong AutoCAD version, that pasting 200 lines makes it worse.
2. **Nobody can review anyone else's routine.** Code arrives by email, in
   chat, on a shared drive as `tool_v3_final_FIXED.lsp`. No history, no way to
   see what changed.
3. **The person who set it up becomes the bottleneck.** That's you, and it
   doesn't scale past about five colleagues.

Shared instruction files fix the first. Some form of version control fixes the
second. A repeatable session fixes the third. One part below for each.

---

## Part A: Encode your standards, once

**20 minutes.** Start here — it's the one with the highest payoff per minute.

Track 2's exercise is worth doing even from here, but at this level the point
is different: you're not writing rules for yourself, you're writing them for
the twelve people who'll use them after you.

1. Read the six files in `C:\LabWork\.continue\rules\`. Note that each one is
   short, single-concern, and says checkable things.
2. Write one real rule file for **your** organisation — your layer naming, your
   text heights, your title-block conventions, your review requirements. Put it
   in `.continue/rules/07-<yourcompany>.md`.
3. Think about where it would actually live at work: alongside the routines, so
   it's versioned and reviewable like everything else — not in someone's
   OneDrive.

The format is portable. The same text works as `CLAUDE.md`, as
`.github/copilot-instructions.md`, or pasted into a ChatGPT project. Pick the
tool your IT department already approved; the content doesn't change.

**The rule of thumb worth taking home:** the third time you correct the
assistant about the same thing, stop correcting and write it down.

**▶ Next: [Part B — Read the drawing instead of drawing](#part-b-read-the-drawing-instead-of-drawing)**

---

## Part B: Read the drawing instead of drawing

**15 minutes.** The one technical idea worth taking from this track: the next
maturity level of AutoLISP tooling isn't drawing more — it's routines that
**understand what the drawing already contains**.

1. In a blank drawing, `APPLOAD`
   `C:\LabWork\showcase\roundabout\rdb-loader.lsp` and run `ROUNDABOUT` — a
   complete application built with the same patterns the tracks teach.
2. Then `APPLOAD` [`examples/read-the-drawing.lsp`](examples/read-the-drawing.lsp)
   and run `RDBINFO`: click one circle and it identifies the whole roundabout
   from nothing but the geometry — `entsel`, `ssget` with a filter, `entget`.
   It's 80 lines and read-only; the header lists extension exercises.

**Then read something nobody wrote for a workshop.** The
[cadastral map showcase](../../showcase/cadastral-map/README.md) is a real
production tool, contributed by the engineer who uses it: a web request, a data
format AutoLISP can't parse, and a dependency on somebody else's plugin. You
can't run it here — that's the point. It's the most honest thing in the
workshop about what this looks like at work.

**▶ Next: [Part C — Run this session yourself](#part-c-run-this-session-yourself)**

---

## Part C: Run this session yourself

**15 minute read.** [`workshop-in-a-box.md`](workshop-in-a-box.md)

What it actually takes: hardware, which model for which machine, the
provisioning script, timing, how many facilitators, and the failure modes that
eat your session if you don't plan for them. Everything in it is in this repo
already and free to reuse.

This is the one part that assumes you're comfortable running a setup script.
Everything else in the workshop deliberately doesn't.

**▶ Next: [Part D — Two people, one routine](#part-d-two-people-one-routine-optional)**

---

## Part D: Two people, one routine (optional)

**25 minutes.** [`../../optional/pair-workflow.md`](../../optional/pair-workflow.md)

> **This is the only part of the whole day that uses git and a terminal.** It's
> here because Track 3 is the audience that actually asks for it. Nothing else
> in the workshop depends on it, and skipping it costs you nothing.

Branch, review, merge, resolve a conflict — the smallest complete loop that
lets two engineers work on the same routine without one overwriting the other.
Two paths, depending on whether you have a GitHub account.

Do this one if your immediate problem is *"my colleague and I keep sending each
other files"*. Working solo and just want today's work on your own GitHub? The
lighter version is
[`../../optional/your-own-remote.md`](../../optional/your-own-remote.md).

---

## Contribute back

This whole lab is public:

```text
https://github.com/FabianHaskoning/au2026-ai-assisted-autolisp-lab
```

If you write a rules file, an example routine, or find something wrong in these
instructions — fork it and open a pull request.
[`pair-workflow.md`](../../optional/pair-workflow.md) walks through exactly
that.

Genuinely useful contributions, in rough order:

- A rules file for a discipline we don't cover (structural, MEP, survey).
- A small, well-commented example routine for Track 1.
- A correction to anything in the instructions that was wrong or confusing on
  the day — you're the only people who'll ever see it under real conditions.

---

← [Start here](../../START-HERE.md) · [Showcases](../../showcase/README.md) ·
[When it goes wrong](../../how-to/when-it-goes-wrong.md)
