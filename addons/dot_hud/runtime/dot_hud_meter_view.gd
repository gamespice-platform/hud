class_name DotHudMeterView
extends Control

## A horizontal bar for health, armour or ammo drawn with _draw and no textures, over a [DotHudMeter]. It processes only while the bar is still moving.

@export var fill_colour := Color(0.35, 0.85, 0.4)
@export var low_colour := Color(0.95, 0.3, 0.25)
@export var trail_colour := Color(1, 1, 1, 0.55)
@export var back_colour := Color(0, 0, 0, 0.5)

var config := DotHudConfig.new()
var meter := DotHudMeter.new()


func _ready() -> void:
	set_process(false)


func setup(cfg: DotHudConfig) -> void:
	config = cfg


## Sets the value; the bar eases to it.
func set_value(v: float, maximum: float) -> void:
	meter.set_value(v, maximum, _now(), config)
	set_process(not meter.settled())
	queue_redraw()


func _process(delta: float) -> void:
	meter.step(config, delta, _now())
	queue_redraw()
	if meter.settled():
		set_process(false)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _draw() -> void:
	if not config.enabled:
		return
	draw_rect(Rect2(Vector2.ZERO, size), back_colour)
	draw_rect(Rect2(0.0, 0.0, size.x * meter.trail_fraction(), size.y), trail_colour)
	draw_rect(Rect2(0.0, 0.0, size.x * meter.shown_fraction(), size.y), low_colour if meter.low(config) else fill_colour)
