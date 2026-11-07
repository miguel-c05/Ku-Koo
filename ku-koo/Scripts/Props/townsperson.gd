class_name Townsperson
extends Node2D
## A background person who turns to look when the pigeon coos.

@export var sprite: Sprite2D
@export var bubble: SpeechBubble
@export var voice: EventSound
@export var lines: PackedStringArray = ["Hm?", "Um pombo?", "Coitado..."]

var _line: int = 0


func hear_coo(pigeon: Pigeon = null) -> void:
	if pigeon and sprite:
		# The placeholder face is drawn on the right side of the texture.
		sprite.flip_h = pigeon.global_position.x < global_position.x
	bubble.say(lines[_line % lines.size()], 1.5)
	_line += 1
	if voice:
		voice.play_event()
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", sprite.position.y - 3.0, 0.08)
	tween.tween_property(sprite, "position:y", sprite.position.y, 0.12)
