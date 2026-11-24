@tool
class_name PlaceholderDecor
extends Node2D
## Non-solid placeholder scenery drawn in code: hanging animals, flies, light
## shafts, coats, doors... Pick a [member kind]. Replace with a Sprite2D or an
## AnimatedSprite2D and delete the node when the art arrives.

enum Kind { RECT, HANGING_ANIMAL, FLIES, LIGHT_SHAFT }

@export var kind: Kind = Kind.RECT:
	set(value):
		kind = value
		queue_redraw()
@export var size: Vector2 = Vector2(30, 40):
	set(value):
		size = value
		queue_redraw()
@export var color: Color = Color(0.4, 0.35, 0.3):
	set(value):
		color = value
		queue_redraw()
## HANGING_ANIMAL: rope length from the origin (the hook) to the body.
@export var rope: float = 40.0:
	set(value):
		rope = value
		queue_redraw()
## LIGHT_SHAFT: width of the beam where it lands (size = source width × height).
@export var spread: float = 120.0:
	set(value):
		spread = value
		queue_redraw()
@export var sway: float = 0.03

var _t: float = 0.0


func _ready() -> void:
	_t = randf() * 10.0


func _process(delta: float) -> void:
	if kind == Kind.HANGING_ANIMAL or kind == Kind.FLIES:
		_t += delta
		queue_redraw()


func _draw() -> void:
	match kind:
		Kind.RECT:
			draw_rect(Rect2(Vector2(-size.x * 0.5, -size.y), size), color)
		Kind.HANGING_ANIMAL:
			var a := sin(_t * 1.3) * sway
			var end := Vector2(0, rope).rotated(a)
			draw_line(Vector2.ZERO, end, Color(0.6, 0.53, 0.4), 1.0)
			draw_circle(Vector2.ZERO, 1.5, Color(0.5, 0.5, 0.52))
			draw_set_transform(end, a, Vector2.ONE)
			draw_rect(Rect2(-size.x * 0.5, 0, size.x, size.y), color)
			draw_rect(Rect2(-size.x * 0.25, size.y, size.x * 0.5, size.y * 0.25), color.darkened(0.25))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		Kind.FLIES:
			for i in 5:
				var phase := _t * (2.0 + i * 0.37) + i * 1.7
				var p := Vector2(cos(phase) * size.x * 0.5, sin(phase * 1.3) * size.y * 0.5)
				draw_circle(p, 1.0, Color(0.05, 0.05, 0.05, 0.9))
		Kind.LIGHT_SHAFT:
			draw_colored_polygon(PackedVector2Array([
				Vector2(-size.x * 0.5, 0), Vector2(size.x * 0.5, 0),
				Vector2(spread * 0.5, size.y), Vector2(-spread * 0.5, size.y)]), color)
