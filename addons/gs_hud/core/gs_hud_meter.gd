class_name GSHudMeter
extends RefCounted

## A health or ammo bar as a model: the value, a smoothed value the bar shows, and a damage trail that waits and then drains. The bar reads [member shown] and [member trail]; this class draws nothing.

var value: float = 100.0
var max_value: float = 100.0
## What the bar's fill shows: eases toward [member value].
var shown: float = 100.0
## The pale trail behind the fill after a loss; falls to the value after `meter_trail_delay`.
var trail: float = 100.0
var _hold_until: float = 0.0


## Sets the real value and maximum. A drop restarts the trail's wait; a rise snaps the trail up.
func set_value(v: float, maximum: float, now: float, cfg: GSHudConfig) -> void:
	max_value = maxf(maximum, 0.0)
	v = clampf(v, 0.0, max_value)
	if v < value:
		_hold_until = now + cfg.meter_trail_delay
	elif v > trail:
		trail = v
	value = v


## Eases the shown value and drains the trail; call it only while [method settled] is false.
func step(cfg: GSHudConfig, delta: float, now: float) -> void:
	var k := 1.0 if cfg.meter_half_life <= 0.0 else 1.0 - pow(0.5, maxf(delta, 0.0) / cfg.meter_half_life)
	shown = lerpf(shown, value, k)
	if absf(shown - value) < max_value * 0.0005:
		shown = value
	if trail > value and (cfg.meter_trail_delay <= 0.0 or now >= _hold_until):
		trail = lerpf(trail, value, k)
		if trail - value < max_value * 0.0005:
			trail = value


func settled() -> bool:
	return shown == value and trail == value


## Fraction of the maximum, 0 to 1; 0 when the maximum is 0.
func fraction() -> float:
	return 0.0 if max_value <= 0.0 else value / max_value


func shown_fraction() -> float:
	return 0.0 if max_value <= 0.0 else shown / max_value


func trail_fraction() -> float:
	return 0.0 if max_value <= 0.0 else trail / max_value


## True under `meter_low` of the maximum.
func low(cfg: GSHudConfig) -> bool:
	return max_value > 0.0 and cfg.meter_low > 0.0 and fraction() < cfg.meter_low
