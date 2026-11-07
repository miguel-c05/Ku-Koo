class_name SlideMover
extends Node
## Moves a node by [member offset] when activated (gate rising, pin pulled
## out, leaf pushed aside). Connect any signal to [method activate].

signal finished

## Defaults to the parent.
@export var target: Node2D
@export var offset: Vector2 = Vector2(0, -100)
@export var duration: float = 0.8
@export var transition: Tween.TransitionType = Tween.TRANS_SINE
@export var delay: float = 0.0

var active: bool = false

var _start: Vector2
var _tween: Tween


func _ready() -> void:
	if target == null:
		target = get_parent() as Node2D
	_start = target.position


func activate(_arg: Variant = null) -> void:
	set_active(true)


func deactivate(_arg: Variant = null) -> void:
	set_active(false)


func set_active(value: bool) -> void:
	if value == active:
		return
	active = value
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	if delay > 0.0:
		_tween.tween_interval(delay)
	_tween.tween_property(target, "position", _start + (offset if value else Vector2.ZERO), duration) \
		.set_trans(transition).set_ease(Tween.EASE_IN_OUT)
	_tween.finished.connect(finished.emit)
