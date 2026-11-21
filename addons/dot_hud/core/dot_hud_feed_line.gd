class_name GSHudFeedLine
extends RefCounted

## One line of a [GSHudFeed]: fragments with a colour each (a kill is two names in team colours around a weapon) and the time it was pushed. Pooled by the feed, never freed.

var texts := PackedStringArray()
var colours := PackedColorArray()
var born: float = 0.0


## The fragments joined, for a log or a screen reader.
func plain() -> String:
	return "".join(texts)
