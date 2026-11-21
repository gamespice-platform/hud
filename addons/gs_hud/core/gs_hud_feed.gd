class_name GSHudFeed
extends RefCounted

## A bounded, self-expiring list of lines: the kill feed. It holds no nodes and reads no clock; time is passed in. Lines are pooled, so after warm-up a push allocates nothing.
##
## It takes fragments, not GameSpice Match types: a game formats whatever it has.

var _cfg: GSHudConfig
var _lines: Array[GSHudFeedLine] = []
var _pool: Array[GSHudFeedLine] = []


func _init(cfg: GSHudConfig = null) -> void:
	_cfg = cfg if cfg != null else GSHudConfig.new()


## Adds a line of [param texts] coloured by [param colours] (same length) at [param now]. With a limit set the oldest line is dropped to make room. Fails INVALID on empty or mismatched fragments.
func push(texts: PackedStringArray, colours: PackedColorArray, now: float) -> GSResult:
	if texts.is_empty() or texts.size() != colours.size():
		return GSResult.fail(GSError.CODE_INVALID, "feed line needs fragments and one colour each (%d texts, %d colours)" % [texts.size(), colours.size()])
	if _cfg.feed_limit > 0:
		while _lines.size() >= _cfg.feed_limit:
			_pool.append(_lines.pop_front())
	var line: GSHudFeedLine = _pool.pop_back() if not _pool.is_empty() else GSHudFeedLine.new()
	line.texts = texts
	line.colours = colours
	line.born = now
	_lines.append(line)
	return GSResult.success(line)


## Drops lines older than `feed_ttl` (0 keeps them) and returns how many went.
func expire(now: float) -> int:
	if _cfg.feed_ttl <= 0.0:
		return 0
	var n := 0
	while not _lines.is_empty() and now - _lines[0].born >= _cfg.feed_ttl:
		_pool.append(_lines.pop_front())
		n += 1
	return n


## Opacity of line [param i] at [param now]: 1 until the last `feed_fade` seconds of its life.
func alpha(i: int, now: float) -> float:
	if _cfg.feed_ttl <= 0.0 or _cfg.feed_fade <= 0.0:
		return 1.0
	var left := _cfg.feed_ttl - (now - _lines[i].born)
	return clampf(left / _cfg.feed_fade, 0.0, 1.0)


func size() -> int:
	return _lines.size()


## Line [param i], oldest first.
func line(i: int) -> GSHudFeedLine:
	return _lines[i]


func clear() -> void:
	_pool.append_array(_lines)
	_lines.clear()
