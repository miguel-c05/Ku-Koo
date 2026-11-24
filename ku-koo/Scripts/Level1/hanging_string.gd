@tool
class_name HangingString
extends Node2D
## The hunter's nail and string (level 1, beats 2-3). Place this node at the
## nail. The pigeon hangs upside down by its foot and swings like a pendulum:
## A / D pump the swing. Pecking near the top of a swing snaps the string and
## the pigeon falls with the swing's momentum. Pecking too low only shakes it.

signal swung        ## first real swing (for the "A / D" prompt)
signal swing_high   ## first time the swing reaches the breaking height
signal missed       ## pecked, but not high enough
signal broken

@export var pigeon: Pigeon
@export var length: float = 120.0:
	set(value):
		length = value
		queue_redraw()
@export var max_angle_degrees: float = 70.0
## Angular acceleration from A / D (rad/s²).
@export var pump_strength: float = 4.0
@export var gravity: float = 980.0
@export var damping: float = 0.35
## Pecks only snap the string beyond this angle (the top of a swing).
@export var break_angle_degrees: float = 42.0
@export var string_color: Color = Color(0.72, 0.64, 0.48)
@export var creak_sound: EventSound
## When the string snaps, the pigeon is released this far down the string
## from the foot (about the middle of the hanging body), so the standing
## sprite appears where the hanging one was.
@export var release_offset: float = 0.0

var angle: float = 0.0
var angular_velocity: float = 0.0
var is_attached: bool = false
var is_broken: bool = false

var _swung_sent: bool = false
var _high_sent: bool = false
var _last_velocity_sign: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if pigeon:
		attach.call_deferred(pigeon)


func attach(target: Pigeon) -> void:
	pigeon = target
	is_attached = true
	pigeon.external_controller = self
	pigeon.velocity = Vector2.ZERO
	pigeon.set_state(Pigeon.State.HANG)
	_place_pigeon()


func get_foot_position() -> Vector2:
	return global_position + Vector2(sin(angle), cos(angle)) * length


## Called by the pigeon every physics frame while it hangs.
func control_pigeon(p: Pigeon, delta: float) -> void:
	var input := 0.0
	if p.input_enabled:
		input = Input.get_axis(&"move_left", &"move_right")
		if not is_zero_approx(input):
			p.set_facing(int(signf(input)))
	var acc := -(gravity / length) * sin(angle) + input * pump_strength - damping * angular_velocity
	angular_velocity += acc * delta
	angle += angular_velocity * delta
	var max_angle := deg_to_rad(max_angle_degrees)
	if absf(angle) > max_angle:
		angle = signf(angle) * max_angle
		angular_velocity = 0.0

	var amplitude := absf(angle)
	if not _swung_sent and amplitude > deg_to_rad(15.0):
		_swung_sent = true
		p.action.emit(&"swing")
		swung.emit()
	if not _high_sent and amplitude >= deg_to_rad(break_angle_degrees):
		_high_sent = true
		swing_high.emit()
	# Rope creak at the turning points.
	var s := signf(angular_velocity)
	if s != 0.0 and s != _last_velocity_sign and amplitude > deg_to_rad(10.0) and creak_sound:
		creak_sound.play_event()
	if s != 0.0:
		_last_velocity_sign = s

	_place_pigeon()
	queue_redraw()

	if p.input_enabled and Input.is_action_just_pressed(&"peck"):
		p.action.emit(&"peck")
		if amplitude >= deg_to_rad(break_angle_degrees):
			_break(p)
		else:
			missed.emit()


func _place_pigeon() -> void:
	pigeon.global_position = get_foot_position()
	# Hanging by the foot: the body points away from the nail. A dedicated hang
	# sprite is already drawn upside down; the standing sprite is flipped over.
	var visuals := pigeon.get_node(^"Visuals") as Node2D
	var upside_down: bool = visuals.has_method(&"has_hang_sprite") and visuals.call(&"has_hang_sprite")
	visuals.rotation = -angle if upside_down else PI - angle


func _break(p: Pigeon) -> void:
	is_attached = false
	is_broken = true
	var tangent := Vector2(cos(angle), -sin(angle))
	p.velocity = tangent * angular_velocity * length
	p.external_controller = null
	if release_offset > 0.0:
		p.global_position = get_foot_position() + Vector2(sin(angle), cos(angle)) * release_offset
	p.set_state(Pigeon.State.AIR)
	var visuals := p.get_node(^"Visuals") as Node2D
	var tween := p.create_tween()
	tween.tween_property(visuals, "rotation", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	p.action.emit(&"string_break")
	broken.emit()
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 2.5, Color(0.55, 0.55, 0.58))  # the nail
	if is_broken:
		draw_line(Vector2.ZERO, Vector2(0, 10), string_color, 1.5)
		return
	var foot := Vector2(sin(angle), cos(angle)) * length
	draw_line(Vector2.ZERO, foot, string_color, 1.5)
