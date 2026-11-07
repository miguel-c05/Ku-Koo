@tool
class_name ToggleInteractable
extends Interactable
## Pins, latches, levers, things pushed aside: each peck flips it.
## Wire [signal switched_on] / [signal switched_off] in the editor.

signal toggled(is_on: bool)
signal switched_on
signal switched_off

@export var is_on: bool = false
## Can only be used once (a pin pulled out stays out).
@export var one_shot: bool = true


func _init() -> void:
	prompt = "puxar"


func _interact(_pigeon: Pigeon) -> void:
	is_on = not is_on
	toggled.emit(is_on)
	if is_on:
		switched_on.emit()
	else:
		switched_off.emit()
	if one_shot:
		enabled = false
