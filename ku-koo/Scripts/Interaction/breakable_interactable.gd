@tool
class_name BreakableInteractable
extends Interactable
## Peck it N times to break it (strings, threads, thin ropes).
## Wire [signal broken] to whatever should happen (hide the string, release
## the hanging item, play a sound...).

signal hit(pecks_left: int)
signal broken

@export var pecks_to_break: int = 2

var _hits: int = 0


func _init() -> void:
	prompt = "bicar o fio"


func _interact(_pigeon: Pigeon) -> void:
	_hits += 1
	if _hits < pecks_to_break:
		hit.emit(pecks_to_break - _hits)
		return
	enabled = false
	broken.emit()
