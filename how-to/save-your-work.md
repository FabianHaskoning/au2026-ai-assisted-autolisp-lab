# How to save your work — and get it back

Two things. Saving is obvious. Getting an earlier version back is the one that
saves your afternoon, and almost nobody knows VS Code does it.

## Save

**File → Save.** *(Shortcut: `Ctrl+S`.)*

A dot on the file's tab means unsaved changes. No dot means it's saved.

Save before every `APPLOAD`. AutoCAD loads what's on disk, not what's on your
screen — an unsaved change is the single most common reason a fix "didn't
work".

Just pasted code from the chat? Two more traps sit on that route — the
code-fence lines and the `.lsp` ending:
[Get the code from the chat into a file](get-code-into-a-file.md).

## Get an earlier version back

VS Code keeps its own history of every file you edit. You don't switch it on
and you don't have to do anything to make it happen.

1. Open the file you want to go back in.
2. In the **Explorer** on the left (the top icon in the far-left strip), scroll
   to the bottom. There's a section called **Timeline** — click it to expand.
3. You'll see a list of earlier versions, newest first, each with a time.
4. **Click one** to see what changed: the old version on the left, yours on the
   right, differences highlighted.
5. Happy with it? **Right-click that entry → Restore Contents.** The file goes
   back to exactly that state.

**Nothing in the Timeline yet?** It fills up as you edit and save. A file you
just created has nothing to go back to.

## So when something breaks

You asked for a change, it made things worse, and you'd like the working
version back:

1. Don't retype anything.
2. Timeline → find the entry from before the change → **Restore Contents**.
3. `APPLOAD` again.

That's the whole recovery story. Your work is never lost, and there's nothing
to set up.

## Smaller undo

Just typed something wrong? **Edit → Undo** *(`Ctrl+Z`)*, as many times as you
like. The Timeline is for when undo has gone too far back to be useful.

---

← [Start here](../START-HERE.md) · [How-to cards](../START-HERE.md#how-to-cards)
