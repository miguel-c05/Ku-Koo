class_name SoundBank
extends Resource
## Maps event names to sounds. One bank per character/prop family.
## Swap placeholder audio by replacing the streams here (an
## AudioStreamRandomizer works too, for variations of the same sound).

@export var sounds: Dictionary[StringName, AudioStream] = {}
## Optional per-event volume in dB (events not listed use 0 dB).
@export var volume_db: Dictionary[StringName, float] = {}
## Random pitch variation applied on every play (0.05 = +/-5%).
@export_range(0.0, 0.5) var pitch_variation: float = 0.06


func get_stream(event_name: StringName) -> AudioStream:
	return sounds.get(event_name)


func get_volume_db(event_name: StringName) -> float:
	return volume_db.get(event_name, 0.0)
