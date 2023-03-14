extends Node


signal deferred_input(event : InputEvent)


const LEVELS := {
	"REAL": {
		"TEST_WORLD": "res://scenes/levels/test_world.tscn",
		"CARLILE_ROOM": "res://scenes/levels/carlile_room.tscn",
	},
	"DREAM": {
		"TEST_DREAM_WORLD": "res://scenes/levels/test_dream_world.tscn"
	}
}

var _load_paths := {
	"real": "",
	"dream": ""
}

@onready var _ui := $UI
@onready var _game := $Game
@onready var _real_world_container := $%RealWorldContainer
@onready var _real_world_viewport := $%RealWorldViewport
@onready var _real_progress_bar := $%RealProgressBar
@onready var _real_load_screen := $%RealLoadScreen
@onready var _dream_world_container := $%DreamWorldContainer
@onready var _dream_world_viewport := $%DreamWorldViewport
@onready var _dream_progress_bar := $%DreamProgressBar
@onready var _dream_load_screen := $%DreamLoadScreen


## Private methods

func _ready() -> void:
	load_real_world("res://scenes/levels/carlile_room.tscn")


func _input(event : InputEvent) -> void:
	deferred_input.emit(event)


func _process(_delta : float) -> void:
	_load_level("real", _real_progress_bar, _real_load_screen, _real_world_viewport)
	_load_level("dream", _dream_progress_bar, _dream_load_screen, _dream_world_viewport)
	
	_real_world_container.set_visible(_real_world_viewport.get_children(true) != [] or _load_paths["real"] != "")
	_dream_world_container.set_visible(_dream_world_viewport.get_children(true) != [] or _load_paths["dream"] != "")


func _load_level(path_key : String, progress_bar : ProgressBar, load_screen : Control, root_node : Node) -> void:
	var progress := []
	var load_status := ResourceLoader.load_threaded_get_status(_load_paths[path_key], progress)
	match load_status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			load_screen.hide()
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			load_screen.show()
			progress_bar.set_value(progress[0] * 100.0)
		ResourceLoader.THREAD_LOAD_FAILED:
			_load_paths[path_key] = ""
			OS.alert("Error whilst loading level, please notify developer.\nClose game if issue does not resolve itself.\n%s" % [progress])
		ResourceLoader.THREAD_LOAD_LOADED:
			load_screen.hide()
			var res := ResourceLoader.load_threaded_get(_load_paths[path_key])
			_load_paths[path_key] = ""
			if not res is PackedScene:
				push_error("Attempted loading level that is not a PackedScene")
				return
			root_node.add_child(res.instantiate())


## Public methods

func load_real_world(path : String) -> void:
	if ResourceLoader.exists(path):
		_load_paths["real"] = path
		await get_tree().create_timer(1.0).timeout
		ResourceLoader.load_threaded_request(path)


func close_real_world() -> void:
	for c in _real_world_viewport.get_children(true):
		c.queue_free()


func load_dream_world(path : String) -> void:
	if ResourceLoader.exists(path):
		_load_paths["dream"] = path
		ResourceLoader.load_threaded_request(path)


func close_dream_world() -> void:
	for c in _dream_world_viewport.get_children(true):
		c.queue_free()
