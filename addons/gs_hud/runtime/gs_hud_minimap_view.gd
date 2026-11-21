class_name GSHudMinimapView
extends Control

## A minimap drawn with _draw and no textures. Feed it a config, the viewer, and a GSHudBlipSet; `layout()` is the draw list, so tests read it without a renderer.

var config := GSHudConfig.new()
var blips := GSHudBlipSet.new()
var viewer_team := 0
var viewer_pos := Vector3.ZERO
var viewer_yaw := 0.0
var now := 0.0

@export var own_color := Color(0.3, 0.8, 1.0)
@export var other_color := Color(1.0, 0.35, 0.3)
@export var ring_color := Color(1, 1, 1, 0.35)


func setup(cfg: GSHudConfig, set: GSHudBlipSet) -> void:
	config = cfg
	blips = set
	custom_minimum_size = Vector2.ONE * cfg.minimap_radius * 2.0
	queue_redraw()


## [{pos: Vector2 from the centre, alpha, own: bool, pinned: bool}] for every blip that should be drawn.
func layout() -> Array:
	var out: Array = []
	if not config.enabled:
		return out
	for b: Dictionary in blips.visible(viewer_team, now):
		var p := GSHudRadar.project(viewer_pos, viewer_yaw, b["pos"], config.minimap_range, config.minimap_radius, config.minimap_rotate)
		if not p["inside"] and not config.edge_pin:
			continue
		out.append({"pos": p["pos"], "alpha": b["alpha"], "own": int(b["team"]) == viewer_team, "pinned": not p["inside"]})
	return out


func _draw() -> void:
	if not config.enabled:
		return
	var c := size / 2.0
	draw_arc(c, config.minimap_radius, 0.0, TAU, 48, ring_color, 1.5)
	for e: Dictionary in layout():
		var col: Color = own_color if e["own"] else other_color
		col.a = float(e["alpha"])
		draw_circle(c + (e["pos"] as Vector2), 3.0, col)
