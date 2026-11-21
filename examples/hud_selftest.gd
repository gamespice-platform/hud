extends Node

## dot-hud's headless suite (res://examples/hud_selftest.tscn).
## Counts sections run to their last line as well as checks, because a script error aborts a section and not the run.

const EXPECTED_SECTIONS := 5
const EXPECTED_CHECKS := 32

var _passed := 0
var _failed := 0
var _sections := 0


func _ready() -> void:
	print("dot-hud")
	_config()
	_radar()
	_blips()
	_view()
	_bearing()
	print("")
	_check(_sections == EXPECTED_SECTIONS, "every section ran to its last line (%d of %d)" % [_sections, EXPECTED_SECTIONS])
	_check(_passed + _failed == EXPECTED_CHECKS, "and the suite ran all %d of its checks (%d)" % [EXPECTED_CHECKS, _passed + _failed])
	print("%d passed, %d failed" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _near(a: Vector2, b: Vector2) -> bool:
	return a.distance_to(b) < 0.001


func _config() -> void:
	var c := DotHudConfig.new()
	_check(c.validate().ok, "defaults validate")
	c.minimap_range = 0.0
	_check(not c.validate().ok and c.validate().error.code == DotError.CODE_INVALID, "a zero range fails loudly")
	c.minimap_range = 50.0
	c.blip_limit = -1
	_check(not c.validate().ok, "a negative blip limit fails")
	c.blip_limit = 0
	c.blip_ttl = 0.0
	_check(c.validate().ok, "blip_limit 0 and blip_ttl 0 (unlimited, forever) are valid")
	var applied := c.apply_dictionary({"minimap_range": 90.0, "minimap_rotate": false, "blip_limit": 8})
	_check(applied.size() == 3 and c.minimap_range == 90.0 and not c.minimap_rotate and c.blip_limit == 8, "a dictionary layer sets every type", str(applied))
	_check(c.env_prefix() == "DOT_HUD_" and c.cli_prefix() == "--hud-", "env and command-line prefixes")
	var r := DotHudConfig.from_files()
	_check(r.ok and (r.value as DotHudConfig).describe().begins_with("hud"), "from_files returns a config that describes itself")
	_sections += 1


func _radar() -> void:
	var o := Vector3(10, 0, 10)
	var p := DotHudRadar.project(o, 0.0, Vector3(10, 0, 0), 20.0, 80.0)
	_check(_near(p["pos"], Vector2(0, -40)) and p["inside"] and is_equal_approx(p["distance"], 10.0), "ahead (-Z) is the top of the map")
	p = DotHudRadar.project(o, 0.0, Vector3(20, 0, 10), 20.0, 80.0)
	_check(_near(p["pos"], Vector2(40, 0)), "+X is to the right")
	p = DotHudRadar.project(o, PI / 2.0, Vector3(10, 0, 0), 20.0, 80.0)
	_check(p["inside"] and absf((p["pos"] as Vector2).y) < 0.001 and absf((p["pos"] as Vector2).x) > 39.0, "turning the player turns the map")
	p = DotHudRadar.project(o, PI / 2.0, Vector3(10, 0, 0), 20.0, 80.0, false)
	_check(_near(p["pos"], Vector2(0, -40)), "rotate off keeps north up whatever the yaw")
	p = DotHudRadar.project(o, 0.0, Vector3(10, 0, -90), 20.0, 80.0)
	_check(not p["inside"] and _near(p["pos"], Vector2(0, -80)) and is_equal_approx(p["distance"], 100.0), "out of range pins to the edge and says so")
	p = DotHudRadar.project(o, 0.0, o, 20.0, 80.0)
	_check(_near(p["pos"], Vector2.ZERO) and p["inside"], "standing on the viewer is the centre")
	_sections += 1


func _blips() -> void:
	var cfg := DotHudConfig.new()
	cfg.blip_limit = 2
	cfg.blip_ttl = 4.0
	cfg.blip_fade = 2.0
	var s := DotHudBlipSet.new(cfg)
	_check(s.sight(&"a", 1, Vector3.ZERO, 0.0).ok and s.sight(&"b", 2, Vector3.ONE, 0.0).ok, "two blips held")
	var over := s.sight(&"c", 2, Vector3.ONE, 0.0)
	_check(not over.ok and over.error.code == DotError.CODE_QUOTA, "past the limit fails with QUOTA")
	_check(s.sight(&"a", 1, Vector3.RIGHT, 1.0).ok and s.size() == 2, "a fresh sighting of a held id is not a new blip")
	_check(not s.sight(&"", 1, Vector3.ZERO, 0.0).ok, "an empty id fails")
	var v := s.visible(1, 3.0)
	_check(v.size() == 2 and v[0]["id"] == &"a" and v[1]["id"] == &"b", "sorted by id")
	_check(is_equal_approx(float(v[1]["alpha"]), 0.5) and float(v[0]["alpha"]) == 1.0, "a stale hostile fades, an own-team blip does not")
	_check(s.visible(1, 4.5).size() == 1 and s.visible(2, 4.5).size() == 2, "past ttl a hostile is hidden")
	_check(s.prune(10.0) == 2 and s.size() == 0, "prune drops what is over")
	var forever := DotHudConfig.new()
	forever.blip_limit = 0
	forever.blip_ttl = 0.0
	var f := DotHudBlipSet.new(forever)
	for i in 300:
		f.sight(StringName("b%d" % i), 2, Vector3.ZERO, 0.0)
	_check(f.size() == 300 and f.prune(1.0e6) == 0 and f.visible(1, 1.0e6).size() == 300, "limit 0 and ttl 0 mean unlimited and forever")
	_sections += 1


func _view() -> void:
	var cfg := DotHudConfig.new()
	cfg.minimap_range = 20.0
	cfg.minimap_radius = 80.0
	var set := DotHudBlipSet.new(cfg)
	set.sight(&"mate", 1, Vector3(0, 0, -10), 0.0)
	set.sight(&"foe", 2, Vector3(0, 0, -90), 0.0)
	var view := DotHudMinimapView.new()
	view.setup(cfg, set)
	view.viewer_team = 1
	view.now = 0.5
	var l := view.layout()
	_check(l.size() == 2 and l[0]["own"] == false and l[1]["own"] == true, "both blips are laid out")
	_check(l[0]["pinned"] == true and _near(l[0]["pos"], Vector2(0, -80)), "the far one is pinned to the edge")
	cfg.edge_pin = false
	_check(view.layout().size() == 1, "edge_pin off hides what is out of range")
	cfg.enabled = false
	_check(view.layout().is_empty(), "a disabled HUD lays out nothing")
	_check(view.custom_minimum_size == Vector2(160, 160), "the view sizes itself from the radius")
	view.free()
	_sections += 1


func _bearing() -> void:
	var o := Vector3.ZERO
	_check(is_equal_approx(DotHudRadar.bearing(o, 0.0, Vector3(0, 0, -5)), 0.0), "straight ahead is 0")
	_check(is_equal_approx(DotHudRadar.bearing(o, 0.0, Vector3(5, 0, 0)), 90.0), "right is 90")
	_check(is_equal_approx(DotHudRadar.bearing(o, 0.0, Vector3(0, 0, 5)), 180.0), "behind is 180")
	_check(is_equal_approx(DotHudRadar.bearing(o, 0.0, Vector3(-5, 0, 0)), 270.0), "left is 270")
	_sections += 1


func _check(ok: bool, what: String, extra: String = "") -> void:
	if ok:
		_passed += 1
		print("  ok    ", what)
	else:
		_failed += 1
		print("  FAIL  ", what, "  ", extra)
