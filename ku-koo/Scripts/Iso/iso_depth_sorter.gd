class_name IsoDepthSorter
extends Node
## Draw order for the isometric view (replaces Godot's y-sort).
## Every frame each child of [member world] gets z_index = its depth:
## its screen Y, or get_iso_depth() when it has one (the pigeon and items
## use it to stay in front of the box they stand on).

@export var world: Node2D


func _process(_delta: float) -> void:
	for child in world.get_children():
		var item := child as Node2D
		if item == null:
			continue
		var depth: float = item.call(&"get_iso_depth") if item.has_method(&"get_iso_depth") else item.global_position.y
		item.z_index = clampi(int(depth), RenderingServer.CANVAS_ITEM_Z_MIN + 10, RenderingServer.CANVAS_ITEM_Z_MAX - 200)
