# Git, if you want it

> **You don't need any of this today.** Everything in Tracks 1 and 2 works
> without it. Saving is **File → Save**, and going back to an earlier version
> is the **Timeline** — see
> [Save your work](../how-to/save-your-work.md). This page is here for people
> who are curious, or who already know what git is and wondered where it went.

## What's quietly running underneath

`C:\LabWork` is a git repository. It was set up before you arrived and it makes
no demands on you — you can ignore it completely and nothing will break.

Three helper commands are installed on this machine, available in any
PowerShell window. **None of the tracks use them.**

| Command | What it actually runs |
| --- | --- |
| `New-Routine -Name <name>` | `git checkout -b <name>`, copies a four-file template into `<name>\`, then `git add -A` + `git commit -m "Start routine: <name>"` |
| `save "<message>"` | `git add -A` + `git commit -m "<message>"` |
| `undo` | `git reset --soft HEAD~1` — **never** discards file changes, only uncommits them |

Nothing here is a black box. That's the whole list.

### Why `--soft` and not `--hard`

`undo` is deliberately non-destructive: it removes the last commit but leaves
your file changes exactly as they were, so you can't lose work by running it.
Actually discarding uncommitted changes is a separate, more dangerous step
(`git checkout -- <file>` or `git reset --hard`) — not something either helper
does for you silently.

## Why this isn't in the tracks

Because "learn version control" and "get an AI to write AutoLISP" are two
different lessons, and only one of them fits in 75 minutes. VS Code's Timeline
gives you the part that actually matters on the day — *get me back to the
version that worked* — with nothing to learn and nothing to type.

Git is the right answer once more than one person is involved. That's exactly
where [`pair-workflow.md`](pair-workflow.md) picks it up.

## Taking the same workflow home

You don't need these helpers or PowerShell to get this on your own machine —
two lines, any terminal, any git host:

```bash
git config --global alias.save '!git add -A && git commit -m'
git config --global alias.undo 'reset --soft HEAD~1'
```

That gives you `git save "message"` and `git undo` everywhere, with any AI tool
and any git hosting. Nothing about it is specific to this lab.

## Where to go next

- [Push today's work to your own GitHub](your-own-remote.md) — three commands
  and a token, entirely optional.
- [Two people, one routine](pair-workflow.md) — branch, review, merge, resolve
  a conflict. This is Track 3 Part D.

---

← [Start here](../START-HERE.md)
