class_name Trembler
extends Node
## Small shake feedback (a leaf trembling on a coo, a string hit by a peck).
## Connect any signal to [method tremble].

## Defaults to the parent.
@export var target: Node2D
@export var strength: float = 1.5
@export var duration: float = 0.45

var _rest: Vector2
var _tween: Tween


func _ready() -> void:
	if target == null:
		target = get_parent() as Node2D
	_rest = target.position


func tremble(_arg1: Variant = null, _arg2: Variant = null) -> void:
	if _tween:
		_tween.kill()
	target.position = _rest
	_tween = create_tween()
	var steps := 8
	for i in steps:
		var falloff := 1.0 - float(i) / steps
		var jitter := Vector2(randf_range(-1, 1), randf_range(-0.5, 0.5)) * strength * falloff
		_tween.tween_property(target, "position", _rest + jitter, duration / steps)
	_tween.tween_property(target, "position", _rest, 0.03)
