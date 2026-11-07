class_name CooRing
extends Node2D
## Placeholder visual for the coo: an expanding ring showing how far it carries.
## Will be removed or replaced by a subtle effect once real audio is in.

@export var color: Color = Color(1.0, 0.95, 0.8, 0.55)
@export var duration: float = 0.7
@export var width: float = 1.5

var _radius: float = 0.0
var _alpha: float = 0.0


func play(max_radius: float) -> void:
	var tween := create_tween().set_parallel()
	_radius = 4.0
	_alpha = 1.0
	tween.tween_property(self, "_radius", max_radius, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_alpha", 0.0, duration)


func _process(_delta: float) -> void:
	if _alpha > 0.0:
		queue_redraw()


func _draw() -> void:
	if _alpha <= 0.0:
		return
	var c := color
	c.a *= _alpha
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, c, width)
