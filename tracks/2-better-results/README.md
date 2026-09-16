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

Every serious assistant has this. Only the delivery changes:

| Tool | Where the standing instructions live |
| --- | --- |
| Any assistant, any chat | Paste [`boilerplate-prompt.md`](../../boilerplate-prompt.md) as your first message — you've been doing this all day |
| ChatGPT | Project instructions |
| Claude (claude.ai) | Project instructions |
| Gemini | Gems (custom instructions) |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Claude Code | `CLAUDE.md` in the project folder |
| Continue.dev | `.continue/rules/*.md` in the workspace |

Same idea, same payoff, everywhere. That's why this is worth an hour.

**▶ Next: [Two ways to get the same lift](#two-ways-to-get-the-same-lift)**

---

## Two ways to get the same lift

Both routes end at the same place:

- **Route A — the boilerplate prompt.** Paste
  [`boilerplate-prompt.md`](../../boilerplate-prompt.md) (plus your own
  additions) as the first message of a chat, or once into your tool's
  project/custom instructions. **This is the route the exercise uses** — it
  works in every browser assistant on this VM.
- **Route B — an instruction file** the tool reads automatically on every
  prompt: `.continue/rules/*.md`, `CLAUDE.md`,
  `.github/copilot-instructions.md`. The stronger form, and what you'll use
  in tools at work — but the tools that read files on this VM may not
  respond, so today you prove the idea with Route A.

Either way, the target is the same: code that looks like
[`examples/well-behaved-command.lsp`](examples/well-behaved-command.lsp) —
`*error*` handler, system variables restored on both exit paths, validated
input, a remembered default. Open it now and skim the header; that's the
standard your rules push every answer toward.

**▶ Next: [You've already been using it](#youve-already-been-using-it)**

---

## You've already been using it

The boilerplate block you've pasted at the start of every chat today **is** a
standing instruction set — delivered by hand. Open
[`boilerplate-prompt.md`](../../boilerplate-prompt.md) and look at its four
sections: Environment, Code conventions, Safety, How we work.

The file-based form looks the same. Open
`C:\LabWork\.continue\rules\05-autolisp-safety-practices.md` in the VS Code
Explorer — 30 lines, one of six rules files a file-reading assistant loads
automatically.

Notice that neither ever says "write good code". They say specific, checkable
things. **That's the difference between standing instructions that work and
ones that don't.**

**▶ Next: [Now prove it to yourself](#now-prove-it-to-yourself)**

---

## Now prove it to yourself

Go do **[the exercise](exercise.md)**. About 35 minutes. It ends with the same
prompt producing two visibly different files, side by side on your screen,
because of the instructions you pasted in between.

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

**Keep them short.** These go along with every single prompt. A bloated
instruction set gets skimmed, not followed.

### The other half: keeping context small

Standing instructions raise the floor. This raises the ceiling:

- **One request per message.** "Draw a circle at the pick point" first, then
  "now ask for a radius". Not both.
- **Short files.** A few dozen lines. If the assistant has to read 300 lines to
  answer, the answer gets worse.
- **Never paste raw data.** "A polyline with about 40 vertices" beats pasting
  40 coordinate pairs.
- **Start a fresh chat when a conversation drifts** — and re-paste the
  boilerplate first. A long meandering history makes any model worse, not
  better.

**▶ Next: [Take it home](#take-it-home)**

---

## Take it home

Paste the boilerplate — plus the rules you wrote in the exercise — into the
project/custom instructions of whichever tool your company actually lets you
use. Done once, it lifts every future answer. The file version is there too:
the rules in `C:\LabWork\.continue\rules\` are yours to copy into a
`CLAUDE.md` or `copilot-instructions.md` at work.

Want to go further — your own company's standards, and running a session
like this for your colleagues? That's
[Track 3](../3-teach-and-scale/README.md).

---

← [Start here](../../START-HERE.md) · [The exercise](exercise.md) ·
[When it goes wrong](../../how-to/when-it-goes-wrong.md)
