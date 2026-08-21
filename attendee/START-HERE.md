# Start here

> Press **`Ctrl+Shift+V`** in VS Code for the readable version of this page.

Welcome. **Nothing needs installing.** AutoCAD 2026, Civil 3D 2026, VS Code,
git and your AI assistant are already set up and running on this machine. You
can start right now.

After the opening talk you have about **75 minutes** of hands-on time. Three
facilitators are in the room - **raise your hand** the moment you're stuck.
Don't sit quietly for ten minutes; that's ten minutes of your session.

---

## 1. Pick your track (60 seconds)

Answer honestly - the tracks are about where you are today, not how clever you
are. You can switch later.

| If this is you | Go to | What you'll leave with |
| --- | --- | --- |
| **I have never written a line of AutoLISP**, or never used an AI assistant to write code | [Track 1 - First routine](tracks/1-first-routine/README.md) | Working examples and your first own routine, running in AutoCAD **today**. That's the whole win - celebrate it |
| **I've tried this before.** I've got AI to produce AutoLISP, but the results are hit-and-miss | [Track 2 - Better results](tracks/2-better-results/README.md) | Measurably better answers - via an instruction file or one boilerplate prompt - and working code that proves it |
| **I do this regularly** and I want to bring it back to my team | [Track 3 - Teach and scale](tracks/3-teach-and-scale/README.md) | Not code - a better, easier way of working, and what it takes to run a session like this at your own company |

Roughly half the room will be on Track 1. If you're torn between two, take the
lower one and move up when it feels easy.

---

## 2. How you'll work

**Your work lives in `C:\LabWork`.** VS Code is already open there. Everything
you make today goes in that folder.

**You can just chat.** Press **`Ctrl+L`** and the AI assistant (Continue.dev)
opens in VS Code. Talk to it in plain language - there are no special commands
to learn. It runs on this machine: no account, no API key, no cost. It is also
**slower and smaller than ChatGPT or Claude**, so ask for one small, concrete
thing at a time rather than a whole finished tool in one go. That trade is
deliberate: it's the setup you could take back to your own company for free.

**It's not the only assistant here.** This VM also has Claude Code on the same
local model, desktop apps for ChatGPT and Claude, and an **AI Assistants**
folder on the desktop linking every major chatbot - if you have your own
account, you can use it. See
[`choose-your-assistant.md`](choose-your-assistant.md) for the map, including
the copy-paste prompt that gives any outside tool the same house rules.

**Getting a routine into AutoCAD** - this is the loop you'll repeat all
session:

1. In AutoCAD, type `APPLOAD` and press Enter.
2. Browse to your file in `C:\LabWork\<your-routine>\`.
3. Select the **loader** file (`<name>-loader.lsp`) and click **Load**.
4. Click **Close**.
5. Type your command name at the AutoCAD command line and press Enter.

Changed the file? Just `APPLOAD` it again - it reloads over the top.

**Optional safety net - three commands, in any PowerShell window:**

| Command | What it does |
| --- | --- |
| `New-Routine <name>` | Starts a new routine: makes a git branch, creates the files, commits |
| `save "what changed"` | Saves your progress (a git commit) |
| `undo` | Undoes the last `save`. **Never** loses your file changes |

You can do the whole session without these - they're not a prerequisite for
chatting or for AutoCAD. They exist so nothing you make can ever be lost. Use
`save` far more often than feels necessary: it costs two seconds and it is the
reason nothing you do today can go badly wrong.

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
- **Claude Code shows an Anthropic sign-in screen** - it lost its local-model
  settings. In a new PowerShell window run `local-mode`, then reload VS Code
  (`Ctrl+Shift+P` → **Developer: Reload Window**). Only applies on VMs that
  have Claude Code; Continue.dev (`Ctrl+L`) is never affected.

Anything else: **raise your hand.**

---

## 4. If you only remember one thing

Each track has its own version of it:

- **Track 1:** you got working code out of an AI and into AutoCAD *today*,
  with your own hands. That's the whole point - everything else is polish.
- **Track 2:** one instruction file (or one boilerplate prompt) lifts *every*
  answer an assistant will ever give you. Write it once, benefit forever.
- **Track 3:** the code was never the hard part. What you're taking home is a
  way of working - and everything you need to run this session yourself.

And for everyone: you can now *check* what the AI wrote, *save* it before you
break it, and *get back* to the last version that worked. That's what turns a
clever demo into something you can actually use at work on Monday.
