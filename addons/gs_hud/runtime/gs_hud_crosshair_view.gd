class_name GSHudCrosshairView
extends Control

## Four ticks round the middle that open with fire and movement, and a hit marker over them. Drawn with _draw and no textures; it processes only while the spread or the marker is moving. Place it full-rect over the HUD.

@export var colour := Color(1, 1, 1, 0.9)
@export var hit_colour := Color(1, 1, 1)
@export var headshot_colour := Color(1.0, 0.9, 0.6)
@export var kill_colour := Color(1.0, 0.3, 0.25)
@export var tick_length: float = 8.0

var config := GSHudConfig.new()
var spread := GSHudSpread.new()
var marker := GSHudHitMarker.new()
## Spread movement or a stance holds up, 0 to 1. Set it from the game.
var floor_value: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func setup(cfg: GSHudConfig) -> void:
	config = cfg


## A shot left the weapon.
func shoot() -> void:
	spread.kick(config)
	_wake()


## The server confirmed a hit.
func hit(kill: bool = false, headshot: bool = false) -> void:
	marker.flash(config, _now(), kill, headshot)
	_wake()


## Sets the held spread (movement); wakes the view when it changes.
func set_floor(v: float) -> void:
	if v != floor_value:
		floor_value = v
		_wake()


func _wake() -> void:
	set_process(true)
	queue_redraw()


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _process(delta: float) -> void:
	spread.step(config, delta, floor_value)
	queue_redraw()
	if spread.settled(floor_value) and not marker.active(_now()):
		set_process(false)


func _draw() -> void:
	if not config.enabled:
		return
	var c := size / 2.0
	var g := spread.gap(config)
	for dir: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(c + dir * g, c + dir * (g + tick_length), colour, 2.0)
	var a := marker.alpha(_now())
	if a > 0.0:
		var col := kill_colour if marker.kill else (headshot_colour if marker.headshot else hit_colour)
		col.a = a
		var reach := 14.0 if marker.kill else 10.0
		for diag: Vector2 in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
			draw_line(c + diag * 5.0, c + diag * reach, col, 2.0)
