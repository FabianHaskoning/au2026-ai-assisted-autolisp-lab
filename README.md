# AU LAB-session — staging repo

Staging repo for the 90-minute hands-on LAB session at Autodesk University
(Las Vegas, Wednesday September 16, 2026): *"AI-Assisted AutoLISP in AutoCAD:
A Practical Workflow for Non-Programmers"*. 60-90 attendees, each on an
individual Skillable-hosted VM (AutoCAD 2026 English + Civil 3D 2026
English), supported by three facilitators.

**This is not the attendee VM itself.** This repo holds the content that
gets cloned onto the real Skillable VM (author access confirmed) and run
from there — see [`facilitator/README.md`](facilitator/README.md) for the
operational checklist.

The repo holds both halves of the session: the **environment** (governance
instructions for the local model, an idempotent provisioning script, hardware
diagnostics, a structural template, facilitator docs) and the **content**
attendees work through ([`attendee/`](attendee/)).

After a 15-minute opening talk the room splits into three self-selected
tracks, all running in parallel with one facilitator each:

| Track | Audience | Expected share |
| --- | --- | --- |
| [1 — First routine](attendee/tracks/1-first-routine/) | Never written AutoLISP, or never used AI to write code | ~50% |
| [2 — Better results](attendee/tracks/2-better-results/) | Has tried it; results are inconsistent | ~35% |
| [3 — Teach and scale](attendee/tracks/3-teach-and-scale/) | Does this regularly; wants to spread it | ~15% |

Attendees install nothing — everything is pre-provisioned, and they start from
a **START HERE** desktop shortcut. [`examples/`](examples/) sits outside the
tracks: real worked-example AutoLISP content (cadastral data processing),
contributed separately.

## Folder map

| Folder | Purpose |
| --- | --- |
| [`attendee/`](attendee/) | What attendees actually read during the session: `START-HERE.md` and the three parallel tracks. Synced onto the VM by provisioning. |
| [`reference/`](reference/) | The submitted session abstract, and the earlier internal workshop handout it grew out of. |
| [`verification/`](verification/) | The feedback loop: a VM self-test whose report is pushed back through git, plus the repo-consistency check CI runs. |
| [`provisioning/`](provisioning/) | PowerShell scripts to check VM hardware/software and provision the environment (Ollama, VS Code, Continue.dev, git, optionally the Claude Code CLI). |
| [`continue-config/`](continue-config/) | The local-model wiring (Continue.dev + Ollama) and the instruction files the model reads on every prompt. |
| [`claude-code-config/`](claude-code-config/) | Optional, advanced path: the real Claude Code CLI wired to a local Ollama model — no Anthropic account needed. |
| [`scaffold/`](scaffold/) | A structural template (no real AutoLISP logic) attendees copy per new routine. |
| [`git-helpers/`](git-helpers/) | PowerShell module + plain git aliases that make branch-per-routine / commit-often nearly automatic. |
| [`examples/`](examples/) | Worked-example AutoLISP routines (Eigendomskaart/cadastral data processing), contributed separately. |
| [`facilitator/`](facilitator/) | Operational guide for the presenter and the two LAB assistants. |
| [`take-home/`](take-home/) | Running this same setup on an attendee's own PC, during the session or afterward. |

## Where to start

- Setting up or re-testing the VM template: [`provisioning/`](provisioning/), starting with `Test-LabVMSpecs.ps1`.
- Confirming a VM (or the whole fleet) is actually ready: [`verification/`](verification/).
- What attendees will read and do: [`attendee/START-HERE.md`](attendee/START-HERE.md).
- Understanding what the local model has been told: [`continue-config/rules/`](continue-config/rules/) and, for the optional CLI path, [`claude-code-config/`](claude-code-config/).
- Running the session: [`facilitator/README.md`](facilitator/README.md).
- Taking it home, or bringing your own AI account (Claude/ChatGPT/Gemini/Kimi/Copilot): [`take-home/README.md`](take-home/README.md).
