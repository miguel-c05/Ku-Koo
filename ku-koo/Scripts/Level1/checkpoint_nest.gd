@tool
class_name CheckpointNest
extends Area2D
## An old pigeon nest: the checkpoint for the whole game. Passing it makes
## it the place the pigeon returns to when caught. Origin = where the pigeon
## stands (bottom centre). Placeholder: a drawn nest; real art as a Sprite2D child.

signal reached(nest: CheckpointNest)

@export var zone_size: Vector2 = Vector2(60, 50)
## Moves the trigger zone (e.g. down to the floor under a shelf, so walking
## past the nest counts).
@export var zone_offset: Vector2 = Vector2.ZERO
@export var show_placeholder: bool = true
## Nest art (drawn centred on the origin, sitting on the surface).
@export var texture: Texture2D
@export var texture_scale: float = 0.12

var is_active: bool = false


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = zone_size
	shape.shape = rect
	shape.position = Vector2(0, -zone_size.y * 0.5) + zone_offset
	add_child(shape, false, Node.INTERNAL_MODE_FRONT)
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func get_spawn_position() -> Vector2:
	return global_position + Vector2(0, -1)


func set_active(value: bool) -> void:
	is_active = value
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is Pigeon:
		reached.emit(self)


func _draw() -> void:
	if texture:
		var size := texture.get_size() * texture_scale
		draw_texture_rect(texture, Rect2(Vector2(-size.x * 0.5, -size.y * 0.8), size), false)
		if is_active:
			draw_circle(Vector2(0, -size.y - 4), 2.0, Color(1, 0.9, 0.6, 0.8))
		return
	if not show_placeholder:
		return
	var twig := Color(0.45, 0.33, 0.2)
	draw_colored_polygon(PackedVector2Array([Vector2(-18, -2), Vector2(18, -2), Vector2(13, -9), Vector2(-13, -9)]), twig)
	for i in 5:
		var x := -15.0 + i * 7.5
		draw_line(Vector2(x, -9), Vector2(x + 6, -1), twig.lightened(0.2), 1.0)
	if is_active:
		draw_circle(Vector2(0, -16), 2.0, Color(1, 0.9, 0.6, 0.8))
