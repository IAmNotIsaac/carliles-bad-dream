extends Logic


@export var _author : String
@export_multiline var _message : String
@export var _chars_per_second := 20.0
@export_node_path("Logic") var _next_path : NodePath


func _activated() -> void:
	var callback = func():
		var next := get_node_or_null(_next_path)
		
		if next is Logic:
			next.activate()
	
	Level.message(_author, _message, _chars_per_second, callback)
