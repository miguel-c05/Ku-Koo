class_name SpeechBubble
extends Label
## Floating text above a character. In the demo it stands in for sounds
## ("ku-koo", "miau?") so the demo reads even with the volume off.

@export var anchor: Vector2 = Vector2(0, -40)
@export var font_size: int = 16
@export var default_duration: float = 1.2

var _tween: Tween


func _ready() -> void:
	add_theme_font_size_override(&"font_size", font_size)
	add_theme_constant_override(&"outline_size", 5)
	add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.85))
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scale = Vector2(0.5, 0.5)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0


func say(message: String, duration: float = -1.0) -> void:
	if duration < 0.0:
		duration = default_duration
	text = message
	reset_size()
	position = anchor - Vector2(size.x * scale.x * 0.5, size.y * scale.y)
	if _tween:
		_tween.kill()
	modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_property(self, "position:y", position.y - 4.0, duration)
	_tween.parallel().tween_property(self, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
