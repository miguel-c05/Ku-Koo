class_name Level1Butchery
extends Node2D
## Flow of level 1, the butchery:
##   - Opening frame: black, the partner's coo far away, fade in on the
##     painting's composition; control starts after a short hold.
##   - Checkpoint nests: the last one passed is where the pigeon returns.
##   - Caught by the hunter: sting, cut to black before the grab, back to the
##     nest. After the first catch the "stay in the shadow" prompt appears.
##   - Pushing the shutter open and stepping out ends the level.
##   - Rooms: [LevelRoom]s with the same segment sit side by side and the camera
##     scrolls across them. A [RoomPassage] (the open door) steps the pigeon in,
##     fades to black and brings it out in another segment. Hunters only work
##     in the segment the pigeon is in.

signal level_completed

@export var pigeon: Pigeon
@export var camera: FollowCamera
## Optional; every Hunter in the level is wired up anyway.
@export var hunter: Hunter
@export var partner: PartnerCall
@export var first_nest: CheckpointNest
@export var fade: ColorRect
@export var end_label: Label
@export var caught_sound: EventSound
@export var shadow_prompt: InstructionPrompt
@export var daylight: CanvasItem
## Where the pigeon steps out (the window), for the closing beat.
@export var exit_point: Node2D
@export var shutter_sprite: Sprite2D
@export var shutter_texture: Texture2D
@export var shutter_hint_texture: Texture2D
## The room the level starts in.
@export var first_room: LevelRoom
@export var passage_fade_time: float = 0.3

@export_group("Opening frame")
## Where the camera holds still (the painting's framing).
@export var opening_frame_position: Vector2 = Vector2(160, -140)
@export var black_time: float = 1.6
@export var fade_in_time: float = 2.0
@export var hold_time: float = 1.2

var current_nest: CheckpointNest
var current_room: LevelRoom
var catches: int = 0
var is_finished: bool = false

var _busy: bool = false


func _ready() -> void:
	for nest in find_children("*", "CheckpointNest", true, false):
		(nest as CheckpointNest).reached.connect(_on_nest_reached)
	for h in get_hunters():
		h.caught_pigeon.connect(_on_caught)
	for passage in find_children("*", "RoomPassage", true, false):
		(passage as RoomPassage).pigeon_passed.connect(_on_passage)
	if first_room:
		enter_room(first_room)
	current_nest = first_nest
	if current_nest:
		current_nest.set_active(true)
	if daylight:
		daylight.modulate.a = 0.0
	end_label.modulate.a = 0.0
	_play_opening()


func _play_opening() -> void:
	pigeon.input_enabled = false
	camera.following = false
	if current_room:
		camera.global_position = current_room.get_rect().get_center()
	else:
		camera.global_position = opening_frame_position
	fade.modulate.a = 1.0
	await get_tree().create_timer(black_time * 0.4).timeout
	if partner:
		partner.call_out()
	await get_tree().create_timer(black_time * 0.6).timeout
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, fade_in_time)
	await tween.finished
	await get_tree().create_timer(hold_time).timeout
	camera.following = true
	pigeon.input_enabled = true


func get_hunters() -> Array[Hunter]:
	var list: Array[Hunter] = []
	for node in find_children("*", "Hunter", true, false):
		list.append(node as Hunter)
	return list


func get_room_of(node: Node) -> LevelRoom:
	var n := node.get_parent()
	while n and not (n is LevelRoom):
		n = n.get_parent()
	return n as LevelRoom


## Locks the camera to the segment [param room] belongs to (the rooms that
## join up with it) and wakes only the hunters in that segment.
func enter_room(room: LevelRoom) -> void:
	current_room = room
	if camera:
		var r := get_segment_rect(room.segment)
		camera.limit_left = int(round(r.position.x))
		camera.limit_top = int(round(r.position.y))
		camera.limit_right = int(round(r.end.x))
		camera.limit_bottom = int(round(r.end.y))
		camera.global_position = pigeon.global_position if pigeon else r.get_center()
		camera.reset_smoothing()
	for h in get_hunters():
		var hr := get_room_of(h)
		h.active = hr != null and hr.segment == room.segment and not is_finished


## Horizontal span of all rooms in the segment; vertically only what every
## room's painting covers.
func get_segment_rect(segment: int) -> Rect2:
	var left := INF
	var right := -INF
	var top := -INF
	var bottom := INF
	for node in find_children("*", "LevelRoom", true, false):
		var r := (node as LevelRoom)
		if r.segment != segment:
			continue
		var rect := r.get_rect()
		left = minf(left, rect.position.x)
		right = maxf(right, rect.end.x)
		top = maxf(top, rect.position.y)
		bottom = minf(bottom, rect.end.y)
	return Rect2(left, ceilf(top), right - left, floorf(bottom) - ceilf(top))


func _process(_delta: float) -> void:
	# Keep track of the room the pigeon is in (for checkpoints and debugging).
	if pigeon == null or current_room == null:
		return
	if current_room.get_rect().has_point(pigeon.global_position + Vector2(0, -4)):
		return
	for node in find_children("*", "LevelRoom", true, false):
		var r := node as LevelRoom
		if r.segment == current_room.segment and r.get_rect().has_point(pigeon.global_position + Vector2(0, -4)):
			current_room = r
			return


func _on_passage(passage: RoomPassage, _who: Pigeon) -> void:
	if _busy or is_finished:
		return
	_busy = true
	pigeon.input_enabled = false
	pigeon.set_physics_process(false)
	var visuals := pigeon.get_node(^"Visuals") as CanvasItem
	# Steps into the opening: walks into the dark.
	var tween := create_tween()
	tween.tween_property(pigeon, "global_position:x", passage.global_position.x, passage_fade_time).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(visuals, "modulate", Color(0.15, 0.15, 0.18), passage_fade_time)
	tween.parallel().tween_property(fade, "modulate:a", 1.0, passage_fade_time).set_delay(passage_fade_time * 0.5)
	await tween.finished
	await get_tree().create_timer(0.15).timeout
	pigeon.respawn_at(passage.entry.global_position)
	pigeon.set_physics_process(true)
	visuals.modulate = Color.WHITE
	var room := get_room_of(passage.entry)
	if room:
		enter_room(room)
	tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, passage_fade_time * 1.4)
	await tween.finished
	pigeon.input_enabled = true
	_busy = false


func _on_nest_reached(nest: CheckpointNest) -> void:
	if nest == current_nest:
		return
	if current_nest:
		current_nest.set_active(false)
	current_nest = nest
	nest.set_active(true)


func _on_caught(_who: Pigeon) -> void:
	if _busy or is_finished:
		return
	_busy = true
	catches += 1
	pigeon.input_enabled = false
	if caught_sound:
		caught_sound.play_event()
	await get_tree().create_timer(0.35).timeout
	# Cut to black before the grab.
	fade.modulate.a = 1.0
	await get_tree().create_timer(0.7).timeout
	pigeon.respawn_at(current_nest.get_spawn_position())
	var room := get_room_of(current_nest)
	if room:
		enter_room(room)
	else:
		camera.global_position = pigeon.global_position
	for h in get_hunters():
		h.resume()
	if catches == 1:
		if shadow_prompt:
			shadow_prompt.activate()
		for prompt in get_tree().get_nodes_in_group(&"shadow_prompt"):
			(prompt as InstructionPrompt).activate()
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 0.6)
	await tween.finished
	pigeon.input_enabled = true
	_busy = false


## Shutter pushed open: grey daylight pours in.
func open_window(_arg: Variant = null) -> void:
	if daylight:
		create_tween().tween_property(daylight, "modulate:a", 1.0, 1.2)
	if shutter_sprite:
		# Swings open on its hinge (left edge).
		shutter_sprite.texture = shutter_texture if shutter_texture else shutter_sprite.texture
		create_tween().tween_property(shutter_sprite, "scale:x", shutter_sprite.scale.x * 0.12, 0.6).set_trans(Tween.TRANS_SINE)


## Highlight the shutter while the beak is on it (the sparkly variant).
func shutter_hint(focused: bool) -> void:
	if shutter_sprite and shutter_hint_texture and shutter_texture:
		shutter_sprite.texture = shutter_hint_texture if focused else shutter_texture


## The pigeon steps out of the window.
func finish(_arg: Variant = null) -> void:
	if is_finished:
		return
	is_finished = true
	pigeon.input_enabled = false
	pigeon.set_physics_process(false)
	for h in get_hunters():
		h.active = false
	var tween := create_tween()
	if exit_point:
		# Steps out through the window: hops towards it and is gone.
		var visuals := pigeon.get_node(^"Visuals") as Node2D
		tween.tween_interval(0.4)
		tween.tween_property(pigeon, "global_position", exit_point.global_position, 0.7).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(visuals, "scale", Vector2(0.75, 0.75), 0.7)
		tween.parallel().tween_property(visuals, "modulate:a", 0.0, 0.7).set_delay(0.3)
	fade.color = Color(0.82, 0.84, 0.86)
	tween.tween_property(fade, "modulate:a", 1.0, 1.4)
	tween.tween_property(end_label, "modulate:a", 1.0, 0.6)
	level_completed.emit()
