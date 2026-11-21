extends Node

## gs-hud's headless suite (res://examples/hud_selftest.tscn).
## Counts sections run to their last line as well as checks, because a script error aborts a section and not the run.

const EXPECTED_SECTIONS := 10
const EXPECTED_CHECKS := 65

var _passed := 0
var _failed := 0
var _sections := 0


func _ready() -> void:
	print("gs-hud")
	_config()
	_radar()
	_blips()
	_view()
	_bearing()
	_feed()
	_numbers()
	_marker_and_spread()
	_meter()
	_views()
	print("")
	_check(_sections == EXPECTED_SECTIONS, "every section ran to its last line (%d of %d)" % [_sections, EXPECTED_SECTIONS])
	_check(_passed + _failed == EXPECTED_CHECKS, "and the suite ran all %d of its checks (%d)" % [EXPECTED_CHECKS, _passed + _failed])
	print("%d passed, %d failed" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _near(a: Vector2, b: Vector2) -> bool:
	return a.distance_to(b) < 0.001


func _config() -> void:
	var c := GSHudConfig.new()
	_check(c.validate().ok, "defaults validate")
	c.minimap_range = 0.0
	_check(not c.validate().ok and c.validate().error.code == GSError.CODE_INVALID, "a zero range fails loudly")
	c.minimap_range = 50.0
	c.blip_limit = -1
	_check(not c.validate().ok, "a negative blip limit fails")
	c.blip_limit = 0
	c.blip_ttl = 0.0
	_check(c.validate().ok, "blip_limit 0 and blip_ttl 0 (unlimited, forever) are valid")
	var applied := c.apply_dictionary({"minimap_range": 90.0, "minimap_rotate": false, "blip_limit": 8})
	_check(applied.size() == 3 and c.minimap_range == 90.0 and not c.minimap_rotate and c.blip_limit == 8, "a dictionary layer sets every type", str(applied))
	_check(c.env_prefix() == "GS_HUD_" and c.cli_prefix() == "--hud-", "env and command-line prefixes")
	var r := GSHudConfig.from_files()
	_check(r.ok and (r.value as GSHudConfig).describe().begins_with("hud"), "from_files returns a config that describes itself")
	_sections += 1


func _radar() -> void:
	var o := Vector3(10, 0, 10)
	var p := GSHudRadar.project(o, 0.0, Vector3(10, 0, 0), 20.0, 80.0)
	_check(_near(p["pos"], Vector2(0, -40)) and p["inside"] and is_equal_approx(p["distance"], 10.0), "ahead (-Z) is the top of the map")
	p = GSHudRadar.project(o, 0.0, Vector3(20, 0, 10), 20.0, 80.0)
	_check(_near(p["pos"], Vector2(40, 0)), "+X is to the right")
	p = GSHudRadar.project(o, PI / 2.0, Vector3(10, 0, 0), 20.0, 80.0)
	_check(p["inside"] and absf((p["pos"] as Vector2).y) < 0.001 and absf((p["pos"] as Vector2).x) > 39.0, "turning the player turns the map")
	p = GSHudRadar.project(o, PI / 2.0, Vector3(10, 0, 0), 20.0, 80.0, false)
	_check(_near(p["pos"], Vector2(0, -40)), "rotate off keeps north up whatever the yaw")
	p = GSHudRadar.project(o, 0.0, Vector3(10, 0, -90), 20.0, 80.0)
	_check(not p["inside"] and _near(p["pos"], Vector2(0, -80)) and is_equal_approx(p["distance"], 100.0), "out of range pins to the edge and says so")
	p = GSHudRadar.project(o, 0.0, o, 20.0, 80.0)
	_check(_near(p["pos"], Vector2.ZERO) and p["inside"], "standing on the viewer is the centre")
	_sections += 1


func _blips() -> void:
	var cfg := GSHudConfig.new()
	cfg.blip_limit = 2
	cfg.blip_ttl = 4.0
	cfg.blip_fade = 2.0
	var s := GSHudBlipSet.new(cfg)
	_check(s.sight(&"a", 1, Vector3.ZERO, 0.0).ok and s.sight(&"b", 2, Vector3.ONE, 0.0).ok, "two blips held")
	var over := s.sight(&"c", 2, Vector3.ONE, 0.0)
	_check(not over.ok and over.error.code == GSError.CODE_QUOTA, "past the limit fails with QUOTA")
	_check(s.sight(&"a", 1, Vector3.RIGHT, 1.0).ok and s.size() == 2, "a fresh sighting of a held id is not a new blip")
	_check(not s.sight(&"", 1, Vector3.ZERO, 0.0).ok, "an empty id fails")
	var v := s.visible(1, 3.0)
	_check(v.size() == 2 and v[0]["id"] == &"a" and v[1]["id"] == &"b", "sorted by id")
	_check(is_equal_approx(float(v[1]["alpha"]), 0.5) and float(v[0]["alpha"]) == 1.0, "a stale hostile fades, an own-team blip does not")
	_check(s.visible(1, 4.5).size() == 1 and s.visible(2, 4.5).size() == 2, "past ttl a hostile is hidden")
	_check(s.prune(10.0) == 2 and s.size() == 0, "prune drops what is over")
	var forever := GSHudConfig.new()
	forever.blip_limit = 0
	forever.blip_ttl = 0.0
	var f := GSHudBlipSet.new(forever)
	for i in 300:
		f.sight(StringName("b%d" % i), 2, Vector3.ZERO, 0.0)
	_check(f.size() == 300 and f.prune(1.0e6) == 0 and f.visible(1, 1.0e6).size() == 300, "limit 0 and ttl 0 mean unlimited and forever")
	_sections += 1


func _view() -> void:
	var cfg := GSHudConfig.new()
	cfg.minimap_range = 20.0
	cfg.minimap_radius = 80.0
	var set := GSHudBlipSet.new(cfg)
	set.sight(&"mate", 1, Vector3(0, 0, -10), 0.0)
	set.sight(&"foe", 2, Vector3(0, 0, -90), 0.0)
	var view := GSHudMinimapView.new()
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
	_check(is_equal_approx(GSHudRadar.bearing(o, 0.0, Vector3(0, 0, -5)), 0.0), "straight ahead is 0")
	_check(is_equal_approx(GSHudRadar.bearing(o, 0.0, Vector3(5, 0, 0)), 90.0), "right is 90")
	_check(is_equal_approx(GSHudRadar.bearing(o, 0.0, Vector3(0, 0, 5)), 180.0), "behind is 180")
	_check(is_equal_approx(GSHudRadar.bearing(o, 0.0, Vector3(-5, 0, 0)), 270.0), "left is 270")
	_sections += 1


func _check(ok: bool, what: String, extra: String = "") -> void:
	if ok:
		_passed += 1
		print("  ok    ", what)
	else:
		_failed += 1
		print("  FAIL  ", what, "  ", extra)


func _feed() -> void:
	var cfg := GSHudConfig.new()
	cfg.feed_limit = 2
	cfg.feed_ttl = 4.0
	cfg.feed_fade = 1.0
	var f := GSHudFeed.new(cfg)
	_check(not f.push(PackedStringArray(), PackedColorArray(), 0.0).ok, "an empty line fails")
	_check(not f.push(PackedStringArray(["a", "b"]), PackedColorArray([Color.RED]), 0.0).ok, "fragments and colours must match")
	f.push(PackedStringArray(["A", " killed ", "B"]), PackedColorArray([Color.RED, Color.WHITE, Color.BLUE]), 0.0)
	f.push(PackedStringArray(["C"]), PackedColorArray([Color.RED]), 1.0)
	f.push(PackedStringArray(["D"]), PackedColorArray([Color.RED]), 2.0)
	_check(f.size() == 2 and f.line(0).plain() == "C", "the limit drops the oldest line")
	_check(is_equal_approx(f.alpha(0, 2.0), 1.0) and is_equal_approx(f.alpha(0, 4.5), 0.5), "a line fades over its last second")
	_check(f.expire(5.0) == 1 and f.size() == 1, "expiry drops lines past the ttl")
	f.clear()
	_check(f.size() == 0, "clear empties the feed")
	var cfg2 := GSHudConfig.new()
	cfg2.feed_limit = 0
	cfg2.feed_ttl = 0.0
	var g := GSHudFeed.new(cfg2)
	for i in 100:
		g.push(PackedStringArray(["x"]), PackedColorArray([Color.WHITE]), float(i))
	_check(g.size() == 100 and g.expire(1e6) == 0 and g.alpha(0, 1e6) == 1.0, "limit 0 and ttl 0 are unlimited and forever")
	_sections += 1


func _numbers() -> void:
	var cfg := GSHudConfig.new()
	cfg.number_limit = 2
	cfg.number_ttl = 1.0
	cfg.number_merge = 0.3
	var n := GSHudNumbers.new(cfg)
	n.add(1, 10.0, Vector3.ZERO, false, 0.0)
	n.add(1, 15.0, Vector3.ONE, true, 0.2)
	_check(n.size() == 1 and n.at(0).amount == 25.0 and n.at(0).headshot, "hits within the merge window add into one number")
	n.add(1, 5.0, Vector3.ZERO, false, 0.9)
	_check(n.size() == 2, "a hit after the window is a new number")
	n.add(2, 5.0, Vector3.ZERO, false, 0.95)
	_check(n.size() == 2 and n.at(0).victim == 1 and n.at(1).victim == 2, "past the limit the oldest is dropped")
	_check(n.expire(1.92) == 1 and n.size() == 1, "expiry drops numbers past their ttl")
	_check(is_equal_approx(n.progress(n.at(0), 1.45), 0.5), "progress runs 0 to 1")
	var cfg2 := GSHudConfig.new()
	cfg2.number_merge = 0.0
	cfg2.number_limit = 0
	var u := GSHudNumbers.new(cfg2)
	for i in 50:
		u.add(1, 1.0, Vector3.ZERO, false, 0.0)
	_check(u.size() == 50, "merge 0 never merges and limit 0 is unlimited")
	_sections += 1


func _marker_and_spread() -> void:
	var cfg := GSHudConfig.new()
	var m := GSHudHitMarker.new()
	_check(not m.active(0.0), "a fresh marker is off")
	m.flash(cfg, 10.0, true, false)
	_check(m.active(10.1) and is_equal_approx(m.alpha(10.0), 1.0) and not m.active(10.7), "a kill marker lasts its kill duration")
	m.flash(cfg, 10.1)
	_check(m.kill, "a pellet after the kill does not downgrade the marker")
	m.flash(cfg, 10.5)
	_check(not m.kill, "a later hit does")
	var s := GSHudSpread.new()
	s.kick(cfg)
	s.kick(cfg)
	_check(is_equal_approx(s.value, 0.5) and s.gap(cfg) > cfg.crosshair_gap, "shots open the crosshair")
	for i in 5:
		s.kick(cfg)
	_check(s.value == 1.0, "spread is capped at full")
	s.step(cfg, cfg.crosshair_recover, 0.0)
	_check(is_equal_approx(s.value, 0.5), "one half life halves the spread")
	s.step(cfg, 1.0, 0.3)
	_check(s.value >= 0.3 and s.value < 0.31 and s.settled(0.3) == (s.value == 0.3), "it recovers to the held floor and no lower")
	for i in 40:
		s.step(cfg, 0.1, 0.3)
	_check(s.settled(0.3), "and settles exactly")
	_sections += 1


func _meter() -> void:
	var cfg := GSHudConfig.new()
	cfg.meter_trail_delay = 0.5
	cfg.meter_half_life = 0.1
	var m := GSHudMeter.new()
	m.set_value(100.0, 100.0, 0.0, cfg)
	_check(m.settled() and m.fraction() == 1.0 and not m.low(cfg), "a full meter is settled and not low")
	m.set_value(20.0, 100.0, 1.0, cfg)
	_check(m.low(cfg) and not m.settled() and m.trail == 100.0, "a loss is low and leaves a trail")
	m.step(cfg, 0.1, 1.1)
	_check(m.shown < 100.0 and m.shown > 20.0 and m.trail == 100.0, "the fill eases while the trail waits")
	m.step(cfg, 0.1, 1.6)
	_check(m.trail < 100.0, "after the delay the trail drains")
	for i in 100:
		m.step(cfg, 0.1, 5.0 + i)
	_check(m.settled() and m.shown == 20.0, "it settles exactly on the value")
	m.set_value(80.0, 100.0, 9.0, cfg)
	_check(m.trail == 80.0, "a rise lifts the trail with it")
	m.set_value(500.0, 100.0, 9.0, cfg)
	_check(m.value == 100.0, "a value over the maximum is clamped")
	m.set_value(5.0, 0.0, 9.0, cfg)
	_check(m.fraction() == 0.0 and not m.low(cfg), "a zero maximum has no fraction and is not low")
	_sections += 1


func _views() -> void:
	var cfg := GSHudConfig.new()
	var meter := GSHudMeterView.new()
	var cross := GSHudCrosshairView.new()
	var feedv := GSHudFeedView.new()
	var numv := GSHudNumbersView.new()
	for v in [meter, cross, feedv, numv]:
		add_child(v)
	meter.setup(cfg)
	cross.setup(cfg)
	feedv.setup(cfg, GSHudFeed.new(cfg))
	numv.setup(cfg, GSHudNumbers.new(cfg))
	_check(not meter.is_processing() and not cross.is_processing() and not feedv.is_processing() and not numv.is_processing(), "idle views do not process")
	meter.set_value(10.0, 100.0)
	cross.shoot()
	_check(feedv.push(PackedStringArray(["x"]), PackedColorArray([Color.WHITE])).ok, "the feed view takes a line")
	numv.add(1, 5.0, Vector3.ZERO)
	_check(meter.is_processing() and cross.is_processing() and feedv.is_processing() and numv.is_processing(), "a change wakes each view")
	for v in [meter, cross, feedv, numv]:
		v.queue_free()
	_sections += 1
