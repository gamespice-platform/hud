class_name GSHudSpread
extends RefCounted

## The crosshair's spread as a number from 0 (still) to 1 (wide open): a shot kicks it, movement holds it, and it recovers with a half life. The view turns it into pixels through [method gap].

## Current spread, 0 to 1.
var value: float = 0.0


## One shot's kick.
func kick(cfg: GSHudConfig) -> void:
	value = minf(value + cfg.crosshair_kick, 1.0)


## Advances by [param delta]. [param floor_value] (0 to 1) is the spread movement or a stance keeps up; the spread never recovers below it.
func step(cfg: GSHudConfig, delta: float, floor_value: float = 0.0) -> void:
	var target := clampf(floor_value, 0.0, 1.0)
	if value <= target:
		value = target
		return
	var k := 1.0 if cfg.crosshair_recover <= 0.0 else 1.0 - pow(0.5, maxf(delta, 0.0) / cfg.crosshair_recover)
	value = lerpf(value, target, k)
	if value - target < 0.001:
		value = target


## True while the spread is moving, so a view can stop redrawing when it is not.
func settled(floor_value: float = 0.0) -> bool:
	return is_equal_approx(value, clampf(floor_value, 0.0, 1.0))


## Pixels from the centre to each tick.
func gap(cfg: GSHudConfig) -> float:
	return cfg.crosshair_gap + cfg.crosshair_spread_px * value
