@tool
class_name Interactable
extends Area2D
## Base for everything the pigeon can peck. Add it as a child (with a
## CollisionShape2D) of any object; the [PeckAbility] picks the nearest one in
## front of the beak. Subclasses override [method _interact] and, if needed,
## [method can_interact].
##
## Gameplay results are exposed as signals, so puzzles are wired in the editor
## (Node > Signals) instead of in code.

signal interacted(pigeon: Pigeon)
signal focus_changed(is_focused: bool)

## Physics layer 5 ("interactables"): only the pigeon's beak looks at it.
const INTERACTABLE_LAYER := 1 << 4

@export var enabled: bool = true:
	set(value):
		enabled = value
		queue_redraw()
## Height of the peck point above the ground. Only used by pigeons that
## have a height (top-down camera); the side view ignores it.
@export var height: float = 0.0
@export var height_tolerance: float = 18.0
## Short verb shown in the debug HUD when focused ("bicar", "agarrar"...).
@export var prompt: String = "bicar"

@export_group("Focus marker (placeholder)")
@export var show_focus_marker: bool = true
@export var marker_offset: Vector2 = Vector2(0, -22)
@export var marker_color: Color = Color(1.0, 0.86, 0.3)

var is_focused: bool = false


func _ready() -> void:
	collision_layer = INTERACTABLE_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true


func _process(_delta: float) -> void:
	if is_focused and not Engine.is_editor_hint():
		queue_redraw()


func can_interact(pigeon: Pigeon) -> bool:
	return enabled and not pigeon.hold.is_busy() and height_ok(pigeon)


## Top-down only: the beak must be at about the right height.
func height_ok(pigeon: Pigeon) -> bool:
	if not pigeon.has_method(&"get_beak_height"):
		return true
	return absf(pigeon.call(&"get_beak_height") - get_peck_height()) <= height_tolerance


func get_peck_height() -> float:
	return height


func interact(pigeon: Pigeon) -> void:
	_interact(pigeon)
	interacted.emit(pigeon)


## Override in subclasses.
func _interact(_pigeon: Pigeon) -> void:
	pass


func enable(_arg: Variant = null) -> void:
	enabled = true


func disable(_arg: Variant = null) -> void:
	enabled = false


func set_focused(value: bool) -> void:
	is_focused = value
	queue_redraw()
	focus_changed.emit(value)


func _draw() -> void:
	if Engine.is_editor_hint():
		# Small cross so designers see where the peck point is.
		draw_line(Vector2(-3, 0), Vector2(3, 0), marker_color, 1.0)
		draw_line(Vector2(0, -3), Vector2(0, 3), marker_color, 1.0)
		return
	if not (is_focused and show_focus_marker):
		return
	var bob := sin(Time.get_ticks_msec() * 0.008) * 1.5
	var p := marker_offset + Vector2(0, bob)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-4, -5), p + Vector2(4, -5), p + Vector2(0, 1)]), marker_color)
