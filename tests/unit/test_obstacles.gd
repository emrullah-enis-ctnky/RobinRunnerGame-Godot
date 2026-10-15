extends Node
## Automated unit tests for Phase 5: Obstacles & Environmental Hazards.
## Verifies hazard collision layers, destructible targets, duck barriers, and route passability.

const GameConfig = preload("res://scripts/common/game_config.gd")

const OBSTACLE_SCENES = [
	"res://scenes/obstacles/obstacle_stones.tscn",
	"res://scenes/obstacles/obstacle_rocks.tscn",
	"res://scenes/obstacles/obstacle_fence.tscn",
	"res://scenes/obstacles/obstacle_log.tscn",
	"res://scenes/obstacles/obstacle_tree.tscn",
	"res://scenes/obstacles/obstacle_tree_tall.tscn"
]

const DESTRUCTIBLE_SCENES = [
	"res://scenes/obstacles/target_archery.tscn",
	"res://scenes/obstacles/barrier_fragile.tscn"
]

const CHUNK_SCENES = [
	"res://scenes/world/chunks/track_chunk_straight.tscn",
	"res://scenes/world/chunks/track_chunk_forest.tscn",
	"res://scenes/world/chunks/track_chunk_rocky.tscn"
]

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _tests_passed: int = 0
var _tests_total: int = 0
var _current_failed: bool = false


func _ready() -> void:
	print("==========================================")
	print("--- Running Obstacle & Hazard Tests ---")
	print("==========================================")

	await _run_all_tests()

	print("==========================================")
	if _tests_passed == _tests_total:
		print("--- ALL OBSTACLE TESTS PASSED (%d/%d) ---" % [_tests_passed, _tests_total])
	else:
		push_error("--- SOME OBSTACLE TESTS FAILED (%d/%d) ---" % [_tests_passed, _tests_total])
	print("==========================================")

	# Quit cleanly on completion
	get_tree().quit(0 if _tests_passed == _tests_total else 1)


func _run_all_tests() -> void:
	_test_static_obstacle_layers()
	await _test_destructible_targets()
	_test_overhead_duck_barrier()
	_test_player_hazard_detector()
	_test_hazard_lethality_profiles()
	_test_hazard_visual_collider_alignment()
	_test_lethal_hit_resolution()
	_test_arch_head_bump_feedback()
	_test_chunk_route_passability()


## Verifies every static hazard sits on the obstacle layer with a real collider.
func _test_static_obstacle_layers() -> void:
	_start_test("Static Obstacle Collision Layers")

	for path in OBSTACLE_SCENES:
		var scene: PackedScene = load(path)
		_assert(scene != null, "%s must load." % path)
		if scene == null:
			continue

		var obstacle: StaticBody3D = scene.instantiate() as StaticBody3D
		_assert(obstacle != null, "%s must instantiate a StaticBody3D." % path)
		if obstacle == null:
			continue

		add_child(obstacle)
		_assert(obstacle.collision_layer == GameConfig.LAYER_OBSTACLE,
			"%s must sit on LAYER_OBSTACLE." % path)
		_assert(obstacle.collision_mask == 0,
			"%s must not scan any collision mask." % path)
		_assert(obstacle.is_in_group("obstacle"),
			"%s must join the obstacle group." % path)
		_assert(obstacle.has_method("get_hazard_type"),
			"%s must expose get_hazard_type()." % path)
		_assert(_first_collision_shape(obstacle) != null,
			"%s must define a collision shape." % path)
		obstacle.queue_free()

	_end_test("Static Obstacle Collision Layers")


## Verifies destructible targets report their reward and can be revived.
func _test_destructible_targets() -> void:
	_start_test("Destructible Targets & Fragile Barriers")

	for path in DESTRUCTIBLE_SCENES:
		var scene: PackedScene = load(path)
		_assert(scene != null, "%s must load." % path)
		if scene == null:
			continue

		var target: StaticBody3D = scene.instantiate() as StaticBody3D
		_assert(target != null, "%s must instantiate a StaticBody3D." % path)
		if target == null:
			continue

		add_child(target)
		_assert(target.collision_layer == GameConfig.LAYER_TARGET,
			"%s must sit on LAYER_TARGET." % path)
		_assert(target.is_in_group("obstacle") and target.is_in_group("destructible"),
			"%s must join the obstacle and destructible groups." % path)
		_assert(_first_collision_shape(target) != null,
			"%s must define a collision shape." % path)
		target.queue_free()

	var reward: Dictionary = {"target_name": "", "score": 0}
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.target_destroyed.connect(func(target_name: String, score: int) -> void:
			reward["target_name"] = target_name
			reward["score"] = score
		)

	var archery: StaticBody3D = load(DESTRUCTIBLE_SCENES[0]).instantiate() as StaticBody3D
	add_child(archery)
	var expected_reward: int = archery.score_reward

	archery.destroy()
	_assert(archery.is_destroyed, "destroy() must flag the target as destroyed.")
	_assert(not archery.visible, "destroy() must hide the target.")
	_assert(reward["score"] == expected_reward,
		"destroy() must report the configured score reward.")
	_assert(reward["target_name"] == str(archery.name),
		"destroy() must report the target name.")

	# The collision layer is cleared deferred, so give the physics server a frame
	await get_tree().process_frame
	_assert(archery.collision_layer == 0,
		"destroy() must stop the target from detecting the player.")

	archery.restore()
	await get_tree().process_frame
	_assert(not archery.is_destroyed and archery.visible, "restore() must revive the target.")
	_assert(archery.collision_layer == GameConfig.LAYER_TARGET,
		"restore() must return the target to LAYER_TARGET.")

	archery.queue_free()
	_end_test("Destructible Targets & Fragile Barriers")


## Verifies the overhead arch exposes a beam the player must duck under.
func _test_overhead_duck_barrier() -> void:
	_start_test("Overhead Duck Barrier")

	var arch: Node3D = load("res://scenes/world/props/overhead_arch.tscn").instantiate() as Node3D
	add_child(arch)

	var body: StaticBody3D = arch.get_node_or_null("HazardBody") as StaticBody3D
	_assert(body != null, "The overhead arch must expose a HazardBody.")
	if body != null:
		_assert(body.collision_layer == GameConfig.LAYER_OBSTACLE,
			"The arch beam must sit on LAYER_OBSTACLE.")
		_assert(body.is_in_group("overhead_barrier"),
			"The arch beam must join the overhead_barrier group.")

		var shape: CollisionShape3D = _first_collision_shape(body)
		_assert(shape != null, "The arch beam must define a collision shape.")
		if shape != null:
			var beam_bottom: float = shape.position.y - _shape_height(shape) * 0.5
			_assert(beam_bottom > 1.0,
				"The beam must hang above ducking height (bottom %.2f)." % beam_bottom)

	arch.queue_free()
	_end_test("Overhead Duck Barrier")


## Verifies the player detector covers hazards and shrinks while ducking.
func _test_player_hazard_detector() -> void:
	_start_test("Player Hazard Detector & Duck Profile")

	var player: CharacterBody3D = PLAYER_SCENE.instantiate() as CharacterBody3D
	add_child(player)

	var detector: Area3D = player.get_node_or_null("HazardDetector") as Area3D
	_assert(detector != null, "The player must carry a HazardDetector area.")
	if detector != null:
		_assert(detector.collision_mask == GameConfig.LAYER_OBSTACLE | GameConfig.LAYER_TARGET,
			"The detector mask must cover obstacles and targets.")

	_assert(player.collision_mask == GameConfig.LAYER_ENVIRONMENT,
		"The player body must only collide with the environment.")

	var hazard_shape: CollisionShape3D = player.get_node_or_null("HazardDetector/CollisionShape3D")
	_assert(hazard_shape != null, "The detector must define a collision shape.")
	if hazard_shape != null:
		var standing_top: float = hazard_shape.position.y + _shape_height(hazard_shape) * 0.5
		player.duck()
		var ducking_top: float = hazard_shape.position.y + _shape_height(hazard_shape) * 0.5
		_assert(standing_top > 1.2 and ducking_top < 1.0,
			"Ducking must shrink the hazard silhouette (standing %.2f, ducking %.2f)." % [standing_top, ducking_top])

	player.queue_free()
	_end_test("Player Hazard Detector & Duck Profile")


## Verifies trees and the ladder barrier declare a lethal profile while logs and low hazards stay forgiving.
func _test_hazard_lethality_profiles() -> void:
	_start_test("Hazard Lethality Profiles")

	var lethal_paths: Array = [
		"res://scenes/obstacles/obstacle_tree.tscn",
		"res://scenes/obstacles/obstacle_tree_tall.tscn",
		"res://scenes/obstacles/barrier_fragile.tscn"
	]
	var forgiving_paths: Array = [
		"res://scenes/obstacles/obstacle_stones.tscn",
		"res://scenes/obstacles/obstacle_rocks.tscn",
		"res://scenes/obstacles/obstacle_fence.tscn",
		"res://scenes/obstacles/obstacle_log.tscn"
	]

	for path in lethal_paths:
		var obstacle: StaticBody3D = load(path).instantiate() as StaticBody3D
		add_child(obstacle)
		_assert(obstacle.is_lethal_hazard(),
			"%s must end the run on a single contact." % path)
		obstacle.queue_free()

	for path in forgiving_paths:
		var obstacle: StaticBody3D = load(path).instantiate() as StaticBody3D
		add_child(obstacle)
		_assert(not obstacle.is_lethal_hazard(),
			"%s must stay forgiving and stagger on the first contact." % path)
		obstacle.queue_free()

	_end_test("Hazard Lethality Profiles")


## Verifies each hazard's visible mesh is centred on its collider, so a player can never
## run through the visible geometry (a misaligned log once left its collider in another lane).
func _test_hazard_visual_collider_alignment() -> void:
	_start_test("Hazard Visual & Collider Alignment")

	var all_paths: Array = OBSTACLE_SCENES + DESTRUCTIBLE_SCENES
	for path in all_paths:
		var obstacle: StaticBody3D = load(path).instantiate() as StaticBody3D
		add_child(obstacle)

		var shape_node: CollisionShape3D = _first_collision_shape(obstacle)
		var mesh_instance: MeshInstance3D = _first_mesh_instance(obstacle)
		if shape_node != null and mesh_instance != null:
			var mesh_center: Vector3 = (mesh_instance.global_transform * mesh_instance.get_aabb()).get_center()
			var shape_center: Vector3 = shape_node.global_position
			_assert(absf(mesh_center.x - shape_center.x) <= 0.3,
				"%s visual must align with its collider on X (mesh %.2f, collider %.2f)." % [path, mesh_center.x, shape_center.x])
			_assert(absf(mesh_center.z - shape_center.z) <= 0.3,
				"%s visual must align with its collider on Z (mesh %.2f, collider %.2f)." % [path, mesh_center.z, shape_center.z])

		obstacle.queue_free()

	_end_test("Hazard Visual & Collider Alignment")


## Verifies lethal hazards end the run instantly and bypass the stagger immunity.
func _test_lethal_hit_resolution() -> void:
	_start_test("Lethal Hit Resolution & Immunity Bypass")

	var player: CharacterBody3D = PLAYER_SCENE.instantiate() as CharacterBody3D
	add_child(player)

	player.take_hit("tree", true)
	_assert(not player.can_control, "A lethal hit must end the run immediately.")
	_assert(not player.is_stumbling, "A lethal hit must not leave the player staggering.")

	# A lethal hit inside the stagger window must still be fatal
	player.reset_player()
	player.take_hit("rocks", false)
	_assert(player.is_stumbling, "A forgiving hazard must stagger the player first.")
	player.take_hit("tree", true)
	_assert(not player.can_control, "A lethal hit must bypass the stagger immunity window.")

	# A forgiving hazard must not kill on its first contact
	player.reset_player()
	player.take_hit("rocks", false)
	_assert(player.can_control and player.is_stumbling,
		"A forgiving hazard must stagger without ending the run.")

	player.queue_free()
	_end_test("Lethal Hit Resolution & Immunity Bypass")


## Verifies an arch hit reads as a head bump while ground hazards tip the runner forward.
func _test_arch_head_bump_feedback() -> void:
	_start_test("Overhead Arch Head-Bump Feedback")

	var player: CharacterBody3D = PLAYER_SCENE.instantiate() as CharacterBody3D
	add_child(player)

	player.take_hit("rocks", false)
	var ground_tilt: float = player.visual_model.rotation.x
	_assert(ground_tilt < 0.0,
		"A ground hazard must tip the runner forward (got %.2f)." % ground_tilt)

	player.reset_player()
	player.take_hit("overhead_barrier", false)
	var arch_tilt: float = player.visual_model.rotation.x
	_assert(arch_tilt > 0.0,
		"An arch hit must recoil the runner backward as a head bump (got %.2f)." % arch_tilt)

	player.queue_free()
	_end_test("Overhead Arch Head-Bump Feedback")


## Verifies every chunk row of hazards always leaves at least one clear lane.
func _test_chunk_route_passability() -> void:
	_start_test("Chunk Hazard Rows & Route Passability")

	for path in CHUNK_SCENES:
		var scene: PackedScene = load(path)
		_assert(scene != null, "%s must load." % path)
		if scene == null:
			continue

		var chunk: Node3D = scene.instantiate() as Node3D
		_assert(chunk != null, "%s must instantiate a Node3D." % path)
		if chunk == null:
			continue

		add_child(chunk)

		# Group every lane-blocking hazard by the chunk-depth row it occupies
		var rows: Dictionary = {}
		for node in chunk.find_children("*", "Node3D", true, false):
			if not node.is_in_group("obstacle"):
				continue
			var row_index: int = int(round(node.position.z / GameConfig.LANE_WIDTH))
			var lane_index: int = int(round(node.position.x / GameConfig.LANE_WIDTH))
			if not rows.has(row_index):
				rows[row_index] = []
			rows[row_index].append(lane_index)

		_assert(rows.size() > 0, "%s must place at least one hazard row." % path)

		var lanes: Array = [GameConfig.LANE_LEFT, GameConfig.LANE_CENTER, GameConfig.LANE_RIGHT]
		for row_index in rows.keys():
			var blocked_lanes: Array = rows[row_index]
			var free_lanes: int = 0
			for lane in lanes:
				if not blocked_lanes.has(lane):
					free_lanes += 1
			_assert(free_lanes >= 1,
				"%s row at z=%.0f must leave a clear lane (free: %d)." % [path, float(row_index) * GameConfig.LANE_WIDTH, free_lanes])

		chunk.queue_free()

	_end_test("Chunk Hazard Rows & Route Passability")


## Returns the first collision shape directly owned by a physics body.
func _first_collision_shape(body: Node) -> CollisionShape3D:
	for child in body.get_children():
		if child is CollisionShape3D:
			return child
	return null


## Returns the first mesh instance found beneath a hazard's visual tree.
func _first_mesh_instance(body: Node) -> MeshInstance3D:
	for node in body.find_children("*", "MeshInstance3D", true, false):
		return node as MeshInstance3D
	return null


## Returns the effective world height of a collision shape after node scaling.
func _shape_height(collision_shape: CollisionShape3D) -> float:
	var shape: Shape3D = collision_shape.shape
	if shape is BoxShape3D:
		return (shape as BoxShape3D).size.y * collision_shape.scale.y
	if shape is CapsuleShape3D:
		return (shape as CapsuleShape3D).height * collision_shape.scale.y
	return 0.0


func _start_test(test_name: String) -> void:
	_tests_total += 1
	_current_failed = false
	print("[TEST] %s..." % test_name)


func _end_test(test_name: String) -> void:
	if _current_failed:
		print("  -> %s FAILED." % test_name)
	else:
		_tests_passed += 1
		print("  -> %s passed." % test_name)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_current_failed = true
		push_error("ASSERTION FAILED: " + message)
