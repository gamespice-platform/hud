class_name GSHudNumber
extends RefCounted

## One floating damage number of a [GSHudNumbers]: pooled, reused, never freed.

var victim: int = 0
var amount: float = 0.0
var at := Vector3.ZERO
var headshot: bool = false
var born: float = 0.0
## Deterministic sideways offset in pixels so two numbers on one body do not stack.
var drift: float = 0.0
var _label_amount: int = -1
var _label: String = ""


## The amount as drawn (rounded), rebuilt only when it changes (a merged hit), not every frame.
func label() -> String:
	var whole := int(roundf(amount))
	if whole != _label_amount:
		_label_amount = whole
		_label = str(whole)  # perf-lint: allow string_build cached, rebuilt only when the amount changes
	return _label
