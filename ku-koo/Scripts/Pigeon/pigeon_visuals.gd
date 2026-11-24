class_name PigeonVisuals
extends Node2D
## Presentation of the pigeon. Reads [member Pigeon.state] and listens to
## [signal Pigeon.action]; never changes gameplay.
##
## Two modes, chosen automatically:
##   1. Placeholder rig (default): a few overlapping Sprite2D parts (body,
##      head, beak, wing, tail, legs) animated procedurally with code.
##   2. Real art: give [member animated_sprite] a SpriteFrames resource that
##      contains animations with the names below; the rig hides itself.
##
## Animation names (state loops):  idle, walk, jump, fall, glide, peck, coo, push
## One-shots (played if present):  flap, land, pick_up, drop
## Missing animations fall back through ANIM_FALLBACKS, then to "idle".
## While there is no "peck" animation, the sprite tilts forward instead.
##
## The AnimatedSprite2D's origin must be at the pigeon's feet (use its
## offset), so the facing flip and the peck tilt pivot on the feet.

const STATE_ANIMS := {
	Pigeon.State.IDLE: &"idle",
	Pigeon.State.WALK: &"walk",
	Pigeon.State.PECK: &"peck",
	Pigeon.State.COO: &"coo",
	Pigeon.State.PUSH: &"push",
	Pigeon.State.HANG: &"hang",
}
const ANIM_FALLBACKS := {
	&"push": &"walk",
	&"glide": &"fall",
	&"fall": &"jump",
}
const ONE_SHOT_ANIMS: Array[StringName] = [&"flap", &"land", &"pick_up", &"drop"]

@export var pigeon: Pigeon
@export var animated_sprite: AnimatedSprite2D
## Optional second sprite for hanging by the foot (frames anchored at the top
## of the string). Shown instead of animated_sprite while the state is HANG.
@export var hang_sprite: AnimatedSprite2D

@export_group("Real art")
## Forward tilt used as a stand-in peck while there is no "peck" animation.
@export var peck_tilt_degrees: float = 45.0
@export var peck_tilt_time: float = 0.2
## Time held at full tilt, so the peck reads.
@export var peck_tilt_hold: float = 0.08
## Beak tip relative to the feet, facing right (where carried items sit).
@export var frames_beak_position: Vector2 = Vector2(6, -29)
## Scale the walk animation speed with the real walking speed.
@export var walk_anim_follows_speed: bool = true

@export_group("Placeholder rig")
@export var rig: Node2D
@export var body: Node2D
@export var head: Node2D
@export var wing: Node2D
@export var coo_ring: CooRing
@export var bubble: SpeechBubble
@export var coo_text: String = "ku-kooo"
## Seconds between idle ground-pecks (random in range), as pigeons do.
@export var idle_peck_interval: Vector2 = Vector2(2.5, 5.0)

var _use_frames: bool = false
var _sprite_scale: Vector2 = Vector2.ONE
var _hang_scale: Vector2 = Vector2.ONE
var _one_shot_playing: bool = false
var _walk_phase: float = 0.0
var _idle_timer: float = 3.0
var _peck_amount: float = 0.0
var _puff: float = 0.0
var _squash: Vector2 = Vector2.ONE
var _wing_flap: float = 0.0
var _head_rest: Vector2
var _body_rest: Vector2
var _beak_rest: Vector2
var _peck_tween: Tween
var _puff_tween: Tween
var _squash_tween: Tween
var _wing_tween: Tween


func _ready() -> void:
	if pigeon == null:
		pigeon = get_parent() as Pigeon
	_use_frames = animated_sprite != null and animated_sprite.sprite_frames != null
	if animated_sprite:
		animated_sprite.visible = _use_frames
		animated_sprite.animation_finished.connect(_on_animation_finished)
		_sprite_scale = animated_sprite.scale.abs()
	if hang_sprite:
		hang_sprite.visible = false
		_hang_scale = hang_sprite.scale.abs()
	if rig:
		rig.visible = not _use_frames
	if head:
		_head_rest = head.position
	if body:
		_body_rest = body.position
	pigeon.action.connect(_on_action)
	pigeon.state_changed.connect(_on_state_changed)
	# Children are ready before their parent, so fetch the component directly.
	(pigeon.get_node(^"CooAbility") as CooAbility).cooed.connect(_on_cooed)


func _process(delta: float) -> void:
	if _use_frames:
		_update_frames()
	else:
		_update_rig(delta)


# --- Real art (AnimatedSprite2D) -------------------------------------------

## True when hanging uses its own sprite (anchored at the string, already upside down).
func has_hang_sprite() -> bool:
	return _use_frames and hang_sprite != null and hang_sprite.sprite_frames != null


func _update_frames() -> void:
	var hanging := pigeon.state == Pigeon.State.HANG and has_hang_sprite()
	if hang_sprite:
		hang_sprite.visible = hanging
		animated_sprite.visible = not hanging
		if hanging:
			hang_sprite.scale = Vector2(_hang_scale.x * pigeon.facing, _hang_scale.y)
			if not hang_sprite.is_playing():
				hang_sprite.play(&"hang")
			return
	var facing := pigeon.facing
	# Flip with the scale (not flip_h) so the pivot stays on the feet.
	animated_sprite.scale = Vector2(_sprite_scale.x * facing, _sprite_scale.y)
	var tilt := deg_to_rad(peck_tilt_degrees) * _peck_amount
	animated_sprite.rotation = tilt * facing
	# Carried items follow the (tilting) beak.
	pigeon.hold.visual_offset = frames_beak_position.rotated(tilt) - pigeon.hold.base_position

	if walk_anim_follows_speed and animated_sprite.animation == &"walk":
		var speed := pigeon.get_move_speed() / maxf(pigeon.walk_speed, 1.0)
		animated_sprite.speed_scale = clampf(speed, 0.35, 1.3)
	else:
		animated_sprite.speed_scale = 1.0

	if _one_shot_playing:
		return
	_play_frames(_current_loop_anim())


func _current_loop_anim() -> StringName:
	if pigeon.state == Pigeon.State.PUSH and pigeon.hold.is_grabbing():
		# Walking towards the gripped object = push, away from it = pull.
		var towards := signf(pigeon.hold.grab_offset.x)
		var vx := pigeon.velocity.x
		if absf(vx) > 5.0 and signf(vx) != towards and animated_sprite.sprite_frames.has_animation(&"pull"):
			return &"pull"
		return &"push"
	if pigeon.state == Pigeon.State.AIR:
		if pigeon.is_gliding:
			return &"glide"
		return &"jump" if pigeon.velocity.y < 0.0 else &"fall"
	return STATE_ANIMS.get(pigeon.state, &"idle")


func _play_frames(anim: StringName) -> void:
	var frames := animated_sprite.sprite_frames
	while not frames.has_animation(anim) and ANIM_FALLBACKS.has(anim):
		anim = ANIM_FALLBACKS[anim]
	if not frames.has_animation(anim):
		anim = &"idle"
	if frames.has_animation(anim) and animated_sprite.animation != anim:
		animated_sprite.play(anim)


func _on_animation_finished() -> void:
	_one_shot_playing = false


# --- Placeholder rig ---------------------------------------------------------

func _update_rig(delta: float) -> void:
	var state := pigeon.state
	var vx := pigeon.get_move_speed()

	# Idle: peck at the ground now and then.
	if state == Pigeon.State.IDLE:
		_idle_timer -= delta
		if _idle_timer <= 0.0:
			_idle_timer = randf_range(idle_peck_interval.x, idle_peck_interval.y)
			_play_peck(0.35)
	else:
		_idle_timer = randf_range(idle_peck_interval.x, idle_peck_interval.y)

	# Walk: the pigeon head-bob (thrust forward, hold) and a little body bounce.
	var head_offset := Vector2.ZERO
	var body_offset := Vector2.ZERO
	if state == Pigeon.State.WALK or state == Pigeon.State.PUSH:
		_walk_phase += vx * delta * 0.45
		head_offset.x = clampf(sin(_walk_phase) * 3.0, -1.0, 2.5)
		body_offset.y = -absf(sin(_walk_phase)) * 1.0
	else:
		_walk_phase = 0.0

	# Peck: head down and forward.
	head_offset += Vector2(5.0, 8.0) * _peck_amount
	# Coo: puffed chest, head pulled in and nodding.
	head_offset += Vector2(-1.0, 2.0 + sin(Time.get_ticks_msec() * 0.03) * 1.0) * _puff

	head.position = _head_rest + head_offset
	head.rotation = 0.7 * _peck_amount
	body.position = _body_rest + body_offset
	body.scale = Vector2.ONE * (1.0 + 0.2 * _puff)

	# Wing: tucked on the ground, raised in the air, spread while gliding.
	var wing_rot := 0.0
	if state == Pigeon.State.AIR:
		wing_rot = -0.25 if pigeon.is_gliding else (-0.6 if pigeon.velocity.y < 0.0 else 0.2)
	wing.rotation = wing_rot - 1.3 * _wing_flap

	# Lean into the push, facing flip and squash/stretch.
	rig.rotation = (0.14 if state == Pigeon.State.PUSH else 0.0) * pigeon.facing
	rig.scale = Vector2(_squash.x * pigeon.facing, _squash.y)

	# The carried item follows the beak.
	pigeon.hold.visual_offset = head_offset


func _play_peck(duration: float = 0.22, hold_time: float = 0.0) -> void:
	if _peck_tween:
		_peck_tween.kill()
	_peck_tween = create_tween()
	_peck_tween.tween_property(self, "_peck_amount", 1.0, duration * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if hold_time > 0.0:
		_peck_tween.tween_interval(hold_time)
	_peck_tween.tween_property(self, "_peck_amount", 0.0, duration * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _play_puff() -> void:
	if _puff_tween:
		_puff_tween.kill()
	_puff_tween = create_tween()
	_puff_tween.tween_property(self, "_puff", 1.0, 0.15)
	_puff_tween.tween_interval(0.35)
	_puff_tween.tween_property(self, "_puff", 0.0, 0.2)


func _play_squash(amount: Vector2, duration: float = 0.15) -> void:
	if _squash_tween:
		_squash_tween.kill()
	_squash = amount
	_squash_tween = create_tween()
	_squash_tween.tween_property(self, "_squash", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_wing_flap() -> void:
	if _wing_tween:
		_wing_tween.kill()
	_wing_flap = 0.0
	_wing_tween = create_tween()
	for i in 2:
		_wing_tween.tween_property(self, "_wing_flap", 1.0, 0.05)
		_wing_tween.tween_property(self, "_wing_flap", 0.0, 0.07)


# --- Event wiring --------------------------------------------------------------

func _on_action(action_name: StringName) -> void:
	if _use_frames:
		if action_name == &"peck" and not animated_sprite.sprite_frames.has_animation(&"peck"):
			_play_peck(peck_tilt_time, peck_tilt_hold)
		if action_name in ONE_SHOT_ANIMS and animated_sprite.sprite_frames.has_animation(action_name):
			_one_shot_playing = true
			animated_sprite.play(action_name)
		return
	match action_name:
		&"jump":
			_play_squash(Vector2(0.8, 1.2))
			_play_wing_flap()
		&"flap":
			_play_wing_flap()
		&"land":
			_play_squash(Vector2(1.25, 0.75))
		&"peck":
			_play_peck()
		&"pick_up", &"drop":
			_play_squash(Vector2(1.1, 0.9), 0.1)


func _on_state_changed(new_state: Pigeon.State, _old_state: Pigeon.State) -> void:
	if new_state == Pigeon.State.COO and not _use_frames:
		_play_puff()


func _on_cooed(_origin: Vector2, radius: float) -> void:
	if coo_ring:
		coo_ring.play(radius)
	if bubble:
		bubble.say(coo_text, 0.9)
