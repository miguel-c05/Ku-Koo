class_name IsoCarryableItem
extends CarryableItem
## Top-down version of [CarryableItem]: no gravity on the screen plane; the
## item has a height instead. Hanging items fall to the floor when released,
## dropped items fall from the beak, and they rest on whatever is below
## (floor or a box top).

## Height while hanging (start_hanging).
@export var hang_height: float = 44.0
## Pickup interactable whose peck height follows the item. Defaults to child "Pickup".
@export var pickup: Interactable

## Current height of the item above the floor.
var item_z: float = 0.0:
	set(value):
		item_z = value
		_apply_height()

var _support: Node2D = null
var _visual_rest: Vector2 = Vector2.ZERO
var _fall_tween: Tween


func _ready() -> void:
	super()
	gravity_scale = 0.0
	linear_damp = 8.0
	if pickup == null:
		pickup = get_node_or_null(^"Pickup") as Interactable
	if visual:
		_visual_rest = visual.position
	item_z = hang_height if start_hanging else 0.0


func release(_arg: Variant = null) -> void:
	freeze = false
	sleeping = false
	_fall_to_ground(func(): pickable = true)


func attach_to(holder: Node2D) -> void:
	if _fall_tween:
		_fall_tween.kill()
	super(holder)
	item_z = 0.0  # the beak already carries the height


func detach(new_parent: Node, at_global: Vector2, throw_velocity: Vector2) -> void:
	var pigeon := get_parent().get_parent() as PigeonTopDown
	var from_height := pigeon.get_beak_height() if pigeon else 10.0
	super(new_parent, at_global, throw_velocity)
	item_z = from_height
	_fall_to_ground()


func _fall_to_ground(on_landed: Callable = Callable()) -> void:
	var surface := IsoMath.surface_at(self, global_position)
	var floor_z: float = surface.height
	_support = surface.node
	if _fall_tween:
		_fall_tween.kill()
	_fall_tween = create_tween()
	var t := sqrt(maxf(item_z - floor_z, 0.0) / 400.0) + 0.05
	_fall_tween.tween_property(self, "item_z", floor_z, t).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_fall_tween.tween_property(self, "item_z", floor_z + 3.0, 0.08).set_ease(Tween.EASE_OUT)
	_fall_tween.tween_property(self, "item_z", floor_z, 0.08).set_ease(Tween.EASE_IN)
	if on_landed.is_valid():
		_fall_tween.tween_callback(on_landed)


func get_iso_depth() -> float:
	return IsoMath.depth_on(global_position, _support)


func _apply_height() -> void:
	if visual:
		visual.position = _visual_rest + Vector2(0, -item_z)
	if pickup:
		pickup.height = item_z
