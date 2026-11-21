class_name DotHudConfig
extends DotConfig

## Every tunable of GameSpice HUD. A game binds it with DotGameConfigBinder (kind `hud`); `cfg/addon/dot_hud/*.yml`, `DOT_HUD_*` and `--hud-*` layer over these defaults. Ranges are inspector slider limits, not caps.

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


func env_prefix() -> String:
	return "DOT_HUD_"


func cli_prefix() -> String:
	return "--hud-"


func validate() -> DotResult:
	if minimap_range <= 0.0 or minimap_radius <= 0.0:
		return DotResult.fail(DotError.CODE_INVALID, "hud minimap_range and minimap_radius must be above 0")
	if blip_limit < 0 or blip_ttl < 0.0 or blip_fade < 0.0:
		return DotResult.fail(DotError.CODE_INVALID, "hud blip_limit, blip_ttl and blip_fade cannot be negative (0 means unlimited or off)")
	return DotResult.success(self)


## Defaults, then `cfg/addon/dot_hud/*.yml` and the game tier, then environment and command line.
static func from_files() -> DotResult:
	var cfg := DotHudConfig.new()
	var files := DotAddonConfig.load_dir(ADDON)
	if not files.ok:
		return files
	cfg.apply_dictionary(files.value as Dictionary, "yml")
	return cfg.load_layered()


func describe() -> String:
	return "hud %s minimap %.0fm over %.0fpx %s blips %s" % ["on" if enabled else "disabled", minimap_range, minimap_radius, "heading-up" if minimap_rotate else "north-up", "unlimited" if blip_limit == 0 else str(blip_limit)]
