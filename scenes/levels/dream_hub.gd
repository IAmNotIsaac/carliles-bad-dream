@tool
extends DreamWorld


@onready var _player := $Player

var _last_grounded_player_pos : Vector3


## Private methods

func _process(delta : float) -> void:
	if not Engine.is_editor_hint():
		if _player.state.get_state() == Player.States.GROUND:
			_last_grounded_player_pos = _player.global_position


func _on_fall_area_body_entered(body : PhysicsBody3D) -> void:
	if body == _player:
		_player.global_position = _last_grounded_player_pos
		_player.velocity = Vector3.ZERO
