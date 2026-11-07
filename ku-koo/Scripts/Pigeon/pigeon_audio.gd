class_name PigeonAudio
extends Node2D
## Plays the pigeon's sounds. Each [signal Pigeon.action] name is looked up
## in [member sound_bank]; to replace a sound, edit the SoundBank resource
## (res://Assets/Audios/pigeon_sound_bank.tres), not this script.

@export var pigeon: Pigeon
@export var sound_bank: SoundBank
@export var bus: StringName = &"Master"
## Simultaneous sounds (footsteps can overlap a coo, etc.).
@export var voices: int = 4

var _players: Array[AudioStreamPlayer2D] = []
var _next: int = 0


func _ready() -> void:
	if pigeon == null:
		pigeon = get_parent() as Pigeon
	for i in voices:
		var player := AudioStreamPlayer2D.new()
		player.bus = bus
		add_child(player)
		_players.append(player)
	pigeon.action.connect(_on_action)


func _on_action(action_name: StringName) -> void:
	if sound_bank == null:
		return
	var stream := sound_bank.get_stream(action_name)
	if stream == null:
		return
	var player := _get_free_player()
	player.stream = stream
	player.volume_db = sound_bank.get_volume_db(action_name)
	player.pitch_scale = 1.0 + randf_range(-sound_bank.pitch_variation, sound_bank.pitch_variation)
	player.play()


func _get_free_player() -> AudioStreamPlayer2D:
	for player in _players:
		if not player.playing:
			return player
	_next = (_next + 1) % _players.size()
	return _players[_next]
