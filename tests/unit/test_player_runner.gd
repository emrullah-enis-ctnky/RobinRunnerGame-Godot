extends Node
## Automated unit test runner for PlayerController and movement mechanics.

const PlayerScene: PackedScene = preload("res://scenes/player/player.tscn")
const PlayerControllerScript = preload("res://scripts/player/player_controller.gd")
const GameConfig = preload("res://scripts/common/game_config.gd")



## Runs all player controller unit tests upon entering the scene tree.
func _ready() -> void:
	print("==========================================")
	print("--- Running Player Controller Tests ---")
	print("==========================================")
	var success: bool = true

	success = success and _test_player_instantiation()
	success = success and _test_lane_switching()
	success = success and _test_jumping_mechanics()
	success = success and _test_hazard_collision_and_reset()

	if success:
		print("==========================================")
		print("--- ALL PLAYER CONTROLLER TESTS PASSED ---")
		print("==========================================")
		get_tree().quit(0)
	else:
		printerr("==========================================")
		printerr("--- PLAYER CONTROLLER TESTS FAILED ---")
		printerr("==========================================")
		get_tree().quit(1)


## Tests player scene instantiation and default properties.
func _test_player_instantiation() -> bool:
	print("[TEST] Player Instantiation...")
	var player: CharacterBody3D = PlayerScene.instantiate() as CharacterBody3D
	if not player:
		printerr("FAIL: Could not instantiate PlayerController from scenes/player/player.tscn")
		return false

	add_child(player)

	if player.current_lane != GameConfig.LANE_CENTER:
		printerr("FAIL: Initial player lane is not LANE_CENTER")
		player.queue_free()
		return false

	if player.target_x != 0.0:
		printerr("FAIL: Initial target_x is not 0.0")
		player.queue_free()
		return false

	var col_shape: CollisionShape3D = player.get_node_or_null("CollisionShape3D")
	if not col_shape or not col_shape.shape is CapsuleShape3D:
		printerr("FAIL: Player CollisionShape3D is missing or not a CapsuleShape3D")
		player.queue_free()
		return false

	player.queue_free()
	print("  -> Player Instantiation passed.")
	return true


## Tests 3-lane switching logic and clamping boundaries.
func _test_lane_switching() -> bool:
	print("[TEST] Lane Switching & Bounds...")
	var player: CharacterBody3D = PlayerScene.instantiate() as CharacterBody3D
	add_child(player)

	# Test switching left to left lane (-1)
	var changed_left: bool = player.change_lane(-1)
	if not changed_left or player.current_lane != GameConfig.LANE_LEFT or player.target_x != -2.0:
		printerr("FAIL: Switch to left lane failed")
		player.queue_free()
		return false

	# Test boundary clamp on left lane
	var underflow_blocked: bool = not player.change_lane(-1)
	if not underflow_blocked or player.current_lane != GameConfig.LANE_LEFT:
		printerr("FAIL: Lane underflow clamp failed, went beyond left lane")
		player.queue_free()
		return false

	# Test switching right back to center (0)
	player.change_lane(1)
	if player.current_lane != GameConfig.LANE_CENTER or player.target_x != 0.0:
		printerr("FAIL: Switch back to center lane failed")
		player.queue_free()
		return false

	# Test switching right to right lane (+1)
	var changed_right: bool = player.change_lane(1)
	if not changed_right or player.current_lane != GameConfig.LANE_RIGHT or player.target_x != 2.0:
		printerr("FAIL: Switch to right lane failed")
		player.queue_free()
		return false

	# Test boundary clamp on right lane
	var overflow_blocked: bool = not player.change_lane(1)
	if not overflow_blocked or player.current_lane != GameConfig.LANE_RIGHT:
		printerr("FAIL: Lane overflow clamp failed, went beyond right lane")
		player.queue_free()
		return false

	player.queue_free()
	print("  -> Lane Switching passed.")
	return true


## Tests jumping constraints and vertical physics response.
func _test_jumping_mechanics() -> bool:
	print("[TEST] Jumping Mechanics...")
	var player: CharacterBody3D = PlayerScene.instantiate() as CharacterBody3D
	add_child(player)

	# When not on floor, jump must be rejected
	var air_jump: bool = player.jump()
	if air_jump:
		printerr("FAIL: Jump in mid-air should not be allowed")
		player.queue_free()
		return false

	# Test gravity application in air
	player.velocity.y = 0.0
	player._apply_vertical_physics(0.1)
	if player.velocity.y >= 0.0:
		printerr("FAIL: Gravity did not reduce vertical velocity")
		player.queue_free()
		return false

	player.queue_free()
	print("  -> Jumping Mechanics passed.")
	return true


## Tests the damage window: a stagger on the first hit, a fatal follow-up hit inside the
## window, healing once the window expires, and player reset.
func _test_hazard_collision_and_reset() -> bool:
	print("[TEST] Hazard Damage Window, Death & Reset...")
	var player: CharacterBody3D = PlayerScene.instantiate() as CharacterBody3D
	add_child(player)

	var signals_received: Dictionary = {
		"hit": false,
		"damaged": false,
		"damage_duration": 0.0,
		"died": false
	}

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.player_hit_hazard.connect(func(_hazard: String) -> void: signals_received["hit"] = true)
		bus.player_damaged.connect(_capture_damage.bind(signals_received))
		bus.player_died.connect(func() -> void: signals_received["died"] = true)

	# The first contact must stagger the player and open the damage window
	player.take_hit("test_rock")
	if not signals_received["hit"]:
		printerr("FAIL: First hit must emit player_hit_hazard")
		player.queue_free()
		return false
	if signals_received["died"] or not player.is_stumbling:
		printerr("FAIL: First hit must stagger the player instead of killing it")
		player.queue_free()
		return false
	if not player.is_vulnerable:
		printerr("FAIL: First hit must open the damage window")
		player.queue_free()
		return false
	if not signals_received["damaged"] or not is_equal_approx(signals_received["damage_duration"], GameConfig.DAMAGE_WINDOW_DURATION):
		printerr("FAIL: First hit must emit player_damaged with the window duration")
		player.queue_free()
		return false
	if not player.can_control:
		printerr("FAIL: Player must keep running while staggering")
		player.queue_free()
		return false

	# A second contact inside the damage window must be fatal
	player.take_hit("test_rock")
	if not signals_received["died"] or player.can_control:
		printerr("FAIL: A follow-up hit inside the damage window must end the run")
		player.queue_free()
		return false

	# Surviving the window heals the player so the next contact only staggers again
	player.reset_player()
	signals_received["died"] = false
	player.take_hit("test_rock")
	player._update_vulnerability(player.vulnerability_duration)
	if player.is_vulnerable:
		printerr("FAIL: Damage window should expire after its duration")
		player.queue_free()
		return false
	player.take_hit("test_rock")
	if signals_received["died"] or not player.can_control:
		printerr("FAIL: A hit after the damage window must only stagger")
		player.queue_free()
		return false

	# Test reset restores player state
	player.reset_player()
	if not player.can_control or player.current_lane != GameConfig.LANE_CENTER or player.position.x != 0.0:
		printerr("FAIL: Player reset failed to restore control, lane, or position")
		player.queue_free()
		return false
	if player.is_vulnerable:
		printerr("FAIL: Player reset failed to clear the damage window")
		player.queue_free()
		return false

	player.queue_free()
	print("  -> Hazard Damage Window, Death & Reset passed.")
	return true


## Records the damage window duration emitted by the player into a shared store.
func _capture_damage(window_duration: float, store: Dictionary) -> void:
	store["damaged"] = true
	store["damage_duration"] = window_duration
