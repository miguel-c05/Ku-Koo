class_name EventSound
extends AudioStreamPlayer2D
## A positional sound meant to be triggered from any signal in the editor
## (Node > Signals > connect to play_event). Extra signal arguments are ignored.

@export_range(0.0, 0.5) var pitch_variation: float = 0.05


func play_event(_arg1: Variant = null, _arg2: Variant = null) -> void:
	if stream == null:
		return
	pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	play()
