# attendee

Everything an attendee reads during the 90-minute session. This is the source
of truth: [`provisioning/Provision-LabVM.ps1`](../provisioning/Provision-LabVM.ps1)
copies `START-HERE.md`, `choose-your-assistant.md`, `boilerplate-prompt.md`,
`tracks/`, `showcase/`, `how-to/` and `optional/` into the workspace
(`C:\LabWork`) and creates a **START HERE** desktop shortcut that opens VS Code
on it. Edit here, re-run provisioning, never edit on the VM.

## The three tracks

The opening talk splits the room; attendees self-select in about a minute via
the three links at the top of `START-HERE.md`. All three run in parallel, one
facilitator each.

| Track | Audience | Expected share | Outcome |
| --- | --- | --- | --- |
| [`1-first-routine/`](tracks/1-first-routine/) | Never written AutoLISP, or never used AI to write code | ~50% | Working examples plus a first own routine, running in AutoCAD |
| [`2-better-results/`](tracks/2-better-results/) | Has tried it; results are inconsistent | ~35% | Measurably better answers (instruction file or boilerplate prompt), proven with a side-by-side compare |
| [`3-teach-and-scale/`](tracks/3-teach-and-scale/) | Does this regularly; wants to spread it | ~15% | Not code: a better way of working, and a plan to run this session internally |

Each track is written to fill about 75 minutes with a step that can be dropped
if the room runs late. Track 1 is the one that must not overrun.

## The supporting folders

| Folder | What it's for |
| --- | --- |
| [`how-to/`](how-to/) | Five short reference cards — open the assistant, load a routine, save and recover, compare two files, when it goes wrong. The tracks link to these instead of repeating them, so each click path is written down exactly once. |
| [`showcase/`](showcase/) | Two complete applications. `roundabout/` runs on the VM; `cadastral-map/` is real production code that deliberately can't. |
| [`optional/`](optional/) | Git, and only git. Nothing in Tracks 1 and 2 links here; Track 3 Part D does, labelled optional. |

## Conventions for editing these files

- **Written for the reader, not the repo.** Second person, short paragraphs,
  every instruction runnable as written on the VM. No repo-internal jargon.
- **No terminal, no PowerShell, no git in Tracks 1 and 2.** Attendees are
  AutoCAD users; both consistently read as intimidating. Everything happens in
  three places: the VS Code editor, the assistant panel, and the AutoCAD
  command line. Git lives in `optional/` and is reachable from exactly two
  places — one line on `START-HERE.md` and Track 3 Part D.
- **Click paths first, shortcuts second.** Never write a keyboard shortcut as
  the only instruction. Write what to click and where it is, then put the
  shortcut in parentheses after it. Nobody can verify a shortcut on the VM
  before the day; a menu path degrades gracefully when a shortcut is rebound
  or an extension moves.
- **Paths are the VM's paths** (`C:\LabWork\...`), not repo-relative ones —
  except in links between these documents, which must stay relative so they
  work both in the repo and in the copied workspace.
- **Every page carries navigation.** A step bar at the top of each track, a
  `▶ Next` line at the end of each step, and a `←` footer with the way back.
  The instructions open as a rendered page on the VM (see the
  `workbench.editorAssociations` block written by provisioning), so links are
  clickable — reading is never the way to find the next thing to do.
- **Every failure mode gets a stated recovery.** Attendees outnumber
  facilitators 25:1; a page that only describes the happy path becomes a raised
  hand.
- **No dependency on which AI backend is configured.** The rules-file lesson in
  Track 2 is deliberately framed as portable (Continue.dev, Claude Code,
  Copilot, ChatGPT) so it survives a change of model or provider.
- **No company names or in-house jargon.** Attendees come from everywhere; an
  abbreviation only your own colleagues recognise reads as a mistake. Use
  neutral placeholders (`PRJ-`, "your company").
- `.lsp` files under `tracks/*/examples/` and `showcase/` must load cleanly in
  AutoCAD 2026 and have balanced parentheses —
  [`verification/Test-RepoConsistency.ps1`](../verification/) checks the
  brackets, but only a real `APPLOAD` proves the rest.
