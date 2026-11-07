class_name PeckAbility
extends Node
## Peck: acts on the nearest [Interactable] in front of the beak.
##   - Gripping something  -> pecking lets go.
##   - Carrying something  -> gives it to a receiver in reach, otherwise drops it.
##   - Otherwise           -> interacts with the focused object (pick up,
##                            break, pull a pin, grip...). With nothing in reach
##                            the pigeon simply pecks the ground.

signal focus_changed(interactable: Interactable)

@export var cooldown: float = 0.3
## How long the pigeon stays planted on the ground while pecking.
@export var lock_time: float = 0.22

var focused: Interactable = null

var _cooldown_left: float = 0.0

@onready var pigeon: Pigeon = get_parent() as Pigeon


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_update_focus()


func try_peck() -> bool:
	if _cooldown_left > 0.0:
		return false
	_cooldown_left = cooldown
	pigeon.lock(lock_time, Pigeon.State.PECK)
	pigeon.action.emit(&"peck")

	var hold := pigeon.hold
	if hold.is_grabbing():
		hold.release()
		return true

	_update_focus()
	if focused:
		focused.interact(pigeon)
		pigeon.action.emit(&"peck_hit")
		_update_focus()
	elif hold.is_carrying():
		hold.drop()
	return true


func _update_focus() -> void:
	var best: Interactable = null
	var best_dist := INF
	var beak := pigeon.beak_area.global_position
	for area in pigeon.beak_area.get_overlapping_areas():
		var candidate := area as Interactable
		if candidate == null or not candidate.can_interact(pigeon):
			continue
		var dist := beak.distance_squared_to(candidate.global_position)
		if dist < best_dist:
			best = candidate
			best_dist = dist
	if best == focused:
		return
	if is_instance_valid(focused):
		focused.set_focused(false)
	focused = best
	if focused:
		focused.set_focused(true)
	focus_changed.emit(focused)
