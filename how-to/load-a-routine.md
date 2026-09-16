# How to get a routine into AutoCAD

This is the loop you'll repeat all session. Learn it once and everything else
today is a variation on it.

## The five steps

1. Switch to **AutoCAD 2026** (it's on the taskbar). Open a **new, blank
   drawing** — never test on real work.
2. Type `APPLOAD` at the command line and press Enter. A file dialog opens.
3. Browse to your file and select it.
4. Click **Load**, then click **Close**.
5. Type the **command name** at the AutoCAD command line and press Enter.

That's it. The routine runs.

## Which file do I load?

**If the folder has a `-loader.lsp` file, load that one.** It's the front
door: it pulls in all the other files for you. Loading one of the other files
on its own usually half-works and then fails confusingly.

If there's only one `.lsp` file, load that.

## After you change the file

Save it in VS Code (**File → Save**), then just run `APPLOAD` again on the
same file. It reloads over the top. You don't need to restart AutoCAD, and you
don't need to close the drawing.

## What the command name is

It's the word after `defun c:` in the code. So a file containing
`(defun c:HELLO ...)` gives you a command called `HELLO`.

Command names aren't case-sensitive, but spelling is.

## When it doesn't work

| What you see | What it means |
| --- | --- |
| **"Unknown command"** | The file didn't load, or you typed the name wrong. Check the spelling, then `APPLOAD` again. |
| **Red error text while loading** | Usually a missing or extra bracket. Copy the **exact** error text and paste it into the assistant. |
| **Nothing visible happens** | Some routines only print a line of text. Look at the command-line area at the bottom of the AutoCAD window. |

More on all of these: [When it goes wrong](when-it-goes-wrong.md).

---

← [Start here](../START-HERE.md) · [How-to cards](../START-HERE.md#how-to-cards)
