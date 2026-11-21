# HUD models and views

Each piece is a pure model in `core/` (no nodes, time passed in, pooled so a warm model allocates nothing) and, where it draws, a thin `Control` in `runtime/` that goes idle (`set_process(false)`) until its model changes.

| Piece | Model | View |
| --- | --- | --- |
| Kill feed | `DotHudFeed`, `DotHudFeedLine` | `DotHudFeedView` |
| Damage numbers | `DotHudNumbers`, `DotHudNumber` | `DotHudNumbersView` |
| Hit marker | `DotHudHitMarker` | drawn by `DotHudCrosshairView` |
| Crosshair spread | `DotHudSpread` | `DotHudCrosshairView` |
| Health, ammo, any bar | `DotHudMeter` | `DotHudMeterView` |
| Minimap | `DotHudBlipSet`, `DotHudRadar` | `DotHudMinimapView` |

## Rules

- A limit of 0 is unlimited, a bad config value is refused by `DotHudConfig.validate()` with a `DotResult`.
- A feed line is a list of coloured fragments (killer, weapon, victim), so a game colours teams without the feed knowing about teams.
- Damage numbers merge hits on one victim inside `number_merge` seconds, so a shotgun reads as one number.
- A meter keeps a pale trail behind the fill after a loss; `low()` is false for a zero maximum.

## Where this came from

The behaviour mirrors the widgets in GameSpice UI (hit marker, damage numbers, feed view). Those still carry their own copy; moving them onto these models is tracked on the nightly board.
