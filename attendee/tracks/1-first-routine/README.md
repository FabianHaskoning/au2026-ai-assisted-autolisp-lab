# Track 1 - Your first routine

**For:** you have never written AutoLISP, or never used an AI assistant to
write code. Both is fine. Most of the room is here.

**You'll leave with:** working examples and a routine you asked for yourself,
running inside AutoCAD — **today**. If you've never done this before, that's
the entire win. Celebrate it.

**Steps:** [1 Say hello](#step-1-say-hello) · [2 Run one](#step-2-run-a-routine-somebody-else-wrote) ·
[3 Ask for your own](#step-3-ask-for-your-own-routine) · [4 Change one thing](#step-4-change-one-thing) ·
[5 Go again](#step-5-go-again) · [Done](#done-three-things)

About 75 minutes in total. If you're running behind, skip step 5, not step 3.

---

## Step 1: Say hello

**5 minutes.**

Open the assistant: in the narrow strip of icons down the far left of VS Code,
click the **Continue** icon. Full instructions with a picture of where to
look: [Open the assistant](../../how-to/open-the-assistant.md).

Type anything — `what is AutoLISP?` will do — and press Enter.

You're waiting for two things: that it answers at all, and that it's noticeably
slower than ChatGPT. Both are normal. This model runs on this machine, for
free, with no account.

**If nothing happens after 60 seconds:** raise your hand.

**▶ Next: [Step 2 — Run a routine somebody else wrote](#step-2-run-a-routine-somebody-else-wrote)**

---

## Step 2: Run a routine somebody else wrote

**10 minutes.** This is the most important step on the page.

Before asking AI for anything, get one working routine into AutoCAD. Then when
something breaks later, you'll know it's the *code* that's wrong — not you.

1. Open AutoCAD 2026 (it's on the taskbar) and start a **new, blank drawing**.
2. Type `APPLOAD` and press Enter.
3. Browse to `C:\LabWork\tracks\1-first-routine\examples\hello-world.lsp`
4. Click **Load**, then **Close**.
5. Type `HELLO` at the command line and press Enter.

A line of text appears. **That's a routine running.** Nothing was drawn — which
is the point, it can't break anything.

Now do the same with `circle-at-point.lsp` in that same folder, and run
`CIRCLEHERE`. This one asks you to pick a point and draws a circle there.

Open both files in VS Code and read them. You are **not** expected to
understand every bracket. Look for the lines starting with `;;` — those are
comments, and they explain what each part does.

> Full version of this loop, including what to do when it doesn't work:
> [Get a routine into AutoCAD](../../how-to/load-a-routine.md).

**Stuck here? Raise your hand.** Don't move on without this working.

**▶ Next: [Step 3 — Ask for your own routine](#step-3-ask-for-your-own-routine)**

---

## Step 3: Ask for your own routine

**20 minutes.** Now the real thing.

### Your folder is already there

Open `C:\LabWork\my-work\routine-1\` in the VS Code Explorer. Four files are
waiting for you — you don't have to create or name anything:

| File | What goes in it |
| --- | --- |
| `routine-1-core.lsp` | **This is the one you'll use.** Paste the assistant's code here |
| `routine-1-util.lsp` | Helper bits, if your routine grows |
| `routine-1-command.lsp` | The command definition, if you split things up later |
| `routine-1-loader.lsp` | The front door. This is what you `APPLOAD` |

For today, `-core.lsp` and `-loader.lsp` are the only two that matter.

### Ask for the code

Open the assistant and paste one of the prompts from
[`prompts.md`](prompts.md). **Start with prompt 1** if you have no strong
preference — it's the one most likely to work first time.

### Get it into your file

Copy the code the assistant produced into `routine-1-core.lsp`, then
**File → Save** *(`Ctrl+S`)*.

Saving matters: AutoCAD loads what's on disk, not what's on your screen.

### Load it and run it

`APPLOAD` **`routine-1-loader.lsp`** — the loader, not the core file. The
loader is the front door; it pulls in everything else.

Then type your command name and press Enter.

> **If the loader asks you to point at `routine-1-util.lsp`**, do it — pick
> that file in the dialog and it carries on. It only happens once. And if it
> gets awkward, just `APPLOAD` `routine-1-core.lsp` directly instead; the
> loader is a convenience, not a requirement.

### When it doesn't work first time

It often won't. That's not failure, that's the loop:

1. Copy the **exact** error text from the AutoCAD command line — all of it,
   red text included.
2. Paste it into the assistant with one sentence in front:
   `I got this error when loading the file:`
3. Apply the fix, `APPLOAD` again.

Two or three rounds of this is completely normal, and it is the single most
useful habit you'll take home from today. More on it in
[When it goes wrong](../../how-to/when-it-goes-wrong.md).

**▶ Next: [Step 4 — Change one thing](#step-4-change-one-thing)**

---

## Step 4: Change one thing

**20 minutes.**

A routine you can *change* is worth much more than one you can only run.

Pick **one** small improvement and ask for it — one change, one prompt:

- "Ask the user for the radius instead of always using 10."
- "Put the circle on a layer called `SKETCH`, and create that layer if it
  doesn't exist."
- "Ask how many circles to draw, then draw that many in a row."

Save the file, `APPLOAD` the loader again, and test it.

### If your change made things worse

Don't retype anything. VS Code kept the earlier version:

1. In the **Explorer**, scroll to the bottom and open the **Timeline** section.
2. Find the entry from before your change and click it to see what's different.
3. **Right-click it → Restore Contents.**

Your file is back exactly as it was. Full instructions:
[Save your work, and get it back](../../how-to/save-your-work.md).

**Nothing you do today can be lost, and nothing you do today can break the
machine.** Try the thing you're not sure about.

**▶ Next: [Step 5 — Go again](#step-5-go-again)**

---

## Step 5: Go again

**Whatever time is left.**

You now know the whole loop. Do it once more on something closer to your
actual job — this time in `C:\LabWork\my-work\routine-2\`.

Ideas, roughly easiest first:

1. **Block counter** — count blocks of a specific name and report the total.
   (`examples/count-blocks.lsp` is a working starting point — read it, then ask
   for the change you want.)
2. **Batch layer creator** — create a standard set of layers with set colours.
   (`examples/make-layers.lsp` does exactly this — run it, read it, then ask
   for your own layer names and colours.)
3. **Text height fixer** — select all text and multiply its height by 1.5.
4. **AsBuilt converter** — change layer properties from ToBuild to AsBuilt.
5. **Quick dimension tool** — place a dimension with a fixed style on a fixed
   layer.

There's a `routine-3` folder too if you get that far.

**▶ Next: [Done? Three things](#done-three-things)**

---

## Done? Three things

1. **Save one last time.** File → Save.
2. **Read [Track 2](../2-better-results/README.md).** It explains why the
   assistant on this VM produced better AutoLISP than you might have expected —
   and how to get that same lift at home. Five-minute read even if you skip the
   exercise.
3. **See where this road leads.** `APPLOAD`
   `C:\LabWork\showcase\roundabout\rdb-loader.lsp` and type `ROUNDABOUT` in a
   blank drawing — a full application built from exactly the patterns you used
   today. Both showcases: [Showcases](../../showcase/README.md).

---

← [Start here](../../START-HERE.md) · [Prompts](prompts.md) ·
[When it goes wrong](../../how-to/when-it-goes-wrong.md)
