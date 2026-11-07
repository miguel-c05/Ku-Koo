@tool
class_name PlaceholderSkyline
extends Node2D
## Placeholder parallax layer content: a row of rectangles (house fronts,
## chimneys, posts). Put it inside a Parallax2D. Replace with painted layers.

@export var random_seed: int = 1:
	set(v):
		random_seed = v
		queue_redraw()
@export var span: Vector2 = Vector2(-400, 3200):
	set(v):
		span = v
		queue_redraw()
## Y of the bottom of the shapes.
@export var base_y: float = 0.0:
	set(v):
		base_y = v
		queue_redraw()
@export var width_range: Vector2 = Vector2(60, 140):
	set(v):
		width_range = v
		queue_redraw()
@export var height_range: Vector2 = Vector2(80, 220):
	set(v):
		height_range = v
		queue_redraw()
@export var gap_range: Vector2 = Vector2(0, 30):
	set(v):
		gap_range = v
		queue_redraw()
@export var color: Color = Color(0.2, 0.18, 0.17):
	set(v):
		color = v
		queue_redraw()
## Small lit windows on the shapes.
@export var windows: bool = true:
	set(v):
		windows = v
		queue_redraw()
@export var window_color: Color = Color(0.55, 0.42, 0.25, 0.6)


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	var x := span.x
	while x < span.y:
		var w := rng.randf_range(width_range.x, width_range.y)
		var h := rng.randf_range(height_range.x, height_range.y)
		draw_rect(Rect2(x, base_y - h, w, h), color.lightened(rng.randf_range(-0.04, 0.04)))
		if windows:
			var wy := base_y - h + 14.0
			while wy < base_y - 24.0:
				var wx := x + 10.0
				while wx < x + w - 16.0:
					if rng.randf() < 0.35:
						draw_rect(Rect2(wx, wy, 8, 12), window_color)
					wx += 22.0
				wy += 30.0
		x += w + rng.randf_range(gap_range.x, gap_range.y)
