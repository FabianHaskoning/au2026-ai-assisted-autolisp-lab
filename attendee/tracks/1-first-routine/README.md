# Track 1 - Your first routine

**For:** you have never written AutoLISP, or never used an AI assistant to
write code. Both is fine. Most of the room is here.

**You'll leave with:** a routine you asked for, running inside AutoCAD, saved
in git.

**Time:** about 60 minutes. Every step below has a target time - if you're
running behind, skip step 5, not step 3.

> New to all of this? Read [`../../START-HERE.md`](../../START-HERE.md) first -
> it's one page and it explains `APPLOAD`, `save`, and where your files live.

---

## Step 1 - Say hello to the assistant (5 min)

In VS Code, press **`Ctrl+L`**. The assistant panel opens on the side.

Type anything - `what is AutoLISP?` will do - and press Enter.

You're waiting for two things: that it answers at all, and that it's noticeably
slower than ChatGPT. Both are normal. This model runs on this machine, for
free, with no account.

**If nothing happens after 60 seconds:** raise your hand.

---

## Step 2 - Run a routine somebody else wrote (10 min)

Before asking AI for anything, get one working routine into AutoCAD. Then
you'll know that when something breaks later, it's the *code* that's wrong -
not you.

1. Open AutoCAD 2026 (it's on the taskbar). Start a new blank drawing.
2. Type `APPLOAD` and press Enter.
3. Browse to:
   `C:\LabWork\tracks\1-first-routine\examples\hello-world.lsp`
4. Click **Load**, then **Close**.
5. Type `HELLO` at the command line and press Enter.

You should see a line of text appear. **That's a routine running.** Nothing was
drawn - that's the point, it can't break anything.

Now do the same with `circle-at-point.lsp` in that same folder, and run
`CIRCLEHERE`. This one asks you to pick a point and draws a circle there.

Open both files in VS Code and read them. You are not expected to understand
every bracket. Look for the comment lines starting with `;;` - they explain
what each part does.

**Stuck here?** This is the most important step to get right. Raise your hand.

---

## Step 3 - Ask for your own routine (20 min)

Now the real thing.

**First, start it properly.** Open a PowerShell window and run:

```powershell
New-Routine my-first
```

That makes a git branch, creates a set of empty files in
`C:\LabWork\my-first\`, and commits them. From here on, everything you do is
recoverable.

**Second, ask for the code.** Press `Ctrl+L` in VS Code and paste one of the
prompts from [`prompts.md`](prompts.md). Start with prompt 1 if you have no
strong preference - it's the one most likely to work first time.

**Third, get it into your file.** Copy the code the assistant produced into
`C:\LabWork\my-first\my-first-core.lsp` (open it in VS Code). Save the file
with `Ctrl+S`.

**Fourth, load and run it** using the `APPLOAD` loop from step 2 - but load
`my-first-loader.lsp`, not the core file. The loader is the front door; it
pulls in everything else.

**Fifth, save your progress:**

```powershell
save "first version of my routine"
```

### When it doesn't work first time

It often won't. That's not failure, that's the loop:

- Copy the **exact** error text from the AutoCAD command line - all of it, red
  text included.
- Paste it into the assistant with one sentence: `I got this error when
  loading the file:` followed by the error.
- Apply the fix, `APPLOAD` again.

Two or three rounds of this is completely normal, and it's the single most
useful habit you'll take home from today.

---

## Step 4 - Change one thing (20 min)

A routine you can *change* is worth much more than one you can only run.

Pick **one** small improvement and ask the assistant for it - one change, one
prompt:

- "Ask the user for the radius instead of always using 10."
- "Put the circle on a layer called `SKETCH`, and create that layer if it
  doesn't exist."
- "Ask how many circles to draw, then draw that many in a row."

Load it, test it, and then:

```powershell
save "asks for the radius now"
```

**If your change made things worse**, don't retype anything. Run:

```powershell
undo
```

That takes back the last `save` and leaves your files exactly as they are, so
you can fix them. Your work is never lost.

---

## Step 5 - Go again (whatever time is left)

You now know the whole loop. Do it once more on something closer to your actual
job. Ideas, roughly easiest first:

1. **Block counter** - count blocks of a specific name and report the total.
   (`examples/count-blocks.lsp` is a working starting point - read it, then ask
   for the change you want.)
2. **Batch layer creator** - create a standard set of layers with set colours.
3. **Text height fixer** - select all text and multiply its height by 1.5.
4. **AsBuilt converter** - change layer properties from ToBuild to AsBuilt.
5. **Quick dimension tool** - place a dimension with a fixed style on a fixed
   layer.

Run `New-Routine <name>` first for each new idea - a fresh branch per routine
keeps them from tangling.

---

## Done? Two things

1. Run `save "final version"` one last time.
2. Have a look at [Track 2](../2-better-results/README.md). It explains why the
   assistant on this VM produced better AutoLISP than you might have expected -
   and how to get that same lift at home. It's a five-minute read even if you
   don't do the exercise.
