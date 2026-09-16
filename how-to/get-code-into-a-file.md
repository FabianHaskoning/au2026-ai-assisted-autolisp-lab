# How to get the code from the chat into a file

Every answer the assistant gives you crosses the same bridge: copy from the
chat, paste into a file, save. Three small traps live on that bridge, and
between them they cause more "it didn't work" than anything else today.

## Copy from the chat

Use the **copy button** on the code block — hover over the block and it
appears near the top corner. Every assistant has one, and it copies exactly
the code and nothing else.

**Selecting by hand instead?** Don't include the fence lines — the line of
three backticks (` ``` `) above the code and the matching one below it. Those
are chat formatting, not AutoLISP.

**Pasted them anyway?** If the first line of your file is three backticks,
delete that line and the matching one at the bottom. AutoCAD will refuse the
whole file otherwise.

## Paste into the ready-made file

Your files already exist — you never create or name one today. Open the one
the track points you at (for Track 1 that's
`my-work\routine-1\routine-1-core.lsp`), click in it, select everything
(`Ctrl+A`) if you're replacing, and paste (`Ctrl+V`).

## The dot means unsaved

Look at the file's tab. **A dot next to the name means the change is not on
disk yet.** AutoCAD loads what's on disk, not what's on your screen — so an
unsaved paste behaves exactly like no paste at all.

**File → Save** *(`Ctrl+S`)*. The dot turns into an ×. Do this before every
`APPLOAD`, every time.

## The name must end in `.lsp`

`APPLOAD` can only see files whose name ends in `.lsp`. A file without that
ending won't appear in its dialog at all — it looks like your work vanished,
but it's only invisible to AutoCAD.

You won't hit this while you paste into the ready-made files — their names
are already right. It bites when a file gets created or renamed by hand:

- **Making a new file?** Type the full name **including `.lsp`** — for
  example `my-tool.lsp`, not `my-tool`.
- **Used File → Save As and ended up without it?** In the VS Code Explorer,
  right-click the file → **Rename…** → type the full name ending in `.lsp`.

## Skip Save As altogether

**File → Save As** from an untitled tab is where both traps live: it's easy
to land in the wrong folder and easy to lose the `.lsp` ending. Today you
never need it — open the ready-made file and paste into it instead.

---

← [Start here](../START-HERE.md) · [Get a routine into AutoCAD](load-a-routine.md)
