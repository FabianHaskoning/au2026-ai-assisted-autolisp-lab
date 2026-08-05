# Scaffold

A **template to copy, not a working example.** Every `.lsp` file here
contains only comment scaffolding and placeholder `defun` stubs - no real
functionality. Exercise content is intentionally out of scope for this repo
(see the top-level [`README.md`](../README.md)); what's here is the
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

Don't copy these files by hand - run the `New-Routine` helper from
[`git-helpers/`](../git-helpers/README.md) instead:

```powershell
New-Routine -Name fence-layout
```

This creates a new git branch, copies this template into
`$WorkspaceRoot\fence-layout\`, renames every file and every occurrence of
`prefix`/`PLACEHOLDER` to `fence-layout`/`FENCE-LAYOUT`, and makes the first
commit - so you start from a clean, already-versioned skeleton instead of a
blank file.
