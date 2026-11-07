@tool
class_name GrabInteractable
extends Interactable
## Peck to grip the parent [PushableBody] in the beak; then walking pushes or
## pulls it. Peck again (or jump) to let go.

## The pigeon must stand at about the same height as the object.
@export var max_height_difference: float = 6.0


func _init() -> void:
	prompt = "agarrar"


func get_body() -> PushableBody:
	return get_parent() as PushableBody


func can_interact(pigeon: Pigeon) -> bool:
	var body := get_body()
	return super(pigeon) and body != null and pigeon.is_on_floor() \
		and absf(body.global_position.y - pigeon.global_position.y) <= max_height_difference


func _interact(pigeon: Pigeon) -> void:
	pigeon.hold.grab(get_body())
