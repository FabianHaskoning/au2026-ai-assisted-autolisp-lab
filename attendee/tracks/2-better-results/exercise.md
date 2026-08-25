# Exercise - before and after, side by side

About 35 minutes. You'll run the **same vague prompt twice**, with one rule
file added in between, and then look at the two answers side by side with
every difference highlighted.

The vagueness is the point. Anyone can get good code from a carefully written
prompt. The question is what you get on a Tuesday afternoon when you type the
first thing that comes into your head.

**Parts:** [1 Baseline](#part-1-the-baseline) · [2 Write a rule](#part-2-write-your-own-rule) ·
[3 Same prompt again](#part-3-the-same-prompt-again) · [4 Look at the difference](#part-4-look-at-the-difference)

---

## Your folder is already there

Open `C:\LabWork\my-work\rules-experiment\` in the VS Code Explorer. Two empty
files are waiting: `baseline.lsp` and `after.lsp`. Nothing to create.

---

## Part 1: The baseline

**8 minutes.**

**Start a brand-new chat.** Click the **+** at the top of the Continue panel
first — a leftover conversation would contaminate the comparison.

Paste this exactly. Don't improve it:

```text
Write me an AutoLISP routine that moves selected objects to a different layer.
```

Copy whatever comes back into `baseline.lsp`, then **File → Save**
*(`Ctrl+S`)*.

**Before you move on, note what you got.** Specifically:

- Did it include an `*error*` handler?
- Does it create the layer if it doesn't exist, or assume it's there?
- Does it restore any system variable it changed?
- Which AutoCAD version did it assume?
- Did it ask you anything, or just guess?

Some of these will already be handled — that's the six existing rule files
working. Note which ones aren't. For what "all of them handled" looks like,
skim [`examples/well-behaved-command.lsp`](examples/well-behaved-command.lsp).

> Using your own ChatGPT/Claude/Copilot account instead? The experiment works
> there too: run the vague prompt in a fresh chat for the baseline, then add
> [`boilerplate-prompt.md`](../../boilerplate-prompt.md) (plus your own rules)
> to the project instructions and run it again.

**▶ Next: [Part 2 — Write your own rule](#part-2-write-your-own-rule)**

---

## Part 2: Write your own rule

**10 minutes.**

Create a new file in `C:\LabWork\.continue\rules\` called
`07-my-standards.md`. In the VS Code Explorer: right-click the `rules` folder →
**New File…** → type the name.

Use this shape. The block at the top matters — `alwaysApply: true` is what
makes it load on every prompt:

```markdown
---
name: my-standards
description: My own conventions for AutoLISP routines
alwaysApply: true
---

# My standards

- <your rule>
- <your rule>
- <your rule>
```

Now fill in **two or three real rules**. Use your actual company conventions if
you have them — this file is more useful to you if it's true. Otherwise pick
from the gaps you noticed in Part 1:

- "Layer names always start with `PRJ-` and are upper case."
- "Default text height is 2.5 unless the user says otherwise."
- "Any routine that moves or modifies existing entities must report how many it
  will affect and ask for confirmation before doing it."
- "Write code comments in Dutch. Chat replies in English."
- "Never use `(command ...)` for layer creation - use `entmake` or the layer
  table."

Keep each one **specific and checkable**. "Write clean code" will do nothing.

Save the file.

> Continue.dev picks the file up on the next prompt. If it clearly hasn't,
> reload the window: **View → Command Palette…** → type `reload` → pick
> **Developer: Reload Window**.

**▶ Next: [Part 3 — The same prompt again](#part-3-the-same-prompt-again)**

---

## Part 3: The same prompt again

**8 minutes.**

**Start another new chat** — the **+** icon again. This matters: reusing the
old chat means the model just copies its previous answer.

Paste the **exact same prompt**:

```text
Write me an AutoLISP routine that moves selected objects to a different layer.
```

Copy the result into `after.lsp`, then **File → Save**.

**▶ Next: [Part 4 — Look at the difference](#part-4-look-at-the-difference)**

---

## Part 4: Look at the difference

**7 minutes.** This is the part worth being here for.

1. In the **Explorer** on the left, click `baseline.lsp` once.
2. Hold **Ctrl** and click `after.lsp`. Both are highlighted now.
3. **Right-click** either one → **Compare Selected**.

Two panes open with every difference coloured in. Green is what the rule added,
red is what it replaced. Full instructions:
[Compare two files](../../how-to/compare-two-files.md).

**What to look for:**

- Did your rules actually show up in the code?
- Did anything you *didn't* ask for improve as well?
- Did anything get worse or longer without being better?
- How close is `after.lsp` to
  [`examples/well-behaved-command.lsp`](examples/well-behaved-command.lsp)?
  The distance that's left is your next rule.

### If the difference is disappointing

That's the real lesson and it's worth the ten minutes to chase it. Almost
always it's one of:

- **The rule was too vague.** "Follow our standards" → make it name the thing.
- **The rule described a style, not an action.** "Be careful with layers" →
  "check the layer exists with `tblsearch` before using it".
- **The file isn't being read.** Check the block at the top is exactly right,
  especially `alwaysApply: true`, and reload the window.
- **You reused the old chat.** Genuinely the most common cause. Start a fresh
  one.

Sharpen one rule and run Part 3 again. Two iterations of this teaches you more
about instruction files than any amount of reading.

---

## Done

Keep `07-my-standards.md`. It's the most portable thing you're taking home
today: paste it into Copilot's custom instructions or a ChatGPT project and it
works there too.

Back to [Track 2](README.md), or on to
[Track 3 — Teach and scale](../3-teach-and-scale/README.md).

---

← [Track 2](README.md) · [Start here](../../START-HERE.md) ·
[Compare two files](../../how-to/compare-two-files.md)
