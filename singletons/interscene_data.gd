extends Node


signal force_player_state(state : Player.States)

var player_camera_rot_x := 0.0
var player_camera_rot_y := 0.0
var player_crawling := false


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("crawl"):
		player_crawling = !player_crawling#event.is_action_pressed("crawl")
