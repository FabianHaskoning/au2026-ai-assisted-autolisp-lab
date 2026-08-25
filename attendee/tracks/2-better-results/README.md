# Track 2 - Better results

**For:** you've got an AI assistant to write AutoLISP before. Sometimes it's
great, sometimes it's nonsense, and you can't tell in advance which you'll get.

**You'll leave with:** measurably better answers — the single highest-leverage
trick there is — and code produced today that proves it, side by side on your
own screen.

**Steps:** [The lever](#the-thing-nobody-tells-you) · [Two routes](#two-ways-to-get-the-same-lift) ·
[You've been using it](#youve-already-been-using-it) · [Prove it](#now-prove-it-to-yourself) ·
[What makes a rule work](#what-makes-a-rule-work) · [Take it home](#take-it-home)

About 75 minutes.

---

## The thing nobody tells you

You've probably been trying to fix bad output by writing better prompts. That
works, but it only fixes *one answer*, and you have to do it again every time.

There's a second lever: a **standing instruction file** that the assistant
reads on *every* prompt, without you pasting anything. Get that right once and
every answer improves — including the lazy one-line prompts you'll actually
type when you're busy.

Every serious assistant has this. Only the filename changes:

| Tool | Where the standing instructions live |
| --- | --- |
| Continue.dev (on this VM) | `.continue/rules/*.md` in your workspace |
| Claude Code | `CLAUDE.md` in the project folder |
| GitHub Copilot | `.github/copilot-instructions.md` |
| ChatGPT | Project instructions |
| Claude (claude.ai) | Project instructions |
| Any tool without instruction-file support | Paste [`boilerplate-prompt.md`](../../boilerplate-prompt.md) as your first message |

Same idea, same payoff, everywhere. That's why this is worth an hour.

**▶ Next: [Two ways to get the same lift](#two-ways-to-get-the-same-lift)**

---

## Two ways to get the same lift

Both routes end at the same place; pick by which tool you're using today:

- **Route A — an instruction file.** Continue.dev on this VM reads
  `.continue/rules/*.md` automatically on every prompt. This is the route the
  exercise uses.
- **Route B — the boilerplate prompt**, for a tool you brought your own account
  to (ChatGPT, Claude in the browser, Copilot, ...). Same content, delivered by
  hand: paste [`boilerplate-prompt.md`](../../boilerplate-prompt.md) as your
  first message, or into the tool's project instructions to turn it into
  Route A.

Either way, the target is the same: code that looks like
[`examples/well-behaved-command.lsp`](examples/well-behaved-command.lsp) —
`*error*` handler, system variables restored on both exit paths, validated
input, a remembered default. Open it now and skim the header; that's the
standard your rules push every answer toward.

**▶ Next: [You've already been using it](#youve-already-been-using-it)**

---

## You've already been using it

Open `C:\LabWork\.continue\rules\` in the VS Code Explorer. There are six files
in there and they were loaded into every answer you got today:

| File | What it makes the assistant do |
| --- | --- |
| `01-environment-and-tooling.md` | Assume AutoCAD 2026 English, not some other version |
| `02-saving-your-work.md` | Work in small testable steps, and point you at File → Save and the Timeline rather than anything complicated |
| `03-file-and-naming-conventions.md` | Split routines into small files instead of one big one |
| `04-context-and-token-economy.md` | Keep answers small enough for a local model to get right |
| `05-autolisp-safety-practices.md` | Add `*error*` handlers and restore system variables by default |
| `06-prompting-habits.md` | Ask you for the exact error text instead of guessing |

Read `05-autolisp-safety-practices.md` now — it's 30 lines. Notice that it
never says "write good code". It says specific, checkable things. **That's the
difference between an instruction file that works and one that doesn't.**

**▶ Next: [Now prove it to yourself](#now-prove-it-to-yourself)**

---

## Now prove it to yourself

Go do **[the exercise](exercise.md)**. About 35 minutes. It ends with the same
prompt producing two visibly different files, side by side on your screen,
because of one rule you wrote in between.

Don't skip it and just read. Seeing the difference is the part that convinces
people — including the colleagues you'll try to explain this to next week.

**▶ Next: [What makes a rule work](#what-makes-a-rule-work)**

---

## What makes a rule work

From the six above, and from what fails in practice:

**Be specific and checkable.** "Always name layers with a `PRJ-` prefix"
works.
"Follow our CAD standards" does nothing — the model has never seen your
standards.

**Say what to do, not what to avoid.** "Use `getreal` with a default value for
numeric input" beats "don't hard-code numbers".

**One concern per file.** Six short files beat one long one: you can read them,
change one without disturbing the others, and see at a glance which one
changed.

**Write down the corrections you keep repeating.** If you've told the assistant
three times this week that your text height is always 2.5, that's a rule. The
third correction is the signal.

**Keep them short.** These get sent with every single prompt. On a local model,
a bloated instruction file makes everything slower *and* worse.

### The other half: keeping context small

Instruction files raise the floor. This raises the ceiling, and it matters more
here than with a cloud model:

- **One request per message.** "Draw a circle at the pick point" first, then
  "now ask for a radius". Not both.
- **Short files.** A few dozen lines. If the assistant has to read 300 lines to
  answer, the answer gets worse.
- **Never paste raw data.** "A polyline with about 40 vertices" beats pasting
  40 coordinate pairs.
- **Start a fresh chat when a conversation drifts.** The **+** at the top of the
  panel. A long meandering history makes a small model worse, not better.

**▶ Next: [Take it home](#take-it-home)**

---

## Take it home

The rules in `C:\LabWork\.continue\rules\` are yours. Copy the folder, or copy
the text into whichever tool your company actually lets you use. Nothing in
them is specific to this VM except the "local model, be brief" advice in
`04-context-and-token-economy.md`.

Want to go further — your own company's standards, and getting colleagues onto
the same setup? That's [Track 3](../3-teach-and-scale/README.md).

---

← [Start here](../../START-HERE.md) · [The exercise](exercise.md) ·
[When it goes wrong](../../how-to/when-it-goes-wrong.md)
