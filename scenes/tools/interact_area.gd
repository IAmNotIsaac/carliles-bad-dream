class_name InteractArea
extends Area3D


signal interacted_with

enum Mode {
	CONTINUOUS,
	DISCRETE,
	SINGULAR
}

@export_node_path("Logic") var _logic_path : NodePath
@export var mode : Mode = Mode.CONTINUOUS

@onready var _logic := get_node_or_null(_logic_path)

var _activation_count := 0


## Public methods

func interact(continuous : bool) -> void:
	match mode:
		Mode.CONTINUOUS: pass
		Mode.DISCRETE:
			if continuous:
				return
		Mode.SINGULAR:
			if _activation_count > 0:
				return
	
	if _logic != null:
		_logic.activate()
	
	interacted_with.emit()
	_activation_count += 1


func reset_activation_count() -> void:
	_activation_count = 0
