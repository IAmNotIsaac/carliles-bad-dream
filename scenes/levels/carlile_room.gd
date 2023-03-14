extends Node3D


func _on_enter_carlile_dream_interacted_with() -> void:
	Level.load_dream_world(Level.LEVELS.DREAM.TEST_DREAM_WORLD)
