class_name PlayerController
extends CharacterBody3D
## Controls the player character in RobinRunner (3-lane movement, jumping, and state).

const GameConfig = preload("res://scripts/common/game_config.gd")

# Hazard labels and the posture each type imprints on a non-fatal contact
const HAZARD_OVERHEAD_BARRIER: String = "overhead_barrier"
const STUMBLE_TILT_FORWARD: float = -0.35
const HEAD_BUMP_TILT_BACK: float = 0.3

@export var lane_switch_speed: float = GameConfig.LANE_SWITCH_SPEED
@export var jump_velocity: float = GameConfig.JUMP_VELOCITY
@export var gravity: float = GameConfig.GRAVITY
@export var roll_lean_angle: float = 0.25
@export var duck_duration: float = 0.65
@export var stumble_duration: float = GameConfig.STUMBLE_DURATION
@export var stumble_speed_factor: float = GameConfig.STUMBLE_SPEED_FACTOR
@export var duck_hitbox_radius: float = 0.3
@export var duck_hitbox_height: float = 0.7

var current_lane: int = GameConfig.LANE_CENTER
var target_x: float = 0.0
var is_jumping: bool = false
var is_ducking: bool = false
var duck_timer: float = 0.0
var is_stumbling: bool = false
var stumble_timer: float = 0.0
var stumbles_remaining: int = GameConfig.MAX_STUMBLES_PER_RUN
var can_control: bool = true

# Stand-in shapes swapped on the detector; Jolt rejects non-uniform shape scaling
var _standing_hitbox: Shape3D
var _ducking_hitbox: CapsuleShape3D
var _standing_hitbox_center_y: float = 0.775

@onready var visual_model: Node3D = get_node_or_null("Model")
@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")
@onready var hazard_detector: Area3D = get_node_or_null("HazardDetector")
@onready var hazard_shape: CollisionShape3D = get_node_or_null("HazardDetector/CollisionShape3D")


## Initializes the player state and connects to global lifecycle signals.
func _ready() -> void:
	_prepare_hitboxes()
	reset_player()
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.game_restarted.connect(reset_player)

	if hazard_detector:
		hazard_detector.body_entered.connect(_on_hazard_body_entered)


## Captures the standing hitbox and builds the smaller ducking silhouette once.
func _prepare_hitboxes() -> void:
	if hazard_shape == null:
		return

	_standing_hitbox = hazard_shape.shape
	_standing_hitbox_center_y = hazard_shape.position.y

	_ducking_hitbox = CapsuleShape3D.new()
	_ducking_hitbox.radius = duck_hitbox_radius
	_ducking_hitbox.height = duck_hitbox_height


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

	_update_stumble(delta)

	# Input is locked while staggering, but forward momentum keeps the run alive
	if not is_stumbling:
		_handle_input()

	_apply_lane_movement(delta)
	_apply_vertical_physics(delta)
	_update_duck_state(delta)

	# Forward velocity along Godot's forward axis (-Z), damped during a stumble
	var forward_speed: float = GameConfig.INITIAL_FORWARD_SPEED
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		forward_speed = gm.current_speed
	if is_stumbling:
		forward_speed *= stumble_speed_factor
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
	_apply_stance(true)

	return true


## Updates duck/slide duration and restores standing posture.
func _update_duck_state(delta: float) -> void:
	if not is_ducking:
		return

	duck_timer -= delta
	if duck_timer <= 0.0:
		is_ducking = false
		_apply_stance(false)


## Swaps the hazard detector between the standing and ducking silhouettes.
func _apply_stance(ducking: bool) -> void:
	if hazard_shape == null or _standing_hitbox == null:
		return

	if ducking:
		hazard_shape.shape = _ducking_hitbox
		hazard_shape.position.y = duck_hitbox_height * 0.5
	else:
		hazard_shape.shape = _standing_hitbox
		hazard_shape.position.y = _standing_hitbox_center_y


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


## Resolves contact with obstacles and destructible targets around the player.
func _on_hazard_body_entered(body: Node3D) -> void:
	var hazard_name: String = str(body.name)
	var lethal: bool = false
	if body.has_method("get_hazard_type"):
		hazard_name = body.get_hazard_type()
	if body.has_method("is_lethal_hazard"):
		lethal = body.is_lethal_hazard()
	take_hit(hazard_name, lethal)


## Resolves a hazard impact: lethal hazards are always fatal, the rest stagger once.
func take_hit(hazard_name: String, lethal: bool = false) -> void:
	if not can_control:
		return

	# Lethal hazards (trees, logs) ignore the stumbling immunity and end the run at once
	if lethal:
		_emit_hazard_hit(hazard_name)
		_die()
		return

	# A contact absorbed by the stagger window leaves the player unharmed
	if is_stumbling:
		return

	_emit_hazard_hit(hazard_name)

	if stumbles_remaining > 0:
		stumbles_remaining -= 1
		_start_stumble(hazard_name)
		return

	_die()


## Broadcasts the hazard label so feedback systems (camera, HUD) can react.
func _emit_hazard_hit(hazard_name: String) -> void:
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.player_hit_hazard.emit(hazard_name)


## Starts the stagger window in which the player stays hazard-immune.
## Overhead arches read as a head bump while ground hazards tip the runner forward.
func _start_stumble(hazard_name: String = "") -> void:
	is_stumbling = true
	stumble_timer = stumble_duration
	if visual_model:
		var overhead: bool = hazard_name == HAZARD_OVERHEAD_BARRIER
		visual_model.rotation.x = HEAD_BUMP_TILT_BACK if overhead else STUMBLE_TILT_FORWARD


## Counts down the stagger window and restores posture when it expires.
func _update_stumble(delta: float) -> void:
	if not is_stumbling:
		return

	stumble_timer -= delta
	if stumble_timer <= 0.0:
		is_stumbling = false
		if visual_model:
			visual_model.rotation.x = 0.0


## Ends the run once the player has no stumbles left.
func _die() -> void:
	can_control = false
	is_stumbling = false
	velocity = Vector3.ZERO
	if visual_model:
		visual_model.rotation = Vector3.ZERO

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
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
	is_stumbling = false
	stumble_timer = 0.0
	stumbles_remaining = GameConfig.MAX_STUMBLES_PER_RUN
	can_control = true
	if visual_model:
		visual_model.scale = Vector3.ONE
		visual_model.rotation = Vector3.ZERO
	_apply_stance(false)
