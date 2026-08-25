# How to compare two files

VS Code will show you two files side by side with every difference coloured
in. Track 2 uses this to prove that a rules file changed what the AI produced,
but it's useful any time you want to know *what actually changed*.

## The three steps

1. In the **Explorer** on the left, click the **first** file once.
2. Hold **Ctrl** and click the **second** file. Both are now highlighted.
3. **Right-click** either one → **Compare Selected**.

A two-pane view opens. Left is the first file, right is the second.

- **Green** = only in the file on the right (added).
- **Red** = only in the file on the left (removed).
- Unchanged lines are grey and lined up with each other.

Close it like any other tab when you're done.

## Reading the result

Scroll down the whole thing. The question isn't "is it different" — of course
it's different. The questions are:

- Did the thing you were expecting actually show up?
- Did anything *else* improve that you didn't ask for?
- Did anything get longer without getting better?

## Can't find "Compare Selected"?

You almost certainly have only one file selected. Both files have to be
highlighted before you right-click — check that the Ctrl+click actually landed
on the second one.

Still not there? Raise your hand.

## The same thing, one file at a time

If you want to compare a file against its own earlier version rather than
against another file, that's the **Timeline** — see
[Save your work](save-your-work.md).

---

← [Start here](../START-HERE.md) · [How-to cards](../START-HERE.md#how-to-cards)
