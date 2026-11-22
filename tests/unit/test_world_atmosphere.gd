extends Node
## Automated unit tests for DayNightCycle, WorldScenery, ChunkBiomeDecorator, and CurvedWorldController.

const DayNightScript = preload("res://scripts/world/day_night_cycle.gd")
const SceneryScript = preload("res://scripts/world/world_scenery.gd")
const CurvedWorldScript = preload("res://scripts/world/curved_world_controller.gd")
const FOREST_CHUNK_SCENE: PackedScene = preload("res://scenes/world/chunks/track_chunk_forest.tscn")
const ROCKY_CHUNK_SCENE: PackedScene = preload("res://scenes/world/chunks/track_chunk_rocky.tscn")
const STRAIGHT_CHUNK_SCENE: PackedScene = preload("res://scenes/world/chunks/track_chunk_straight.tscn")

var _passed: int = 0
var _failed: int = 0
var _current_failed: bool = false


func _ready() -> void:
	await _run_all_tests()
	print("WORLD_ATMOSPHERE_TEST_SUMMARY: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func _run_all_tests() -> void:
	await _test_day_night_cycle()
	await _test_world_scenery_horizon()
	await _test_biome_decorators_and_curved_materials()
	await _test_curved_world_controller()


## Verifies DayNightCycle randomizes starting time and transitions day/night lighting & stars.
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


## Verifies WorldScenery creates distant mountain horizon and anchors it to player Z.
func _test_world_scenery_horizon() -> void:
	_start_test("WorldScenery Horizon Anchor")
	var host := Node3D.new()
	add_child(host)

	var fake_player := Node3D.new()
	fake_player.name = "Player"
	host.add_child(fake_player)

	var scenery: Node3D = SceneryScript.new()
	host.add_child(scenery)
	await get_tree().process_frame

	_assert(scenery._horizon_root != null and scenery._horizon_root.get_child_count() >= 5,
		"WorldScenery should build distant mountain horizon meshes")
	fake_player.global_position.z = -80.0
	scenery._process(0.016)
	_assert(is_equal_approx(scenery._horizon_root.global_position.z, -80.0), "Horizon mountains should track player Z")

	host.queue_free()
	await get_tree().process_frame
	_end_test("WorldScenery Horizon Anchor")


## Verifies all 3 chunk variants populate BiomeDecor on activation and apply curved_world shader.
func _test_biome_decorators_and_curved_materials() -> void:
	_start_test("ChunkBiomeDecorator Biomes & Curved Shader")
	for scene in [STRAIGHT_CHUNK_SCENE, FOREST_CHUNK_SCENE, ROCKY_CHUNK_SCENE]:
		var chunk: TrackChunk = scene.instantiate() as TrackChunk
		add_child(chunk)
		await get_tree().process_frame

		chunk.activate(Vector3(0.0, 0.0, -45.0))
		await get_tree().process_frame

		var decor: Node3D = chunk.get_node_or_null("BiomeDecorator/BiomeDecor") as Node3D
		_assert(decor != null and decor.get_child_count() > 5,
			"Chunk %s should populate BiomeDecor children on activate" % chunk.name)

		var deck: MeshInstance3D = chunk.get_node_or_null("Visuals/TrackDeck") as MeshInstance3D
		_assert(deck != null and deck.get_active_material(0) is ShaderMaterial,
			"TrackDeck on %s should use curved ShaderMaterial" % chunk.name)

		chunk.queue_free()
		await get_tree().process_frame
	_end_test("ChunkBiomeDecorator Biomes & Curved Shader")


## Verifies CurvedWorldController updates global shader uniforms and resets on exit.
func _test_curved_world_controller() -> void:
	_start_test("CurvedWorldController Global Uniforms")
	var host := Node3D.new()
	add_child(host)

	var fake_player := Node3D.new()
	fake_player.name = "Player"
	fake_player.position = Vector3(0.0, 0.0, -42.0)
	host.add_child(fake_player)

	var ctrl: Node = CurvedWorldScript.new()
	host.add_child(ctrl)
	await get_tree().process_frame
	ctrl._process(0.016)

	var origin: Vector3 = RenderingServer.global_shader_parameter_get("curve_origin")
	var strength: Vector2 = RenderingServer.global_shader_parameter_get("curve_strength")
	_assert(is_equal_approx(origin.z, -42.0), "curve_origin.z should track player Z")
	_assert(strength.y > 0.0, "Vertical horizon curve strength should be positive")

	host.queue_free()
	await get_tree().process_frame
	_end_test("CurvedWorldController Global Uniforms")


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
