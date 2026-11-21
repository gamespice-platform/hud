class_name DotHudRadar
extends RefCounted

## World to minimap projection on the ground plane (x and z). Pure maths: no nodes, no art. Yaw is rotation about +Y; at yaw 0 the player faces -Z, which is the top of a heading-up minimap.


## Projects `target` as seen from `origin`. Returns {pos: Vector2 in pixels from the minimap centre, inside: bool, distance: float}. Past the range the position is pinned to the edge (`inside` false) so the caller chooses to draw or hide it.
static func project(origin: Vector3, yaw: float, target: Vector3, world_range: float, radius_px: float, rotate: bool = true) -> Dictionary:
	var d := target - origin
	var flat := Vector2(d.x, d.z)
	if rotate:
		flat = flat.rotated(yaw)
	var dist := flat.length()
	var scaled := flat / world_range * radius_px
	var inside := dist <= world_range
	if not inside:
		scaled = flat.normalized() * radius_px
	return {"pos": scaled, "inside": inside, "distance": Vector2(d.x, d.z).length()}


## Heading of `target` from `origin` in degrees clockwise from the top of the minimap, 0..360.
static func bearing(origin: Vector3, yaw: float, target: Vector3, rotate: bool = true) -> float:
	var d := target - origin
	var flat := Vector2(d.x, d.z)
	if rotate:
		flat = flat.rotated(yaw)
	return fposmod(rad_to_deg(atan2(flat.x, -flat.y)), 360.0)
