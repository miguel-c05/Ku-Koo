@tool
class_name IsoPushableBody
extends PushableBody
## Top-down version of [PushableBody]: a box the pigeon grips and pushes or
## pulls in any direction on the floor. It is also an iso solid, so once in
## place the pigeon can hop on top of it. Origin = centre of the footprint.

@export var grid_size: Vector2 = Vector2(0.7, 0.7):
	set(value):
		grid_size = value
		_update_shape()
		queue_redraw()
@export var iso_height: float = 24.0:
	set(value):
		iso_height = value
		queue_redraw()
@export var color: Color = Color(0.55, 0.37, 0.2):
	set(value):
		color = value
		queue_redraw()
@export var show_placeholder: bool = true

var _shape_node: CollisionShape2D


func _ready() -> void:
	_shape_node = CollisionShape2D.new()
	_shape_node.shape = ConvexPolygonShape2D.new()
	add_child(_shape_node, false, Node.INTERNAL_MODE_FRONT)
	_update_shape()


func _update_shape() -> void:
	if _shape_node:
		(_shape_node.shape as ConvexPolygonShape2D).points = IsoMath.footprint(grid_size)


func _physics_process(_delta: float) -> void:
	pass  # no gravity on the floor plane


func get_iso_height() -> float:
	return iso_height


func get_iso_base() -> float:
	return 0.0


## Moves on the floor, stopping at any solid. Returns the motion applied.
func slide_vec(motion: Vector2) -> Vector2:
	var exclude: Array[RID] = [get_rid()]
	var allowed := IsoMath.resolve_motion(self, _shape_node.shape, global_position, motion, 0.5, exclude)
	global_position += allowed
	return allowed


func slide_by(dx: float) -> float:
	return slide_vec(Vector2(dx, 0)).x


func _draw() -> void:
	if not show_placeholder:
		return
	var fp := IsoMath.footprint(grid_size)
	IsoMath.draw_prism(self, fp, iso_height, color.lightened(0.15), color, color.darkened(0.25))
	# Crate cross on the visible faces.
	var up := Vector2(0, -iso_height)
	var line := color.darkened(0.45)
	draw_line(fp[2], fp[1] + up, line, 1.0)
	draw_line(fp[1], fp[2] + up, line, 1.0)
	draw_line(fp[2], fp[3] + up, line, 1.0)
	draw_line(fp[3], fp[2] + up, line, 1.0)
