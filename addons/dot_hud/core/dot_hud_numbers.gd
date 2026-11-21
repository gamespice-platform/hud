class_name DotHudNumbers
extends RefCounted

## Floating damage numbers as a model: hits on one victim within `number_merge` seconds add into one number, a headshot flags it, a deterministic drift keeps stacked numbers apart. Nothing is drawn here; a view reads [method at] and [method progress]. Pooled, so after warm-up an add allocates nothing.

var _cfg: DotHudConfig
var _live: Array[DotHudNumber] = []
var _pool: Array[DotHudNumber] = []
var _seed: int = 0


func _init(cfg: DotHudConfig = null) -> void:
	_cfg = cfg if cfg != null else DotHudConfig.new()


## A hit of [param amount] on [param victim] at world point [param at]. Returns the number it landed in. Past `number_limit` the oldest number is dropped.
func add(victim: int, amount: float, at: Vector3, headshot: bool, now: float) -> DotHudNumber:
	if _cfg.number_merge > 0.0:
		for n in _live:
			if n.victim == victim and now - n.born < _cfg.number_merge:
				n.amount += amount
				n.at = at
				n.headshot = n.headshot or headshot
				n.born = now
				return n
	if _cfg.number_limit > 0:
		while _live.size() >= _cfg.number_limit:
			_pool.append(_live.pop_front())
	var n: DotHudNumber = _pool.pop_back() if not _pool.is_empty() else DotHudNumber.new()
	_seed += 1
	n.victim = victim
	n.amount = amount
	n.at = at
	n.headshot = headshot
	n.born = now
	n.drift = float((_seed * 37) % 7 - 3) * 9.0
	_live.append(n)
	return n


## Drops numbers past `number_ttl` and returns how many went.
func expire(now: float) -> int:
	var kept := 0
	var dropped := 0
	for i in _live.size():
		var n := _live[i]
		if now - n.born >= _cfg.number_ttl:
			_pool.append(n)
			dropped += 1
		else:
			_live[kept] = n
			kept += 1
	_live.resize(kept)
	return dropped


## 0 as the number appears, 1 as it is gone: drive rise and fade from it.
func progress(n: DotHudNumber, now: float) -> float:
	return clampf((now - n.born) / _cfg.number_ttl, 0.0, 1.0)


func size() -> int:
	return _live.size()


func at(i: int) -> DotHudNumber:
	return _live[i]


func clear() -> void:
	_pool.append_array(_live)
	_live.clear()
