# Exercise - before and after, in your own git history

About 35 minutes. You'll run the **same vague prompt twice**, with one rule
file added in between, and use `git diff` to see exactly what changed.

The vagueness is the point. Anyone can get good code from a carefully written
prompt. The question is what you get on a Tuesday afternoon when you type the
first thing that comes into your head.

---

## Set up (2 min)

```powershell
New-Routine rules-experiment
```

---

## Part 1 - The baseline (8 min)

**Start a brand-new chat.** In the Continue.dev panel, click the **+** (new
session) icon first - a leftover conversation would contaminate the comparison.

Paste this exactly. Don't improve it:

```text
Write me an AutoLISP routine that moves selected objects to a different layer.
```

Copy whatever comes back into
`C:\LabWork\rules-experiment\baseline.lsp`, save the file, then:

```powershell
save "baseline - before adding my own rule"
```

**Before you move on, note what you got.** Specifically:

- Did it include an `*error*` handler?
- Does it create the layer if it doesn't exist, or assume it's there?
- Does it restore any system variable it changed?
- Which AutoCAD version did it assume?
- Did it ask you anything, or just guess?

Some of these will already be handled - that's the six existing rule files
working. Note which ones aren't. For what "all of them handled" looks like,
skim [`examples/well-behaved-command.lsp`](examples/well-behaved-command.lsp).

> Using your own ChatGPT/Claude/Copilot account instead of Continue.dev? The
> experiment works there too: run the vague prompt in a fresh chat for the
> baseline, then add [`boilerplate-prompt.md`](../../boilerplate-prompt.md)
> (plus your own rules) to the project instructions and run it again.

---

## Part 2 - Write your own rule (10 min)

Create a new file: `C:\LabWork\.continue\rules\07-my-standards.md`

Use this shape - the front matter matters, `alwaysApply: true` is what makes it
load on every prompt:

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
you have them - this file is more useful to you if it's true. Otherwise pick
from the gaps you noticed in Part 1:

- "Layer names always start with `PRJ-` and are upper case."
- "Default text height is 2.5 unless the user says otherwise."
- "Any routine that moves or modifies existing entities must report how many it
  will affect and ask for confirmation before doing it."
- "Write code comments in Dutch. Chat replies in English."
- "Never use `(command ...)` for layer creation - use `entmake` or the layer
  table."

Keep each one **specific and checkable**. "Write clean code" will do nothing.

Save the file, then:

```powershell
save "added my own rules file"
```

> Continue.dev picks the file up on the next prompt. If it clearly hasn't, run
> **Developer: Reload Window** from `Ctrl+Shift+P`.

---

## Part 3 - The same prompt again (8 min)

**Start another new chat** - the `+` icon again. This matters: reusing the old
chat means the model just copies its previous answer.

Paste the **exact same prompt**:

```text
Write me an AutoLISP routine that moves selected objects to a different layer.
```

Copy the result into `C:\LabWork\rules-experiment\after.lsp`, then:

```powershell
save "after - with my own rule applied"
```

---

## Part 4 - Look at the difference (7 min)

In PowerShell:

```powershell
cd C:\LabWork\rules-experiment
git diff --no-index baseline.lsp after.lsp
```

Green is what the rule added, red is what it replaced.

**What to look for:**

- Did your rules actually show up in the code?
- Did anything you *didn't* ask for improve as well?
- Did anything get worse or longer without being better?
- How close is `after.lsp` to
  [`examples/well-behaved-command.lsp`](examples/well-behaved-command.lsp)?
  The distance that's left is your next rule.

**If the diff is disappointing**, that's the real lesson and it's worth the ten
minutes to chase it. Almost always it's one of:

- **The rule was too vague.** "Follow our standards" → make it name the thing.
- **The rule described a style, not an action.** "Be careful with layers" →
  "check the layer exists with `tblsearch` before using it".
- **The file isn't being read.** Check the front matter is exactly right,
  especially `alwaysApply: true`, and reload the window.
- **You reused the old chat.** Genuinely the most common cause. Start a fresh
  one.

Sharpen one rule and run Part 3 again. Two iterations of this teaches you more
about instruction files than any amount of reading.

---

## Part 5 - The same trick, one level up (bonus)

Open `C:\LabWork\CLAUDE.md`. Same idea, different tool: this is what the
`claude-local` command-line assistant reads on every prompt, and it's the file
you'd write for Claude, Copilot or ChatGPT at home.

Try it - in PowerShell:

```powershell
claude-local
```

Ask it the same vague prompt. Then edit `CLAUDE.md`, restart it, and ask again.
Same lever, different handle.

> This is slower than the Continue.dev panel - it's the same local model, but
> the command-line assistant reads more files before answering. Give it time.

---

## Done

```powershell
save "finished the rules experiment"
```

Keep `07-my-standards.md`. It's the most portable thing you're taking home
today: paste it into Copilot's custom instructions or a ChatGPT project and it
works there too.
