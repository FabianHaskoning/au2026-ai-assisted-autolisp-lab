# Track 3 - Teach and scale

**For:** you already use AI to write AutoLISP and it mostly works. Your problem
isn't getting a routine out of a model - it's everything around that.

**You'll leave with:** a workflow two people can share without stepping on each
other, and a concrete plan for running this session inside your own
organisation.

**Time:** about 60 minutes. Pick two of the three parts below - all three won't
fit, and the third is a good read on the plane home.

---

## Why this track exists

The hard part of AI-assisted AutoLISP at scale isn't the AI. Three things break
first, and none of them are model problems:

1. **Nobody can review anyone else's routine.** Code arrives by email, in
   chat, on a shared drive as `tool_v3_final_FIXED.lsp`. There's no history and
   no way to see what changed.
2. **Everyone re-learns the same lessons.** Each person independently
   discovers that you need an `*error*` handler, that the model assumes the
   wrong AutoCAD version, that pasting 200 lines makes it worse.
3. **The person who set it up becomes the bottleneck.** That's you, and it
   doesn't scale past about five colleagues.

Git fixes the first. Shared instruction files fix the second. A repeatable
session fixes the third. One part below for each.

---

## Part A - Two people, one routine (25 min)

[`pair-workflow.md`](pair-workflow.md)

Branch, review, merge, resolve a conflict - the smallest complete loop that
lets two engineers work on the same routine without one overwriting the other.
Two ways to do it depending on whether you have a GitHub account.

Do this one if your immediate problem is *"my colleague and I keep sending each
other files"*.

---

## Part B - Encode your standards, once (20 min)

Track 2's exercise is worth doing even from here, but at this level the point
is different: you're not writing rules for yourself, you're writing them for
the twelve people who'll use them after you.

1. Read the six files in `C:\LabWork\.continue\rules\`. Note that each one is
   short, single-concern, and says checkable things.
2. Write one real rule file for **your** organisation - your layer naming, your
   text heights, your title-block conventions, your review requirements. Put it
   in `.continue/rules/07-<yourcompany>.md`.
3. Commit it, and think about where it would actually live at work: in the
   repo alongside the routines, so it's versioned and reviewable like
   everything else - not in someone's OneDrive.

The format is portable. The same text works as `CLAUDE.md`, as
`.github/copilot-instructions.md`, or pasted into a ChatGPT project. Pick the
tool your IT department already approved; the content doesn't change.

**The rule of thumb worth taking home:** the third time you correct the
assistant about the same thing, stop correcting and write it down.

---

## Part C - Run this session yourself (15 min read)

[`workshop-in-a-box.md`](workshop-in-a-box.md)

What it actually takes: hardware, which model for which machine, the
provisioning script, timing, how many facilitators, and the failure modes that
eat your session if you don't plan for them. Everything in it is in this repo
already and free to reuse.

---

## Contribute back

This whole lab is public:

```text
https://github.com/FabianHaskoning/au2026-ai-assisted-autolisp-lab
```

If you write a rules file, an example routine, or find something wrong in these
instructions - fork it and open a pull request. `pair-workflow.md` walks
through exactly that, and it doubles as the git exercise.

Genuinely useful contributions, in rough order:

- A rules file for a discipline we don't cover (structural, MEP, survey).
- A small, well-commented example routine for Track 1.
- A correction to anything in `attendee/` that was wrong or confusing on the
  day - you're the only people who'll ever see it under real conditions.
