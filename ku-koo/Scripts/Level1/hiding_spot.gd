@tool
class_name HidingSpot
extends Area2D
## Behind something (the bucket) or in deep shadow: the pigeon cannot be seen
## here, even inside a [LightZone]. Origin = bottom centre.
## The pigeon stands between the cover and the camera (the cover shields it from
## the room beyond) and is shaded while it hides.

@export var size: Vector2 = Vector2(44, 40):
	set(value):
		size = value
		_update_shape()
		queue_redraw()
## Tint of the hidden pigeon (in the cover's shadow).
@export var hidden_tint: Color = Color(0.5, 0.5, 0.58)

var _shape_node: CollisionShape2D


func _ready() -> void:
	_shape_node = CollisionShape2D.new()
	_shape_node.shape = RectangleShape2D.new()
	add_child(_shape_node, false, Node.INTERNAL_MODE_FRONT)
	_update_shape()
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	add_to_group(&"hiding_spots")
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)


func _update_shape() -> void:
	if _shape_node:
		(_shape_node.shape as RectangleShape2D).size = size
		_shape_node.position = Vector2(0, -size.y * 0.5)


func _on_body_entered(body: Node2D) -> void:
	if body is Pigeon:
		_tint(body, hidden_tint)


func _on_body_exited(body: Node2D) -> void:
	if body is Pigeon:
		_tint(body, Color.WHITE)


func _tint(body: Node2D, color: Color) -> void:
	var visuals := body.get_node_or_null(^"Visuals") as CanvasItem
	if visuals:
		create_tween().tween_property(visuals, "modulate", color, 0.25)


func contains(body: Node2D) -> bool:
	return overlaps_body(body)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2(-size.x * 0.5, -size.y), size), Color(0.3, 0.5, 1.0, 0.2))
