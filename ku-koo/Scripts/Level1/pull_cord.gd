@tool
class_name PullCord
extends PushableBody
## A cord hanging from a latch (level 1, beat 6). The pigeon grips its end
## with a peck (child GrabInteractable) and walks away to pull it; when pulled
## far enough it emits [signal pulled] once (lift the latch, open the door).
## It springs back when let go. Not solid. Origin = the cord's end.

signal pulled

## Where the cord hangs from (the latch).
@export var anchor: Node2D
## -1 = pulled towards the left.
@export var pull_direction: int = -1
@export var pull_distance: float = 24.0
@export var color: Color = Color(0.7, 0.6, 0.42)
@export var width: float = 1.5

var is_pulled: bool = false

var _start_x: float


func _ready() -> void:
	_start_x = position.x
	collision_layer = 0
	collision_mask = 0


func _process(_delta: float) -> void:
	queue_redraw()


func _physics_process(_delta: float) -> void:
	pass  # hangs; no gravity


func slide_by(dx: float) -> float:
	var offset := (position.x - _start_x) * pull_direction
	var new_offset := clampf(offset + dx * pull_direction, 0.0, pull_distance)
	var applied := (new_offset - offset) * pull_direction
	position.x += applied
	if not is_pulled and new_offset >= pull_distance * 0.95:
		is_pulled = true
		pulled.emit()
	return applied


func on_released(pigeon: Pigeon) -> void:
	super(pigeon)
	var tween := create_tween()
	tween.tween_property(self, "position:x", _start_x, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	if anchor:
		draw_line(to_local(anchor.global_position), Vector2.ZERO, color, width)
	draw_circle(Vector2.ZERO, 2.5, color.darkened(0.2))
