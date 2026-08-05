# AU LAB-session — staging repo

Staging repo for the 90-minute hands-on LAB session at Autodesk University
(Las Vegas, Wednesday September 16, 2026): *"AI-Assisted AutoLISP in AutoCAD:
A Practical Workflow for Non-Programmers"*. 60-90 attendees, each on an
individual Skillable-hosted VM (AutoCAD 2026 English + Civil 3D 2026
English), supported by three facilitators.

**This is not the attendee VM itself.** This repo holds the content that
will be transferred to / run on the real Skillable VM once author access to
that lab profile is confirmed. Nothing here has been deployed to the actual
VM yet — see [`facilitator/README.md`](facilitator/README.md) for the
operational checklist once it is.

This repo intentionally does **not** contain fixed exercises or a curriculum.
It's a generic scaffold: governance instructions for the local model, an
idempotent provisioning script, a hardware diagnostics script, a minimal
structural template, and facilitator docs. Curriculum content and how the
beginner/experienced audience split gets handled live are the presenter's
call, decided separately.

## Folder map

| Folder | Purpose |
| --- | --- |
| [`reference/`](reference/) | Copy of the submitted session abstract PDF. |
| [`provisioning/`](provisioning/) | PowerShell scripts to check VM hardware/software and provision the environment (Ollama, VS Code, Continue.dev, git). |
| [`continue-config/`](continue-config/) | The local-model wiring (Continue.dev + Ollama) and the instruction files the model reads on every prompt. |
| [`scaffold/`](scaffold/) | A structural template (no real AutoLISP logic) attendees copy per new routine. |
| [`git-helpers/`](git-helpers/) | PowerShell module + plain git aliases that make branch-per-routine / commit-often nearly automatic. |
| [`facilitator/`](facilitator/) | Operational guide for the presenter and the two LAB assistants. |

## Where to start

- Setting up or re-testing the VM template: [`provisioning/`](provisioning/), starting with `Test-LabVMSpecs.ps1`.
- Understanding what the local model has been told: [`continue-config/rules/`](continue-config/rules/).
- Running the session: [`facilitator/README.md`](facilitator/README.md).
