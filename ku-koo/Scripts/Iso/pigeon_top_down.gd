class_name PigeonTopDown
extends Pigeon
## The pigeon for the isometric, top-down (Hades-like) camera.
##
## Same actions and components as the side-view [Pigeon] (peck, coo, carry,
## grip, hop + one flap with a slowed fall), so visuals, audio and all
## interactables are shared. The differences:
##   - Walking is on the floor plane in 8 directions (W/A/S/D).
##   - Hopping is a height [member z] above the floor; a shadow stays on the
##     ground. Gravity acts on z, not on the screen Y axis.
##   - Obstacles are iso solids with a height (IsoMath): the pigeon is blocked
##     by anything taller than it can step onto, can hop/flap over low ones and
##     stand on top of them (crates, ledges).

@export_group("Top-down")
## Walking straight up/down the screen is slower (perspective), like Hades.
@export var vertical_speed_scale: float = 0.7
## Small height differences the pigeon simply walks up.
@export var step_height: float = 4.0
## Beak height above the feet (for reaching hanging/raised things).
@export var beak_height: float = 14.0
## Radius of the feet footprint used against solids.
@export var footprint_radius: float = 5.0
## Distance from the feet to the beak target on the floor.
@export var beak_reach: float = 15.0

## Height above the floor, in pixels.
var z: float = 0.0
## Vertical (height) speed, positive = up.
var vz: float = 0.0
## Height of whatever is under the feet (floor = 0, a crate = its height).
var ground_z: float = 0.0
## Last walking direction on screen (beak/drop direction).
var aim: Vector2 = Vector2.RIGHT

## The solid under the pigeon (null = floor); used for draw order.
var support: Node2D = null

var _airborne: bool = false
var _feet_shape: CircleShape2D

@onready var visuals: Node2D = $Visuals
@onready var shadow: IsoShadow = $Shadow


func _ready() -> void:
	super()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_mask = 0  # solids are resolved by height in code
	_feet_shape = CircleShape2D.new()
	_feet_shape.radius = footprint_radius
	ground_z = IsoMath.surface_height_at(self, global_position)
	z = ground_z
	IsoBlock.xray_target = self


func _exit_tree() -> void:
	if IsoBlock.xray_target == self:
		IsoBlock.xray_target = null


## Draw-order key read by IsoDepthSorter.
func get_iso_depth() -> float:
	return IsoMath.depth_on(global_position, support)


## Screen area of the pigeon, used by tall blocks to turn see-through.
func get_xray_rect() -> Rect2:
	return Rect2(global_position + Vector2(-13, -38 - z), Vector2(26, 40))


# --- Hooks used by shared components ---------------------------------------------

func is_grounded() -> bool:
	return not _airborne


func get_beak_height() -> float:
	return z + beak_height


func same_level_as(node: Node2D, tolerance: float) -> bool:
	var base := 0.0
	if node.has_method(&"get_iso_base"):
		base = node.call(&"get_iso_base")
	return absf(z - base) <= tolerance


func get_drop_point() -> Vector2:
	return global_position + aim * 12.0


func get_drop_velocity() -> Vector2:
	return aim * 30.0


func get_move_speed() -> float:
	return get_real_velocity().length()


# --- Physics ---------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if input_enabled:
		input = Input.get_vector(&"move_left", &"move_right", &"look_up", &"look_down")
		if Input.is_action_just_pressed(&"jump"):
			_jump_buffer = jump_buffer_time
		if Input.is_action_just_pressed(&"peck"):
			peck_ability.try_peck()
		if Input.is_action_just_pressed(&"coo"):
			coo_ability.try_coo()
	look = 0.0

	_lock_timer = maxf(_lock_timer - delta, 0.0)
	_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	var grounded := not _airborne
	_coyote = coyote_time if grounded else maxf(_coyote - delta, 0.0)
	var locked := _lock_timer > 0.0 and grounded
	if locked:
		input = Vector2.ZERO
	if not locked:
		_handle_hop(grounded)

	_move_planar(delta, input, grounded, locked)
	_update_height(delta)
	_update_presentation()
	_after_move_top_down(delta)


func _handle_hop(grounded: bool) -> void:
	if _jump_buffer <= 0.0:
		return
	if hold.is_grabbing():
		hold.release()
	if grounded or _coyote > 0.0:
		vz = -jump_velocity
		_airborne = true
		_coyote = 0.0
		_jump_buffer = 0.0
		flaps_used = 0
		action.emit(&"jump")
	elif can_flap():
		vz = -flap_velocity
		flaps_used += 1
		_jump_buffer = 0.0
		action.emit(&"flap")


func _move_planar(delta: float, input: Vector2, grounded: bool, locked: bool) -> void:
	# Squash the input so diagonals follow the isometric floor axes.
	var dir := Vector2(input.x, input.y * 0.5)
	var target := Vector2.ZERO
	if dir.length() > 0.01:
		var n := dir.normalized()
		var speed := walk_speed * lerpf(1.0, vertical_speed_scale, absf(n.y) * absf(n.y))
		if hold.is_grabbing():
			speed *= push_speed_scale
		target = n * speed * minf(input.length(), 1.0)
		if not locked and not hold.is_grabbing():
			aim = n
			if absf(input.x) > 0.1:
				set_facing(int(signf(input.x)))
	var accel := ground_acceleration if grounded else air_acceleration
	if target == Vector2.ZERO and grounded:
		accel = ground_friction
	velocity = velocity.move_toward(target, accel * delta)

	var motion := velocity * delta
	var exclude: Array[RID] = [get_rid()]
	var gripped: IsoPushableBody = hold.grabbed as IsoPushableBody
	var body_motion := Vector2.ZERO
	if gripped:
		exclude.append(gripped.get_rid())
		body_motion = gripped.slide_vec(motion)
		motion = body_motion
	motion = IsoMath.resolve_motion(self, _feet_shape, global_position, motion, z + step_height, exclude)
	if gripped and not motion.is_equal_approx(body_motion):
		gripped.slide_vec(motion - body_motion)
	velocity = motion / delta
	move_and_slide()  # no collision mask: moves exactly by the resolved motion

	if gripped:
		var drift := (gripped.global_position - global_position) - hold.grab_offset
		if _airborne or drift.length() > grip_break_distance:
			hold.release()

	# Beak target in front of the pigeon, on the floor.
	beak_area.position = aim * beak_reach


func _update_height(delta: float) -> void:
	var exclude: Array[RID] = [get_rid()]
	var surface := IsoMath.surface_at(self, global_position, exclude)
	ground_z = surface.height
	support = surface.node
	if not _airborne:
		if ground_z < z - 0.5:
			# Walked off an edge.
			_airborne = true
			vz = 0.0
		else:
			z = ground_z
			return
	var g := gravity
	is_gliding = flaps_used > 0 and vz < 0.0
	if is_gliding:
		g *= glide_gravity_scale
	vz -= g * delta
	if is_gliding:
		vz = maxf(vz, -glide_max_fall_speed)
	vz = maxf(vz, -max_fall_speed)
	z += vz * delta
	if z <= ground_z and vz <= 0.0:
		z = ground_z
		vz = 0.0
		_airborne = false
		is_gliding = false
		flaps_used = 0
		action.emit(&"land")


func _update_presentation() -> void:
	visuals.position.y = -z
	shadow.position.y = -ground_z
	shadow.lift = z - ground_z
	hold.height_offset = z


func _after_move_top_down(delta: float) -> void:
	var speed := get_move_speed()
	if not _airborne and speed > 5.0:
		_step_accum += speed * delta
		if _step_accum >= step_distance:
			_step_accum = 0.0
			action.emit(&"step")
	_update_state(not _airborne)


func _update_state(on_floor: bool) -> void:
	var new_state: State
	if _lock_timer > 0.0:
		new_state = _lock_state
	elif not on_floor:
		new_state = State.AIR
	elif hold.is_grabbing():
		new_state = State.PUSH
	elif get_move_speed() > 4.0:
		new_state = State.WALK
	else:
		new_state = State.IDLE
	if new_state != state:
		var old := state
		state = new_state
		state_changed.emit(new_state, old)
