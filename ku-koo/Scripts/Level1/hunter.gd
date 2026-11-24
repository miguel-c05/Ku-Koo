@tool
class_name Hunter
extends Node2D
## The hunter in the workroom, seen from behind through the doorway
## (level 1, beats 8-10). He chops in a loop; every few seconds the chopping
## stops, a beat later he looks over his shoulder for about two seconds, then
## turns back. While he looks, a pigeon standing in a [LightZone] and not in a
## [HidingSpot] is caught.
##
## Placeholder drawing in _draw(). For real art, add an AnimatedSprite2D as
## [member sprite] with animations: chop, pause, look, turn, reach.

signal phase_changed(phase: Phase)
signal caught_pigeon(pigeon: Pigeon)

enum Phase { CHOP, PAUSE, LOOK, TURN_BACK, REACH }

@export var pigeon: Pigeon
@export var sprite: AnimatedSprite2D
@export var chop_sound: EventSound
@export var turn_sound: EventSound
## Seconds of chopping before each look (random in range).
@export var chop_time: Vector2 = Vector2(2.6, 4.0)
## The warning beat: chopping stops, then he looks.
@export var pause_time: float = 0.6
@export var look_time: float = 2.0
@export var turn_back_time: float = 0.4
@export var chop_interval: float = 0.55
@export var active: bool = true
## Light zones this hunter watches (LightZone.zone_group).
@export var zone_group: StringName = &"light_zones"

var phase: Phase = Phase.CHOP

var _timer: float = 3.0
var _chop_timer: float = 0.0
var _arm: float = 0.0  # 0 raised, 1 down (placeholder chop)
var _look: float = 0.0  # 0 back turned, 1 looking over the shoulder
var _reach: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_set_phase(Phase.CHOP, randf_range(chop_time.x, chop_time.y))


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not active:
		return
	_timer -= delta
	match phase:
		Phase.CHOP:
			_chop_timer -= delta
			if _chop_timer <= 0.0:
				_chop_timer = chop_interval
				_arm = 1.0
				if chop_sound:
					chop_sound.play_event()
			if _timer <= 0.0:
				_set_phase(Phase.PAUSE, pause_time)
		Phase.PAUSE:
			if _timer <= 0.0:
				_set_phase(Phase.LOOK, look_time)
				if turn_sound:
					turn_sound.play_event()
		Phase.LOOK:
			if is_pigeon_visible():
				_set_phase(Phase.REACH, 99.0)
				caught_pigeon.emit(pigeon)
			elif _timer <= 0.0:
				_set_phase(Phase.TURN_BACK, turn_back_time)
		Phase.TURN_BACK:
			if _timer <= 0.0:
				_set_phase(Phase.CHOP, randf_range(chop_time.x, chop_time.y))
		Phase.REACH:
			pass


func _process(delta: float) -> void:
	var looking := phase == Phase.LOOK or phase == Phase.REACH
	_look = move_toward(_look, 1.0 if looking else 0.0, delta * 5.0)
	_reach = move_toward(_reach, 1.0 if phase == Phase.REACH else 0.0, delta * 3.0)
	_arm = move_toward(_arm, 0.0, delta * 3.5)
	queue_redraw()


## True while he looks round and the pigeon is in the light, not hidden.
func is_pigeon_visible() -> bool:
	if pigeon == null:
		return false
	for spot in get_tree().get_nodes_in_group(&"hiding_spots"):
		if (spot as HidingSpot).contains(pigeon):
			return false
	for zone in get_tree().get_nodes_in_group(zone_group):
		if (zone as LightZone).contains(pigeon):
			return true
	return false


## After a catch: turn back to the block and start chopping again.
func resume(_arg: Variant = null) -> void:
	_set_phase(Phase.TURN_BACK, turn_back_time + 0.6)


func _set_phase(new_phase: Phase, duration: float) -> void:
	phase = new_phase
	_timer = duration
	if sprite and sprite.sprite_frames:
		var anim: StringName = [&"chop", &"pause", &"look", &"turn", &"reach"][new_phase]
		if sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)
	phase_changed.emit(new_phase)


func _draw() -> void:
	if sprite and sprite.sprite_frames:
		return
	var coat := Color(0.25, 0.2, 0.18)
	var skin := Color(0.62, 0.48, 0.4)
	var red := Color(0.68, 0.12, 0.1)
	# Body from behind (origin = feet).
	draw_rect(Rect2(-26, -150, 52, 120), coat)
	draw_rect(Rect2(-22, -30, 18, 30), coat.darkened(0.3))
	draw_rect(Rect2(4, -30, 18, 30), coat.darkened(0.3))
	# Head turns towards the viewer when he looks.
	var head := Vector2(lerpf(0.0, -8.0, _look), -166)
	draw_circle(head, 16, skin.darkened(0.35 * (1.0 - _look)))
	if _look > 0.4:
		draw_circle(head + Vector2(-6, -2), 2.2, Color(0.08, 0.06, 0.05))
		draw_circle(head + Vector2(3, -2), 2.2, Color(0.08, 0.06, 0.05))
	# Red peaked hat.
	draw_colored_polygon(PackedVector2Array([head + Vector2(-18, -6), head + Vector2(18, -6), head + Vector2(2, -34)]), red)
	draw_rect(Rect2(head + Vector2(-20, -8), Vector2(40, 5)), red.darkened(0.2))
	# Arm: chopping on the block (right), or reaching out (left) when he catches.
	var shoulder := Vector2(20, -135)
	var hand := shoulder.lerp(Vector2(46, -78), _arm * 0.6 + 0.4)
	if _reach > 0.0:
		hand = hand.lerp(Vector2(-90, -40), _reach)
	draw_line(shoulder, hand, coat.lightened(0.1), 9.0)
	draw_circle(hand, 6, skin)
	if _reach < 0.5:
		draw_line(hand, hand + Vector2(14, -10), Color(0.7, 0.72, 0.75), 4.0)  # cleaver
