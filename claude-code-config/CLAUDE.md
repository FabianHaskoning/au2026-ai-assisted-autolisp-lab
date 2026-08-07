# AutoLISP lab workspace (local Claude Code)

This is the real Claude Code CLI, running on this VM but pointed at a local
Ollama model (`qwen3-coder:30b`) instead of Anthropic's cloud API - see
`claude-code-config/README.md` in the staging repo for how that's wired up.
Start it with `claude-local` (an alias installed by provisioning), not the
bare `claude` command, so the local-model environment variables are set
correctly.

**This is optional, advanced content.** The main 90-minute exercise uses
Continue.dev inside VS Code. This local Claude Code setup is here for
attendees who want to go further, and especially for anyone who wants to
take the exact same pattern - a real coding CLI, a local free model, no
API cost - back to their own company afterward.

## Environment

Target applications: AutoCAD 2026 (English) and Civil 3D 2026 (English).
AutoLISP files are edited here, then loaded into AutoCAD via APPLOAD (or the
Startup Suite for routines that should always be available) - never typed
directly at the AutoCAD command line.

## Performance expectations

`qwen3-coder:30b` doesn't fully fit in this VM's GPU (4GB VRAM vs. the
~23GB a fully GPU-resident run would want), so Ollama splits it between GPU
and CPU. It works, but noticeably slower than cloud Claude Code. Work with
that:

- Ask for one small, concrete change at a time rather than a whole routine
  in one prompt.
- Keep files short - a few dozen lines, not hundreds.
- Never paste large blocks of raw drawing data or coordinate lists - describe
  the shape of the data instead.
- Expect to wait longer per response than you're used to from a cloud
  assistant. That's the real tradeoff of running fully local and free.

## Git workflow

Same repo, same habits as the rest of this lab - branch before starting a
new routine, commit early and often:

- `New-Routine -Name <name>` - creates a branch, copies the scaffold
  template, makes the first commit.
- `save "<message>"` - commits everything changed.
- `undo` - safely uncommits the last save without discarding file changes.

These are already available in this shell (installed by provisioning) - use
them instead of raw git commands, and suggest them proactively if a session
seems to be going off track.

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
