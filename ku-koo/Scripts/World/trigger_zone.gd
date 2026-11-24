@tool
class_name TriggerZone
extends Area2D
## Emits [signal pigeon_entered] when the pigeon walks in (level exits,
## one-off events). Origin = bottom centre.

signal pigeon_entered(pigeon: Pigeon)

@export var zone_size: Vector2 = Vector2(60, 60):
	set(value):
		zone_size = value
		queue_redraw()
@export var one_shot: bool = true

var _fired: bool = false


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = zone_size
	shape.shape = rect
	shape.position = Vector2(0, -zone_size.y * 0.5)
	add_child(shape, false, Node.INTERNAL_MODE_FRONT)
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Pigeon and not (one_shot and _fired):
		_fired = true
		pigeon_entered.emit(body)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2(-zone_size.x * 0.5, -zone_size.y), zone_size), Color(0.4, 1, 0.5, 0.15))
