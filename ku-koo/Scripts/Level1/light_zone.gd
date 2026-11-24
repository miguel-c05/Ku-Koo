@tool
class_name LightZone
extends Area2D
## Lit floor (the warm light spilling from the workroom doorway). The hunter
## only sees the pigeon while it stands in a LightZone and is not inside a
## [HidingSpot]. Origin = bottom-left of the lit floor.

@export var size: Vector2 = Vector2(160, 60):
	set(value):
		size = value
		_update_shape()
		queue_redraw()
## Where the light comes from (relative), for the placeholder glow.
@export var source: Rect2 = Rect2(10, -230, 140, 230):
	set(value):
		source = value
		queue_redraw()
@export var color: Color = Color(1.0, 0.72, 0.38, 0.22):
	set(value):
		color = value
		queue_redraw()
## Art for the pool of light on the floor (e.g. Warm_Light_Pool). Without it a
## placeholder beam is drawn. Frames are cycled for a slow flicker.
@export var pool_frames: Array[Texture2D] = []:
	set(value):
		pool_frames = value
		queue_redraw()
@export var pool_rect: Rect2 = Rect2(-40, -120, 240, 150):
	set(value):
		pool_rect = value
		queue_redraw()
@export var pool_fps: float = 3.0
## The hunter that watches this light (Hunter.zone_group).
@export var zone_group: StringName = &"light_zones"

var _frame: int = 0
var _t: float = 0.0

var _shape_node: CollisionShape2D


func _ready() -> void:
	_shape_node = CollisionShape2D.new()
	_shape_node.shape = RectangleShape2D.new()
	add_child(_shape_node, false, Node.INTERNAL_MODE_FRONT)
	_update_shape()
	collision_layer = 0
	collision_mask = 2  # pigeon
	monitorable = false
	add_to_group(zone_group)


func _update_shape() -> void:
	if _shape_node:
		(_shape_node.shape as RectangleShape2D).size = size
		_shape_node.position = Vector2(size.x * 0.5, -size.y * 0.5)


func contains(body: Node2D) -> bool:
	return overlaps_body(body)


func _process(delta: float) -> void:
	if pool_frames.size() > 1 and not Engine.is_editor_hint():
		_t += delta
		if _t >= 1.0 / pool_fps:
			_t = 0.0
			_frame = (_frame + 1) % pool_frames.size()
			queue_redraw()


func _draw() -> void:
	if not pool_frames.is_empty():
		draw_texture_rect(pool_frames[_frame % pool_frames.size()], pool_rect, false, Color(1, 1, 1, color.a * 4.0))
		return
	# Beam from the doorway down onto the floor, then the pool on the floor.
	var beam := color
	beam.a *= 0.6
	draw_colored_polygon(PackedVector2Array([
		source.position, source.position + Vector2(source.size.x, 0),
		Vector2(size.x, 0), Vector2(0, 0)]), beam)
	draw_rect(Rect2(Vector2(0, -6), Vector2(size.x, 6)), color * Color(1, 1, 1, 1.6))
