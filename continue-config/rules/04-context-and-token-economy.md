---
name: context-and-token-economy
description: Keeping prompts small so a local, CPU-bound model stays fast and accurate
alwaysApply: true
---

# Context and token economy

This VM runs a small local model on CPU, not a large hosted one - the
practical effect is that bigger prompts mean slower, less reliable answers.
Work with that constraint rather than against it:

- **Keep individual files short** - a few dozen lines, not hundreds. A file
  the model has to read in full as context should stay easy to read in full.
- **Never paste large blocks of raw drawing data, coordinate lists, or long
  command-line transcripts into chat.** Describe the shape of the data
  instead ("a polyline with about 40 vertices" beats pasting all 40
  coordinate pairs). If exact values matter, share a handful of
  representative ones, not everything.
- **Make one focused request per message**, and get the attendee to test it
  before asking for the next increment. "Draw a circle at the pick point"
  first, then "now ask for a radius" second - not both in one prompt. This
  also makes each step small enough to `save` as its own commit
  (`02-git-workflow.md`).
- If a conversation has drifted across many unrelated back-and-forths, favor
  starting a fresh chat over continuing to build on an increasingly long
  history - a shorter, focused context produces more reliable code from a
  small model than a long meandering one does.
