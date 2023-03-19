extends Node


## Private methods

func _ready() -> void:
	_dream_mesh_children(self)


func _dream_mesh_children(node : Node) -> void:
	if node is MeshInstance3D:
		node.layers <<= 10
	
	for c in node.get_children(true):
		_dream_mesh_children(c)
