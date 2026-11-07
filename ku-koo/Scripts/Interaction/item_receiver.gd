@tool
class_name ItemReceiver
extends Interactable
## Someone/something that takes a carried item (the hungry cat takes the cod,
## the partner takes the worm...). Only focusable while the pigeon carries an
## accepted item.

signal received(item: CarryableItem)

## Empty = accepts anything.
@export var accepted_item_id: StringName = &""
## Free the item after giving it (eaten). Otherwise the receiver keeps it.
@export var consume_item: bool = true
@export var one_shot: bool = true


func _init() -> void:
	prompt = "dar"


func can_interact(pigeon: Pigeon) -> bool:
	if not enabled or not pigeon.hold.is_carrying():
		return false
	return accepted_item_id == &"" or pigeon.hold.carried.item_id == accepted_item_id


func _interact(pigeon: Pigeon) -> void:
	var item := pigeon.hold.take_carried()
	pigeon.action.emit(&"give")
	received.emit(item)
	if consume_item:
		item.consume()
	if one_shot:
		enabled = false
