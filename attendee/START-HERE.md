# Start here

> Press **`Ctrl+Shift+V`** in VS Code for the readable version of this page.

Welcome. **Nothing needs installing.** AutoCAD 2026, Civil 3D 2026, VS Code,
git and your AI assistant are already set up and running on this machine. You
can start right now.

You have about **60 minutes** of hands-on time. Three facilitators are in the
room - **raise your hand** the moment you're stuck. Don't sit quietly for ten
minutes; that's ten minutes of your hour.

---

## 1. Pick your track (60 seconds)

Answer honestly - the tracks are about where you are today, not how clever you
are. You can switch later.

| If this is you | Go to | What you'll leave with |
| --- | --- | --- |
| **I have never written a line of AutoLISP**, or never used an AI assistant to write code | [Track 1 - First routine](tracks/1-first-routine/README.md) | A routine you wrote, running in AutoCAD |
| **I've tried this before.** I've got AI to produce AutoLISP, but the results are hit-and-miss | [Track 2 - Better results](tracks/2-better-results/README.md) | The instruction-file trick that lifts every answer you'll ever get |
| **I do this regularly** and I want to bring it back to my team | [Track 3 - Teach and scale](tracks/3-teach-and-scale/README.md) | A workflow two people can share, and what it takes to run this session yourself |

Roughly half the room will be on Track 1. If you're torn between two, take the
lower one and move up when it feels easy.

---

## 2. The four things you need to know

**Your work lives in `C:\LabWork`.** VS Code is already open there. Everything
you make today goes in that folder.

**`Ctrl+L` opens the AI assistant** (Continue.dev) in VS Code. It runs on this
machine - no account, no API key, no cost. It is also **slower and smaller than
ChatGPT or Claude**, so ask for one small, concrete thing at a time rather than
a whole finished tool in one go. That trade is deliberate: it's the setup you
could take back to your own company for free.

**Three commands, in any PowerShell window:**

| Command | What it does |
| --- | --- |
| `New-Routine <name>` | Starts a new routine: makes a git branch, creates the files, commits |
| `save "what changed"` | Saves your progress (a git commit) |
| `undo` | Undoes the last `save`. **Never** loses your file changes |

Use `save` far more often than feels necessary. It costs two seconds and it is
the reason nothing you do today can go badly wrong.

**Getting a routine into AutoCAD** - this is the loop you'll repeat all
session:

1. In AutoCAD, type `APPLOAD` and press Enter.
2. Browse to your file in `C:\LabWork\<your-routine>\`.
3. Select the **loader** file (`<name>-loader.lsp`) and click **Load**.
4. Click **Close**.
5. Type your command name at the AutoCAD command line and press Enter.

Changed the file? Just `APPLOAD` it again - it reloads over the top.

---

## 3. When something goes wrong

Most problems today are one of these:

- **"Unknown command"** - the file didn't load, or you typed the name wrong.
  Command names are case-insensitive but spelling isn't. Re-run `APPLOAD`.
- **AutoCAD complains when loading** - almost always unbalanced brackets.
  Copy the **exact** red error text from the AutoCAD command line and paste it
  into the assistant. It's usually specific enough to fix in one round.
- **The assistant is slow** - expected. It's a local model. Shorter prompt,
  shorter file, one request at a time.
- **`New-Routine` / `save` / `undo` not recognised** - your PowerShell window
  was open before setup finished. Close it and open a new one.

Anything else: **raise your hand.**

---

## 4. If you only remember one thing

The point of today is not that AI writes AutoLISP. It's that you can now
*check* what it wrote, *save* it before you break it, and *get back* to the
last version that worked. That's what turns a clever demo into something you
can actually use at work on Monday.
