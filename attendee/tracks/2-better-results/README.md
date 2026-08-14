# Track 2 - Better results

**For:** you've got an AI assistant to write AutoLISP before. Sometimes it's
great, sometimes it's nonsense, and you can't tell in advance which you'll get.

**You'll leave with:** the single highest-leverage trick there is for fixing
that - and proof, in your own git history, that it works.

**Time:** about 60 minutes.

---

## The thing nobody tells you

You've probably been trying to fix bad output by writing better prompts. That
works, but it only fixes *one answer*, and you have to do it again every time.

There's a second lever: a **standing instruction file** that the assistant
reads on *every* prompt, without you pasting anything. Get that right once and
every answer improves - including the lazy one-line prompts you'll actually
type when you're busy.

Every serious assistant has this. Only the filename changes:

| Tool | Where the standing instructions live |
| --- | --- |
| Continue.dev (on this VM) | `.continue/rules/*.md` in your workspace |
| Claude Code | `CLAUDE.md` in the project folder |
| GitHub Copilot | `.github/copilot-instructions.md` |
| ChatGPT | Project instructions |
| Claude (claude.ai) | Project instructions |

Same idea, same payoff, everywhere. That's why this is worth an hour.

---

## You've already been using it

Open `C:\LabWork\.continue\rules\` in VS Code. There are six files in there and
they were loaded into every answer you got today:

| File | What it makes the assistant do |
| --- | --- |
| `01-environment-and-tooling.md` | Assume AutoCAD 2026 English, not some other version |
| `02-git-workflow.md` | Push you to branch and commit, unprompted |
| `03-file-and-naming-conventions.md` | Split routines into small files instead of one big one |
| `04-context-and-token-economy.md` | Keep answers small enough for a local model to get right |
| `05-autolisp-safety-practices.md` | Add `*error*` handlers and restore system variables by default |
| `06-prompting-habits.md` | Ask you for the exact error text instead of guessing |

Read `05-autolisp-safety-practices.md` now - it's 30 lines. Notice that it
never says "write good code". It says specific, checkable things. **That's the
difference between an instruction file that works and one that doesn't.**

---

## Now prove it to yourself

Go do [`exercise.md`](exercise.md). It takes about 35 minutes and ends with a
`git diff` showing the same prompt producing measurably different code, before
and after you add a rule of your own.

Don't skip it and just read. The diff is the part that convinces people.

---

## What makes a rule work

From the six above, and from what fails in practice:

**Be specific and checkable.** "Always name layers with a `RHDHV-` prefix"
works. "Follow our CAD standards" does nothing - the model has never seen your
standards.

**Say what to do, not what to avoid.** "Use `getreal` with a default value for
numeric input" beats "don't hard-code numbers".

**One concern per file.** Six short files beat one long one: you can read them,
change one without disturbing the others, and see in a diff which one changed.

**Write down the corrections you keep repeating.** If you've told the assistant
three times this week that your text height is always 2.5, that's a rule. The
third correction is the signal.

**Keep them short.** These get sent with every single prompt. On a local model,
a bloated instruction file makes everything slower *and* worse.

---

## The other half: keeping context small

Instruction files raise the floor. This raises the ceiling, and it matters more
here than with a cloud model:

- **One request per message.** "Draw a circle at the pick point" first, then
  "now ask for a radius". Not both.
- **Short files.** A few dozen lines. If the assistant has to read 300 lines to
  answer, the answer gets worse.
- **Never paste raw data.** "A polyline with about 40 vertices" beats pasting
  40 coordinate pairs.
- **Start a fresh chat when a conversation drifts.** A long meandering history
  makes a small model worse, not better. Nothing is lost - your code is in git.

---

## Take it home

The rules in `C:\LabWork\.continue\rules\` are yours. Copy the folder, or copy
the text into whichever tool your company actually lets you use. Nothing in
them is specific to this VM except the "local model, be brief" advice in
`04-context-and-token-economy.md`.

Want to go further - your own company's standards, and getting colleagues onto
the same setup? That's [Track 3](../3-teach-and-scale/README.md).
