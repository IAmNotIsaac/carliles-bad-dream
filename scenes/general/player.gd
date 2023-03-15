class_name Player
extends CharacterBody3D

enum States {
	DEFAULT,
	GROUND,
	JUMP,
	CLIMB,
	QUICK_CLIMB,
	AIR,
	LAND,
	WALLRUN,
	CRAWL,
	DEAD,
}

#const _Ragdoll := preload("res://src/instance/RobotRagdoll.tscn")
#const _SFX := preload("res://src/instance/SoundEffect.tscn")

const _TEXTURE_RETICLE := preload("res://assets/textures/reticle.png")
const _TEXTURE_RETICLE_HIGHLIGHT := preload("res://assets/textures/reticle_highlight.png")

const _AIR_FRICTION := 0.1
const _MAX_HEALTH := 100.0
const _HEAL_RATE := 20.0 # health per second
const _HOLD_HEALTH_TIME := 2000 # measured in milliseconds
const _WALLRUN_CAM_TILT := 5.0
const _WALLRUN_FALL_SPEED := -0.5
const _FAST_SPEED := 1.5
const _DAMAGE_COOLDOWN := 500
const _CAM_HEIGHT := 0.5
const _CRAWL_CAM_HEIGHT := -0.25
const _CLIMB_DISTANCE := 0.7
const _CLIMB_SPEED := 1.7
const _QUICK_CLIMB_HEIGHT := 0.6
const _QUICK_CLIMB_SPEED := 2.0
const _QUICK_CLIMB_FDIST := 2.0
const _COYOTE_TIME := 0.25

@export var _gravity := 20.0
@export var _jump_force := 7.0
@export var _walk_speed := 7.0
@export var _run_speed := 4.0
@export var _air_speed := 14.0
@export var _crawl_speed := 2.0
@export var _wallrun_limit := 69420
@export_flags_3d_physics var _interact_collision_mask := 1 | 4
@export_flags_3d_render var _render_layers := 2
@export_node_path("CameraTarget") var _camera_target_path : NodePath

var _state := StateMachine.new(self, States, States.DEFAULT)
var _wallrun_cast : RayCast3D
var _health := _MAX_HEALTH
var _last_damage_time := 0
var _target_camera_tilt := 0.0
var _last_step_sound := 0
var _cam_v_offset := 0.0
var _cam_h_offset := 0.0
var _jump_count := 0
var _wallrun_count := 0

var speed_factor := 1.0

@onready var _cam_target : CameraTarget = get_node_or_null(_camera_target_path)
@onready var _gimbal := $Gimbal
@onready var _cam := $Gimbal/CameraStandIn
@onready var _wallrunl_check := $Gimbal/WallrunLeftCheck
@onready var _wallrunr_check := $Gimbal/WallrunRightCheck
@onready var _wallrun_tracker := $WallrunTracker
@onready var _interact_cast := $Gimbal/CameraStandIn/InteractCast
@onready var _climb_check := $Gimbal/ClimbCheck
@onready var _climb_space_check := $Gimbal/ClimbCheck/SpaceCheck
@onready var _stand_col := $BodyCollision
@onready var _crawl_col := $CrawlCollision
@onready var _stand_space_check := $StandSpaceCheck
@onready var _mesh := $MeshInstance3D
@onready var _reticle := $HUD/Reticle


## Private methods ##

func _ready() -> void:
	IntersceneData.force_player_state.connect(_on_force_state)
	
	_interact_cast.collision_mask = _interact_collision_mask
	_mesh.layers = _render_layers
	
	_cam.rotation_degrees.x = IntersceneData.player_camera_rot_x
	_gimbal.rotation_degrees.y = IntersceneData.player_camera_rot_y
	
	Level.deferred_input.connect(_deferred_input)
	
	_climb_check.position.z = -_CLIMB_DISTANCE
	_health = _MAX_HEALTH
	if _cam_target != null:
		_cam_target.set_cull_mask(_cam_target.get_cull_mask() & ~_mesh.layers)
	_state.ready()
	
	if IntersceneData.player_crawling:
		_state.switch(States.CRAWL)


func _on_force_state(state : States) -> void:
	_state.switch(state)


func _deferred_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		if not _state.matches(States.QUICK_CLIMB):
			_gimbal.rotation_degrees.y -= event.relative.x * Settings.camera_sensitivity
			_cam.rotation_degrees.x -= event.relative.y * Settings.camera_sensitivity
			_cam.rotation_degrees.x = clamp(_cam.rotation_degrees.x, -90, 90)
			
			IntersceneData.player_camera_rot_x = _cam.rotation_degrees.x
			IntersceneData.player_camera_rot_y = _gimbal.rotation_degrees.y


func _physics_process(delta : float) -> void:
	_state.process(delta)
	_controller_look()
	_camera_tilt()
	_update_camera_target()


func _controller_look() -> void:
	if not _state.matches(States.CLIMB):
		var input := Vector2(
			Input.get_action_strength("look_right") - Input.get_action_strength("look_left"),
			Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
		)
		
		_gimbal.rotation_degrees.y -= input.x * Settings.controller_sensitivity
		_cam.rotation_degrees.x -= input.y * Settings.controller_sensitivity
		_cam.rotation_degrees.x = clamp(_cam.rotation_degrees.x, -90, 90)


func _camera_tilt() -> void:
	_cam.rotation_degrees.z = lerp(_cam.rotation_degrees.z, _target_camera_tilt, 0.2)


func _update_camera_target() -> void:
	if _cam_target != null:
		_cam_target.set_global_position(_cam.global_position)
		_cam_target.set_global_rotation(_cam.global_rotation)
		_cam_target.set_h_offset(_cam_h_offset)
		_cam_target.set_v_offset(_cam_v_offset)


func _step_sound() -> void:
	pass


func _can_climb() -> bool:
	if not _climb_check.is_colliding():
		return false
	
	var dist : float = _climb_check.global_position.y - _climb_check.get_collision_point().y
	
	_climb_space_check.position.y = -dist
	
	await get_tree().physics_frame # must wait for collision to update
	
	if _climb_space_check.has_overlapping_bodies():
		return false
	
	return true


func _can_quick_climb() -> bool:
	if not _climb_check.is_colliding():
		return false
	
	var dist : float = _climb_check.global_position.y - _climb_check.get_collision_point().y
	
	if dist < _QUICK_CLIMB_HEIGHT:
		return false
	
	_climb_space_check.position.y = -dist
	
	await get_tree().physics_frame # must wait for collision to update
	
	if _climb_space_check.has_overlapping_bodies():
		return false
	
	return true


func _ground_movement(_delta : float, speed : float) -> void:
	var input := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	
	var theta : float = _gimbal.global_transform.basis.get_euler().y
	
	var move_forward := Vector3(sin(theta) * input.y, 0.0, cos(theta) * input.y)
	var move_strafe := Vector3(cos(-theta) * input.x, 0.0, sin(-theta) * input.x)
	velocity = (move_forward + move_strafe).normalized() * speed * speed_factor * max(_FAST_SPEED, 1.0)
	
	_cam_v_offset = lerp(_cam_v_offset, sin(Time.get_ticks_msec() * 0.01) * 0.1 * int(input.x or input.y), 0.2)
	
	if velocity != Vector3.ZERO and Time.get_ticks_msec() - _last_step_sound > 500:
		_last_step_sound = Time.get_ticks_msec()
		_step_sound()
	
	move_and_slide()


func _air_movement(delta : float) -> void:
	var input := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	
	var theta = _gimbal.global_transform.basis.get_euler().y
	
	var move_forward = Vector3(sin(theta) * input.y, 0.0, cos(theta) * input.y)
	var move_strafe = Vector3(cos(-theta) * input.x, 0.0, sin(-theta) * input.x)
	var accel := _gravity * delta
	
	var v := Vector2(velocity.x + (move_forward.x + move_strafe.x) * _AIR_FRICTION, velocity.z + (move_forward.z + move_strafe.z) * _AIR_FRICTION)
	v = v.limit_length(_air_speed)
	velocity = Vector3(v.x, velocity.y, v.y)
	velocity.y -= accel
	
	move_and_slide()


func _permit_interact() -> void:
	var col = _interact_cast.get_collider()
	if col is InteractArea:
		_reticle.texture = _TEXTURE_RETICLE_HIGHLIGHT
		if Input.is_action_pressed("interact"):
				col.interact(not Input.is_action_just_pressed("interact"))
	else:
		_reticle.texture = _TEXTURE_RETICLE


func _crawl_collision() -> void:
	_crawl_col.set_disabled(false)
	_stand_col.set_disabled(true)


func _stand_collision() -> void:
	_crawl_col.set_disabled(true)
	_stand_col.set_disabled(false)


## State processes ##

func _sp_GROUND(delta : float) -> void:
	_ground_movement(delta, _walk_speed if Input.is_action_pressed("walk") else _run_speed)
	_permit_interact()
	
	if Input.is_action_just_pressed("crawl"):
		_state.switch(States.CRAWL)
	
	if Input.is_action_pressed("walk"):
		if await _can_quick_climb() and is_equal_approx(velocity.length(), _run_speed * _FAST_SPEED):
			_state.switch(States.QUICK_CLIMB)
			return
	
	if Input.is_action_just_pressed("jump"):
		if await _can_climb():
			_state.switch(States.CLIMB)
			return
	
	elif Input.is_action_pressed("jump"):
		_state.switch(States.JUMP)
		return
	
	if not is_on_floor():
		_state.switch(States.AIR)
		return


func _sp_CRAWL(delta : float) -> void:
	_ground_movement(delta, _crawl_speed)
	_permit_interact()
	
	if Input.is_action_just_pressed("crawl"):
		_state.switch(States.GROUND)
#		IntersceneData.force_player_state.emit(States.GROUND)
		return
	
	if not is_on_floor():
		IntersceneData.force_player_state.emit(States.AIR)
		return


func _sp_LAND(delta : float) -> void:
	_cam_v_offset = max(_cam_v_offset - 2.0 * delta, -0.2)
	_permit_interact()
	
	if _state.get_state_time() > 0.1:
		_state.switch(States.GROUND)
		return
	
	move_and_slide()
	
	if Input.is_action_pressed("jump"):
		_state.switch(States.JUMP)
		return


func _sp_AIR(delta : float) -> void:
	var impact_vel := velocity.y
	var accel := _gravity * delta
	
	_air_movement(delta)
	_permit_interact()
	
	if Input.is_action_pressed("jump"):
		if await _can_climb():
			_state.switch(States.CLIMB)
			return
	
	if is_on_floor():
		_state.switch(States.LAND if impact_vel < -accel - 0.1 else States.GROUND)
		return
	
	if Input.is_action_just_pressed("jump"):
		if _state.get_state_time() < _COYOTE_TIME and not _jump_count:
			_state.switch(States.JUMP)
			return
		
		else:
			for c in [ {
					"raycast": _wallrunl_check,
					"input": "move_left"
				}, {
					"raycast": _wallrunr_check,
					"input": "move_right"
			} ]:
				if c["raycast"].get_collider() and Input.is_action_pressed(c["input"]) and _wallrun_count < _wallrun_limit:
					_wallrun_cast = c["raycast"]
					_state.switch(States.WALLRUN)
					return


func _sp_WALLRUN(_delta : float) -> void:
	var normal : Vector3 = _wallrun_tracker.get_collision_normal()
	_wallrun_tracker.target_position = -Vector3(normal.x, 0.0, normal.z) * 0.5
	var angle := atan2(normal.z, normal.x) + PI * 0.5 * (-1 if _wallrun_cast == _wallrunr_check else 1)
	
	if velocity != Vector3.ZERO and Time.get_ticks_msec() - _last_step_sound > 200:
		_last_step_sound = Time.get_ticks_msec()
		_step_sound()
	
	var forvel : Vector3 = -Vector3(cos(angle), 0.0, sin(angle)) * 10.0
	velocity = forvel
	velocity += _wallrun_tracker.target_position
	velocity.y = _WALLRUN_FALL_SPEED
	
	move_and_slide()
	
	_target_camera_tilt = _WALLRUN_CAM_TILT * (-1.0 if _wallrun_cast == _wallrunl_check else 1.0)
	
	if not _wallrun_tracker.get_collider():
		velocity = forvel
		_state.switch(States.JUMP)
		return
	
	if Input.is_action_just_released("jump"):
		velocity = normal * _jump_force
		_state.switch(States.JUMP)
		return
	
	if is_on_floor():
		_state.switch(States.GROUND)
		return


func _sp_DEAD(_delta : float) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


## State [un]loading ##

func _sl_DEFAULT() -> void:
	if _stand_space_check.has_overlapping_bodies():
		_state.switch(States.CRAWL)
		return
	
	_stand_collision()
	_cam.position.y = _CAM_HEIGHT
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if is_on_floor():
		_state.switch(States.GROUND)
	else:
		_state.switch(States.AIR)


func _sl_CRAWL() -> void:
	IntersceneData.player_crawling = true
	_crawl_collision()
	_cam.position.y = _CRAWL_CAM_HEIGHT


func _su_CRAWL() -> void:
	IntersceneData.player_crawling = false


func _sl_WALLRUN() -> void:
	var normal := _wallrun_cast.get_collision_normal()
	_wallrun_tracker.target_position = -Vector3(normal.x, 0.0, normal.z)
	_wallrun_count += 1


func _su_WALLRUN() -> void:
	_target_camera_tilt = 0.0


func _sl_LAND() -> void:
	_jump_count = 0
	_cam.position.y = _CAM_HEIGHT


func _sl_GROUND() -> void:
	_jump_count = 0
	_wallrun_count = 0
	if _stand_space_check.has_overlapping_bodies():
		_state.switch(States.CRAWL)
		return
	
	_stand_collision()
	_cam.position.y = _CAM_HEIGHT


func _su_GROUND() -> void:
	get_tree().create_tween().tween_property(self, "_cam_v_offset", 0.0, 1)


func _sl_JUMP() -> void:
	_jump_count += 1
	velocity.y = _jump_force
	_state.switch(States.AIR)


func _sl_CLIMB() -> void:
	var target_position : Vector3 = _climb_check.get_collision_point() + Vector3(0.0, 1.0, 0.0)
	var dist : float = _climb_check.global_position.y - _climb_check.get_collision_point().y
	var climb_height : float = _climb_check.position.y + 1.0 - dist
	var climb_time := climb_height / _CLIMB_SPEED
	var cam_pos : Vector3 = _cam.position
	
	var tween_bob := get_tree().create_tween().bind_node(self)
	var tween_forward := get_tree().create_tween().bind_node(self).set_parallel(true)
	var tween_tilt := get_tree().create_tween().bind_node(self)
	
	tween_bob.tween_property(_cam, "position:y", climb_height + _CAM_HEIGHT - 0.5, climb_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween_bob.tween_property(_cam, "position:y", climb_height + _CAM_HEIGHT + 0.25, 0.5 / _CLIMB_SPEED).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween_bob.tween_property(_cam, "position:y", climb_height + _CAM_HEIGHT, 0.5 / _CLIMB_SPEED).set_trans(Tween.TRANS_QUAD)
	
	tween_forward.tween_property(_cam, "global_position:x", target_position.x, 1.0 / _CLIMB_SPEED).set_delay(climb_time)
	tween_forward.tween_property(_cam, "global_position:z", target_position.z, 1.0 / _CLIMB_SPEED).set_delay(climb_time)
	
	tween_tilt.tween_property(_cam, "rotation_degrees:z", PI, 0.25 / _CLIMB_SPEED).set_delay(climb_time * 0.8)
	
	await tween_bob.finished
	
	var tween_adjust := get_tree().create_tween().bind_node(self).parallel()
	
	tween_adjust.tween_property(_cam, "global_position", target_position + Vector3(0.0, _CAM_HEIGHT, 0.0), 0.1)
	
	await tween_adjust.finished
	
	_cam.position = cam_pos
#	_cam.rotation = cam_rot
	global_position = target_position
	velocity = Vector3.ZERO
	_state.switch(States.DEFAULT)


func _sl_QUICK_CLIMB() -> void:
	var fdir := Vector3(velocity.x, 0.0, velocity.z).normalized()
	var target_position : Vector3 = _climb_check.get_collision_point() + Vector3(0.0, 1.0, 0.0) + fdir * _QUICK_CLIMB_FDIST
	var dist : float = _climb_check.global_position.y - _climb_check.get_collision_point().y
	
	var climb_height : float = _climb_check.position.y + 1.0 - dist
	var climb_time := climb_height / _QUICK_CLIMB_SPEED
	var cam_pos : Vector3 = _cam.position
	var cam_rot : Vector3 = _cam.rotation
	
	var tween_bob := get_tree().create_tween().bind_node(self)
	var tween_forward := get_tree().create_tween().bind_node(self)
	
	tween_bob.tween_property(_cam, "position:y", climb_height + _CAM_HEIGHT - 0.5, climb_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween_bob.tween_property(_cam, "position:y", climb_height + _CAM_HEIGHT, 0.5 / _QUICK_CLIMB_SPEED).set_trans(Tween.TRANS_BOUNCE)
	
	tween_forward.tween_property(_cam, "position:z", -_QUICK_CLIMB_FDIST, 1.0 / _QUICK_CLIMB_SPEED).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)#.set_delay(climb_time)
	
	await tween_bob.finished
	
	var tween_adjust := get_tree().create_tween().bind_node(self).parallel()

	tween_adjust.tween_property(_cam, "global_position", target_position + Vector3(0.0, _CAM_HEIGHT, 0.0), 0.1)
	tween_adjust.tween_property(_cam, "rotation", cam_rot, 0.1)

	await tween_adjust.finished
	
	_cam.position = cam_pos
	_cam.rotation = cam_rot
	global_position = target_position
	_state.switch(States.DEFAULT)


func _sl_DEAD() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


## Public methods ##

func damage(damage_data : Damage) -> void:
	match _state:
		States.CLIMB:
			if damage_data.is_avian():
				return
		
		States.DEAD:
			return
	
	if Time.get_ticks_msec() - _last_damage_time > _DAMAGE_COOLDOWN:
		_last_damage_time = Time.get_ticks_msec()
		_health -= damage_data.amount


func die() -> void:
	_state.switch(States.DEAD)


func is_alive() -> bool:
	return not _state.matches(States.DEAD)
