extends Node3D


@export var _start_index := 0
@export var _level : String

@onready var _cam := $Camera3D
@onready var _anim := $AnimationPlayer


## Private methods

func _on_interact_area_interacted_with() -> void:
	_cam.make_current()
	_anim.play("open")
	await _anim.animation_finished
	Level.load_dream_world(Level.LEVELS.DREAM[_level])
