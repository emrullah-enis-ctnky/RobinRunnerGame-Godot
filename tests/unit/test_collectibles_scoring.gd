extends Node
## Automated unit tests for Phase 8: CoinPickup, ScoreManager, ArcheryTarget scoring, and ChunkCollectibleSpawner.

const GameConfig = preload("res://scripts/common/game_config.gd")
const COIN_SCENE: PackedScene = preload("res://scenes/collectibles/coin.tscn")
const TARGET_SCENE: PackedScene = preload("res://scenes/obstacles/target_archery.tscn")
const CHUNK_SCENE: PackedScene = preload("res://scenes/world/chunks/track_chunk_forest.tscn")
const ARROW_SCENE: PackedScene = preload("res://scenes/combat/arrow.tscn")
const ARCHERY_TARGET_SCRIPT = preload("res://scripts/obstacles/archery_target.gd")

var _passed: int = 0
var _failed: int = 0
var _current_failed: bool = false


func _ready() -> void:
	await _run_all_tests()
	print("COLLECTIBLES_SCORING_TEST_SUMMARY: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func _run_all_tests() -> void:
	await _test_coin_size_and_idle()
	await _test_coin_pickup_burst_and_restore()
	await _test_score_manager_distance_and_combo()
	await _test_archery_target_ring_scoring()
	await _test_chunk_collectible_spawner()


## Verifies the coin mesh is scaled down appropriately relative to the ~1.55m runner and rotates/bobs.
func _test_coin_size_and_idle() -> void:
	_start_test("Coin Size & Idle Animation")
	var coin: Area3D = COIN_SCENE.instantiate() as Area3D
	add_child(coin)
	await get_tree().process_frame

	var mesh: Node3D = coin.get_node_or_null("Mesh") as Node3D
	_assert(mesh != null, "CoinPickup should contain a Mesh child")
	if mesh != null:
		var bounds: AABB = MeshFit.local_bounds(mesh)
		var max_dim: float = maxf(bounds.size.x * mesh.scale.x, maxf(bounds.size.y * mesh.scale.y, bounds.size.z * mesh.scale.z))
		_assert(max_dim <= GameConfig.COIN_MODEL_DIAMETER + 0.05 and max_dim >= 0.25,
			"Coin diameter should be normalized around %.2fm (got %.3f)" % [GameConfig.COIN_MODEL_DIAMETER, max_dim])

		var start_rot_y: float = mesh.rotation.y
		coin._process(0.1)
		_assert(not is_equal_approx(mesh.rotation.y, start_rot_y), "Coin should spin around Y during idle")

	coin.queue_free()
	await get_tree().process_frame
	_end_test("Coin Size & Idle Animation")


## Verifies player contact emits collectible_picked, spawns gold PickupBurst, hides, and restores cleanly.
func _test_coin_pickup_burst_and_restore() -> void:
	_start_test("Coin Pickup Burst & Restore")
	var coin: Area3D = COIN_SCENE.instantiate() as Area3D
	add_child(coin)

	var body := CharacterBody3D.new()
	body.add_to_group("player")
	add_child(body)
	await get_tree().process_frame

	var picked_count: Array[int] = [0]
	var picked_val: Array[int] = [0]
	var bus: Node = get_node("/root/EventBus")
	var cb := func(t: String, v: int) -> void:
		if t == GameConfig.COLLECTIBLE_TYPE_COIN:
			picked_count[0] += 1
			picked_val[0] = v
	bus.collectible_picked.connect(cb)

	coin._on_body_entered(body)
	await get_tree().process_frame
	_assert(picked_count[0] == 1 and picked_val[0] == GameConfig.COIN_SCORE_VALUE,
		"Coin contact should emit collectible_picked with coin value")

	var bursts: Array[Node] = get_tree().get_nodes_in_group("pickup_burst")
	_assert(bursts.size() >= 1, "Coin pickup should spawn a PickupBurst particle effect")

	coin.restore()
	_assert(coin.visible and is_equal_approx(coin.scale.x, 1.0), "restore() should reset coin visibility and scale")

	bus.collectible_picked.disconnect(cb)
	coin.queue_free()
	body.queue_free()
	await get_tree().process_frame
	_end_test("Coin Pickup Burst & Restore")


## Verifies ScoreManager accumulates distance, applies coin combo multipliers, and resets on restart/damage.
func _test_score_manager_distance_and_combo() -> void:
	_start_test("ScoreManager Distance & Combo")
	var gm: Node = get_node("/root/GameManager")
	var sm: Node = get_node("/root/ScoreManager")
	var bus: Node = get_node("/root/EventBus")

	gm.restart_game()
	await get_tree().process_frame
	_assert(gm.score == 0 and sm.coins_collected == 0, "ScoreManager and GameManager should start at 0")

	bus.distance_updated.emit(12.6)
	_assert(gm.score == 12, "Distance 12.6m should add 12 distance points (got %d)" % gm.score)

	# Collect 10 coins to step combo multiplier from 1.0x to 1.1x (+10%)
	for i in range(10):
		bus.collectible_picked.emit(GameConfig.COLLECTIBLE_TYPE_COIN, 10)
	_assert(sm.coins_collected == 10, "Should track 10 collected coins")
	_assert(is_equal_approx(sm.combo_multiplier, 1.1), "10-coin streak should reach 1.1x (+10%%) multiplier (got %.2f)" % sm.combo_multiplier)

	# Damage breaks combo and applies -20% stumble penalty (0.8x)
	bus.player_damaged.emit(5.0)
	_assert(sm.combo_count == 0 and is_equal_approx(sm.get_effective_multiplier(), 0.8),
		"Hazard damage should reset coin combo and apply 0.8x (-20%%) penalty")

	gm.restart_game()
	_assert(sm.coins_collected == 0 and gm.score == 0, "Restart should reset ScoreManager")
	_end_test("ScoreManager Distance & Combo")


## Verifies ArcheryTarget emits ring-based target_destroyed scores when an arrow embeds.
func _test_archery_target_ring_scoring() -> void:
	_start_test("ArcheryTarget Ring Scoring")
	var gm: Node = get_node("/root/GameManager")
	gm.restart_game()

	var target: StaticBody3D = TARGET_SCENE.instantiate() as StaticBody3D
	add_child(target)
	await get_tree().process_frame

	var bullseye_score: int = target.score_for_impact(ARCHERY_TARGET_SCRIPT.BOARD_CENTER)
	var outer_score: int = target.score_for_impact(ARCHERY_TARGET_SCRIPT.BOARD_CENTER + Vector3(0.45, 0.0, 0.0))
	_assert(bullseye_score == 100, "Bullseye should award 100 points (got %d)" % bullseye_score)
	_assert(outer_score < bullseye_score, "Outer ring should award fewer points than bullseye")

	var arrow: Node3D = ARROW_SCENE.instantiate() as Node3D
	add_child(arrow)
	arrow.activate(Vector3(0.0, 0.64, 2.0), Vector3.FORWARD, GameConfig.ARROW_TYPE_NORMAL)
	target.stick_arrow(arrow, target.global_position + ARCHERY_TARGET_SCRIPT.BOARD_CENTER)
	_assert(gm.score > 0, "Sticking an arrow in ArcheryTarget should bank ring score into GameManager")

	target.queue_free()
	await get_tree().process_frame
	_end_test("ArcheryTarget Ring Scoring")


## Verifies ChunkCollectibleSpawner populates coins on TrackChunk activation without crashing or zeroing.
func _test_chunk_collectible_spawner() -> void:
	_start_test("ChunkCollectibleSpawner")
	var chunk: TrackChunk = CHUNK_SCENE.instantiate() as TrackChunk
	add_child(chunk)
	await get_tree().process_frame

	chunk.activate(Vector3.ZERO)
	await get_tree().process_frame
	await get_tree().process_frame

	var pickups: Node3D = chunk.get_node_or_null("Pickups") as Node3D
	var coin_count: int = 0
	if pickups != null:
		for child in pickups.get_children():
			if child.is_in_group("coin"):
				coin_count += 1
	_assert(coin_count >= 3, "Activated chunk should spawn at least one group of coins (got %d)" % coin_count)

	chunk.queue_free()
	await get_tree().process_frame
	_end_test("ChunkCollectibleSpawner")


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
