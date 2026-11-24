class_name Pigeon
extends CharacterBody2D
## The pigeon (player character).
##
## This script owns only the movement physics: walk, hop, one short air flap
## followed by a slowed fall, and look up/down. The other actions live in
## child components:
##   - [PeckAbility]  (peck, interact)
##   - [CooAbility]   (coo)
##   - [BeakHold]     (carry one object, grip/push/pull)
##
## Presentation never lives here. Visuals and audio listen to [signal action]
## (one-shot events) and read [member state] (continuous state), so the
## placeholder art and sound can be replaced without touching gameplay.
##
## Action names emitted through [signal action]:
##   &"jump", &"flap", &"land", &"step", &"peck", &"peck_hit", &"coo",
##   &"pick_up", &"drop", &"give", &"grab", &"release"

signal action(action_name: StringName)
signal state_changed(new_state: State, old_state: State)
signal facing_changed(new_facing: int)

enum State { IDLE, WALK, AIR, PECK, COO, PUSH, HANG }

@export_group("Walk")
@export var walk_speed: float = 110.0
@export var ground_acceleration: float = 900.0
@export var ground_friction: float = 1300.0
@export var air_acceleration: float = 650.0
## Distance walked between two &"step" events (footstep sounds, head-bob).
@export var step_distance: float = 12.0

@export_group("Hop and flap")
@export var jump_velocity: float = -330.0
@export var flap_velocity: float = -270.0
## Air flaps allowed before landing. 1 = the game's "double jump" flap.
## -1 = unlimited, i.e. real flight (tutorial forest only).
@export var max_air_flaps: int = 1
@export var gravity: float = 980.0
@export var max_fall_speed: float = 450.0
## After a flap, the fall is slowed (wings spread).
@export var glide_gravity_scale: float = 0.35
@export var glide_max_fall_speed: float = 100.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.12

@export_group("Push and pull")
@export var push_speed_scale: float = 0.55
## The grip breaks if the gripped object drifts this far from where it was gripped.
@export var grip_break_distance: float = 10.0

@export_group("Input")
@export var input_enabled: bool = true

## When set, this node drives the pigeon instead of the normal movement
## (e.g. a HangingString while the pigeon hangs by its foot). It must have
## control_pigeon(pigeon, delta).
var external_controller: Node = null

var state: State = State.IDLE
var facing: int = 1
## -1 looking up, +1 looking down (read by the camera).
var look: float = 0.0
var flaps_used: int = 0
var is_gliding: bool = false

@onready var hold: BeakHold = $BeakHold
@onready var peck_ability: PeckAbility = $PeckAbility
@onready var coo_ability: CooAbility = $CooAbility
@onready var beak_area: Area2D = $BeakArea

var _coyote: float = 0.0
var _jump_buffer: float = 0.0
var _lock_timer: float = 0.0
var _lock_state: State = State.IDLE
var _step_accum: float = 0.0
var _was_on_floor: bool = true
var _beak_area_x: float = 0.0


func _ready() -> void:
	_beak_area_x = absf(beak_area.position.x)
	set_facing(facing, true)


func _physics_process(delta: float) -> void:
	if external_controller:
		external_controller.call(&"control_pigeon", self, delta)
		return
	var move_input := 0.0
	if input_enabled:
		move_input = Input.get_axis(&"move_left", &"move_right")
		look = Input.get_axis(&"look_up", &"look_down")
		if Input.is_action_just_pressed(&"jump"):
			_jump_buffer = jump_buffer_time
		if Input.is_action_just_pressed(&"peck"):
			peck_ability.try_peck()
		if Input.is_action_just_pressed(&"coo"):
			coo_ability.try_coo()
	else:
		look = 0.0

	_lock_timer = maxf(_lock_timer - delta, 0.0)
	_jump_buffer = maxf(_jump_buffer - delta, 0.0)

	var on_floor := is_on_floor()
	_coyote = coyote_time if on_floor else maxf(_coyote - delta, 0.0)

	# Pecking and cooing on the ground plant the pigeon for a moment.
	var locked := _lock_timer > 0.0 and on_floor
	if locked:
		move_input = 0.0

	_apply_gravity(delta, on_floor)
	if not locked:
		_handle_jump(on_floor)

	if hold.is_grabbing():
		_move_gripping(delta, move_input)
	else:
		_move_free(delta, move_input, on_floor, locked)

	_after_move(delta)


## Plants the pigeon (no walking or jumping on the ground) and shows [param lock_state].
func lock(duration: float, lock_state: State) -> void:
	_lock_timer = duration
	_lock_state = lock_state
	_update_state(is_grounded())


func set_facing(new_facing: int, force: bool = false) -> void:
	if new_facing == 0 or (new_facing == facing and not force):
		return
	facing = new_facing
	beak_area.position.x = _beak_area_x * facing
	hold.set_facing(facing)
	facing_changed.emit(facing)


## Sets the state from outside (external controllers).
func set_state(new_state: State) -> void:
	if new_state != state:
		var old := state
		state = new_state
		state_changed.emit(new_state, old)


## Puts the pigeon back at a checkpoint, empty-beaked and still.
func respawn_at(at: Vector2) -> void:
	if hold.is_grabbing():
		hold.release()
	if hold.is_carrying():
		hold.drop()
	global_position = at
	velocity = Vector2.ZERO
	flaps_used = 0
	_lock_timer = 0.0
	_jump_buffer = 0.0
	set_facing(1)
	_update_state(true)


## --- Hooks overridden by other camera styles (e.g. PigeonTopDown) ----------

## True when standing on something (side view: on the floor).
func is_grounded() -> bool:
	return is_on_floor()


## Whether [param node] sits at the pigeon's own level (for gripping it).
func same_level_as(node: Node2D, tolerance: float) -> bool:
	return absf(node.global_position.y - global_position.y) <= tolerance


## Where a dropped item is placed, and how it is thrown.
func get_drop_point() -> Vector2:
	return hold.global_position


func get_drop_velocity() -> Vector2:
	return Vector2(facing * 30.0, -30.0)


## Movement speed used by the visuals (walk animation speed, head-bob).
func get_move_speed() -> float:
	return absf(get_real_velocity().x)


func can_flap() -> bool:
	return max_air_flaps < 0 or flaps_used < max_air_flaps


func _apply_gravity(delta: float, on_floor: bool) -> void:
	if on_floor:
		is_gliding = false
		return
	var g := gravity
	var max_fall := max_fall_speed
	is_gliding = flaps_used > 0 and velocity.y > 0.0
	if is_gliding:
		g *= glide_gravity_scale
		max_fall = glide_max_fall_speed
	velocity.y = minf(velocity.y + g * delta, max_fall)


func _handle_jump(on_floor: bool) -> void:
	if _jump_buffer <= 0.0:
		return
	if hold.is_grabbing():
		hold.release()
	if on_floor or _coyote > 0.0:
		velocity.y = jump_velocity
		_coyote = 0.0
		_jump_buffer = 0.0
		flaps_used = 0
		action.emit(&"jump")
	elif can_flap():
		velocity.y = flap_velocity
		flaps_used += 1
		_jump_buffer = 0.0
		action.emit(&"flap")


func _move_free(delta: float, move_input: float, on_floor: bool, locked: bool) -> void:
	var target := move_input * walk_speed
	var accel := ground_acceleration if on_floor else air_acceleration
	if is_zero_approx(move_input) and on_floor:
		accel = ground_friction
	velocity.x = move_toward(velocity.x, target, accel * delta)
	if not locked and not is_zero_approx(move_input):
		set_facing(int(signf(move_input)))
	move_and_slide()


## Push/pull: the gripped object moves first (it may be blocked by a wall),
## then the pigeon follows by the same amount, so both keep their distance.
func _move_gripping(delta: float, move_input: float) -> void:
	var body := hold.grabbed
	var target := move_input * walk_speed * push_speed_scale
	velocity.x = move_toward(velocity.x, target, ground_acceleration * delta)
	var wanted_dx := velocity.x * delta
	var body_dx := body.slide_by(wanted_dx)
	velocity.x = body_dx / delta
	var before := global_position.x
	move_and_slide()
	var moved := global_position.x - before
	if absf(moved - body_dx) > 0.01:
		body.slide_by(moved - body_dx)
	var drift := (body.global_position - global_position) - hold.grab_offset
	if not is_on_floor() or drift.length() > grip_break_distance:
		hold.release()


func _after_move(delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		flaps_used = 0
		is_gliding = false
		action.emit(&"land")
	var real_vx := absf(get_real_velocity().x)
	if on_floor and real_vx > 5.0:
		_step_accum += real_vx * delta
		if _step_accum >= step_distance:
			_step_accum = 0.0
			action.emit(&"step")
	_was_on_floor = on_floor
	_update_state(on_floor)


func _update_state(on_floor: bool) -> void:
	var new_state: State
	if _lock_timer > 0.0:
		new_state = _lock_state
	elif not on_floor:
		new_state = State.AIR
	elif hold.is_grabbing():
		new_state = State.PUSH
	elif absf(get_real_velocity().x) > 4.0:
		new_state = State.WALK
	else:
		new_state = State.IDLE
	if new_state != state:
		var old := state
		state = new_state
		state_changed.emit(new_state, old)
