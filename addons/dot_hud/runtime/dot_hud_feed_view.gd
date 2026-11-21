class_name GSHudFeedView
extends Control

## Draws a [GSHudFeed] right-aligned, newest at the bottom, one coloured run per fragment. It processes only while the feed holds lines, to expire and fade them.

@export var font_size: int = 16
@export var line_height: float = 20.0
@export var gap: float = 6.0

var config := GSHudConfig.new()
var feed := GSHudFeed.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func setup(cfg: GSHudConfig, p_feed: GSHudFeed) -> void:
	config = cfg
	feed = p_feed


## Adds a line and starts expiring. Same contract as [method GSHudFeed.push].
func push(texts: PackedStringArray, colours: PackedColorArray) -> GSResult:
	var r := feed.push(texts, colours, _now())
	set_process(feed.size() > 0)
	queue_redraw()
	return r


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _process(_delta: float) -> void:
	feed.expire(_now())
	queue_redraw()
	if feed.size() == 0:
		set_process(false)


func _draw() -> void:
	if not config.enabled:
		return
	var font := ThemeDB.fallback_font
	var now := _now()
	var y := size.y
	for i in range(feed.size() - 1, -1, -1):
		var line := feed.line(i)
		var width := 0.0
		for t in line.texts:
			width += font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + gap
		var x := size.x - width
		var a := feed.alpha(i, now)
		for j in line.texts.size():
			var col := line.colours[j]
			col.a *= a
			draw_string(font, Vector2(x, y - 4.0), line.texts[j], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
			x += font.get_string_size(line.texts[j], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + gap
		y -= line_height
