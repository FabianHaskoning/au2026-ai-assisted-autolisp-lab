# Cadastral map showcase

> **You can't run this one here — and that's fine.** It needs the *ArcGIS for
> AutoCAD* plugin, internet access to a ProRail map service, and a drawing
> that already contains the feature layer. None of those are on this VM. It's
> here to **read**: this is what an AutoLISP routine looks like when somebody
> actually uses it at work every week.

Everything else in the workshop was written to be taught. This wasn't. It's a
real tool, contributed as-is by the engineer who uses it, and then tidied up
to the same standard the tracks ask of you.

## What it does

Property parcels in a cadastral drawing each carry a score. The web service
that publishes those parcels also publishes the colour it uses for each score.
This routine fetches that colour table and repaints the drawing to match it:

1. Downloads the map service definition and reads out its colour classes.
2. For each class, selects every parcel with that score.
3. Recolours those parcels, and puts a solid fill behind each closed one.
4. Pushes every fill to the back, so the parcel lines stay readable.

The result is a drawing coloured exactly like the online map, without anybody
picking colours by hand.

## What it would change in your drawing

Worth knowing before you ever point something like this at real work:

- It **recolours** every selected parcel — an override on the entity, not a
  layer change.
- It **creates** the layer `EIGENDOMSKAART_HATCH` if it isn't there.
- It **adds** one solid hatch per closed parcel. On a large drawing that is
  thousands of new objects.
- It **offers to delete** whatever is already on that layer from an earlier
  run. It counts them and asks first; say no and the new fills are simply
  added on top.
- The whole run sits inside one undo mark, so a single `U` reverses all of it.

## How it's put together

The only file you'd ever load is the loader. The modules have to load in this
order, each one building on the last:

| File | What it holds |
| --- | --- |
| `eg-loader.lsp` | Finds and loads the modules, then checks `EGMAP` exists |
| `eg-util.lsp` | String helpers and the attribute-query builder. No commands |
| `eg-service.lsp` | The HTTP request and the JSON reading. **Read this last** |
| `eg-color.lsp` | TrueColor objects, layer creation, clearing a layer |
| `eg-select.lsp` | The one bridge to the ArcGIS for AutoCAD plugin |
| `eg-hatch.lsp` | Solid fills, including rolling back a half-built hatch |
| `eg-command.lsp` | `EGMAP` — ties it together, with the `*error*` handler |

## Read it with your assistant

This is the best thing in the workshop to point an AI at, because it's long
enough to be genuinely opaque and real enough to be worth understanding.

Open any of these files, select the whole thing, and use **prompt 6** from
[`../../tracks/1-first-routine/prompts.md`](../../tracks/1-first-routine/prompts.md):
*"Explain what this AutoLISP does, line by line, in plain English. I am not a
programmer."*

Three questions worth putting to it afterwards:

- `eg-color.lsp` makes one colour object per class and releases it. What
  happens if you make one per entity and never release it?
- `eg-hatch.lsp` deletes the hatch it just made when the next step fails. Why
  is that better than leaving it?
- `eg-command.lsp` restores `CMDECHO` in two different places. Why twice?

## What it teaches, and what it doesn't

Worth copying: the `*error*` handler, the undo mark around the whole command,
counting-then-asking before deleting anything, and cleaning up COM objects you
created.

Not worth copying: `eg-service.lsp` reads JSON by walking the text character
by character, because AutoLISP has no JSON parser. It works for this one
service and would break on the next one. Its header says so. Real code that
needs JSON should be doing it somewhere other than AutoLISP.

---

← [Showcases](../README.md) · [Start here](../../START-HERE.md)
