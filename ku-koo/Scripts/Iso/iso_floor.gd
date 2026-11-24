@tool
class_name IsoFloor
extends Node2D
## Placeholder isometric floor: a checkerboard of diamond tiles.
## Replace with a TileMapLayer (isometric) or painted floor art.

@export var grid_rect: Rect2 = Rect2(0, 0, 10, 10):
	set(value):
		grid_rect = value
		queue_redraw()
@export var color_a: Color = Color(0.33, 0.3, 0.28):
	set(value):
		color_a = value
		queue_redraw()
@export var color_b: Color = Color(0.3, 0.27, 0.26):
	set(value):
		color_b = value
		queue_redraw()


func _draw() -> void:
	var x0 := int(grid_rect.position.x)
	var y0 := int(grid_rect.position.y)
	for gx in range(x0, x0 + int(grid_rect.size.x)):
		for gy in range(y0, y0 + int(grid_rect.size.y)):
			var c := color_a if (gx + gy) % 2 == 0 else color_b
			draw_colored_polygon(PackedVector2Array([
				IsoMath.to_screen(Vector2(gx, gy)),
				IsoMath.to_screen(Vector2(gx + 1, gy)),
				IsoMath.to_screen(Vector2(gx + 1, gy + 1)),
				IsoMath.to_screen(Vector2(gx, gy + 1)),
			]), c)
