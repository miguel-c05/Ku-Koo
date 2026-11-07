class_name PartnerCall
extends Node2D
## The partner's coo. Placed at "home"; she is never seen in town, only heard.
## Calls now and then and answers the pigeon's coo. The AudioStreamPlayer2D
## pans it in stereo and makes it louder as the pigeon gets closer.

signal called(from_position: Vector2)

@export var voice: AudioStreamPlayer2D
@export var listener: CooListener
## Random seconds between spontaneous calls.
@export var call_interval: Vector2 = Vector2(9.0, 14.0)
@export var first_call_delay: float = 1.5

var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timer)
	if listener:
		listener.heard.connect(_on_heard)
	_timer.start(first_call_delay)


func call_out() -> void:
	if voice:
		voice.play()
	called.emit(global_position)


func _on_timer() -> void:
	call_out()
	_timer.start(randf_range(call_interval.x, call_interval.y))


func _on_heard(_pigeon: Pigeon) -> void:
	call_out()
	_timer.start(randf_range(call_interval.x, call_interval.y))
