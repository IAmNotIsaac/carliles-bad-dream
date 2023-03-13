class_name InteractArea
extends Area3D


signal interacted_with


## Public methods

func interact() -> void:
	interacted_with.emit()
