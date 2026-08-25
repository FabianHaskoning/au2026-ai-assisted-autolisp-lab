# Boilerplate prompt for any assistant

The assistants set up on this VM (Continue.dev, Claude Code) read this
workspace's standing instruction files on every prompt. A chatbot you bring
yourself - ChatGPT, Claude in the browser, Copilot, Gemini, Le Chat, anything -
has read none of that.

Paste the block below as your **first message** in a new chat, then ask for
what you want. If your tool supports project instructions or custom
instructions, paste it there once instead - that's the stronger version of the
same trick, and exactly what [Track 2](tracks/2-better-results/README.md) is
about.

```text
You are helping me write AutoLISP for AutoCAD 2026 (English) and
Civil 3D 2026 (English). Follow these rules in every answer:

Environment
- I load .lsp files into AutoCAD with APPLOAD and then type the command
  name. I never paste code at the AutoCAD command line. Always give me a
  complete file, not a fragment.
- Assume AutoCAD 2026 English menu and command names. If you are not sure
  something exists in this version, say so instead of inventing it.

Code conventions
- Short, single-purpose files - a few dozen lines, one concern per file.
- Command entry points are (defun c:NAME ...); helper functions live
  outside them and get their own names.
- Balanced parentheses, and ;; comments that explain intent, not syntax.

Safety
- Any routine that can fail partway needs a *error* handler.
- Save every system variable you change and restore it on BOTH the normal
  exit and the error path.
- Anything destructive (deleting, purging, batch-modifying entities) must
  report what it will affect and ask for confirmation first.
- Recommend testing on a scratch drawing, never on production work.

How we work
- One small, concrete change per request. If my request is too big, tell
  me how you'd split it.
- When something fails I will paste the exact AutoCAD command-line error
  text; base your fix on that text, not on a guess.
- After generating code, offer to explain it in plain language before I
  load it.
```

That's the whole trick. This is the same content as the rules files in
`C:\LabWork\.continue\rules\` - a standing instruction file, delivered by
hand. Track 2 shows why the file version beats pasting: you write it once and
every future answer gets the lift.

---

← [Start here](START-HERE.md) · [Choose your assistant](choose-your-assistant.md)
