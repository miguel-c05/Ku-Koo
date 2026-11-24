class_name IsoShadow
extends Node2D
## Ground shadow (an ellipse). Essential in a top-down view: it shows where
## the pigeon will land while it is in the air. Shrinks with [member lift].

@export var radius: Vector2 = Vector2(11, 5)
@export var color: Color = Color(0, 0, 0, 0.35)
## Height above the surface (set by the owner every frame).
var lift: float = 0.0:
	set(value):
		lift = value
		queue_redraw()


func _draw() -> void:
	var k := clampf(1.0 - lift / 120.0, 0.45, 1.0)
	var c := color
	c.a *= k
	var points := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		points.append(Vector2(cos(a) * radius.x, sin(a) * radius.y) * k)
	draw_colored_polygon(points, c)
