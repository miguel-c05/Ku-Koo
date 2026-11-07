class_name CarryableItem
extends RigidBody2D
## A small object the pigeon can carry in its beak (worm, dried cod, key...).
## Needs a child [PickupInteractable] so it can be pecked up.
## While carried it is frozen, non-colliding and parented to the [BeakHold].

signal picked_up
signal dropped

@export var item_id: StringName = &"item"
@export var display_name: String = "objeto"
## False while it cannot be taken yet (hanging on a string, hidden under a leaf).
@export var pickable: bool = true
## Starts frozen in the air, e.g. hanging, until [method release] is called.
@export var start_hanging: bool = false
## Local offset while held in the beak.
@export var carry_offset: Vector2 = Vector2(4, 0)
## Flipped with the pigeon's facing. Defaults to the child "Sprite2D".
@export var visual: Node2D

var is_carried: bool = false

var _layer: int
var _mask: int


func _ready() -> void:
	_layer = collision_layer
	_mask = collision_mask
	lock_rotation = true
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	if start_hanging:
		freeze = true
		pickable = false
	if visual == null:
		visual = get_node_or_null(^"Sprite2D") as Node2D


## Lets a hanging item fall (connect a string's "broken" signal here).
func release(_arg: Variant = null) -> void:
	freeze = false
	sleeping = false
	pickable = true


func make_pickable(_arg: Variant = null) -> void:
	pickable = true


func attach_to(holder: Node2D) -> void:
	is_carried = true
	freeze = true
	linear_velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	reparent(holder, false)
	position = carry_offset
	rotation = 0.0
	picked_up.emit()


func detach(new_parent: Node, at_global: Vector2, throw_velocity: Vector2) -> void:
	is_carried = false
	reparent(new_parent, false)
	global_position = at_global
	rotation = 0.0
	scale = Vector2.ONE
	collision_layer = _layer
	collision_mask = _mask
	freeze = false
	sleeping = false
	linear_velocity = throw_velocity
	if visual:
		visual.scale.x = absf(visual.scale.x)
	dropped.emit()


## Used when the item is given away and eaten.
func consume() -> void:
	queue_free()


func set_facing(facing: int) -> void:
	if visual:
		visual.scale.x = absf(visual.scale.x) * facing
	if is_carried:
		position = Vector2(carry_offset.x * facing, carry_offset.y)
