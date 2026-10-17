class_name PlayerController
extends CharacterBody3D
## Controls the player character in RobinRunner (3-lane movement, jumping, and state).

const GameConfig = preload("res://scripts/common/game_config.gd")
const BOW_SCENE: PackedScene = preload("res://assets/models/weapon-bow.glb")
const BOW_BONE: String = "arm-left"

# Hazard labels and the posture each type imprints on a non-fatal contact
const HAZARD_OVERHEAD_BARRIER: String = "overhead_barrier"
const STUMBLE_TILT_FORWARD: float = -0.35
const HEAD_BUMP_TILT_BACK: float = 0.6

# Animation clip names baked into the archer model
const ANIM_IDLE: String = "idle"
const ANIM_RUN: String = "sprint"
const ANIM_JUMP: String = "jump"
const ANIM_FALL: String = "fall"
const ANIM_CROUCH: String = "crouch"
const ANIM_DUCK: String = "duck"
const ANIM_DEATH: String = "die"
const ANIM_STUMBLE: String = "trip"
const ANIM_STUMBLE_LEGACY: String = "hit"
const ANIM_AIM: String = "holding-both"
const ANIM_AIM_LEGACY: String = "holding-right"
const ANIM_SHOOT: String = "holding-both-shoot"
const ANIM_SHOOT_LEGACY: String = "holding-right-shoot"
const ANIM_BLEND_TIME: float = 0.15

@export var lane_switch_speed: float = GameConfig.LANE_SWITCH_SPEED
@export var jump_velocity: float = GameConfig.JUMP_VELOCITY
@export var gravity: float = GameConfig.GRAVITY
@export var roll_lean_angle: float = 0.25
@export var duck_duration: float = 0.65
@export var stumble_duration: float = GameConfig.STUMBLE_DURATION
@export var stumble_speed_factor: float = GameConfig.STUMBLE_SPEED_FACTOR
@export var vulnerability_duration: float = GameConfig.DAMAGE_WINDOW_DURATION
@export var duck_hitbox_radius: float = 0.3
@export var duck_hitbox_height: float = 0.7
@export var shoot_draw_time: float = GameConfig.SHOOT_DRAW_TIME
@export var shoot_release_time: float = GameConfig.SHOOT_RELEASE_TIME
@export var arrow_scan_range: float = GameConfig.ARROW_SCAN_RANGE
@export var bow_offset: Vector3 = Vector3(0.6, 0.0, 0.15)
@export var bow_rotation_degrees: Vector3 = Vector3(0.0, 0.0, 31.0)
@export var bow_scale: float = 1.0

var current_lane: int = GameConfig.LANE_CENTER
var target_x: float = 0.0
var is_jumping: bool = false
var is_ducking: bool = false
var duck_timer: float = 0.0
var is_stumbling: bool = false
var stumble_timer: float = 0.0
var is_vulnerable: bool = false
var vulnerability_timer: float = 0.0
var is_shooting: bool = false
var shoot_timer: float = 0.0
var shoot_released: bool = false
var can_control: bool = true

# Stored shot parameters released once the draw window completes
var _shoot_origin: Vector3 = Vector3.ZERO
var _shoot_forward: Vector3 = Vector3.FORWARD
var _shoot_preferred: String = GameConfig.ARROW_TYPE_NORMAL

# Stand-in shapes swapped on the detector; Jolt rejects non-uniform shape scaling
var _standing_hitbox: Shape3D
var _ducking_hitbox: CapsuleShape3D
var _standing_hitbox_center_y: float = 0.775

@onready var visual_model: Node3D = get_node_or_null("Model")
@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")
@onready var hazard_detector: Area3D = get_node_or_null("HazardDetector")
@onready var hazard_shape: CollisionShape3D = get_node_or_null("HazardDetector/CollisionShape3D")
@onready var animation_player: AnimationPlayer = get_node_or_null("Model/ArcherModel/AnimationPlayer")

var current_animation: String = ""
var stumble_animates: bool = false


## Initializes the player state and connects to global lifecycle signals.
func _ready() -> void:
	_prepare_hitboxes()
	_setup_animations()
	_attach_bow()
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


## Attaches the bow model to the archer's right-hand bone so it is held at all times.
func _attach_bow() -> void:
	var skeleton: Skeleton3D = _find_skeleton(visual_model)
	if skeleton == null or skeleton.find_bone(BOW_BONE) < 0:
		return

	var attach := BoneAttachment3D.new()
	attach.bone_name = BOW_BONE
	skeleton.add_child(attach)

	var bow: Node3D = BOW_SCENE.instantiate()
	bow.name = "Bow"
	MeshFit.fit_longest_axis(bow, GameConfig.BOW_MODEL_LENGTH)
	bow.position = bow_offset
	bow.rotation_degrees = bow_rotation_degrees
	bow.scale *= bow_scale
	attach.add_child(bow)


## Returns the first Skeleton3D found under a node.
func _find_skeleton(node: Node) -> Skeleton3D:
	if node == null:
		return null
	for child in node.get_children():
		if child is Skeleton3D:
			return child
		var found: Skeleton3D = _find_skeleton(child)
		if found != null:
			return found
	return null


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
		_update_animation()
		return

	_update_stumble(delta)
	_update_vulnerability(delta)
	_update_shoot(delta)

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
	_update_animation()


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

	if Input.is_action_just_pressed("shoot") and not is_shooting:
		try_shoot()


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


## Begins a shot: the arrow is released once the draw window completes.
func try_shoot() -> bool:
	if not has_node("/root/AbilityManager"):
		return false
	var ability: Node = get_node("/root/AbilityManager")
	if not ability.can_fire():
		return false

	_shoot_origin = global_position + Vector3(0.0, GameConfig.ARROW_MUZZLE_HEIGHT, 0.0)
	_shoot_forward = (-global_transform.basis.z).normalized()
	_shoot_preferred = _preferred_arrow_type(_shoot_origin, _shoot_forward)
	_start_shoot_animation()
	return true


## Scans the lane ahead and returns a usable arrow type for the first shootable found.
func _preferred_arrow_type(origin: Vector3, forward: Vector3) -> String:
	var hit: Dictionary = _scan_ahead(origin, forward)
	if not hit.is_empty():
		var body: Object = hit.get("collider")
		if body != null and body.has_method("required_arrow_types"):
			for arrow_type in body.required_arrow_types():
				if _quiver_has(arrow_type):
					return arrow_type
	return GameConfig.ARROW_TYPE_NORMAL


## Casts a ray through the current lane to find the first shootable surface.
func _scan_ahead(origin: Vector3, forward: Vector3) -> Dictionary:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * arrow_scan_range)
	query.collision_mask = GameConfig.LAYER_OBSTACLE | GameConfig.LAYER_TARGET
	query.collide_with_areas = false
	return space.intersect_ray(query)


## Returns true when the quiver still holds an arrow of the given type.
func _quiver_has(arrow_type: String) -> bool:
	if not has_node("/root/AbilityManager"):
		return false
	return get_node("/root/AbilityManager").has_ammo(arrow_type)


## Starts the short draw-and-release shooting window.
func _start_shoot_animation() -> void:
	is_shooting = true
	shoot_released = false
	shoot_timer = shoot_draw_time + shoot_release_time


## Advances the shooting window and releases the arrow at the shot moment.
func _update_shoot(delta: float) -> void:
	if not is_shooting:
		return

	shoot_timer -= delta
	if not shoot_released and shoot_timer <= shoot_release_time:
		shoot_released = true
		_release_arrow()
	if shoot_timer <= 0.0:
		is_shooting = false


## Fires the stored shot through the ability manager.
func _release_arrow() -> void:
	if has_node("/root/AbilityManager"):
		get_node("/root/AbilityManager").try_fire(_shoot_origin, _shoot_forward, _shoot_preferred)


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


## Resolves a hazard impact: lethal hazards are always fatal, while a forgiving contact
## staggers the runner and opens the damage window in which a second contact is fatal.
func take_hit(hazard_name: String, lethal: bool = false) -> void:
	if not can_control:
		return

	# Lethal hazards (trees, fragile barriers) end the run at once
	if lethal:
		_emit_hazard_hit(hazard_name)
		_die()
		return

	# A second forgiving contact inside the damage window is fatal
	if is_vulnerable:
		_emit_hazard_hit(hazard_name)
		_die()
		return

	# The first forgiving contact staggers the runner and opens the damage window
	_emit_hazard_hit(hazard_name)
	_start_stumble(hazard_name)
	_start_vulnerability()


## Broadcasts the hazard label so feedback systems (camera, HUD) can react.
func _emit_hazard_hit(hazard_name: String) -> void:
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.player_hit_hazard.emit(hazard_name)


## Starts the short stumble in which the runner is slowed and tips out of posture.
## Overhead arches read as a head bump while ground hazards tip the runner forward.
func _start_stumble(hazard_name: String = "") -> void:
	is_stumbling = true
	stumble_timer = stumble_duration
	var overhead: bool = hazard_name == HAZARD_OVERHEAD_BARRIER
	# Use the baked hit clip for ground hazards; the arch keeps a backward head bump.
	stumble_animates = not overhead and animation_player != null and (
		animation_player.has_animation(ANIM_STUMBLE) or animation_player.has_animation(ANIM_STUMBLE_LEGACY))
	if visual_model and not stumble_animates:
		visual_model.rotation.x = HEAD_BUMP_TILT_BACK if overhead else STUMBLE_TILT_FORWARD


## Counts down the stumble window and restores posture when it expires.
func _update_stumble(delta: float) -> void:
	if not is_stumbling:
		return

	stumble_timer -= delta
	if stumble_timer <= 0.0:
		is_stumbling = false
		if visual_model:
			visual_model.rotation.x = 0.0


## Opens the damage window during which the next forgiving contact is fatal.
func _start_vulnerability() -> void:
	is_vulnerable = true
	vulnerability_timer = vulnerability_duration
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.player_damaged.emit(vulnerability_duration)


## Counts down the damage window and heals the runner once it expires.
func _update_vulnerability(delta: float) -> void:
	if not is_vulnerable:
		return

	vulnerability_timer -= delta
	if vulnerability_timer <= 0.0:
		is_vulnerable = false


## Ends the run on a fatal hazard or a second contact inside the damage window.
func _die() -> void:
	can_control = false
	is_stumbling = false
	is_vulnerable = false
	velocity = Vector3.ZERO
	if visual_model:
		visual_model.rotation = Vector3.ZERO
	_play_animation(ANIM_DEATH, true)

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
	stumble_animates = false
	stumble_timer = 0.0
	is_vulnerable = false
	vulnerability_timer = 0.0
	is_shooting = false
	shoot_timer = 0.0
	shoot_released = false
	can_control = true
	if visual_model:
		visual_model.scale = Vector3.ONE
		visual_model.rotation = Vector3.ZERO
	_apply_stance(false)
	_play_animation(ANIM_IDLE, true)


## Enables linear looping on the clips that must cycle continuously.
func _setup_animations() -> void:
	if animation_player == null:
		return
	_set_animation_loop(ANIM_IDLE)
	_set_animation_loop(ANIM_RUN)


## Enables linear looping on a single clip when the model provides it.
func _set_animation_loop(anim_name: String) -> void:
	if animation_player.has_animation(anim_name):
		animation_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR


## Picks the clip matching the current gameplay state and blends to it.
func _update_animation() -> void:
	if animation_player == null:
		return
	var anim_name: String = _resolve_animation()
	_play_animation(anim_name)
	_apply_animation_speed(anim_name)


## Maps movement, stance, and life state to an animation clip name.
func _resolve_animation() -> String:
	if not can_control:
		return ANIM_DEATH
	if is_stumbling and stumble_animates:
		return _available_animation(ANIM_STUMBLE, ANIM_STUMBLE_LEGACY)
	if is_shooting:
		if shoot_released:
			return _available_animation(ANIM_SHOOT, ANIM_SHOOT_LEGACY)
		return _available_animation(ANIM_AIM, ANIM_AIM_LEGACY)
	if is_ducking:
		return _available_animation(ANIM_DUCK, ANIM_CROUCH)
	if not is_on_floor():
		return ANIM_JUMP if velocity.y > 0.0 else ANIM_FALL
	if _is_game_playing():
		return ANIM_RUN
	return ANIM_IDLE


## Returns true while the game manager reports the active run state.
func _is_game_playing() -> bool:
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		return gm.current_state == gm.GameState.PLAYING
	return true


## Returns the preferred clip when the model provides it, otherwise the fallback.
func _available_animation(primary: String, fallback: String) -> String:
	if animation_player != null and animation_player.has_animation(primary):
		return primary
	return fallback


## Blends to a clip unless it is already the active one.
func _play_animation(anim_name: String, force: bool = false) -> void:
	if animation_player == null or not animation_player.has_animation(anim_name):
		return
	if not force and anim_name == current_animation:
		return
	current_animation = anim_name
	animation_player.play(anim_name, ANIM_BLEND_TIME)


## Scales run playback so the stride keeps pace with forward speed.
func _apply_animation_speed(anim_name: String) -> void:
	var target_scale: float = 1.0
	if anim_name == ANIM_RUN and has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		target_scale = clampf(gm.current_speed / GameConfig.INITIAL_FORWARD_SPEED, 1.0, 1.6)
	animation_player.speed_scale = target_scale
