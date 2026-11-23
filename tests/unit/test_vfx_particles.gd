extends Node
## Automated unit tests for Step 10.3: VFXSpawner bursts and PlayerController run dust.

const VFXSpawner = preload("res://scripts/vfx/vfx_spawner.gd")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _passed: int = 0
var _failed: int = 0
var _current_failed: bool = false


func _ready() -> void:
	await _run_all_tests()
	print("VFX_PARTICLES_TEST_SUMMARY: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func _run_all_tests() -> void:
	await _test_one_shot_vfx_spawners()
	await _test_player_run_dust()


## Verifies tree burn, wood splinters, and landing dust spawn valid curved GPUParticles3D bursts.
func _test_one_shot_vfx_spawners() -> void:
	_start_test("VFXSpawner One-Shot Bursts")
	var host := Node3D.new()
	add_child(host)
	await get_tree().process_frame

	var dust: GPUParticles3D = VFXSpawner.spawn_landing_dust(host, Vector3.ZERO)
	var splinters: GPUParticles3D = VFXSpawner.spawn_wood_splinters(host, Vector3(0, 1, -5))
	var burn: Node3D = VFXSpawner.spawn_tree_burn(host, Vector3(2, 0, -10))

	_assert(dust != null and dust.emitting, "Landing dust should spawn and emit")
	_assert(splinters != null and splinters.emitting, "Wood splinters should spawn and emit")
	_assert(burn != null and burn.get_child_count() >= 3, "Tree burn should spawn fire + ash emitters and cleanup timer")
	_assert(get_tree().get_nodes_in_group("vfx_burst").size() >= 3, "All bursts should register in vfx_burst group")

	host.queue_free()
	await get_tree().process_frame
	_end_test("VFXSpawner One-Shot Bursts")


## Verifies PlayerController attaches RunDust and stops emitting when not playing.
func _test_player_run_dust() -> void:
	_start_test("Player RunDust Emitter")
	var gm: Node = get_node("/root/GameManager")
	gm.reset_game()

	var player: CharacterBody3D = PLAYER_SCENE.instantiate() as CharacterBody3D
	add_child(player)
	await get_tree().process_frame

	var dust: GPUParticles3D = player.get_node_or_null("RunDust") as GPUParticles3D
	_assert(dust != null, "PlayerController should attach RunDust emitter")
	if dust != null:
		_assert(not dust.emitting, "RunDust must not emit in READY state")

	player.queue_free()
	await get_tree().process_frame
	_end_test("Player RunDust Emitter")


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
