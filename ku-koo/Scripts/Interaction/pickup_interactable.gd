@tool
class_name PickupInteractable
extends Interactable
## Peck to pick up the parent [CarryableItem] (one object in the beak at a time).


func _init() -> void:
	prompt = "apanhar"


func get_item() -> CarryableItem:
	return get_parent() as CarryableItem


func can_interact(pigeon: Pigeon) -> bool:
	var item := get_item()
	return super(pigeon) and item != null and item.pickable and not item.is_carried


func _interact(pigeon: Pigeon) -> void:
	pigeon.hold.carry(get_item())
