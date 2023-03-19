extends Node


signal deferred_input(event : InputEvent)

const LEVELS := {
	"REAL": {
		"TEST_WORLD": "res://scenes/levels/test_world.tscn",
		"CARLILE_ROOM": "res://scenes/levels/carlile_room.tscn",
	},
	"DREAM": {
		"TEST_DREAM_WORLD": "res://scenes/levels/test_dream_world.tscn",
		"DREAM_HUB": "res://scenes/levels/dream_hub.tscn",
	}
}
const DEFAULT_CHARS_PER_SECOND := 12

var _load_paths := { "real": "", "dream": "" }
var _message_tween : Tween
var _message_callback : Callable
var _paused := false

var root_nodes := { "real": null, "dream": null }

@onready var _real_world_container := $%RealWorldContainer
@onready var _real_world_viewport := $%RealWorldViewport
@onready var _real_progress_bar := $%RealProgressBar
@onready var _real_load_screen := $%RealLoadScreen
@onready var _dream_world_container := $%DreamWorldContainer
@onready var _dream_world_viewport := $%DreamWorldViewport
@onready var _dream_progress_bar := $%DreamProgressBar
@onready var _dream_load_screen := $%DreamLoadScreen
@onready var _message_box := $UI/Root/MessageBox
@onready var _message_text := $UI/Root/MessageBox/TextMargin/Text
@onready var _message_author := $UI/Root/MessageBox/AuthorMargin/Author
@onready var _pause_menu := $%PauseMenu

## Private methods

func _ready() -> void:
	_pause_menu.hide()
	_clear_message()


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("action") and is_message_active():
		if is_message_finished():
			_close_message()
		else:
			_finish_message()
	elif event.is_action_pressed("pause"):
		_toggle_pause()
	else:
		if not _paused:
			deferred_input.emit(event)


func _process(_delta : float) -> void:
	_load_level("real", _real_progress_bar, _real_load_screen, _real_world_viewport, "real")
	_load_level("dream", _dream_progress_bar, _dream_load_screen, _dream_world_viewport, "dream")
	
	_real_world_container.set_visible(_real_world_viewport.get_children(true) != [] or _load_paths["real"] != "")
	_dream_world_container.set_visible(_dream_world_viewport.get_children(true) != [] or _load_paths["dream"] != "")


func _load_level(path_key : String, progress_bar : ProgressBar, load_screen : Control, viewport_node : Node, root_key : String) -> void:
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
			var root : Node3D = res.instantiate()
			viewport_node.add_child(root)
			root_nodes[root_key] = root


func _toggle_pause() -> void:
	_paused = not _paused
	_pause_menu.set_visible(_paused)
	get_tree().paused = _paused
	
	if _paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	else:
		if is_real_world_active() or is_dream_world_active():
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _clear_message() -> void:
	if _message_tween:
		_message_tween.kill()
	
	_message_box.hide()
	_message_author.text = ""
	_message_text.text = ""
	_message_text.visible_characters = -1


func _close_message() -> void:
	if _message_callback:
		_message_callback.call()
	_clear_message()


func _finish_message() -> void:
	_message_tween.kill()
	_message_text.visible_characters = -1


## Public methods

func load_real_world(path : String) -> void:
	close_real_world()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if ResourceLoader.exists(path):
		_load_paths["real"] = path
		await get_tree().create_timer(1.0).timeout
		ResourceLoader.load_threaded_request(path)


func close_real_world() -> void:
	root_nodes.real = null
	for c in _real_world_viewport.get_children(true):
		c.queue_free()
	
	if not is_dream_world_active():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func is_real_world_active() -> bool:
	return _real_world_viewport.get_children(true) != []


func load_dream_world(path : String) -> void:
	close_dream_world()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if ResourceLoader.exists(path):
		_load_paths["dream"] = path
		ResourceLoader.load_threaded_request(path)


func close_dream_world() -> void:
	root_nodes.dream = null
	for c in _dream_world_viewport.get_children(true):
		c.queue_free()
	
	if not is_real_world_active():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func is_dream_world_active() -> bool:
	return _dream_world_viewport.get_children(true) != []


func message(author : String, text : String, chars_per_second : float, callback : Callable) -> void:
	var text_length := len(text)
	
	_clear_message()
	_message_box.show()
	_message_author.text = author
	_message_text.text = text
	_message_tween = get_tree().create_tween().set_parallel(false)
	_message_tween.tween_property(_message_text, "visible_characters", text_length, float(text_length) / chars_per_second)
	_message_callback = callback


func is_message_active() -> bool:
	return _message_box.is_visible()


func is_message_finished() -> bool:
	return _message_text.visible_characters in [len(_message_text.text), -1]
