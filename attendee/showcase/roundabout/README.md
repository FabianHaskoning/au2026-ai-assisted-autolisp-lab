# Roundabout showcase

A complete, real AutoLISP application - not an exercise. It draws a full
roundabout (carriageway, mountable apron, central island, splitter islands,
optional cycle ring with crossings) from a dialog, and can connect two
roundabouts with a road. It exists so you can see where the patterns from the
tracks lead when they grow up: the same loader-plus-modules layout as the
scaffold, `*error*` handlers, system-variable save/restore, `entmake`,
selection sets, and a tool that *reads* the drawing it made earlier.

It was translated to English from a working Dutch roundabout-design tool
(dimensions follow the Dutch CROW design guidance; the urban/rural presets are
its 16.00/10.50 and 18.00/12.75 m standard sizes).

## Try it (2 minutes)

1. In AutoCAD, open a **new, blank drawing** - the tool creates its own layers
   and draws a lot of entities.
2. Type `APPLOAD`, browse to
   `C:\LabWork\showcase\roundabout\rdb-loader.lsp`, click **Load**, then
   **Close**. The loader loads the other modules for you.
3. Type `ROUNDABOUT`. Accept the defaults in the dialog, click **OK**, pick a
   center point, then click a few directions for the arms. Press **Enter**
   when you're done.
4. Draw a second one somewhere else, then type `RDBCONNECT`: pick the outer
   circle of each roundabout and a waypoint in between - it cuts openings
   into both and draws the connecting road.

If a command is unknown, the loader didn't finish - re-run `APPLOAD` and watch
the command line for "module not found" messages.

## How it's put together

The only file you ever load is the loader. The modules must load in this
order (each layer builds on the previous one):

| File | What it holds |
| --- | --- |
| `rdb-loader.lsp` | Finds and loads the modules, verifies both commands exist |
| `rdb-util.lsp` | Math + entity-making primitives (no commands) |
| `rdb-layers.lsp` | Creates the `RDB-*` layers, only when missing |
| `rdb-core.lsp` | The concentric core rings |
| `rdb-arms.lsp` | Arm geometry: fillets, asphalt fill, splitter islands |
| `rdb-cycle.lsp` | Cycle ring and crossings |
| `rdb-connect.lsp` | `RDBCONNECT`: reads existing roundabouts back from the drawing |
| `rdb-dialog.lsp` | The DCL dialog (written to a temp file at runtime) |
| `rdb-command.lsp` | `ROUNDABOUT`: ties everything together |

## Where the tracks borrow from this

- **Track 1** - `make-layers.lsp` is a simplified `rdb-layers.lsp`: one idea
  (build a DXF list, hand it to `entmake`), instant visual payoff.
- **Track 2** - `well-behaved-command.lsp` is the skeleton of
  `rdb-command.lsp` without the dialog: the `*error*` handler,
  system-variable restore and input validation your instruction file should
  push every generated routine toward.
- **Track 3** - `read-the-drawing.lsp` uses the same technique as
  `rdb-connect.lsp`: select one entity, then let `ssget` and `entget` work
  out what the drawing already contains.

Nothing here is off-limits: load it, break it, ask your assistant to explain
any function in plain language, or to add a feature. It's a showcase, not a
museum piece.
