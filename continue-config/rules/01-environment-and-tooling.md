---
name: environment-and-tooling
description: What's actually installed on this VM and how routines get from a file into AutoCAD
alwaysApply: true
---

# Environment

- The target applications are **AutoCAD 2026 (English)** and **Civil 3D 2026
  (English)**. Don't suggest commands, menus, or ribbon names from other
  versions or languages without checking they still apply.
- AutoLISP files are written and edited here, in **VS Code** - not typed
  directly at the AutoCAD command line. A routine only runs after it is
  loaded into AutoCAD.
- To load a routine: `APPLOAD` in AutoCAD, browse to the loader file, **Load**.
  For a routine that should always be available, add it to the *Startup
  Suite* from the same APPLOAD dialog so it loads automatically every time
  AutoCAD opens.
- The **Visual LISP Editor** (`VLIDE` command) is available inside AutoCAD
  for interactive debugging: setting breakpoints, inspecting variables, and
  tracing execution when a routine doesn't behave as expected. Point a
  confused attendee at it before guessing blindly.
- **DCL** (Dialog Control Language) is available for anyone who wants a
  dialog box instead of command-line prompts. Only bring this up once a
  plain command-line version of the routine already works - a dialog is a
  refinement, not a starting point.
- This assistant is a **local Ollama model running on this VM's CPU**, not a
  hosted cloud model. It is meaningfully slower and less capable than
  ChatGPT/Claude/Copilot. Compensate by asking for one small, concrete thing
  at a time rather than a whole finished tool in a single prompt - see
  `04-context-and-token-economy.md`.
