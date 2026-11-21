[![GameSpice HUD - GameSpice addon](docs/banner.png)](https://moddingcommunity.com/a/149-gs-hud)

Godot 4.7+ addon for the shooter HUD with no art: kill feed, scoreboard, damage numbers, hit markers, crosshair, ammo and health widgets and a minimap, all bound to data, each as a pure model plus a thin drawing view. Part of the GameSpice addon family.

## Install

1. Copy `addons/gs_hud/` and `addons/gs_core/` into your project.
2. Enable the addon in *Project > Project Settings > Plugins*.

It needs only GameSpice Core ([gs_core](https://github.com/gamespice-platform/core)).

## Quick start

```gdscript
var cfg := GSHudConfig.from_files().value as GSHudConfig
var blips := GSHudBlipSet.new(cfg)
blips.sight(&"mate_2", team, mate.global_position, now)    # QUOTA past blip_limit, unless it is 0

var view := GSHudMinimapView.new()                        # a Control, drawn with _draw, no textures
add_child(view)
view.setup(cfg, blips)
# each frame
view.viewer_team = my_team
view.viewer_pos = player.global_position
view.viewer_yaw = player.rotation.y
view.now = now
view.queue_redraw()

var feed := GSHudFeed.new(cfg)                            # kill feed model: push(texts, colours, now), expire(now)
var meter := GSHudMeter.new()                             # health or ammo: set_value(v, max, now, cfg), a pale loss trail
var spread := GSHudSpread.new()                           # crosshair: kick(cfg) per shot, step(cfg, delta, floor)

var p := GSHudRadar.project(origin, yaw, target, cfg.minimap_range, cfg.minimap_radius)   # {pos, inside, distance}
```

## Settings

Every number is a field on `GSHudConfig`. The values below are defaults, and the ranges are inspector slider limits, not enforced caps. Set the property from code or a config file (`cfg/addon/gs_hud/hud.yml`, `GS_HUD_*`, `--hud-*`) to go beyond them. A bad value fails loudly in `validate()`.

| Setting | Default | What it does |
| --- | --- | --- |
| `enabled` | true | Master switch: off, the minimap draws nothing. |
| `minimap_range` | 60.0 | World units from the player to the minimap edge. |
| `minimap_radius` | 80.0 | Minimap radius in pixels. |
| `minimap_rotate` | true | True keeps the player's heading at the top; false keeps north up. |
| `blip_limit` | 64 | Blips tracked at once; 0 is unlimited. Past the limit a new blip fails loudly. |
| `blip_ttl` | 3.0 | Seconds a blip survives without a fresh sighting; 0 keeps it until removed. |
| `blip_fade` | 0.5 | Seconds a blip fades out at the end of its life; 0 drops it without fading. |
| `edge_pin` | true | Pin blips that leave the range to the minimap edge instead of hiding them. |
| `feed_limit` | 6 | Kill feed lines kept; 0 is unlimited. The oldest is dropped past it. |
| `feed_ttl` | 6.0 | Seconds a feed line lives; 0 keeps it until removed. |
| `feed_fade` | 0.5 | Seconds a feed line fades at the end of its life. |
| `number_limit` | 32 | Damage numbers live at once; 0 is unlimited. |
| `number_ttl` | 0.9 | Seconds a damage number floats. |
| `number_merge` | 0.35 | Hits on one victim within this window add into one number. |
| `marker_hit_sec` | 0.28 | Hit marker flash length. |
| `marker_kill_sec` | 0.6 | Kill marker flash length. |
| `crosshair_gap` | 4.0 | Resting gap of the crosshair arms in pixels. |
| `crosshair_spread_px` | 24.0 | Extra gap at full spread. |
| `crosshair_kick` | 0.25 | Spread added by one shot (0 to 1). |
| `crosshair_recover` | 0.12 | Seconds for spread to halve. |
| `meter_half_life` | 0.08 | Seconds for a health or ammo bar to cover half the way to its value. |
| `meter_trail_delay` | 0.4 | Seconds the pale loss trail waits before draining. |
| `meter_low` | 0.25 | Fraction under which a meter reads as low; 0 never. |

## What it is not

- Ships no art: no textures, fonts or icons. Colours are exports on the view.
- Not the scoreboard table or menus: GameSpice UI owns those. The HUD owns the in-play pieces: feed, damage numbers, hit marker, crosshair, meters and minimap.
- Not the match data: GameSpice Match owns the kill feed entries and scoreboard rows; the HUD binds to them.
- Not a layout system or theme.

## Test

```bash
godot --headless --path . --import
godot --headless --path . res://examples/hud_selftest.tscn
```

The self-test is offline and exits non-zero on any failure.

## Status

Built and maintained with Claude Code. The test suites pass, but little of this has been in front of real players yet. Please report rough edges by opening an issue. The assets keep improving through Nightly.

## Licence

MIT. See [LICENSE](LICENSE). Only the TMC back-end web infrastructure is not open source.
