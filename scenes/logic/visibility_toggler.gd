extends Logic


@export_node_path("CanvasItem", "Node3D") var _target_path : NodePath

@onready var _target := get_node_or_null(_target_path)


func _activated() -> void:
	if _target != null:
		_target.set_visible(not _target.is_visible())
