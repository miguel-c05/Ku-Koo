@tool
class_name RoomShade
extends Node2D
## Darkness over a part of the level the pigeon has left behind. Origin =
## top-left; the right edge fades out over [member feather] so it melts into
## the room the pigeon is in. Call [method darken] (any signal) to bring it in.

@export var size: Vector2 = Vector2(700, 410):
	set(value):
		size = value
		queue_redraw()
@export var feather: float = 60.0:
	set(value):
		feather = value
		queue_redraw()
@export var color: Color = Color(0.0, 0.0, 0.0, 0.88)
@export var fade_time: float = 1.6
## 0 = invisible, 1 = fully dark.
@export_range(0.0, 1.0) var amount: float = 0.0:
	set(value):
		amount = value
		queue_redraw()


func darken(_arg: Variant = null) -> void:
	create_tween().tween_property(self, "amount", 1.0, fade_time).set_trans(Tween.TRANS_SINE)


func _draw() -> void:
	var c := Color(color, color.a * amount)
	if Engine.is_editor_hint():
		c = Color(color, 0.25)
	var solid_w := maxf(size.x - feather, 0.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(solid_w, size.y)), c)
	var clear := Color(c, 0.0)
	draw_polygon(PackedVector2Array([Vector2(solid_w, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(solid_w, size.y)]),
		PackedColorArray([c, clear, clear, c]))
