class_name ForegroundSway
extends Node2D
## Something hanging close to the camera (a rabbit on a hook): swings gently
## around its origin (the hook). Put the art as a child hanging below it.

@export var amplitude_degrees: float = 3.0
@export var period: float = 3.6
@export var phase: float = 0.0

var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	rotation = deg_to_rad(amplitude_degrees) * sin(TAU * _t / period + phase)
