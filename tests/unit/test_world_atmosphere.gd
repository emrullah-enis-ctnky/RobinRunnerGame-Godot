extends Node
## Automated unit tests for DayNightCycle (random start, 24h cycle, sky/lighting) and WorldScenery.

const DayNightScript = preload("res://scripts/world/day_night_cycle.gd")
const SceneryScript = preload("res://scripts/world/world_scenery.gd")

var _passed: int = 0
var _failed: int = 0
var _current_failed: bool = false


func _ready() -> void:
	await _run_all_tests()
	print("WORLD_ATMOSPHERE_TEST_SUMMARY: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func _run_all_tests() -> void:
	await _test_day_night_cycle()
	await _test_world_scenery_wrapping()


## Verifies DayNightCycle randomizes starting time, advances smoothly, and switches day/night palettes.
func _test_day_night_cycle() -> void:
	_start_test("DayNightCycle Random Start & Palette Progression")
	var host := Node3D.new()
	add_child(host)

	var env_node := WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	env_node.environment = Environment.new()
	host.add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.name = "SunLight"
	host.add_child(sun)

	var cycle: Node = DayNightScript.new()
	cycle.day_duration_seconds = 24.0
	host.add_child(cycle)
	await get_tree().process_frame

	_assert(cycle.time_of_day >= 0.0 and cycle.time_of_day < 24.0, "Random start time must be in [0, 24)")
	_assert(env_node.environment.sky != null and env_node.environment.sky.sky_material is ShaderMaterial,
		"DayNightCycle should assign stylized sky ShaderMaterial")

	cycle.apply_time(13.0)
	var noon_energy: float = sun.light_energy
	var noon_stars: float = (env_node.environment.sky.sky_material as ShaderMaterial).get_shader_parameter("stars_alpha")
	cycle.apply_time(0.5)
	var night_energy: float = sun.light_energy
	var night_stars: float = (env_node.environment.sky.sky_material as ShaderMaterial).get_shader_parameter("stars_alpha")

	_assert(noon_energy > night_energy, "Noon sunlight should be brighter than midnight moonlight")
	_assert(night_stars > 0.7 and noon_stars < 0.05, "Stars should be visible at midnight and hidden at noon")

	host.queue_free()
	await get_tree().process_frame
	_end_test("DayNightCycle Random Start & Palette Progression")


## Verifies WorldScenery creates flanking forest strips and wraps them forward as player advances.
func _test_world_scenery_wrapping() -> void:
	_start_test("WorldScenery Horizon & Strip Wrapping")
	var host := Node3D.new()
	add_child(host)

	var fake_player := Node3D.new()
	fake_player.name = "Player"
	host.add_child(fake_player)

	var scenery: Node3D = SceneryScript.new()
	host.add_child(scenery)
	await get_tree().process_frame

	_assert(scenery._strips.size() == SceneryScript.STRIP_COUNT, "Should spawn configured forest strips")
	var first_z_before: float = scenery._strips[0].global_position.z
	fake_player.global_position.z = -80.0
	scenery._process(0.016)
	_assert(scenery._strips[0].global_position.z < first_z_before, "Passed forest strip should leapfrog ahead")
	_assert(is_equal_approx(scenery._horizon_root.global_position.z, -80.0), "Horizon mountains should track player Z")

	host.queue_free()
	await get_tree().process_frame
	_end_test("WorldScenery Horizon & Strip Wrapping")


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
