class_name CameraTarget
extends Node3D


@export var h_offset := 0.0
@export var v_offset := 0.0
@export var position_offset := Vector3.ZERO
@export_flags_3d_render var cull_mask := 1048575
@export_range(0.0, 1.0) var weight := 1.0


## Public methods ##

func set_h_offset(value : float) -> void:
	h_offset = value


func get_h_offset() -> float:
	return h_offset


func set_v_offset(value : float) -> void:
	v_offset = value


func get_v_offset() -> float:
	return v_offset


func set_position_offset(value : Vector3) -> void:
	position_offset = value


func get_position_offset() -> Vector3:
	return position_offset


func set_cull_mask(mask : int) -> void:
	cull_mask = mask


func get_cull_mask() -> int:
	return cull_mask
