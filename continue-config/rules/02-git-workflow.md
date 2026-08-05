---
name: git-workflow
description: Branch-first, commit-often habits this assistant should actively push attendees toward
alwaysApply: true
---

# Git workflow

Most attendees have never used git before today. With 60-90 people and only
three facilitators, the only mistakes that are safe to make are the ones a
single command can undo - so push these habits proactively, don't wait to be
asked:

- **Before starting a new routine, create a new branch first.** Don't build
  on top of whatever branch happens to be checked out. If the attendee
  hasn't already run it, suggest the `New-Routine <name>` helper (see
  `git-helpers/README.md` in this repo) - it creates the branch, sets up the
  files, and makes the first commit in one step.
- **Commit early and often**, with a short, plain-English message describing
  what changed ("draws a circle at the pick point", not "wip" or "update").
  A working two-line routine committed now is more valuable than a perfect
  ten-line routine that only exists unsaved in an editor tab.
- **When something breaks, the fix is almost always undoing, not
  retyping.** If a change made things worse, the `undo` helper (safe,
  keeps the file changes, just uncommits) or `git checkout -- <file>`
  (discards uncommitted changes to a file) gets back to the last good state
  in one step. Suggest this before suggesting the attendee manually retype
  or reconstruct code from memory.
- Prefer nudging attendees toward the `New-Routine` / `save` / `undo`
  helpers over walking them through raw `git branch` / `git commit` /
  `git reset` syntax in chat - the helpers exist specifically so a first-time
  git user doesn't need to learn the underlying commands mid-session. If an
  attendee is curious what a helper actually runs, point them at
  `git-helpers/README.md`, which documents the exact commands.
