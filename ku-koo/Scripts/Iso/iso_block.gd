@tool
class_name IsoBlock
extends PlaceholderBlock
## Isometric level geometry: a box with a floor footprint of [member grid_size]
## tiles and a [member iso_height] in pixels. Drawn as a placeholder prism.
## The node origin is the CENTRE of the footprint (used for depth sorting),
## so place it at IsoMath.to_screen(grid_position + grid_size / 2).
##
## Heights: low (<= ~25) can be hopped onto/over, medium need hop + flap,
## very high (walls) block. Long walls should be split in 1-tile segments so
## depth sorting stays correct.
## To replace with art: add a Sprite2D child and untick show_placeholder.

@export var grid_size: Vector2 = Vector2(1, 1):
	set(value):
		grid_size = value
		_update_shape()
		queue_redraw()
@export var iso_height: float = 32.0:
	set(value):
		iso_height = value
		queue_redraw()

@export_group("See-through")
## Blocks at least this tall turn see-through when the pigeon is behind them.
@export var xray_min_height: float = 30.0
@export var xray_alpha: float = 0.3

## Who tall blocks keep visible (set by the pigeon).
static var xray_target: Node2D


func _ready() -> void:
	_shape_node = CollisionShape2D.new()
	_shape_node.shape = ConvexPolygonShape2D.new()
	add_child(_shape_node, false, Node.INTERNAL_MODE_FRONT)
	_update_shape()


func _update_shape() -> void:
	if _shape_node == null:
		return
	(_shape_node.shape as ConvexPolygonShape2D).points = IsoMath.footprint(grid_size)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not show_placeholder or iso_height < xray_min_height:
		return
	var want := 1.0
	var target := IsoBlock.xray_target
	if is_instance_valid(target) and z_index > target.z_index:
		if _screen_rect().intersects(target.call(&"get_xray_rect")):
			want = xray_alpha
	if not is_equal_approx(modulate.a, want):
		modulate.a = move_toward(modulate.a, want, delta * 4.0)


func _screen_rect() -> Rect2:
	var fp := IsoMath.footprint(grid_size)
	var rect := Rect2(fp[0], Vector2.ZERO)
	for point in fp:
		rect = rect.expand(point)
	rect.position.y -= iso_height
	rect.size.y += iso_height
	rect.position += global_position
	return rect


func get_iso_height() -> float:
	if _shape_node and _shape_node.disabled:
		return 0.0
	return iso_height


## Sinks into the floor and stops blocking (gates, barriers).
func lower(_arg: Variant = null) -> void:
	var tween := create_tween()
	tween.tween_property(self, "iso_height", 0.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(set_solid.bind(false))


func _draw() -> void:
	if not show_placeholder:
		return
	IsoMath.draw_prism(self, IsoMath.footprint(grid_size), iso_height,
		color.lightened(0.18), color, color.darkened(0.25))
