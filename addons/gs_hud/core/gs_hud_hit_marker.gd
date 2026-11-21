class_name GSHudHitMarker
extends RefCounted

## When a hit marker shows and how strongly. Flash it only for a hit the server confirmed: a marker from local prediction says hit for shots the server then refuses.
##
## A later non-lethal hit does not turn a fresh kill marker back to a plain hit: a shotgun's pellets land after the lethal one and the kill is the news.

var kill: bool = false
var headshot: bool = false
var _born: float = -1000.0
var _life: float = 0.0


## Starts the marker at [param now].
func flash(cfg: GSHudConfig, now: float, p_kill: bool = false, p_headshot: bool = false) -> void:
	if kill and not p_kill and now - _born < _life * 0.5:
		return
	kill = p_kill
	headshot = p_headshot
	_born = now
	_life = cfg.marker_kill_sec if p_kill else cfg.marker_hit_sec


## 1 as it flashes, 0 when it is gone.
func alpha(now: float) -> float:
	if _life <= 0.0:
		return 0.0
	return clampf(1.0 - (now - _born) / _life, 0.0, 1.0)


func active(now: float) -> bool:
	return alpha(now) > 0.0
