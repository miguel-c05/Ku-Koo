class_name BeakHold
extends Marker2D
## What the pigeon has in its beak: one carried [CarryableItem] OR one gripped
## [PushableBody] (push/pull). Sits at the tip of the beak.

signal carried_changed(item: CarryableItem)
signal grabbed_changed(body: PushableBody)

var carried: CarryableItem = null
var grabbed: PushableBody = null
## Offset body - pigeon at the moment of gripping.
var grab_offset: Vector2 = Vector2.ZERO
## Set by the visuals so the carried item follows the head-bob.
var visual_offset: Vector2 = Vector2.ZERO:
	set(value):
		visual_offset = value
		_refresh_position()

var _base: Vector2
var _facing: int = 1

@onready var pigeon: Pigeon = get_parent() as Pigeon


func _ready() -> void:
	_base = Vector2(absf(position.x), position.y)


func is_carrying() -> bool:
	return carried != null


func is_grabbing() -> bool:
	return grabbed != null


func is_busy() -> bool:
	return carried != null or grabbed != null


func carry(item: CarryableItem) -> bool:
	if item == null or is_busy():
		return false
	carried = item
	item.attach_to(self)
	item.set_facing(_facing)
	pigeon.action.emit(&"pick_up")
	carried_changed.emit(item)
	return true


## Drops the carried item in front of the beak.
func drop() -> void:
	var item := take_carried()
	if item == null:
		return
	item.detach(pigeon.get_parent(), global_position, Vector2(pigeon.facing * 30.0, -30.0))
	pigeon.action.emit(&"drop")


## Removes the item from the beak and hands it over; the caller decides what happens to it.
func take_carried() -> CarryableItem:
	var item := carried
	carried = null
	if item:
		carried_changed.emit(null)
	return item


func grab(body: PushableBody) -> bool:
	if body == null or is_busy():
		return false
	grabbed = body
	grab_offset = body.global_position - pigeon.global_position
	pigeon.add_collision_exception_with(body)
	body.on_grabbed(pigeon)
	pigeon.set_facing(int(signf(grab_offset.x)))
	pigeon.action.emit(&"grab")
	grabbed_changed.emit(body)
	return true


func release() -> void:
	if grabbed == null:
		return
	var body := grabbed
	grabbed = null
	if is_instance_valid(body):
		pigeon.remove_collision_exception_with(body)
		body.on_released(pigeon)
	pigeon.action.emit(&"release")
	grabbed_changed.emit(null)


func set_facing(new_facing: int) -> void:
	_facing = new_facing
	_refresh_position()
	if carried:
		carried.set_facing(new_facing)


func _refresh_position() -> void:
	position = Vector2((_base.x + visual_offset.x) * _facing, _base.y + visual_offset.y)
