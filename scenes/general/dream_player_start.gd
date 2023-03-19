@tool
class_name DreamPlayerStart
extends Marker3D


@export var id := 0
@export var _hint : String:
	set(v):
		_hint = v
		if is_inside_tree():
			_label.text = v

@onready var _label := $Label3D
