# git-helpers

Makes real git discipline (branch before you start, commit early and often)
close to automatic for 60-90 people who mostly have never used git before,
supported by just three facilitators. Nothing here is a black box - every
command below is documented so an attendee (especially the experienced
sub-audience) can see exactly what runs.

## What gets installed on the VM

`Provision-LabVM.ps1` installs `LabGitHelpers.psm1` into the PowerShell
module path and imports it from `$PROFILE`, so these are available in any
new PowerShell window without attendees doing anything:

| Command | What it actually runs |
| --- | --- |
| `New-Routine -Name <name>` | `git checkout -b <name>`, copies+renames the `scaffold/` template into `<name>\`, then `git add -A` + `git commit -m "Start routine: <name>"`. |
| `save "<message>"` (alias for `Save-Progress`) | `git add -A` + `git commit -m "<message>"`. |
| `undo` (alias for `Undo-LastCommit`) | `git reset --soft HEAD~1` - **never** discards file changes, only uncommits them. |

## Taking it home

You don't need `LabGitHelpers.psm1` or PowerShell to get the same workflow
on your own machine or company git server - just these three lines, which
`git-aliases.ps1` installs (or run them yourself, any terminal):

```bash
git config --global alias.save '!git add -A && git commit -m'
git config --global alias.undo 'reset --soft HEAD~1'
```

That gives you `git save "message"` and `git undo` everywhere, with any
LLM and any git hosting - nothing about it is specific to this lab
environment.

## Why `--soft HEAD~1` and not `--hard`

`undo` is deliberately non-destructive: it removes the last commit but
leaves your file changes exactly as they were, so a beginner can never lose
work by running it. If you actually want to discard uncommitted file
changes too, that's a separate, more dangerous step (`git checkout -- <file>`
or `git reset --hard`) - not something either helper does for you silently.
