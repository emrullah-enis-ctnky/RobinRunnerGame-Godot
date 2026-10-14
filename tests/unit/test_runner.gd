extends Node
## Automated unit test runner executing inside the Godot SceneTree with active autoloads.

const GameConfig = preload("res://scripts/common/game_config.gd")


## Runs all core architecture tests upon entering the scene tree.
func _ready() -> void:
	print("==========================================")
	print("--- Running Core Architecture Tests ---")
	print("==========================================")
	var success: bool = true

	success = success and _test_game_config()
	success = success and _test_event_bus_signals()
	success = success and _test_game_manager_states()

	if success:
		print("==========================================")
		print("--- ALL CORE ARCHITECTURE TESTS PASSED ---")
		print("==========================================")
		get_tree().quit(0)
	else:
		printerr("==========================================")
		printerr("--- CORE ARCHITECTURE TESTS FAILED ---")
		printerr("==========================================")
		get_tree().quit(1)


## Tests GameConfig static helpers and constants.
func _test_game_config() -> bool:
	print("[TEST] GameConfig...")

	# Verify lane coordinates
	if GameConfig.get_lane_x(GameConfig.LANE_LEFT) != -2.0:
		printerr("FAIL: Left lane X coordinate mismatch")
		return false
	if GameConfig.get_lane_x(GameConfig.LANE_CENTER) != 0.0:
		printerr("FAIL: Center lane X coordinate mismatch")
		return false
	if GameConfig.get_lane_x(GameConfig.LANE_RIGHT) != 2.0:
		printerr("FAIL: Right lane X coordinate mismatch")
		return false

	# Verify clamping
	if GameConfig.clamp_lane(-5) != GameConfig.LANE_LEFT:
		printerr("FAIL: Lane clamp underflow failed")
		return false
	if GameConfig.clamp_lane(5) != GameConfig.LANE_RIGHT:
		printerr("FAIL: Lane clamp overflow failed")
		return false

	print("  -> GameConfig passed.")
	return true


## Tests EventBus signal emissions and payload delivery via autoload.
func _test_event_bus_signals() -> bool:
	print("[TEST] EventBus...")
	if not has_node("/root/EventBus"):
		printerr("FAIL: EventBus autoload is not loaded in SceneTree")
		return false

	var bus: Node = get_node("/root/EventBus")
	var result: Dictionary = {
		"received": false,
		"lane": 999,
		"x": 999.0
	}

	var callable: Callable = func(lane_idx: int, target_x: float) -> void:
		result["received"] = true
		result["lane"] = lane_idx
		result["x"] = target_x

	bus.player_lane_changed.connect(callable)
	bus.player_lane_changed.emit(GameConfig.LANE_LEFT, -2.0)
	bus.player_lane_changed.disconnect(callable)

	if not result["received"] or result["lane"] != GameConfig.LANE_LEFT or result["x"] != -2.0:
		printerr("FAIL: EventBus player_lane_changed signal payload mismatch")
		return false

	print("  -> EventBus passed.")
	return true


## Tests GameManager state transitions, speed progression, and scoring.
func _test_game_manager_states() -> bool:
	print("[TEST] GameManager...")
	if not has_node("/root/GameManager"):
		printerr("FAIL: GameManager autoload is not loaded in SceneTree")
		return false

	var gm: Node = get_node("/root/GameManager")

	# Verify initial state
	if gm.current_state != gm.GameState.READY:
		printerr("FAIL: Initial GameManager state should be READY, got: ", gm.current_state)
		return false

	# Test starting game
	gm.start_game()
	if gm.current_state != gm.GameState.PLAYING:
		printerr("FAIL: GameManager state after start_game should be PLAYING")
		return false

	# Test pausing game
	gm.pause_game()
	if gm.current_state != gm.GameState.PAUSED:
		printerr("FAIL: GameManager state after pause_game should be PAUSED")
		return false

	# Test resuming game
	gm.resume_game()
	if gm.current_state != gm.GameState.PLAYING:
		printerr("FAIL: GameManager state after resume_game should be PLAYING")
		return false

	# Test scoring
	gm.add_score(250)
	if gm.score != 250:
		printerr("FAIL: Score accumulation mismatch, got: ", gm.score)
		return false

	# Test Game Over
	gm.trigger_game_over()
	if gm.current_state != gm.GameState.GAME_OVER:
		printerr("FAIL: GameManager state after trigger_game_over should be GAME_OVER")
		return false
	if gm.high_score != 250:
		printerr("FAIL: High score tracking mismatch, got: ", gm.high_score)
		return false

	# Test restarting
	gm.restart_game()
	if gm.current_state != gm.GameState.PLAYING or gm.score != 0:
		printerr("FAIL: GameManager restart state or score reset failed")
		return false

	# Reset for cleanliness
	gm.reset_game()

	print("  -> GameManager passed.")
	return true
