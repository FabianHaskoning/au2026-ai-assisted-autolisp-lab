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

The core of this repo is a **generic scaffold**, not a fixed curriculum:
governance instructions for the local model, an idempotent provisioning
script, a hardware diagnostics script, a minimal structural template, and
facilitator docs. How the beginner/experienced audience split gets handled
live is the presenter's call, decided separately. [`examples/`](examples/)
is the one exception — real worked-example AutoLISP content, contributed
separately, not part of the generic scaffold itself.

## Folder map

| Folder | Purpose |
| --- | --- |
| [`reference/`](reference/) | Copy of the submitted session abstract PDF. |
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
- Understanding what the local model has been told: [`continue-config/rules/`](continue-config/rules/) and, for the optional CLI path, [`claude-code-config/`](claude-code-config/).
- Running the session: [`facilitator/README.md`](facilitator/README.md).
- Taking it home, or bringing your own AI account (Claude/ChatGPT/Gemini/Kimi/Copilot): [`take-home/README.md`](take-home/README.md).
