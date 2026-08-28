# Prompts you can copy and paste

[Open the assistant](../../how-to/open-the-assistant.md) — boilerplate pasted
first — then paste one of these into the chat box and press Enter.

Every assistant does well with one concrete request at a time and badly with
"build me a tool". Every prompt below is deliberately narrow for that reason.

## How to read this page

Each prompt has **what you should get back** and **what to do if it goes
wrong**. If you get something different from what's described, that's useful
information - not your mistake.

---

## 1. A circle where you click (start here)

```text
Write an AutoLISP routine for AutoCAD 2026.

It should define a command called MYCIRCLE that:
- asks the user to pick one point
- draws a circle with radius 10 at that point
- does nothing at all if the user presses Esc instead of picking

Include an *error* handler. Add short comments explaining each part.
Give me the complete file, ready to save as one .lsp file.
```

**You should get:** roughly 20-30 lines starting with `(defun c:MYCIRCLE`.

**If it goes wrong:** the most common failure is unbalanced brackets. Load it
anyway - AutoCAD will tell you exactly which line, and pasting that error back
usually fixes it in one round.

---

## 2. Ask for a value instead of hard-coding it

Use this **after** prompt 1 works, in the same chat.

```text
Change it so the routine asks the user for the radius instead of always
using 10. If the user just presses Enter, default to 10.
```

**You should get:** the same routine with a `getreal` call added.

**If it goes wrong:** if it rewrites the whole thing and loses your `*error*`
handler, say: `keep the *error* handler you wrote before`.

---

## 3. Count something

```text
Write an AutoLISP routine for AutoCAD 2026 that defines a command
COUNTLINES. It should count how many LINE entities are in the drawing and
print the total to the command line. It must not change the drawing.
Complete file please, with comments.
```

**You should get:** something using `ssget` with a `"_X"` filter.

**If it goes wrong:** if it tries to make the user select objects manually,
say: `search the whole drawing automatically, don't ask the user to select`.

---

## 4. Create layers to a standard

```text
Write an AutoLISP routine for AutoCAD 2026 with a command SETUPLAYERS.

It should create these layers if they don't already exist:
- DRAFT, colour 8
- SKETCH, colour 3
- FINAL, colour 7

It must not fail or overwrite anything if a layer already exists.
Complete file, with an *error* handler and comments.
```

**You should get:** a routine using `(command "._-LAYER" ...)` or `tblsearch`.

**If it goes wrong:** if it errors on the second run, say: `it fails when the
layers already exist - check for each layer first`.

---

## 5. Change existing objects

Run this one on a **scratch drawing** with some text in it, never on real work.

```text
Write an AutoLISP routine for AutoCAD 2026, command BIGGERTEXT, that
selects every TEXT entity in the drawing and multiplies its height by 1.5.

Before changing anything, print how many entities it found and ask the user
to confirm with Y before proceeding.

Complete file, *error* handler, comments.
```

**You should get:** a confirmation prompt before anything changes. If it
doesn't ask for confirmation, ask again - that habit matters more than the
routine.

---

## 6. Explain code you didn't write

Paste code into the chat first, then:

```text
Explain what this AutoLISP does, line by line, in plain English. I am not a
programmer. Tell me if anything in it could change my drawing in a way I
can't undo.
```

**Use this every time before you load something you didn't write.** It takes
30 seconds and it's the whole "validation" half of today's session.

---

## 7. Fix an error

```text
I loaded this file in AutoCAD 2026 and got this exact error:

<paste the full red error text from the AutoCAD command line here>

Here is the file:

<paste your file here>

What's wrong, and what's the smallest change that fixes it?
```

**Paste the error verbatim.** Not your description of it. AutoCAD's messages
are specific enough to diagnose directly; your paraphrase usually isn't.

---

## 8. Split a file that's getting long

```text
This file is getting long. Split it into:
- a file with the helper calculations only
- a file with the main logic
- a file with just the (defun c:...) command definition
- a small loader file that loads the other three

Use the prefix "myroutine-" for all four filenames. Show me each file
separately with its filename.
```

**Why:** short files are easier for you to read, easier for a facilitator to
help with, and produce better answers from any assistant. See
`.continue/rules/03-file-and-naming-conventions.md` in your workspace.

---

## Things to build, if you need an idea

Roughly easiest first. Use a fresh folder for each one — `my-work\routine-2\`,
then `routine-3\`.

**Straightforward:**

- **Block counter** - count blocks of a given name, report the total.
- **Batch layer creator** - your company's standard layers, with colours and
  linetypes.
- **AsBuilt converter** - switch layer properties from ToBuild to AsBuilt.
- **Quick dimension tool** - dimension with a fixed style on a fixed layer.

**More ambitious** (pick one piece of it, not the whole thing):

- **Drawing cleanup** - purge unused elements, audit, zoom extents, save.
- **Revision cloud manager** - place a numbered revision cloud, update a table.
- **Room data extractor** - read polyline boundaries, calculate areas, label
  them.
- **Cable tray generator** - draw trays from parameters, with bends and tees.

For the ambitious ones: ask for **one function at a time**. "Calculate the area
of a closed polyline the user picks" is a good prompt. "Build me a room data
extractor" is not - any assistant will produce something long, plausible and
wrong somewhere you can't see.

---

← [Track 1](README.md) · [Start here](../../START-HERE.md)
