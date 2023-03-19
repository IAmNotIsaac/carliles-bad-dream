@tool
extends DreamWorld


@onready var _player := $Player

var _last_grounded_player_pos : Vector3


## Private methods

func _ready() -> void:
	super()
	var start_idx : int = Level.get_dream_metadata("start_idx", 0)
	var starts : Array[Node] = get_tree().get_nodes_in_group("dream_player_start")
	for s in starts:
		if s is DreamPlayerStart and s.id == start_idx:
			_player.global_position = s.global_position
			_player.set_yaw(s.global_rotation_degrees.y)
			break


func _process(delta : float) -> void:
	if not Engine.is_editor_hint():
		if _player.state.get_state() == Player.States.GROUND:
			_last_grounded_player_pos = _player.global_position


func _on_fall_area_body_entered(body : PhysicsBody3D) -> void:
	if body == _player:
		_player.global_position = _last_grounded_player_pos
		_player.velocity = Vector3.ZERO
