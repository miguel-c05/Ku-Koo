class_name CooAbility
extends Node
## Coo: the pigeon's only voice, and a tool.
## Every [CooListener] within [member hearing_radius] (or set to hear from
## anywhere, like the partner) reacts to it.

## Emitted on every coo, for presentation (e.g. the placeholder ring).
signal cooed(origin: Vector2, radius: float)

@export var hearing_radius: float = 240.0
@export var cooldown: float = 0.9
## How long the pigeon stays planted while cooing.
@export var lock_time: float = 0.7
@export var listener_group: StringName = &"coo_listeners"

var _cooldown_left: float = 0.0

@onready var pigeon: Pigeon = get_parent() as Pigeon


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func try_coo() -> bool:
	if _cooldown_left > 0.0:
		return false
	_cooldown_left = cooldown
	pigeon.lock(lock_time, Pigeon.State.COO)
	pigeon.action.emit(&"coo")
	var origin := pigeon.global_position
	cooed.emit(origin, hearing_radius)
	for node in get_tree().get_nodes_in_group(listener_group):
		var listener := node as CooListener
		if listener:
			listener.try_hear(pigeon, origin, hearing_radius)
	return true
