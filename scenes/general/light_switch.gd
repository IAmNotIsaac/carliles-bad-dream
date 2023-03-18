extends Node3D


@export_node_path("Logic") var _logic_path : NodePath
@export var _start_off := false

@onready var _interact_area := $InteractArea
@onready var _lsp := $light_switch_piece
@onready var _off := _start_off
@onready var _anim := $AnimationPlayer


## Private methods

func _ready() -> void:
	_interact_area.logic_path = _logic_path
	_interact_area.logic = get_node_or_null(_logic_path)
	
	if _start_off:
		_lsp.rotation_degrees.x = 68.0


func _on_interact_area_interacted_with() -> void:
	_off = not _off
	
	match _off:
		true:
			_anim.play("turn_off")
		false:
			_anim.play("turn_on")
