# GameSpice HUD

Godot 4.7+ addon for the shooter HUD with no art: kill feed, scoreboard, damage numbers, hit markers, crosshair, ammo and health widgets and a minimap, all bound to data. Part of the GameSpice addon family.

**The distributable is `addons/gs_hud/`.** It requires only gs-core (`addons/gs_core`, a gitignored symlink to `../../gs-core/addons/gs_core`). Never depend on another addon from here.

| Path | What it holds |
| --- | --- |
| `addons/gs_hud/gs_hud_api.gd` | `LEVEL` and `OLDEST`: the API level (2) and the oldest a consumer may target |
| `addons/gs_hud/core/`, `runtime/` | blip set, radar, feed, feed line, numbers, number, hit marker, spread, meter and config in core (pure logic: no nodes, no I/O); minimap, feed, numbers, crosshair and meter views in runtime (idle until their model changes) |
| `cfg/addon/gs_hud/hud.yml` | shipped defaults, layered under the game, environment and command line |
| `examples/hud_selftest.gd` | the headless suite; `EXPECTED_SECTIONS` and `EXPECTED_CHECKS` must match what it runs |

## Boundaries

- Ships no art: no textures, fonts or icons. Colours are exports on the view.
- Not the scoreboard table or menus: GameSpice UI owns those.
- Not the match data: GameSpice Match owns the kill feed entries and scoreboard rows; the HUD binds to them.
- Not a layout system or theme.

## Rules

- Every limit is configurable, 0 means unlimited where a limit makes sense, and a bad value fails loudly through `GSResult`.
- Time is passed in (`now`, `delta`); core classes never read a clock.
- Everything here is prefixed `GSHud`. No `uid://` paths.
- Prose says GameSpice, never the internal repo prefix.
- Run the suite with `hv`, never bare Godot. Commit with the owner's identity; never tag.
