# Exercise - before and after, side by side

About 35 minutes. You'll run the **same vague prompt twice** — once bare,
once with standing instructions pasted first — and then look at the two
answers side by side with every difference highlighted.

The vagueness is the point. Anyone can get good code from a carefully written
prompt. The question is what you get on a Tuesday afternoon when you type the
first thing that comes into your head.

**Parts:** [1 Baseline](#part-1-the-baseline) · [2 Write your own rules](#part-2-write-your-own-rules) ·
[3 Same prompt again](#part-3-the-same-prompt-again) · [4 Look at the difference](#part-4-look-at-the-difference)

---

## Your folder is already there

Open `C:\LabWork\my-work\rules-experiment\` in the VS Code Explorer. Two empty
files are waiting: `baseline.lsp` and `after.lsp`. Nothing to create.

---

## Part 1: The baseline

**8 minutes.**

**Start a brand-new chat** in your browser assistant — and, just this once,
**don't paste the boilerplate**. The bare chat *is* the experiment: this is
what everyone who never heard of standing instructions gets.

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
- Did it give you a complete file, or a fragment to "paste at the command
  line"?

Note the gaps — they're what Part 2 fixes. For what "all of them handled"
looks like, skim
[`examples/well-behaved-command.lsp`](examples/well-behaved-command.lsp).

**▶ Next: [Part 2 — Write your own rules](#part-2-write-your-own-rules)**

---

## Part 2: Write your own rules

**10 minutes.**

You're going to extend the boilerplate with **two or three rules of your
own**. Open [`boilerplate-prompt.md`](../../boilerplate-prompt.md), copy its
prompt block somewhere handy (a scratch file, or straight into the chat box
of a new chat — don't send yet), and type your rules underneath, like:

```text
My standards
- Layer names always start with PRJ- and are upper case.
- Default text height is 2.5 unless the user says otherwise.
- Any routine that moves or modifies existing entities must report how
  many it will affect and ask for confirmation before doing it.
```

Use your actual company conventions if you have them — this list is more
useful to you if it's true. Otherwise pick from the gaps you noticed in
Part 1. More ideas:

- "Write code comments in Dutch. Chat replies in English."
- "Never use `(command ...)` for layer creation - use `entmake` or the layer
  table."

Keep each one **specific and checkable**. "Write clean code" will do nothing.

**▶ Next: [Part 3 — The same prompt again](#part-3-the-same-prompt-again)**

---

## Part 3: The same prompt again

**8 minutes.**

**Start another new chat.** This matters: reusing the old chat means the
model just copies its previous answer.

Send the **boilerplate + your rules** as the first message. Then paste the
**exact same prompt**:

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

Two panes open with every difference coloured in. Green is what your
instructions added, red is what they replaced. Full instructions:
[Compare two files](../../how-to/compare-two-files.md).

**What to look for:**

- Did your rules actually show up in the code?
- Did anything you *didn't* ask for improve as well? (That's the boilerplate's
  Safety section working.)
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
- **The instructions never reached the chat.** Did you actually send the
  boilerplate + rules as the first message of the *new* chat?
- **You reused the old chat.** Genuinely the most common cause. Start a fresh
  one.

Sharpen one rule and run Part 3 again. Two iterations of this teaches you
more about standing instructions than any amount of reading.

### The file version — for tools at work

Tools like Copilot, Claude Code and Continue.dev read standing instructions
from a *file* automatically, so nobody has to remember to paste anything —
that's the stronger form you'll set up at work
(`.github/copilot-instructions.md`, `CLAUDE.md`, `.continue/rules/*.md`; see
the table in [Track 2](README.md)). This VM has example rules files in
`C:\LabWork\.continue\rules\` worth copying — but the file-reading tools
here may not respond, which is why today's proof ran through the chat box.

---

## Done

Keep your rules block. It's the most portable thing you're taking home today:
paste it — with the boilerplate — into a ChatGPT project, Claude project
instructions or Copilot's custom instructions and it works there too.

Back to [Track 2](README.md), or on to
[Track 3 — Teach and scale](../3-teach-and-scale/README.md).

---

← [Track 2](README.md) · [Start here](../../START-HERE.md) ·
[Compare two files](../../how-to/compare-two-files.md)
