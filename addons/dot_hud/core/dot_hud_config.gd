class_name GSHudConfig
extends GSConfig

## Every tunable of GameSpice HUD. A game binds it with GSGameConfigBinder (kind `hud`); `cfg/addon/dot_hud/*.yml`, `DOT_HUD_*` and `--hud-*` layer over these defaults. Ranges are inspector slider limits, not caps.

const ADDON := "dot-hud"

## Master switch: off, the minimap draws nothing.
@export var enabled: bool = true
## World units from the player to the minimap edge.
@export_range(5.0, 500.0, 1.0) var minimap_range: float = 60.0
## Minimap radius in pixels.
@export_range(16.0, 512.0, 1.0) var minimap_radius: float = 80.0
## True keeps the player's heading at the top; false keeps north up.
@export var minimap_rotate: bool = true
## Blips tracked at once; 0 is unlimited. Past the limit a new blip fails loudly.
@export_range(0, 512, 1) var blip_limit: int = 64
## Seconds a blip survives without a fresh sighting; 0 keeps it until removed.
@export_range(0.0, 30.0, 0.1) var blip_ttl: float = 3.0
## Seconds a blip fades out at the end of its life; 0 drops it without fading.
@export_range(0.0, 10.0, 0.1) var blip_fade: float = 0.5
## Pin blips that leave the range to the minimap edge instead of hiding them.
@export var edge_pin: bool = true

@export_group("Kill feed")
## Lines kept at once; the oldest falls off the top. 0 is unlimited.
@export_range(0, 40, 1) var feed_limit: int = 6
## Seconds a feed line stays; 0 keeps lines until they fall off.
@export_range(0.0, 600.0, 0.5) var feed_ttl: float = 6.0
## Seconds a feed line fades out at the end of its life.
@export_range(0.0, 5.0, 0.05) var feed_fade: float = 0.5

@export_group("Damage numbers")
## Numbers alive at once; 0 is unlimited. Past the limit the oldest is dropped.
@export_range(0, 256, 1) var number_limit: int = 32
## Seconds a number rises and fades before it is gone.
@export_range(0.1, 10.0, 0.05) var number_ttl: float = 0.9
## Hits on one victim within this many seconds add into one number; 0 never merges.
@export_range(0.0, 5.0, 0.05) var number_merge: float = 0.35

@export_group("Hit marker")
## Seconds a hit marker shows.
@export_range(0.05, 5.0, 0.01) var marker_hit_sec: float = 0.28
## Seconds a kill marker shows.
@export_range(0.05, 5.0, 0.01) var marker_kill_sec: float = 0.6

@export_group("Crosshair")
## Gap in pixels from the centre to the ticks at rest.
@export_range(0.0, 100.0, 0.5) var crosshair_gap: float = 4.0
## Extra gap in pixels at full spread; 0 keeps the crosshair fixed.
@export_range(0.0, 200.0, 0.5) var crosshair_spread_px: float = 24.0
## Spread added by one shot, as a fraction of full spread (0 to 1).
@export_range(0.0, 1.0, 0.01) var crosshair_kick: float = 0.25
## Seconds for the spread to halve once the player stops shooting or moving.
@export_range(0.0, 5.0, 0.01) var crosshair_recover: float = 0.12

@export_group("Meters")
## Seconds for a health or ammo bar to cover half the distance to its value; 0 snaps.
@export_range(0.0, 2.0, 0.01) var meter_half_life: float = 0.08
## Seconds a damage trail waits before it drains to the value; 0 has no trail.
@export_range(0.0, 5.0, 0.05) var meter_trail_delay: float = 0.4
## Fraction of the maximum under which a meter reads as low (0 to 1; 0 never reads low).
@export_range(0.0, 1.0, 0.01) var meter_low: float = 0.25


func env_prefix() -> String:
	return "DOT_HUD_"


func cli_prefix() -> String:
	return "--hud-"


func validate() -> GSResult:
	if minimap_range <= 0.0 or minimap_radius <= 0.0:
		return GSResult.fail(GSError.CODE_INVALID, "hud minimap_range and minimap_radius must be above 0")
	if blip_limit < 0 or blip_ttl < 0.0 or blip_fade < 0.0:
		return GSResult.fail(GSError.CODE_INVALID, "hud blip_limit, blip_ttl and blip_fade cannot be negative (0 means unlimited or off)")
	if feed_limit < 0 or feed_ttl < 0.0 or feed_fade < 0.0:
		return GSResult.fail(GSError.CODE_INVALID, "hud feed_limit, feed_ttl and feed_fade cannot be negative (0 means unlimited or off)")
	if number_limit < 0 or number_merge < 0.0:
		return GSResult.fail(GSError.CODE_INVALID, "hud number_limit and number_merge cannot be negative (0 means unlimited or off)")
	if number_ttl <= 0.0 or marker_hit_sec <= 0.0 or marker_kill_sec <= 0.0:
		return GSResult.fail(GSError.CODE_INVALID, "hud number_ttl and the marker durations must be above 0")
	if crosshair_gap < 0.0 or crosshair_spread_px < 0.0 or crosshair_recover < 0.0 or crosshair_kick < 0.0 or crosshair_kick > 1.0:
		return GSResult.fail(GSError.CODE_INVALID, "hud crosshair gap, spread and recover cannot be negative and kick is 0 to 1")
	if meter_half_life < 0.0 or meter_trail_delay < 0.0 or meter_low < 0.0 or meter_low > 1.0:
		return GSResult.fail(GSError.CODE_INVALID, "hud meter half life and trail delay cannot be negative and meter_low is 0 to 1")
	return GSResult.success(self)


## Defaults, then `cfg/addon/dot_hud/*.yml` and the game tier, then environment and command line.
static func from_files() -> GSResult:
	var cfg := GSHudConfig.new()
	var files := GSAddonConfig.load_dir(ADDON)
	if not files.ok:
		return files
	cfg.apply_dictionary(files.value as Dictionary, "yml")
	return cfg.load_layered()


func describe() -> String:
	return "hud %s minimap %.0fm over %.0fpx %s blips %s" % ["on" if enabled else "disabled", minimap_range, minimap_radius, "heading-up" if minimap_rotate else "north-up", "unlimited" if blip_limit == 0 else str(blip_limit)]
