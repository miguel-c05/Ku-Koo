class_name PushableBody
extends CharacterBody2D
## A light object the pigeon can grip and push/pull (crate, stool, clog,
## basket). It is solid, so once in place it becomes a step to climb.
## Needs a child [GrabInteractable]. Origin = bottom centre.

signal grabbed
signal released

@export var gravity: float = 980.0
@export var max_fall_speed: float = 450.0

var gripped_by: Pigeon = null


func _physics_process(delta: float) -> void:
	velocity.x = 0.0
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	move_and_slide()


## Moves horizontally, stopping at walls. Returns how far it really moved.
func slide_by(dx: float) -> float:
	if is_zero_approx(dx):
		return 0.0
	var start := global_position.x
	move_and_collide(Vector2(dx, 0.0))
	return global_position.x - start


func on_grabbed(pigeon: Pigeon) -> void:
	gripped_by = pigeon
	add_collision_exception_with(pigeon)
	grabbed.emit()


func on_released(pigeon: Pigeon) -> void:
	if is_instance_valid(pigeon):
		remove_collision_exception_with(pigeon)
	gripped_by = null
	released.emit()
