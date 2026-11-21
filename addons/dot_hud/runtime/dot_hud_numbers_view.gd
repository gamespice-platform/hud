class_name DotHudNumbersView
extends Control

## Draws a [DotHudNumbers] over the world: each number is projected through the camera, rises and fades. It processes only while numbers are alive.

@export var font_size: int = 24
@export var headshot_size: int = 30
@export var rise_px: float = 70.0
@export var colour := Color(1, 1, 1)
@export var headshot_colour := Color(1.0, 0.85, 0.3)

var config := DotHudConfig.new()
var numbers := DotHudNumbers.new()
## The camera points are projected through; null uses the viewport's current one.
var camera: Camera3D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func setup(cfg: DotHudConfig, p_numbers: DotHudNumbers) -> void:
	config = cfg
	numbers = p_numbers


## A confirmed hit of [param amount] on [param victim] at world [param point].
func add(victim: int, amount: float, point: Vector3, headshot: bool = false) -> void:
	numbers.add(victim, amount, point, headshot, _now())
	set_process(true)
	queue_redraw()


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _process(_delta: float) -> void:
	numbers.expire(_now())
	queue_redraw()
	if numbers.size() == 0:
		set_process(false)


func _draw() -> void:
	if not config.enabled:
		return
	var cam := camera if camera != null else get_viewport().get_camera_3d()
	if cam == null:
		return
	var font := ThemeDB.fallback_font
	var now := _now()
	for i in numbers.size():
		var n := numbers.at(i)
		if cam.is_position_behind(n.at):
			continue
		var p := numbers.progress(n, now)
		var pos := cam.unproject_position(n.at) + Vector2(n.drift, -rise_px * p)
		var col := headshot_colour if n.headshot else colour
		col.a = 1.0 - p
		draw_string(font, pos, str(int(roundf(n.amount))), HORIZONTAL_ALIGNMENT_CENTER, -1, headshot_size if n.headshot else font_size, col)
