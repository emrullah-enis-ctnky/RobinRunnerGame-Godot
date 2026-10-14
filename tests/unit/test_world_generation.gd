extends Node
## Automated unit tests for Phase 4: World & Modular Track Generation.
## Tests TrackChunk snapping, ObjectPool node reuse, contiguous chunk generation, and recycling.

const TrackChunkScript = preload("res://scripts/world/track_chunk.gd")
const ObjectPoolScript = preload("res://scripts/common/object_pool.gd")
const TrackSpawnerScript = preload("res://scripts/world/track_spawner.gd")

var _tests_passed: int = 0
var _tests_total: int = 0


func _ready() -> void:
	print("==========================================")
	print("--- Running World Generation Tests ---")
	print("==========================================")

	_run_all_tests()

	print("==========================================")
	if _tests_passed == _tests_total:
		print("--- ALL WORLD GENERATION TESTS PASSED (%d/%d) ---" % [_tests_passed, _tests_total])
	else:
		push_error("--- SOME TESTS FAILED (%d/%d) ---" % [_tests_passed, _tests_total])
	print("==========================================")

	# Quit cleanly on completion
	get_tree().quit(0 if _tests_passed == _tests_total else 1)


func _run_all_tests() -> void:
	_test_track_chunk_base()
	_test_object_pool()
	_test_track_spawner_layout()
	_test_track_continuous_spawning_and_recycling()
	_test_track_reset()


func _test_track_chunk_base() -> void:
	_start_test("Track Chunk Base & Snap Anchors")

	var chunk_scene: PackedScene = load("res://scenes/world/track_chunk_base.tscn")
	_assert(chunk_scene != null, "track_chunk_base.tscn must load successfully.")

	var chunk: TrackChunk = chunk_scene.instantiate() as TrackChunk
	add_child(chunk)

	_assert(chunk.chunk_length == GameConfig.CHUNK_LENGTH, "Chunk length must match GameConfig.CHUNK_LENGTH.")
	_assert(chunk.get_entry_position() == Vector3.ZERO, "Entry position must be at origin (0,0,0).")
	_assert(chunk.get_exit_position() == Vector3(0.0, 0.0, -30.0), "Exit position must snap at (0,0,-30).")

	# Test activation and deactivation
	chunk.activate(Vector3(0.0, 0.0, -60.0))
	_assert(chunk.is_active == true, "Chunk should be marked active.")
	_assert(chunk.visible == true, "Chunk should be visible when active.")
	_assert(chunk.global_position == Vector3(0.0, 0.0, -60.0), "Chunk should move to spawn position.")

	chunk.deactivate()
	_assert(chunk.is_active == false, "Chunk should be marked inactive.")
	_assert(chunk.visible == false, "Chunk should be hidden when deactivated.")

	# Test collision ground layer
	var ground: StaticBody3D = chunk.get_node_or_null("GroundCollision") as StaticBody3D
	_assert(ground != null, "GroundCollision node must exist.")
	_assert(ground.collision_layer == GameConfig.LAYER_ENVIRONMENT, "Ground collision layer must be LAYER_ENVIRONMENT (2).")

	chunk.queue_free()
	_end_test("Track Chunk Base & Snap Anchors")


func _test_object_pool() -> void:
	_start_test("Object Pool Lifecycle & Reuse")

	var chunk_scene: PackedScene = load("res://scenes/world/track_chunk_base.tscn")
	var pool_host: Node = Node.new()
	add_child(pool_host)

	var pool: ObjectPool = ObjectPoolScript.new(chunk_scene, pool_host, 3, 10)
	_assert(pool.get_available_count() == 3, "Pool should have 3 prewarmed available instances.")
	_assert(pool.get_active_count() == 0, "Pool should start with 0 active instances.")
	_assert(pool.get_total_count() == 3, "Total pool count should equal 3.")

	# Acquire instances
	var item1: Node = pool.acquire()
	var item2: Node = pool.acquire()
	_assert(item1 != null and item2 != null, "Acquired instances must be valid.")
	_assert(item1 != item2, "Acquired instances must be distinct.")
	_assert(pool.get_active_count() == 2, "Active count must be 2.")
	_assert(pool.get_available_count() == 1, "Available count must be 1.")

	# Release an instance
	pool.release(item1)
	_assert(pool.get_active_count() == 1, "Active count should decrease to 1.")
	_assert(pool.get_available_count() == 2, "Available count should increase to 2.")

	# Re-acquire: should recycle item1 without instantiating new
	var item3: Node = pool.acquire()
	_assert(item3 == item1, "Pool should recycle previously released instance.")

	pool.clear()
	_assert(pool.get_total_count() == 0, "Pool should be completely empty after clear().")

	pool_host.queue_free()
	_end_test("Object Pool Lifecycle & Reuse")


func _test_track_spawner_layout() -> void:
	_start_test("Track Spawner Initial Layout & Seamless Snapping")

	var spawner: TrackSpawner = TrackSpawnerScript.new()
	add_child(spawner)

	_assert(spawner.active_chunks.size() == GameConfig.INITIAL_CHUNKS_COUNT,
		"Spawner should initialize with %d active chunks." % GameConfig.INITIAL_CHUNKS_COUNT)

	# Verify contiguous snapping without gaps or overlaps
	for i in range(spawner.active_chunks.size()):
		var chunk: TrackChunk = spawner.active_chunks[i]
		var expected_z: float = -float(i) * GameConfig.CHUNK_LENGTH
		_assert(is_equal_approx(chunk.global_position.z, expected_z),
			"Chunk %d should be at Z=%.1f, found %.1f." % [i, expected_z, chunk.global_position.z])

		if i > 0:
			var prev_chunk: TrackChunk = spawner.active_chunks[i - 1]
			var seam_gap: float = absf(prev_chunk.get_exit_position().z - chunk.get_entry_position().z)
			_assert(seam_gap < 0.01, "Seam between chunk %d and %d must have zero gap (found %.3f)." % [i - 1, i, seam_gap])

	spawner.queue_free()
	_end_test("Track Spawner Initial Layout & Seamless Snapping")


func _test_track_continuous_spawning_and_recycling() -> void:
	_start_test("Continuous Spawning & Memory Recycling")

	var spawner: TrackSpawner = TrackSpawnerScript.new()
	add_child(spawner)

	var initial_active_count: int = spawner.active_chunks.size()

	# Simulate player moving forward from Z=0 to Z=-100
	var player_mock: Node3D = Node3D.new()
	add_child(player_mock)
	player_mock.global_position = Vector3(0.0, 0.0, -100.0)
	spawner.target_player = player_mock

	# Trigger update
	spawner._update_track(-100.0)

	# Oldest chunk at Z=0 (100m behind player) and Z=-30 (70m behind player) must be recycled (>40m)
	_assert(spawner.active_chunks[0].global_position.z <= -60.0,
		"Old chunks behind player should have been recycled.")

	# Leading chunk must extend well ahead of player
	var furthest_z: float = spawner.next_spawn_z
	var distance_ahead: float = player_mock.global_position.z - furthest_z
	var expected_lead: float = float(GameConfig.INITIAL_CHUNKS_COUNT) * GameConfig.CHUNK_LENGTH
	_assert(distance_ahead >= expected_lead,
		"Track must maintain at least %.1f lead distance ahead of player." % expected_lead)

	# Active chunk count must remain bounded (avoiding runaway memory accumulation)
	_assert(spawner.active_chunks.size() <= initial_active_count + 2,
		"Active chunk count should remain stable and bounded.")

	player_mock.queue_free()
	spawner.queue_free()
	_end_test("Continuous Spawning & Memory Recycling")


func _test_track_reset() -> void:
	_start_test("Track Reset")

	var spawner: TrackSpawner = TrackSpawnerScript.new()
	add_child(spawner)

	spawner.reset_track()
	_assert(spawner.active_chunks.size() == 0, "active_chunks must be empty after reset_track().")
	_assert(spawner.next_spawn_z == 0.0, "next_spawn_z must reset to 0.0.")

	spawner.spawn_initial_track()
	_assert(spawner.active_chunks.size() == GameConfig.INITIAL_CHUNKS_COUNT,
		"spawn_initial_track() should re-populate initial chunk count.")

	spawner.queue_free()
	_end_test("Track Reset")


func _start_test(test_name: String) -> void:
	_tests_total += 1
	print("[TEST] %s..." % test_name)


func _end_test(test_name: String) -> void:
	_tests_passed += 1
	print("  -> %s passed." % test_name)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error("ASSERTION FAILED: " + message)
		assert(condition, message)
