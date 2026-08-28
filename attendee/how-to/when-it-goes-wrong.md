# When it goes wrong

Everything on this page is normal and expected. None of it means you did
something stupid, and none of it will break the machine.

**Three facilitators are in the room. Raise your hand the moment you're
stuck** — don't sit quietly for ten minutes. That's ten minutes of your
session.

## AutoCAD says "Unknown command"

The file didn't load, or the name is misspelled.

- Check the spelling. Command names aren't case-sensitive, but spelling is.
- Load it again: [How to get a routine into AutoCAD](load-a-routine.md).
- If the folder has a `-loader.lsp` file, make sure that's the one you loaded.

## AutoCAD shows red error text when loading

Almost always a missing or extra bracket. This is the most common thing that
will happen to you today, and it has a reliable fix:

1. Select the **exact** error text on the AutoCAD command line — all of it,
   including the bit that looks like nonsense — and copy it.
2. Paste it into the assistant with one sentence in front:
   `I got this error when loading the file:`
3. Apply the fix and load it again.

**Paste the error, not your description of it.** AutoCAD's messages are
specific enough to diagnose directly; a paraphrase usually isn't. Two or three
rounds of this is completely normal — it's the single most useful habit you'll
take home today.

## The routine ran but nothing happened

Look at the command-line area at the bottom of the AutoCAD window. A lot of
routines only print a line of text there. That still counts as working.

## The assistant is slow, or the answers get worse

Long chats and big requests do that to every assistant. Make it easier on
itself:

- One request per message. Not "draw a circle and ask for a radius and put it
  on a layer" — one of those, then the next.
- Short files. If it has to read 300 lines to answer, the answer gets worse.
- Never paste raw data. "A polyline with about 40 vertices" beats 40 pairs of
  coordinates.
- Start a fresh chat when the conversation drifts — **New chat**, then paste
  the [boilerplate](../boilerplate-prompt.md) again first.

**Not answering at all?** If it's a browser assistant, check the tab is still
signed in — or open a different assistant from the desktop folder and carry
on there. Your code is in your files, not in the chat.

## The answer is confidently wrong

It will happen. The model will invent a function, or assume a different
AutoCAD version, or describe a menu that isn't there. That isn't the setup
being broken — it's the reason today is about *checking* what you get, not
just asking for it.

Tell it what's actually on your screen and carry on. Everything here is
AutoCAD and Civil 3D **2026, English**.

## I changed something and now it's worse

Don't retype anything. Go back to the last version that worked:
[Save your work → Get an earlier version back](save-your-work.md).

## Something else

**Raise your hand.**

---

← [Start here](../START-HERE.md) · [How-to cards](../START-HERE.md#how-to-cards)
