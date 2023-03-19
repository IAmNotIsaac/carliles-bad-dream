class_name InteractArea
extends Area3D


signal interacted_with

enum Mode {
	CONTINUOUS,
	DISCRETE,
	SINGULAR,
}

const _HOVER_TIME_HINT := 10

@export_node_path("Logic") var logic_path : NodePath
@export var mode : Mode = Mode.CONTINUOUS

@onready var logic := get_node_or_null(logic_path)
@onready var _hint := $Hint

var _activation_count := 0
var _hovered_time := -_HOVER_TIME_HINT


## Private methods

func _ready() -> void:
	_hint.hide()


func _process(_delta : float) -> void:
	_hint.set_visible(Time.get_ticks_msec() - _hovered_time < _HOVER_TIME_HINT)


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
	
	if logic != null:
		logic.activate()
	
	interacted_with.emit()
	_activation_count += 1


func reset_activation_count() -> void:
	_activation_count = 0


func show_hint() -> void:
	_hovered_time = Time.get_ticks_msec()


func can_interact() -> bool:
	if mode == Mode.SINGULAR:
		return _activation_count == 0
	return true
