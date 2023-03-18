extends Node3D


const _GIMBAL_TILT := 20.0
const _CAMERA_TILT := 20.0
const _GIMBAL_TILT_WEIGHT := 0.35
const _CAMERA_TILT_WEIGHT := 0.35

@onready var _play_button := $PlayButton
@onready var _play_button_label := $PlayButton/Label3D
@onready var _quit_button := $QuitButton
@onready var _quit_button_label := $QuitButton/Label3D
@onready var _raycast := $RayCast3D
@onready var _gimbal := $Gimbal
@onready var _camera := $Gimbal/Camera3D
@onready var _gimbal_offset : float = _gimbal.rotation_degrees.y
@onready var _camera_offset : float = _camera.rotation_degrees.x


## Private methods

func _input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_raycast()
		_update_camera_and_gimbal()
	
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var a := {
			_play_button: func():
				get_tree().change_scene_to_file("res://scenes/general/main.tscn"),
			_quit_button: func():
				get_tree().quit()
		}
		var col : Object = _raycast.get_collider()
		
		if a.has(col):
			a[col].call()


func _mouse_percent_directional() -> Vector2:
	var s := Vector2(DisplayServer.window_get_size())
	var m := get_viewport().get_mouse_position()
	return m / s - Vector2(0.5, 0.5)


func _update_raycast() -> void:
	var p := _mouse_percent_directional()
	
	# Magic numbers! :D
	_raycast.target_position.x = p.x * 27.0
	_raycast.target_position.y = p.y * -27.0
	
	var a := {
		_play_button: func():
			_play_button_label.modulate = Color.YELLOW
			_quit_button_label.modulate = Color.WHITE,
		_quit_button: func():
			_play_button_label.modulate = Color.WHITE
			_quit_button_label.modulate = Color.YELLOW
	}
	var col : Object = _raycast.get_collider()
	
	if a.has(col):
		a[col].call()
	else:
		_play_button_label.modulate = Color.WHITE
		_quit_button_label.modulate = Color.WHITE


func _update_camera_and_gimbal() -> void:
	var p := _mouse_percent_directional()
	
	var tg := -p.x * _GIMBAL_TILT + _gimbal_offset
	var tc := -p.y * _CAMERA_TILT + _camera_offset
	
	_gimbal.rotation_degrees.y += (tg - _gimbal.rotation_degrees.y) * _GIMBAL_TILT_WEIGHT
	_camera.rotation_degrees.x += (tc - _camera.rotation_degrees.x) * _CAMERA_TILT_WEIGHT

