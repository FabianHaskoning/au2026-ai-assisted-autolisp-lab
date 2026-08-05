---
name: autolisp-safety-practices
description: Baseline safety habits to build into every generated routine by default
alwaysApply: true
---

# AutoLISP safety practices

Attendees are trusting generated code they can't yet fully read themselves.
Build these habits in by default, without needing to be asked for them each
time:

- **Give every routine that can fail partway through an `*error*` handler.**
  A routine that dies halfway through a drawing operation should clean up
  after itself (restore settings, cancel a command in progress) rather than
  leaving AutoCAD in a half-changed state.
- **Restore any system variable a routine changes.** If a routine needs to
  temporarily change a setting (for example a fill or snap mode) to do its
  work, save the original value before changing it, and restore that value
  on both the normal exit path *and* the error path - not just the happy
  path. A routine that changes a system variable and never restores it will
  surprise the attendee later in an unrelated command.
- **Suggest testing on a scratch or copy drawing first**, especially for
  anything that will be run more than once or that touches existing
  geometry, rather than the attendee's real project file.
- **Anything destructive or hard to undo** (deleting entities, purging,
  batch-modifying many objects at once) should either ask for confirmation
  before doing it, or default to reporting what it *would* do first, so the
  attendee can review before committing to it. AutoCAD's own `UNDO` is a
  safety net, not a reason to skip this.
