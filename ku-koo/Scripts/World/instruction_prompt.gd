@tool
class_name InstructionPrompt
extends Area2D
## In-world instruction ("A / D  andar"). Appears when the pigeon enters the
## zone the first time the action is needed and fades once it is done; never
## shown again, except prompts marked [member show_every_time] (the coo).
## Placeholder lettering: a Label; later a hand-lettered sprite.

@export_multiline var text: String = "":
	set(value):
		text = value
		if _label:
			_label.text = value
## The [signal Pigeon.action] that completes it (&"jump", &"peck", &"coo"...).
@export var completed_by: StringName = &""
@export var show_every_time: bool = false
## For prompts with no single completing action: done once the pigeon walks out of the zone.
@export var complete_on_exit: bool = false
@export var zone_size: Vector2 = Vector2(120, 80):
	set(value):
		zone_size = value
		queue_redraw()
## Where the text sits, relative to the zone's origin (bottom centre).
@export var label_offset: Vector2 = Vector2(0, -60)
@export var font_size: int = 18

var _label: Label
var _done: bool = false
var _pigeon: Pigeon
var _tween: Tween


func _ready() -> void:
	_label = Label.new()
	_label.text = text
	_label.add_theme_font_size_override(&"font_size", font_size)
	_label.add_theme_color_override(&"font_color", Color(1.0, 0.95, 0.82))
	_label.add_theme_constant_override(&"outline_size", 6)
	_label.add_theme_color_override(&"font_outline_color", Color(0.1, 0.07, 0.05, 0.9))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.scale = Vector2(0.5, 0.5)
	add_child(_label, false, Node.INTERNAL_MODE_FRONT)
	_label.reset_size()
	_label.position = label_offset - Vector2(_label.size.x * 0.25, _label.size.y * 0.5)
	if Engine.is_editor_hint():
		return
	_label.modulate.a = 0.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = zone_size
	shape.shape = rect
	shape.position = Vector2(0, -zone_size.y * 0.5)
	add_child(shape, false, Node.INTERNAL_MODE_FRONT)
	collision_layer = 0
	collision_mask = 2  # pigeon layer
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	var pigeon := body as Pigeon
	if pigeon == null or (_done and not show_every_time):
		return
	_pigeon = pigeon
	if not pigeon.action.is_connected(_on_action):
		pigeon.action.connect(_on_action)
	_fade(1.0)


func _on_body_exited(body: Node2D) -> void:
	if body != _pigeon:
		return
	_fade(0.0)
	if complete_on_exit:
		_done = true
	if _pigeon.action.is_connected(_on_action):
		_pigeon.action.disconnect(_on_action)
	_pigeon = null


func _on_action(action_name: StringName) -> void:
	if completed_by != &"" and action_name == completed_by:
		_done = true
		_fade(0.0, 0.8)


func _fade(to: float, duration: float = 0.35) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", to, duration)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2(-zone_size.x * 0.5, -zone_size.y), zone_size), Color(1, 0.9, 0.4, 0.15))
