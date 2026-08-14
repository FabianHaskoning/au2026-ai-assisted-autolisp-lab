# Reference documents

Source material this lab is built from. **Neither file is attendee-facing** -
what attendees actually read on the VM lives in [`attendee/`](../attendee/).
Both are kept verbatim as authored (formatting fixed for lint, wording
untouched), so they can be cited as-is.

| File | What it is |
| --- | --- |
| `AI-Assisted-AutoLISP-in-AutoCAD-A-Practical-Workflow-for-Non-Programmers.pdf` | The abstract submitted to Autodesk University 2026. Sets the thesis: empowerment (non-programmers writing useful routines with AI) plus governance (version control, validation, review) as one package. |
| `LISP-Workshop-QuickStart.md` | The handout from the earlier internal Dutch workshop (October 2025, version 2.0) that this AU session grew out of. Dutch, Copilot-based, self-install. |

## What carries over from the QuickStart, and what does not

The QuickStart was written for colleagues on their **own** machines with
**Microsoft Copilot**. The AU lab is the opposite: a disposable, fully
pre-provisioned Skillable VM running a **local Ollama model**. Read it for the
teaching content, not the setup.

**Superseded - do not follow on the lab VM:**

- *Stap 1 (Folder Structuur Opzetten)* - no `setup-lisp-folders.ps1`, no
  execution-policy change, no `Documents\AutoCAD-LISP\` tree. The workspace is
  `C:\LabWork`, created by
  [`provisioning/Provision-LabVM.ps1`](../provisioning/Provision-LabVM.ps1).
- *Stap 1 (Trusted Locations)* and *Stap 2 (Code Editor Kiezen)* - VS Code and
  the AutoLISP extension are already installed and the workspace is already
  trusted. Attendees install nothing.
- *Stap 5 (Microsoft Copilot)* - the assistant on the VM is Continue.dev
  against local Ollama. Copilot has no API Continue.dev can call.
- Version references to AutoCAD 2024/2025 - the VM is AutoCAD 2026 and
  Civil 3D 2026, both English.

**Carried over into the lab, mostly translated to English:**

| From the QuickStart | Where it lives now |
| --- | --- |
| Hello-world routine and the APPLOAD load/run loop | [`attendee/tracks/1-first-routine/`](../attendee/tracks/1-first-routine/) |
| Prompt patterns ("specify the version, ask for error handling, ask for modular code") | [`attendee/tracks/1-first-routine/prompts.md`](../attendee/tracks/1-first-routine/prompts.md) |
| Modular file split (helper / logic / command / loader) | [`scaffold/`](../scaffold/) and [`continue-config/rules/03-file-and-naming-conventions.md`](../continue-config/rules/03-file-and-naming-conventions.md) |
| `*error*` handler template and sysvar restore | [`continue-config/rules/05-autolisp-safety-practices.md`](../continue-config/rules/05-autolisp-safety-practices.md) |
| Project ideas (low-threshold and advanced) | [`attendee/tracks/1-first-routine/prompts.md`](../attendee/tracks/1-first-routine/prompts.md) |
| Troubleshooting symptoms (unknown command, bad argument type, malformed list) | [`facilitator/troubleshooting.md`](../facilitator/troubleshooting.md) |
