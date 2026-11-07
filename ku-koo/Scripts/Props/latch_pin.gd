class_name LatchPin
extends Node2D
## A pin/latch the pigeon pecks out. Exposes a single [signal opened] signal
## so the level can connect it to a gate, a tailgate, a cage...

signal opened

@export var toggle: ToggleInteractable


func _ready() -> void:
	toggle.switched_on.connect(opened.emit)
