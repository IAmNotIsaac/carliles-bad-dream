extends Logic


@export_node_path("Logic") var _target_a : NodePath
@export_node_path("Logic") var _target_b : NodePath
@export_node_path("Logic") var _target_c : NodePath
@export_node_path("Logic") var _target_d : NodePath
@export_node_path("Logic") var _target_e : NodePath
@export_node_path("Logic") var _target_f : NodePath
@export_node_path("Logic") var _target_g : NodePath
@export_node_path("Logic") var _target_h : NodePath

@onready var _targets := [
	get_node_or_null(_target_a),
	get_node_or_null(_target_b),
	get_node_or_null(_target_c),
	get_node_or_null(_target_d),
	get_node_or_null(_target_e),
	get_node_or_null(_target_f),
	get_node_or_null(_target_g),
	get_node_or_null(_target_h),
]


func _activated() -> void:
	for t in _targets:
		if t != null:
			t.activate()
