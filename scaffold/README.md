# Scaffold

A **template to copy, not a working example.** Every `.lsp` file here
contains only comment scaffolding and placeholder `defun` stubs - no real
functionality. Working examples live under
[`attendee/tracks/*/examples/`](../attendee/) and the full-scale
[`attendee/showcase/roundabout/`](../attendee/showcase/roundabout/), which
follows this same loader-plus-modules pattern; what's here is the
structural convention described in
[`continue-config/rules/03-file-and-naming-conventions.md`](../continue-config/rules/03-file-and-naming-conventions.md),
made concrete enough to copy.

## The convention

| File | Purpose |
| --- | --- |
| `TEMPLATE-loader.lsp` | Loader - the only file you `APPLOAD`. Loads the module files below and reports success/failure. No real logic. |
| `prefix-util.lsp` | Reusable helper functions (calculations, small building blocks). No commands. |
| `prefix-core.lsp` | The routine's main logic, calling helpers from `prefix-util.lsp`. |
| `prefix-command.lsp` | The `(defun c:...)` entry point(s) an attendee actually types, wrapped with an `*error*` handler. |

`prefix` is a placeholder for a short, unique lowercase prefix - all of a
routine's files should share one, so they sort together and are
unambiguous at a glance.

## Using it

**Attendees never copy these files themselves.**
[`provisioning/Provision-LabVM.ps1`](../provisioning/Provision-LabVM.ps1)
expands this template into `C:\LabWork\my-work\routine-1\`, `-2` and `-3`
before the session starts: every file renamed and every occurrence of
`prefix`/`PLACEHOLDER` replaced, so an attendee opens a folder that is already
correct and has nothing to create or name. Existing folders are never
overwritten - after the session starts they hold somebody's work.

The `New-Routine` helper in [`git-helpers/`](../git-helpers/README.md) does the
same expansion plus a git branch and a first commit. It still works, but it is
no longer part of the attendee path - the session is deliberately terminal-free
(see [`attendee/README.md`](../attendee/README.md)).
