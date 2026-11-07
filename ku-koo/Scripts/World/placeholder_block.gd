@tool
class_name PlaceholderBlock
extends AnimatableBody2D
## Solid level geometry drawn as a coloured rectangle (ground, ledges, sills,
## walls, gates). Origin = TOP-LEFT corner, so levels can be laid out by
## coordinates. It is an AnimatableBody2D so it can also be moved (gates).
##
## To replace with art: add a Sprite2D child and untick [member show_placeholder].

@export var size: Vector2 = Vector2(64, 32):
	set(value):
		size = value
		_update_shape()
		queue_redraw()
@export var color: Color = Color(0.36, 0.33, 0.3):
	set(value):
		color = value
		queue_redraw()
@export var show_placeholder: bool = true:
	set(value):
		show_placeholder = value
		queue_redraw()
## Thin lighter line on top, so walkable surfaces read clearly.
@export var top_highlight: bool = true

var _shape_node: CollisionShape2D


func _ready() -> void:
	_shape_node = CollisionShape2D.new()
	_shape_node.shape = RectangleShape2D.new()
	add_child(_shape_node, false, Node.INTERNAL_MODE_FRONT)
	_update_shape()


func _update_shape() -> void:
	if _shape_node == null:
		return
	(_shape_node.shape as RectangleShape2D).size = size
	_shape_node.position = size * 0.5


## Turns collision on/off (e.g. an obstacle that goes away).
func set_solid(value: bool) -> void:
	_shape_node.set_deferred(&"disabled", not value)


func _draw() -> void:
	if not show_placeholder:
		return
	draw_rect(Rect2(Vector2.ZERO, size), color)
	if top_highlight:
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, minf(2.0, size.y))), color.lightened(0.25))
