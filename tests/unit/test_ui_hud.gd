extends Node
## Automated unit tests for Phase 9: UIManager state transitions and ScoreDistanceHUD updates.

const UI_MANAGER_SCENE: PackedScene = preload("res://scenes/ui/ui_manager.tscn")
const SCORE_HUD_SCENE: PackedScene = preload("res://scenes/ui/score_distance_hud.tscn")

var _passed: int = 0
var _failed: int = 0
var _current_failed: bool = false


func _ready() -> void:
	await _run_all_tests()
	print("UI_HUD_TEST_SUMMARY: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func _run_all_tests() -> void:
	await _test_ui_manager_lifecycle()
	await _test_score_distance_hud()
	await _test_settings_manager()


## Verifies UIManager shows Main Menu in READY, hides during PLAYING, shows Pause/GameOver, and resets cleanly.
func _test_ui_manager_lifecycle() -> void:
	_start_test("UIManager Lifecycle")
	var gm: Node = get_node("/root/GameManager")
	gm.reset_game()

	var ui: CanvasLayer = UI_MANAGER_SCENE.instantiate() as CanvasLayer
	add_child(ui)
	await get_tree().process_frame

	_assert(ui._main_menu.visible and not ui._pause_menu.visible and not ui._game_over_panel.visible,
		"Main Menu should be visible in READY state")

	ui._on_play_pressed()
	_assert(ui._is_counting_down and ui._countdown_label.visible and not ui._main_menu.visible,
		"Pressing Play should hide Main Menu and start 3-2-1 countdown")
	ui._cancel_sequences()
	gm.start_game()
	await get_tree().process_frame
	_assert(gm.current_state == gm.GameState.PLAYING and not ui._main_menu.visible,
		"GameManager.start_game() should enter PLAYING and keep Main Menu hidden")

	gm.pause_game()
	await get_tree().process_frame
	_assert(ui._pause_menu.visible, "Pause Menu should be visible when game is paused")

	ui._on_resume_pressed()
	await get_tree().process_frame
	_assert(gm.current_state == gm.GameState.PLAYING and not ui._pause_menu.visible,
		"Pressing Resume should hide Pause Menu and resume PLAYING")

	gm.add_score(250)
	gm.distance_traveled = 84.3
	ui.show_game_over(gm.score, gm.distance_traveled, true)
	await get_tree().process_frame
	_assert(ui._game_over_panel.visible and ui._go_score_value.text == "250" and ui._go_distance_value.text == "84m",
		"Game Over panel should display final score and distance")

	ui._on_menu_pressed()
	await get_tree().process_frame
	_assert(gm.current_state == gm.GameState.READY and ui._main_menu.visible,
		"Main Menu button should reset to READY and show Main Menu")

	ui.queue_free()
	await get_tree().process_frame
	_end_test("UIManager Lifecycle")


## Verifies ScoreDistanceHUD updates score, distance, and combo badge from EventBus signals.
func _test_score_distance_hud() -> void:
	_start_test("ScoreDistanceHUD Updates")
	var gm: Node = get_node("/root/GameManager")
	var bus: Node = get_node("/root/EventBus")
	gm.start_game()

	var hud: CanvasLayer = SCORE_HUD_SCENE.instantiate() as CanvasLayer
	add_child(hud)
	await get_tree().process_frame

	_assert(hud._root.visible, "ScoreDistanceHUD should be visible during PLAYING")

	bus.score_updated.emit(420)
	bus.distance_updated.emit(67.9)
	bus.combo_updated.emit(10, 1.1)
	_assert(hud._score_label.text == "420", "Score label should show 420")
	_assert(hud._distance_label.text == "67m", "Distance label should show 67m")
	_assert(hud._combo_label.visible and hud._combo_label.text == "%10", "Combo badge should show %10")

	bus.combo_updated.emit(0, 0.8)
	_assert(hud._combo_label.visible and hud._combo_label.text == "-%20", "Penalty badge should show -%20")

	gm.trigger_game_over()
	await get_tree().process_frame
	_assert(not hud._root.visible, "ScoreDistanceHUD should hide on GAME_OVER")

	hud.queue_free()
	gm.reset_game()
	await get_tree().process_frame
	_end_test("ScoreDistanceHUD Updates")


## Verifies SettingsManager language switching, audio mute/volume, and multi-key rebinding + reset.
func _test_settings_manager() -> void:
	_start_test("SettingsManager Audio, Language & Controls")
	var sm: Node = get_node("/root/SettingsManager")

	sm.set_language("tr")
	_assert(sm.t("title_settings") == "AYARLAR", "Turkish translation should return AYARLAR")
	sm.set_language("de")
	_assert(sm.t("title_settings") == "EINSTELLUNGEN", "German translation should return EINSTELLUNGEN")
	sm.set_language("en")
	_assert(sm.t("title_settings") == "SETTINGS", "English translation should return SETTINGS")

	sm.set_music_volume(0.4)
	sm.set_music_muted(true)
	_assert(is_equal_approx(sm.music_volume, 0.4) and sm.music_muted, "Music volume and mute should update")

	var before_count: int = InputMap.action_get_events("jump").size()
	var extra := InputEventKey.new()
	extra.keycode = KEY_K
	_assert(sm.add_action_event("jump", extra), "Should allow adding an extra key to an action")
	_assert(InputMap.action_get_events("jump").size() == before_count + 1, "Action should hold multiple keys")

	sm.reset_controls_to_defaults()
	_assert(InputMap.action_get_events("jump").size() == before_count, "Reset defaults should restore original bindings")

	var avail: Array[Vector2i] = sm.get_available_resolutions()
	_assert(avail.size() >= 1 and avail.has(Vector2i(1280, 720)), "Available resolutions must include 1280x720")
	sm.set_resolution(Vector2i(1280, 720))
	_assert(sm.resolution == Vector2i(1280, 720), "Resolution should update to 1280x720")
	sm.set_fullscreen(false)
	_assert(not sm.fullscreen, "Fullscreen toggle should update cleanly")
	_end_test("SettingsManager Audio, Language & Controls")


func _start_test(test_name: String) -> void:
	_current_failed = false
	print("RUN: ", test_name)


func _end_test(test_name: String) -> void:
	if _current_failed:
		_failed += 1
		print("FAIL: ", test_name)
	else:
		_passed += 1
		print("PASS: ", test_name)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_current_failed = true
		printerr("  ASSERT FAILED: ", message)
