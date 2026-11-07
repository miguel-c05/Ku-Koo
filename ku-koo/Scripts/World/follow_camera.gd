class_name FollowCamera
extends Camera2D
## Follows the pigeon with a little look-ahead; W / S look up and down.
## Kept outside the pigeon scene so cinematics can take it over later.

@export var target: Node2D
@export var look_ahead: float = 30.0
@export var vertical_bias: float = -30.0
@export var look_distance: float = 70.0
@export var follow_sharpness: float = 6.0
## When false the camera stays where it is (for cinematics).
@export var following: bool = true


func _ready() -> void:
	make_current()
	if target:
		global_position = _desired_position()
	reset_smoothing()


func _physics_process(delta: float) -> void:
	if not following or target == null:
		return
	var weight := 1.0 - exp(-follow_sharpness * delta)
	global_position = global_position.lerp(_desired_position(), weight)


func _desired_position() -> Vector2:
	var p := target.global_position + Vector2(0, vertical_bias)
	var pigeon := target as Pigeon
	if pigeon:
		p.x += pigeon.facing * look_ahead
		p.y += pigeon.look * look_distance
	return p
