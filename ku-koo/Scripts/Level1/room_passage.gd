@tool
class_name RoomPassage
extends TriggerZone
## A way into another room (a hole in the wall, an open door). Walking into
## it (or, with [member require_action], pressing that action while in front of
## it) hands the pigeon to the level, which steps it in, fades and puts it at
## [member entry] in the other room. Origin = bottom centre of the opening.

## Where the pigeon appears in the next room (a Marker2D inside that room).
@export var entry: Node2D
## Closed passages (a shut door) do nothing until [method enable] is called.
@export var enabled: bool = true
## If set (e.g. &"enter_door"), walking in is not enough: the pigeon has to
## press this action while standing in front of the opening.
@export var require_action: StringName = &""

signal pigeon_passed(passage: RoomPassage, pigeon: Pigeon)


func _ready() -> void:
	one_shot = false
	super._ready()
	if not Engine.is_editor_hint():
		pigeon_entered.connect(_on_pigeon_entered)


func enable(_arg: Variant = null) -> void:
	enabled = true
	if require_action != &"":
		return
	# Already standing in it when it opens.
	for body in get_overlapping_bodies():
		if body is Pigeon:
			_on_pigeon_entered(body)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or require_action == &"" or not enabled or entry == null:
		return
	if not Input.is_action_just_pressed(require_action):
		return
	for body in get_overlapping_bodies():
		var pigeon := body as Pigeon
		if pigeon and pigeon.input_enabled and pigeon.is_on_floor():
			pigeon_passed.emit(self, pigeon)
			return


func _on_pigeon_entered(pigeon: Pigeon) -> void:
	if enabled and entry and require_action == &"":
		pigeon_passed.emit(self, pigeon)
