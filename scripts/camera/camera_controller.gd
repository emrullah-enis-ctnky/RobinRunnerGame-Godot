class_name RunnerCamera
extends Camera3D
## Dynamic follow camera for RobinRunner with damping, dynamic FOV, and screen shake.

const GameConfig = preload("res://scripts/common/game_config.gd")

@export var target_path: NodePath
@export var follow_offset: Vector3 = Vector3(0.0, 2.8, 4.5)
@export var follow_speed_x: float = 12.0
@export var follow_speed_y: float = 8.0
@export var base_fov: float = 68.0
@export var max_fov: float = 78.0
@export var fov_smooth_speed: float = 4.0
@export var trauma_decay: float = 1.5
@export var max_shake_offset: Vector3 = Vector3(0.25, 0.25, 0.05)
@export var max_shake_angles: Vector3 = Vector3(0.04, 0.04, 0.06)

var target: Node3D = null
var trauma: float = 0.0
var base_rotation: Vector3 = Vector3.ZERO
var noise_seed: float = 0.0


## Initializes default camera settings, caches base rotation, and hooks to EventBus.
func _ready() -> void:
	current = true
	fov = base_fov
	base_rotation = rotation

	if not target_path.is_empty():
		target = get_node_or_null(target_path)

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.player_hit_hazard.connect(_on_player_hit_hazard)


## Updates camera position, dynamic FOV, and screen shake every frame.
func _process(delta: float) -> void:
	_update_tracking(delta)
	_update_dynamic_fov(delta)
	_update_screen_shake(delta)


## Smoothly tracks target position with decoupled axis damping.
func _update_tracking(delta: float) -> void:
	if not is_instance_valid(target):
		return

	# Forward Z-axis tracks directly with offset to maintain framing
	var desired_z: float = target.global_position.z + follow_offset.z
	global_position.z = desired_z

	# Lateral X-axis smoothly damps towards target lane
	var desired_x: float = target.global_position.x + follow_offset.x
	global_position.x = lerpf(global_position.x, desired_x, follow_speed_x * delta)

	# Vertical Y-axis smoothly damps jumps and drops
	var desired_y: float = target.global_position.y + follow_offset.y
	global_position.y = lerpf(global_position.y, desired_y, follow_speed_y * delta)


## Scales field of view dynamically based on forward running speed.
func _update_dynamic_fov(delta: float) -> void:
	var speed_ratio: float = 0.0
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		var speed_range: float = GameConfig.MAX_FORWARD_SPEED - GameConfig.INITIAL_FORWARD_SPEED
		if speed_range > 0.0:
			speed_ratio = clampf((gm.current_speed - GameConfig.INITIAL_FORWARD_SPEED) / speed_range, 0.0, 1.0)

	var target_fov: float = lerpf(base_fov, max_fov, speed_ratio)
	fov = lerpf(fov, target_fov, fov_smooth_speed * delta)


## Decays trauma and applies screen shake offsets and rotations.
func _update_screen_shake(delta: float) -> void:
	if trauma <= 0.0:
		h_offset = 0.0
		v_offset = 0.0
		rotation = base_rotation
		return

	# Quadratic shake curve (trauma squared for punchy falloff)
	var shake_amount: float = trauma * trauma
	noise_seed += delta * 40.0

	# Pseudo-random oscillation based on sin/cos waves with distinct frequencies
	var shake_x: float = sin(noise_seed * 1.7) * max_shake_offset.x * shake_amount
	var shake_y: float = cos(noise_seed * 2.3) * max_shake_offset.y * shake_amount
	h_offset = shake_x
	v_offset = shake_y

	# Rotational shake
	var rot_pitch: float = sin(noise_seed * 1.3) * max_shake_angles.x * shake_amount
	var rot_yaw: float = cos(noise_seed * 1.9) * max_shake_angles.y * shake_amount
	var rot_roll: float = sin(noise_seed * 2.7) * max_shake_angles.z * shake_amount
	rotation = base_rotation + Vector3(rot_pitch, rot_yaw, rot_roll)

	# Decay trauma over time
	trauma = maxf(trauma - trauma_decay * delta, 0.0)


## Adds shake trauma up to the maximum cap of 1.0.
func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


## Manually assigns target node to track.
func set_target(new_target: Node3D) -> void:
	target = new_target


## Triggers impactful screen shake when player hits an obstacle.
func _on_player_hit_hazard(_hazard_name: String) -> void:
	add_trauma(0.65)
