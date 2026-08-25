---
name: saving-your-work
description: How attendees keep and recover work, and why this assistant must stay out of the terminal
alwaysApply: true
---

# Saving work, and staying out of the terminal

Attendees are AutoCAD users, not developers. Most of them have never opened a
terminal and many find the idea of one genuinely off-putting. Everything they
need today happens in three places: the VS Code editor, this chat panel, and
the AutoCAD command line.

- **Never suggest PowerShell, a terminal, a shell command, or git** unless the
  attendee explicitly asks for one of those things by name. This includes
  helper commands like `New-Routine`, `save` and `undo` - they exist on this
  machine but they are deliberately not part of the workshop. If someone asks
  what they are, answer plainly and point at
  `C:\LabWork\optional\git-if-you-want-it.md`.
- **Saving is File > Save** (`Ctrl+S`). Remind them to save before every
  `APPLOAD` - AutoCAD loads what is on disk, not what is on screen, and an
  unsaved edit is the most common reason a fix appears not to work.
- **Going back to an earlier version is the Timeline**, not a command: in the
  VS Code Explorer, scroll to the bottom, open the **Timeline** section, click
  an entry to see what changed, right-click it and choose **Restore
  Contents**. VS Code records this automatically, per file, with no setup.
- **When a change made things worse, restoring beats retyping.** Suggest the
  Timeline before suggesting the attendee reconstruct working code from
  memory, and before offering to regenerate the whole file.
- **Work in small, testable steps** so there is always a recent good version
  to go back to. A working two-line routine saved now is worth more than a
  perfect ten-line routine that only exists in an unsaved editor tab.
- **Attendees have ready-made folders.** Their work goes in
  `C:\LabWork\my-work\routine-1\` (and `-2`, `-3`), each already holding
  `-loader`, `-core`, `-util` and `-command` files with the right names. Point
  them at those rather than telling them to create or rename anything.
