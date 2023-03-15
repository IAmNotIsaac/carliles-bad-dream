extends RealWorld


@onready var _ceiling_light := $Lights/CeilingLight


## Private methods

func _on_enter_carlile_dream_interacted_with() -> void:
	Level.load_dream_world(Level.LEVELS.DREAM.TEST_DREAM_WORLD)


func _on_ceiling_light_visibility_changed() -> void:
	if Level.root_nodes.dream:
		Level.root_nodes.dream.set_light(_ceiling_light.visible)


## Public methods

func is_light() -> bool:
	return _ceiling_light.is_visible()
