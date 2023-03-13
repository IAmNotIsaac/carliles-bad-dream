class_name DynamicCamera
extends Node3D


@export_node_path("CameraTarget") var _target_path : NodePath
@export var _current := false

@onready var _target : CameraTarget = get_node_or_null(_target_path)
@onready var _n_cam := $Camera3D


## Private methods ##

func _ready() -> void:
	if _current:
		_n_cam.make_current()


func _process(_delta : float) -> void:
	if _target != null:
		global_position = global_position.lerp(_target.global_position, _target.weight)
		global_rotation = Vector3(
			lerp_angle(global_rotation.x, _target.global_rotation.x, _target.weight),
			lerp_angle(global_rotation.y, _target.global_rotation.y, _target.weight),
			lerp_angle(global_rotation.z, _target.global_rotation.z, _target.weight)
		)
		_n_cam.h_offset = lerp(_n_cam.h_offset, _target.get_h_offset(), _target.weight)
		_n_cam.v_offset = lerp(_n_cam.v_offset, _target.get_v_offset(), _target.weight)
		_n_cam.cull_mask = _target.get_cull_mask()
		_n_cam.position = _target.position_offset


## Public methods ##

func set_target(target : CameraTarget) -> void:
	_target = target


func get_camera() -> Camera3D:
	return _n_cam
