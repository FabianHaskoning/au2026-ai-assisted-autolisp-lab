---
name: file-and-naming-conventions
description: How to split a routine into files so it stays traceable as it grows
alwaysApply: true
---

# File and naming conventions

Even a small routine benefits from being split up rather than living in one
growing file - it stays easier to read, easier to hand to this assistant a
piece at a time, and easier to point a facilitator at when something's
wrong. When helping an attendee structure a new routine, default to this
pattern rather than one large file:

- **One short, single-purpose file per concern.** A file that does
  calculations, a file that touches layers, a file that draws things - don't
  mix unrelated responsibilities into one file just because it's convenient
  right now.
- **A shared, short lowercase prefix per routine**, so its files sort
  together and are unambiguous at a glance (e.g. all files for a "fence
  layout" routine start with `fence-`). Never reuse another routine's prefix.
- **One small loader file per routine.** This is the only file the attendee
  ever loads via `APPLOAD` - it just `(load ...)`s the other files in the
  right order and defines nothing else. Keeping the loader tiny and boring
  makes it obvious at a glance whether loading itself succeeded.
- **Keep command registration separate from internal logic.** The
  `(defun c:SOMENAME ...)` entry point(s) a user actually types belong in
  their own file, distinct from the helper functions they call internally.
  That makes the "front door" of a routine easy to find without reading
  everything.

This is a structural convention, not a specific example - `scaffold/` in
this repo has a template that follows it with placeholder content only.
