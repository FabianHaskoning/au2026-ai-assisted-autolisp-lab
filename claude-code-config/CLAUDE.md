# AutoLISP lab workspace (local Claude Code)

This is the real Claude Code CLI, running on this VM but pointed at a local
Ollama model by default instead of Anthropic's cloud API - see
`claude-code-config/README.md` in the staging repo for how that's wired up.
Start it with `claude-local` (an alias installed by provisioning), not the
bare `claude` command, so the local-model environment variables are set
correctly. `fast-model` (default) and `quality-model` switch between a
small, fast model and a bigger, slower one; `cloud-mode`/`local-mode`
switch between this local setup and a real Anthropic account, for anyone
who has or wants one.

**This is optional, advanced content.** The main 90-minute exercise runs in
a browser assistant (the desktop's **AI Assistants** folder - see
`C:\LabWork\choose-your-assistant.md`). This local Claude Code setup is here
for attendees who want to go further, and especially for anyone who wants to
take the exact same pattern - a real coding CLI, a local free model, no
API cost - back to their own company afterward.

## Environment

Target applications: AutoCAD 2026 (English) and Civil 3D 2026 (English).
AutoLISP files are edited here, then loaded into AutoCAD via APPLOAD (or the
Startup Suite for routines that should always be available) - never typed
directly at the AutoCAD command line.

## Performance expectations

The fast default model fits fully in this VM's GPU and responds reasonably
quickly. The optional `quality-model` doesn't fully fit in a small GPU's
VRAM, so Ollama splits it between GPU and CPU - noticeably slower. Either
way, this is a local model, not a cloud one. Work with that:

- Ask for one small, concrete change at a time rather than a whole routine
  in one prompt.
- Keep files short - a few dozen lines, not hundreds.
- Never paste large blocks of raw drawing data or coordinate lists - describe
  the shape of the data instead.
- Expect to wait longer per response than you're used to from a cloud
  assistant. That's the real tradeoff of running fully local and free.

## Saving work, and staying out of the terminal

Attendees are AutoCAD users, not developers, and the workshop is deliberately
terminal-free. Never suggest PowerShell, a shell command or git unless the
person explicitly asks for one by name.

- Saving is **File > Save** in VS Code. Remind them to save before every
  `APPLOAD` - AutoCAD loads what is on disk, not what is on screen.
- Going back to an earlier version is the VS Code **Timeline**: Explorer panel,
  scroll to the bottom, open **Timeline**, right-click an entry, **Restore
  Contents**. Suggest that before suggesting anyone retypes working code.
- Their work lives in `C:\LabWork\my-work\routine-1\` (and `-2`, `-3`), which
  already contain correctly named `-loader`, `-core`, `-util` and `-command`
  files. Nothing needs creating or renaming.
- Git helper commands (`New-Routine`, `save`, `undo`) do exist on this machine
  but are not part of the workshop. If asked, answer plainly and point at
  `C:\LabWork\optional\git-if-you-want-it.md`.

## File and naming conventions

One short, single-purpose `.lsp` file per concern. A shared lowercase prefix
per routine so its files sort together. One small loader file per routine -
the only file ever loaded via `APPLOAD` - that just loads the other files
and defines nothing else. Command registration (`(defun c:...)` entry
points) kept separate from internal helper logic.

## AutoLISP safety practices

- Give every routine that can fail partway through an `*error*` handler.
- Restore any system variable a routine changes - save the original value
  before changing it, restore it on both the normal exit path and the error
  path.
- Suggest testing on a scratch or copy drawing first.
- Anything destructive or hard to undo (deleting entities, purging,
  batch-modifying many objects) should ask for confirmation first, or report
  what it would do before doing it.

## Prompting habits

Describe the desired outcome in AutoCAD terms ("select two points and draw
a circle between them," not "write a function"). When something doesn't
work, ask for the exact AutoCAD command-line error text. After generating
code, offer to explain it in plain language before it gets loaded into
AutoCAD - both a learning aid and a lightweight review step.
