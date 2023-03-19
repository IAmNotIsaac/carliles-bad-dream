extends Logic


@export var _author : String
@export_multiline var _message : String
@export var _chars_per_second := 20.0
@export var _override_message := false
@export_node_path("Logic") var _next_path : NodePath


func _activated() -> void:
	var callback = func():
		var next := get_node_or_null(_next_path)
		
		if next is Logic:
			next.activate()
	
	if Level.is_message_active() and not _override_message:
		return
	
	Level.message(_author, _message, _chars_per_second, callback)
