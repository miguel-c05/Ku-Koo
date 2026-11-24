@tool
class_name LevelRoom
extends Node2D
## One room of a level: a full-screen painting. Origin = left end of the floor
## (floor at y 0). Rooms with the same [member segment] sit side by side and the
## camera scrolls freely across them; going to another segment goes through a
## [RoomPassage] (a door) with a fade.

## Size of the room in world units (the painting at its world scale).
@export var room_size: Vector2 = Vector2(726, 408)
## Distance from the top of the painting down to the floor.
@export var floor_depth: float = 353.0
## Rooms that join up seamlessly share a segment number.
@export var segment: int = 0


func get_rect() -> Rect2:
	return Rect2(global_position + Vector2(0, -floor_depth), room_size)


## Locks the camera to this room.
func frame_camera(camera: Camera2D) -> void:
	var r := get_rect()
	camera.limit_left = int(round(r.position.x))
	camera.limit_top = int(round(r.position.y))
	camera.limit_right = int(round(r.end.x))
	camera.limit_bottom = int(round(r.end.y))
	camera.global_position = r.get_center()
	camera.reset_smoothing()


func _draw() -> void:
	if Engine.is_editor_hint():
		var r := Rect2(Vector2(0, -floor_depth), room_size)
		draw_rect(r, Color(1, 0.8, 0.3, 0.6), false, 2.0)
