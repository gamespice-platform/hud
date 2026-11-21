class_name DotHudNumber
extends RefCounted

## One floating damage number of a [DotHudNumbers]: pooled, reused, never freed.

var victim: int = 0
var amount: float = 0.0
var at := Vector3.ZERO
var headshot: bool = false
var born: float = 0.0
## Deterministic sideways offset in pixels so two numbers on one body do not stack.
var drift: float = 0.0
