class_name GSHudBlipSet
extends RefCounted

## The minimap's data: who is seen where, how long ago, and who may see them. Pure logic; time is passed as `now`.

var _blips: Dictionary[StringName, Dictionary] = {}
## Scratch list of [method prune], reused.
var _gone: Array[StringName] = []
var _limit: int
var _ttl: float
var _fade: float


func _init(config: GSHudConfig = null) -> void:
	var c := config if config else GSHudConfig.new()
	_limit = c.blip_limit
	_ttl = c.blip_ttl
	_fade = c.blip_fade


func size() -> int:
	return _blips.size()


## Records a sighting. `team` is the blip's team; `hostile_spotted` marks an enemy as seen this tick. Fails QUOTA at the limit for an id not yet held.
func sight(id: StringName, team: int, pos: Vector3, now: float) -> GSResult:
	if id == &"":
		return GSResult.fail(GSError.CODE_INVALID, "blip id is empty")
	if not _blips.has(id) and _limit > 0 and _blips.size() >= _limit:
		return GSResult.fail(GSError.CODE_QUOTA, "blip limit %d reached" % _limit)  # perf-lint: allow string_build refusal path only
	var b: Variant = _blips.get(id)
	if b != null:
		b["team"] = team
		b["pos"] = pos
		b["seen"] = now
	else:
		_blips[id] = {"team": team, "pos": pos, "seen": now}  # perf-lint: allow alloc first sighting of a blip only
	return GSResult.success(id)


func remove(id: StringName) -> void:
	_blips.erase(id)


## Drops blips whose life is over; returns how many went.
func prune(now: float) -> int:
	if _ttl <= 0.0:
		return 0
	var gone := _gone
	gone.clear()
	for id: StringName in _blips:
		if now - float(_blips[id]["seen"]) > _ttl:
			gone.append(id)
	for id: StringName in gone:
		_blips.erase(id)
	return gone.size()


## Blips `viewer_team` may see, as [{id, team, pos, alpha}] sorted by id. Own team is always shown; others only while within their ttl (a stale hostile is hidden, not faded, once past it).
func visible(viewer_team: int, now: float) -> Array:
	var out: Array = []
	var ids := _blips.keys()
	ids.sort()
	for id: StringName in ids:
		var b: Dictionary = _blips[id]
		var age := now - float(b["seen"])
		if int(b["team"]) != viewer_team and _ttl > 0.0 and age > _ttl:
			continue
		out.append({"id": id, "team": b["team"], "pos": b["pos"], "alpha": _alpha(age, int(b["team"]) == viewer_team)})
	return out


func _alpha(age: float, own: bool) -> float:
	if own or _ttl <= 0.0 or _fade <= 0.0:
		return 1.0
	var fade_start := _ttl - _fade
	if age <= fade_start:
		return 1.0
	return clampf(1.0 - (age - fade_start) / _fade, 0.0, 1.0)
