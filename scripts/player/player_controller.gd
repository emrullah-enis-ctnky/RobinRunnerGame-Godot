class_name PlayerController
extends CharacterBody3D
## Controls the player character in RobinRunner (3-lane movement, jumping, and state).

const GameConfig = preload("res://scripts/common/game_config.gd")

@export var lane_switch_speed: float = GameConfig.LANE_SWITCH_SPEED
@export var jump_velocity: float = GameConfig.JUMP_VELOCITY
@export var gravity: float = GameConfig.GRAVITY
@export var roll_lean_angle: float = 0.25

var current_lane: int = GameConfig.LANE_CENTER
var target_x: float = 0.0
var is_jumping: bool = false
var is_ducking: bool = false
var duck_timer: float = 0.0
@export var duck_duration: float = 0.65
var can_control: bool = true

@onready var visual_model: Node3D = get_node_or_null("Model")
@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")


## Initializes the player state and connects to global lifecycle signals.
func _ready() -> void:
	reset_player()
	if Engine.has_singleton("EventBus") or has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.game_restarted.connect(reset_player)


## Handles movement, lane interpolation, and jumping physics each frame.
func _physics_process(delta: float) -> void:
	if not can_control:
		return

	# Only move forward and process active runner logic during PLAYING state
	var is_playing: bool = true
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		is_playing = (gm.current_state == gm.GameState.PLAYING)

	if not is_playing:
		# Apply simple gravity if falling while paused/ready
		if not is_on_floor():
			velocity.y -= gravity * delta
			move_and_slide()
		return

	_handle_input()
	_apply_lane_movement(delta)
	_apply_vertical_physics(delta)
	_update_duck_state(delta)

	# Forward velocity along Godot's forward axis (-Z)
	var forward_speed: float = GameConfig.INITIAL_FORWARD_SPEED
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		forward_speed = gm.current_speed
	velocity.z = -forward_speed

	move_and_slide()
	_check_landing()


## Captures discrete player inputs for lane switching, jumping, and ducking/sliding.
func _handle_input() -> void:
	if Input.is_action_just_pressed("move_left") or Input.is_key_pressed(KEY_A) and not Input.is_key_pressed(KEY_D):
		change_lane(-1)
	elif Input.is_action_just_pressed("move_right") or Input.is_key_pressed(KEY_D) and not Input.is_key_pressed(KEY_A):
		change_lane(1)

	if (Input.is_action_just_pressed("jump") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W)) and is_on_floor():
		jump()

	if Input.is_action_just_pressed("move_down") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		if is_on_floor():
			duck()
		else:
			# Fast fall downward if in mid-air
			velocity.y = minf(velocity.y, -gravity * 0.9)


## Shifts the target lane by direction offset (-1 for left, +1 for right).
func change_lane(direction: int) -> bool:
	var next_lane: int = GameConfig.clamp_lane(current_lane + direction)
	if next_lane == current_lane:
		return false

	current_lane = next_lane
	target_x = GameConfig.get_lane_x(current_lane)

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.player_lane_changed.emit(current_lane, target_x)
	return true


## Triggers vertical jump if currently on the ground.
func jump() -> bool:
	if not is_on_floor():
		return false

	velocity.y = jump_velocity
	is_jumping = true

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.player_jumped.emit()
	return true


## Triggers sliding / ducking to pass under overhead barriers.
func duck() -> bool:
	if is_ducking:
		return false

	is_ducking = true
	duck_timer = duck_duration

	if visual_model:
		visual_model.scale = Vector3(1.25, 0.45, 1.35)
	if collision_shape:
		collision_shape.scale = Vector3(1.0, 0.45, 1.0)
		collision_shape.position.y = 0.35

	return true


## Updates duck/slide duration and restores standing posture.
func _update_duck_state(delta: float) -> void:
	if not is_ducking:
		return

	duck_timer -= delta
	if duck_timer <= 0.0:
		is_ducking = false
		if visual_model:
			visual_model.scale = Vector3.ONE
		if collision_shape:
			collision_shape.scale = Vector3.ONE
			collision_shape.position.y = 0.775


## Smoothly interpolates the lateral X position towards target lane.
func _apply_lane_movement(delta: float) -> void:
	var previous_x: float = position.x
	position.x = move_toward(position.x, target_x, lane_switch_speed * delta)

	# Visual banking/lean effect when moving laterally
	if visual_model:
		var lateral_direction: float = signf(target_x - position.x)
		var target_rotation_z: float = -lateral_direction * roll_lean_angle if absf(target_x - position.x) > 0.05 else 0.0
		visual_model.rotation.z = lerpf(visual_model.rotation.z, target_rotation_z, 15.0 * delta)


## Applies gravity to vertical velocity when in the air.
func _apply_vertical_physics(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta


## Detects ground contact to reset jump state and dispatch landing signal.
func _check_landing() -> void:
	if is_jumping and is_on_floor():
		is_jumping = false
		if has_node("/root/EventBus"):
			var bus: Node = get_node("/root/EventBus")
			bus.player_landed.emit()


## Resolves collision with hazards, triggering stumble and game over.
func take_hit(hazard_name: String) -> void:
	can_control = false
	velocity = Vector3.ZERO

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.player_hit_hazard.emit(hazard_name)
		bus.player_died.emit()

	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		gm.trigger_game_over()


## Resets the player back to initial lane, position, and control state.
func reset_player() -> void:
	current_lane = GameConfig.LANE_CENTER
	target_x = GameConfig.get_lane_x(current_lane)
	position = Vector3(target_x, 0.0, 0.0)
	velocity = Vector3.ZERO
	is_jumping = false
	is_ducking = false
	duck_timer = 0.0
	can_control = true
	if visual_model:
		visual_model.scale = Vector3.ONE
		visual_model.rotation = Vector3.ZERO
	if collision_shape:
		collision_shape.scale = Vector3.ONE
		collision_shape.position.y = 0.775
