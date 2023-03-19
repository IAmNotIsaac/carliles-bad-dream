extends Logic


@export_group("Condition", "_con_")
@export_node_path("Node") var _con_target_path : NodePath
@export_placeholder("Target property") var _con_property_name : String
@export var _con_callable := false
@export var _con_inverse := false
@export_placeholder("(optional)") var _con_string_value := ""
@export_node_path("Logic") var _true_path : NodePath
@export_node_path("Logic") var _else_path : NodePath

@onready var _true := get_node_or_null(_true_path)
@onready var _else := get_node_or_null(_else_path)
@onready var _con_target := get_node_or_null(_con_target_path)


## Private methods

func _activated() -> void:
	if _con_target == null:
		return
	
	var v = _con_target.get(_con_property_name)
	if _con_callable and v is Callable:
		v = v.call()
	var c = v
	
	if _con_string_value != "":
		c = str(v) == _con_string_value
	
	if _con_inverse:
		c = not c
	
	if c:
		if _true: _true.activate()
	else:
		if _else: _else.activate()
