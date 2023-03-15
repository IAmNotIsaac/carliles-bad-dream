class_name DreamWorld
extends Node3D


enum EnvironmentMode {
	LIGHT, DARK
}

@export var environment_mode : EnvironmentMode = EnvironmentMode.LIGHT:
	set(v):
		environment_mode = v
		if is_inside_tree():
			_update_environment()
@export var _light_environment : Environment
@export var _dark_environment : Environment
@export_node_path("DirectionalLight3D") var _sun_path : NodePath

@onready var _sun := get_node_or_null(_sun_path)


## Private methods

func _ready() -> void:
	environment_mode = bool_to_environment_mode(Level.root_nodes.real.is_light())
	_update_environment()


func _update_environment() -> void:
	match environment_mode:
		EnvironmentMode.LIGHT:
			get_viewport().find_world_3d().environment = _light_environment
			if _sun:
				_sun.show()
		EnvironmentMode.DARK:
			get_viewport().find_world_3d().environment = _dark_environment
			if _sun:
				_sun.hide()


## Public methods

func toggle_light() -> void:
	match environment_mode:
		EnvironmentMode.LIGHT:
			environment_mode = EnvironmentMode.DARK
		EnvironmentMode.DARK:
			environment_mode = EnvironmentMode.LIGHT


func set_light(light : bool) -> void:
	environment_mode = bool_to_environment_mode(light)


static func bool_to_environment_mode(is_light : bool) -> EnvironmentMode:
	return {
		true: EnvironmentMode.LIGHT,
		false: EnvironmentMode.DARK,
	}[is_light]
