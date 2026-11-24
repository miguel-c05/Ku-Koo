@tool
class_name FlySwarm
extends Node2D
## A few flies looping around something (the hanging animals). Uses the fly
## art when given, otherwise little dots.

@export var texture: Texture2D
@export var count: int = 5
@export var area: Vector2 = Vector2(60, 30)
@export var fly_scale: float = 0.07
@export var speed: float = 1.0

var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta * speed
	queue_redraw()


func _draw() -> void:
	for i in count:
		var phase := _t * (2.0 + i * 0.37) + i * 1.7
		var p := Vector2(cos(phase) * area.x * 0.5, sin(phase * 1.3) * area.y * 0.5)
		if texture:
			var flutter := 1.0 + 0.25 * sin(_t * 40.0 + i)
			var size := texture.get_size() * fly_scale * Vector2(1.0, flutter)
			var flip := 1.0 if cos(phase) < 0.0 else -1.0
			draw_set_transform(p, 0.0, Vector2(flip, 1.0))
			draw_texture_rect(texture, Rect2(-size * 0.5, size), false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_circle(p, 1.0, Color(0.05, 0.05, 0.05, 0.9))
