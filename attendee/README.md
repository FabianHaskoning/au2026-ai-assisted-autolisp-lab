# attendee

Everything an attendee reads during the 90-minute session. This is the source
of truth: [`provisioning/Provision-LabVM.ps1`](../provisioning/Provision-LabVM.ps1)
copies `START-HERE.md`, `choose-your-assistant.md`, `boilerplate-prompt.md`,
`tracks/` and `showcase/` into the workspace (`C:\LabWork`) and creates a
**START HERE** desktop shortcut that opens VS Code on it. Edit here, re-run
provisioning, never edit on the VM.

## The three tracks

The opening talk splits the room; attendees self-select in about a minute via
the table in `START-HERE.md`. All three run in parallel, one facilitator each.

| Track | Audience | Expected share | Outcome |
| --- | --- | --- | --- |
| [`1-first-routine/`](tracks/1-first-routine/) | Never written AutoLISP, or never used AI to write code | ~50% | Working examples plus a first own routine, running in AutoCAD, committed |
| [`2-better-results/`](tracks/2-better-results/) | Has tried it; results are inconsistent | ~35% | Measurably better answers (instruction file or boilerplate prompt), proven with a `git diff` |
| [`3-teach-and-scale/`](tracks/3-teach-and-scale/) | Does this regularly; wants to spread it | ~15% | Not code: a better way of working, and a plan to run this session internally |

Each track is written to fill about 75 minutes with a step that can be dropped
if the room runs late. Track 1 is the one that must not overrun.

## Conventions for editing these files

- **Written for the reader, not the repo.** Second person, short paragraphs,
  every instruction runnable as written on the VM. No repo-internal jargon.
- **Paths are the VM's paths** (`C:\LabWork\...`), not repo-relative ones -
  except in links between these documents, which must stay relative so they
  work both in the repo and in the copied workspace.
- **Every failure mode gets a stated recovery.** Attendees outnumber
  facilitators 25:1; a page that only describes the happy path becomes a raised
  hand.
- **No dependency on which AI backend is configured.** The rules-file lesson in
  Track 2 is deliberately framed as portable (Continue.dev, Claude Code,
  Copilot, ChatGPT) so it survives a change of model or provider.
- `.lsp` files under `tracks/*/examples/` and `showcase/` must load cleanly in
  AutoCAD 2026 and have balanced parentheses -
  [`verification/Test-RepoConsistency.ps1`](../verification/) checks the
  brackets, but only a real `APPLOAD` proves the rest.
