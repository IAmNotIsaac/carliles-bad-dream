class_name InteractArea
extends Area3D


signal interacted_with

enum Mode {
	CONTINUOUS,
	DISCRETE,
	SINGULAR
}

@export var mode : Mode = Mode.CONTINUOUS

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
	
	interacted_with.emit()
	_activation_count += 1
