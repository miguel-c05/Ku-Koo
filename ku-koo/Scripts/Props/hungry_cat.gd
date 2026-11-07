class_name HungryCat
extends Node2D
## The hungry cat in the alley. Blocks the way until it is given food,
## then eats and jumps away. Reacts to the coo.

signal fed

@export var blocker: PlaceholderBlock
@export var sprite: Sprite2D
@export var bubble: SpeechBubble
@export var eat_sound: EventSound
@export var meow_sound: EventSound
## Where it goes after eating (relative to its start).
@export var leave_offset: Vector2 = Vector2(80, -100)
@export var hungry_lines: PackedStringArray = ["miau...", "MIAU!", "miau?"]

var is_fed: bool = false

var _line: int = 0


func feed(_item: Variant = null) -> void:
	if is_fed:
		return
	is_fed = true
	bubble.say("nham nham!", 1.6)
	if eat_sound:
		eat_sound.play_event()
	blocker.set_solid(false)
	fed.emit()
	var tween := create_tween()
	tween.tween_interval(1.4)
	tween.tween_property(self, "position", position + Vector2(leave_offset.x * 0.5, leave_offset.y - 30), 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", position + leave_offset, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(bubble.say.bind("prrr", 1.5))


func hear_coo(pigeon: Pigeon = null) -> void:
	if pigeon and sprite:
		sprite.flip_h = pigeon.global_position.x < global_position.x
	if is_fed:
		bubble.say("prrr")
		return
	bubble.say(hungry_lines[_line % hungry_lines.size()])
	_line += 1
	if meow_sound:
		meow_sound.play_event()
