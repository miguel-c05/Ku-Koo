class_name IsoMath
extends RefCounted
## Helpers for the isometric (top-down, Hades-like) view.
##
## Grid coordinates (gx, gy) are tiles on the floor; [method to_screen]
## projects them to 2:1 isometric screen space. Solid things ("iso solids")
## are physics bodies with a footprint on the floor plus a height, exposed via
## get_iso_height(). Height is resolved in code (not by physics), so the
## pigeon can hop over low things and stand on top of others.

const TILE := Vector2(64, 32)
## Physics layers that hold iso solids: 1 world, 3 props.
const SOLID_MASK := 1 | 4


static func to_screen(grid: Vector2) -> Vector2:
	return Vector2((grid.x - grid.y) * TILE.x * 0.5, (grid.x + grid.y) * TILE.y * 0.5)


static func to_grid(screen: Vector2) -> Vector2:
	var a := screen.x / (TILE.x * 0.5)
	var b := screen.y / (TILE.y * 0.5)
	return Vector2((a + b) * 0.5, (b - a) * 0.5)


## Footprint of a [param size]-tile box, relative to its CENTRE, which is
## the node origin used for depth sorting (y-sort). Keep solids at about
## 1 tile (split long walls) so sorting by centre stays correct.
## Order: back, right, front, left.
static func footprint(size: Vector2) -> PackedVector2Array:
	var center := to_screen(size * 0.5)
	return PackedVector2Array([
		to_screen(Vector2.ZERO) - center,
		to_screen(Vector2(size.x, 0)) - center,
		to_screen(size) - center,
		to_screen(Vector2(0, size.y)) - center,
	])


## Draws a box: the two faces facing the viewer and the top.
static func draw_prism(ci: CanvasItem, fp: PackedVector2Array, height: float,
		top: Color, left: Color, right: Color) -> void:
	var up := Vector2(0, -height)
	if height > 0.01:
		ci.draw_colored_polygon(PackedVector2Array([fp[1], fp[2], fp[2] + up, fp[1] + up]), right)
		ci.draw_colored_polygon(PackedVector2Array([fp[2], fp[3], fp[3] + up, fp[2] + up]), left)
	var top_poly := PackedVector2Array([fp[0] + up, fp[1] + up, fp[2] + up, fp[3] + up])
	ci.draw_colored_polygon(top_poly, top)
	var edge := top.lightened(0.25)
	ci.draw_polyline(PackedVector2Array([fp[3] + up, fp[2] + up, fp[1] + up]), edge, 1.0)


static func solid_height(collider: Object) -> float:
	if collider and collider.has_method(&"get_iso_height"):
		return collider.call(&"get_iso_height")
	return 0.0


## Height of the highest solid under [param point] (0 = floor).
static func surface_height_at(ci: CanvasItem, point: Vector2, exclude: Array[RID] = [],
		mask: int = SOLID_MASK) -> float:
	return surface_at(ci, point, exclude, mask).height


## Highest solid under [param point]: {height, node} (node = null on the floor).
static func surface_at(ci: CanvasItem, point: Vector2, exclude: Array[RID] = [],
		mask: int = SOLID_MASK) -> Dictionary:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collision_mask = mask
	query.exclude = exclude
	var best := 0.0
	var node: Node2D = null
	for hit in ci.get_world_2d().direct_space_state.intersect_point(query, 16):
		var h := solid_height(hit.collider)
		if h > best:
			best = h
			node = hit.collider as Node2D
	return {"height": best, "node": node}


## Draw-order key for something standing on [param support] (or the floor):
## always in front of what it stands on.
static func depth_on(position: Vector2, support: Node2D) -> float:
	if support and is_instance_valid(support):
		return maxf(position.y, support.global_position.y + 1.0)
	return position.y


## True if a [param shape] placed at [param at] overlaps any solid taller
## than [param max_height].
static func is_blocked(ci: CanvasItem, shape: Shape2D, at: Vector2, max_height: float,
		exclude: Array[RID] = [], mask: int = SOLID_MASK) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, at)
	query.collision_mask = mask
	query.exclude = exclude
	for hit in ci.get_world_2d().direct_space_state.intersect_shape(query, 16):
		if solid_height(hit.collider) > max_height:
			return true
	return false


## Moves [param motion] axis by axis, dropping the axes that would end up blocked.
static func resolve_motion(ci: CanvasItem, shape: Shape2D, from: Vector2, motion: Vector2,
		max_height: float, exclude: Array[RID] = []) -> Vector2:
	var allowed := Vector2.ZERO
	if not is_zero_approx(motion.x) and not is_blocked(ci, shape, from + Vector2(motion.x, 0), max_height, exclude):
		allowed.x = motion.x
	if not is_zero_approx(motion.y) and not is_blocked(ci, shape, from + Vector2(allowed.x, motion.y), max_height, exclude):
		allowed.y = motion.y
	return allowed
