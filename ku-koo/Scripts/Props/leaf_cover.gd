class_name LeafCover
extends Node2D
## A leaf hiding something. A coo nearby makes it tremble (hint); pecking
## pushes it aside and makes the hidden item pickable.

signal uncovered

@export var hidden_item: CarryableItem
@export var mover: SlideMover


func _ready() -> void:
	if hidden_item:
		hidden_item.pickable = false
	mover.finished.connect(_on_moved)


func _on_moved() -> void:
	if hidden_item:
		hidden_item.make_pickable()
	uncovered.emit()
