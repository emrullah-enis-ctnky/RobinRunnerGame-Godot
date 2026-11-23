extends Node
## Automated unit tests for AudioManager: buses, pooled SFX, music ducking, and graceful missing files.

var _passed: int = 0
var _failed: int = 0
var _current_failed: bool = false


func _ready() -> void:
	await _run_all_tests()
	print("AUDIO_MANAGER_TEST_SUMMARY: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func _run_all_tests() -> void:
	await _test_audio_buses_and_missing_files()
	await _test_pooled_sfx_and_music_ducking()


## Verifies Music and SFX buses exist and missing audio slots no-op safely without errors.
func _test_audio_buses_and_missing_files() -> void:
	_start_test("Audio Buses & Missing-Asset Safety")
	var am: Node = get_node("/root/AudioManager")
	_assert(AudioServer.get_bus_index("Music") >= 0, "Music audio bus should exist")
	_assert(AudioServer.get_bus_index("SFX") >= 0, "SFX audio bus should exist")
	_assert(am.play_sfx("nonexistent_sfx_slot") == null, "Missing SFX slot should return null safely")
	_end_test("Audio Buses & Missing-Asset Safety")


## Verifies runtime SFX pool playback and pause/resume music ducking state.
func _test_pooled_sfx_and_music_ducking() -> void:
	_start_test("Pooled SFX & Music Ducking")
	var am: Node = get_node("/root/AudioManager")
	var dummy := AudioStreamWAV.new()
	dummy.format = AudioStreamWAV.FORMAT_8_BITS
	dummy.mix_rate = 8000
	dummy.data = PackedByteArray([0, 0, 0, 0])

	am.register_sfx("test_beep", dummy)
	_assert(am.has_sfx("test_beep"), "Registered SFX should be reported by has_sfx()")
	var p1: AudioStreamPlayer = am.play_sfx("test_beep", 1.1)
	var p2: AudioStreamPlayer = am.play_sfx("test_beep", 1.2)
	_assert(p1 != null and p2 != null and p1 != p2, "Consecutive SFX calls should rotate across pooled players")

	am.register_music("test_track", dummy)
	am.play_music("test_track", 0.0)
	_assert(am._current_track == "test_track", "play_music should set active track name")

	var bus: Node = get_node("/root/EventBus")
	bus.game_paused.emit()
	_assert(am._is_ducked, "game_paused should duck background music")
	bus.game_resumed.emit()
	_assert(not am._is_ducked, "game_resumed should restore background music")

	am.stop_music(0.0)
	_end_test("Pooled SFX & Music Ducking")


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
