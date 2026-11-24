@tool
class_name SwingDoor
extends PlaceholderBlock
## A door or shutter that swings open: it narrows to a thin edge (seen side-on)
## and stops blocking. Connect any signal to [method open].

signal opened

@export var open_width: float = 3.0
@export var open_time: float = 0.8
## Open towards the right (true) or the left.
@export var open_to_right: bool = true
## Optional art (e.g. the painted door) that swings with it: its scale.x
## shrinks around its left edge (use centered = false on the Sprite2D).
@export var visual: Node2D
@export var visual_open_scale: float = 0.12
## Instead of swinging, the closed-door art fades away and reveals the open
## door painted in the room behind it.
@export var visual_fades: bool = false

## False for a door in the back wall (walked past, not into): it never blocks,
## opening it only matters to whatever listens to [signal opened].
@export var blocks_when_closed: bool = true

var is_open: bool = false


func _ready() -> void:
	super._ready()
	if not blocks_when_closed:
		set_solid(false)


func open(_arg: Variant = null) -> void:
	if is_open:
		return
	is_open = true
	set_solid(false)
	var tween := create_tween()
	var target := Vector2(open_width, size.y)
	if open_to_right:
		tween.tween_property(self, "size", target, open_time).set_trans(Tween.TRANS_SINE)
	else:
		tween.set_parallel()
		tween.tween_property(self, "size", target, open_time).set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "position:x", position.x + size.x - open_width, open_time).set_trans(Tween.TRANS_SINE)
	if visual and visual_fades:
		tween.parallel().tween_property(visual, "modulate:a", 0.0, open_time).set_trans(Tween.TRANS_SINE)
	elif visual:
		tween.parallel().tween_property(visual, "scale:x", visual.scale.x * visual_open_scale, open_time).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(opened.emit)
