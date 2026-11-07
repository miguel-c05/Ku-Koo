@tool
class_name CooListener
extends Node2D
## Makes its parent react to the pigeon's coo. Wire [signal heard] in the
## editor (a person turns to look, a leaf trembles, the partner answers...).

signal heard(pigeon: Pigeon)

@export var enabled: bool = true
## Hears every coo regardless of distance (the partner, far away at home).
@export var hears_from_anywhere: bool = false
## Added to the coo's own radius (sharp-eared listeners).
@export var hearing_bonus: float = 0.0
@export var reaction_delay: float = 0.0
@export var one_shot: bool = false


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group(&"coo_listeners")


func try_hear(pigeon: Pigeon, origin: Vector2, radius: float) -> bool:
	if not enabled:
		return false
	if not hears_from_anywhere and global_position.distance_to(origin) > radius + hearing_bonus:
		return false
	if one_shot:
		enabled = false
	_react(pigeon)
	return true


func _react(pigeon: Pigeon) -> void:
	if reaction_delay > 0.0:
		await get_tree().create_timer(reaction_delay).timeout
	if is_instance_valid(pigeon):
		heard.emit(pigeon)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, 3.0, Color(0.5, 0.8, 1.0))
