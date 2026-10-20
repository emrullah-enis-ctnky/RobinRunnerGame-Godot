extends Node
## Automated unit tests for Phase 7: Combat & Ability System.
## Verifies the quiver, arrow pool, arrow flight, hit resolution, pickups, and smart selection.

const GameConfig = preload("res://scripts/common/game_config.gd")

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const ARROW_SCENE: PackedScene = preload("res://scenes/combat/arrow.tscn")
const ARROW_POOL_SCRIPT: GDScript = preload("res://scripts/combat/arrow_pool.gd")
const TARGET_SCENE: PackedScene = preload("res://scenes/obstacles/target_archery.tscn")
const TREE_SCENE: PackedScene = preload("res://scenes/obstacles/obstacle_tree.tscn")
const BARRIER_SCENE: PackedScene = preload("res://scenes/obstacles/barrier_fragile.tscn")
const ROCKY_CHUNK_SCENE: PackedScene = preload("res://scenes/world/chunks/track_chunk_rocky.tscn")
const PICKUP_SCENE: PackedScene = preload("res://scenes/combat/arrow_pickup_normal.tscn")
const FLAME_PICKUP_SCENE: PackedScene = preload("res://scenes/combat/arrow_pickup_flame.tscn")

var _tests_passed: int = 0
var _tests_total: int = 0
var _current_failed: bool = false


func _ready() -> void:
	print("==========================================")
	print("--- Running Combat & Ability Tests ---")
	print("==========================================")

	await _run_all_tests()

	print("==========================================")
	if _tests_passed == _tests_total:
		print("--- ALL COMBAT TESTS PASSED (%d/%d) ---" % [_tests_passed, _tests_total])
	else:
		push_error("--- SOME COMBAT TESTS FAILED (%d/%d) ---" % [_tests_passed, _tests_total])
	print("==========================================")

	# Quit cleanly on completion
	get_tree().quit(0 if _tests_passed == _tests_total else 1)


func _run_all_tests() -> void:
	_test_quiver_and_ammo()
	await _test_arrow_lifecycle()
	await _test_arrow_pool()
	await _test_arrow_hit_resolution()
	await _test_ladder_topple()
	await _test_ladder_resets_on_chunk_reuse()
	await _test_arrow_pickup()
	await _test_smart_arrow_selection()


## Verifies the AbilityManager quiver charges, spends, and blocks empty shots.
func _test_quiver_and_ammo() -> void:
	_start_test("Quiver & Ammo")

	var ability: Node = get_node_or_null("/root/AbilityManager")
	_assert(ability != null, "The AbilityManager autoload must exist.")
	if ability == null:
		_end_test("Quiver & Ammo")
		return

	ability.reset_ammo()
	_assert(ability.get_ammo(GameConfig.ARROW_TYPE_NORMAL) == GameConfig.START_AMMO_NORMAL,
		"The quiver must start with the configured normal arrows.")
	_assert(ability.get_ammo(GameConfig.ARROW_TYPE_FLAME) == GameConfig.START_AMMO_FLAME,
		"The quiver must start with the configured flame arrows.")

	# Collecting an arrow pickup tops up the quiver.
	var before: int = ability.get_ammo(GameConfig.ARROW_TYPE_FLAME)
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").collectible_picked.emit("arrow_flame", 2)
	_assert(ability.get_ammo(GameConfig.ARROW_TYPE_FLAME) == before + 2,
		"collectible_picked must add arrows to the quiver.")

	# Firing consumes an arrow and announces its type.
	var fired_types: Array = []
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").arrow_fired.connect(func(_origin: Vector3, _dir: Vector3, t: String) -> void:
			fired_types.append(t)
		)
	var fired: bool = ability.try_fire(Vector3.ZERO, Vector3.FORWARD, GameConfig.ARROW_TYPE_FLAME)
	_assert(fired, "try_fire must succeed while the quiver holds the type.")
	_assert(fired_types == [GameConfig.ARROW_TYPE_FLAME], "arrow_fired must report the fired type.")

	# An empty quiver blocks the shot entirely.
	ability.ammo[GameConfig.ARROW_TYPE_NORMAL] = 0
	ability.ammo[GameConfig.ARROW_TYPE_FLAME] = 0
	fired_types.clear()
	var blocked: bool = ability.try_fire(Vector3.ZERO, Vector3.FORWARD, GameConfig.ARROW_TYPE_NORMAL)
	_assert(not blocked, "try_fire must fail once the quiver is empty.")
	_assert(fired_types.is_empty(), "An empty quiver must not emit arrow_fired.")

	ability.reset_ammo()
	_end_test("Quiver & Ammo")


## Verifies a fired arrow travels forward, expires, and reports completion.
func _test_arrow_lifecycle() -> void:
	_start_test("Arrow Flight & Lifecycle")

	var arrow: Arrow = ARROW_SCENE.instantiate() as Arrow
	_assert(arrow != null, "arrow.tscn must instantiate an Arrow.")
	if arrow == null:
		_end_test("Arrow Flight & Lifecycle")
		return
	add_child(arrow)

	var finished: Array = []
	arrow.finished.connect(func(a: Arrow) -> void:
		finished.append(a)
	)

	arrow.lifetime = 0.1
	arrow.activate(Vector3.ZERO, Vector3.FORWARD, GameConfig.ARROW_TYPE_FLAME)
	_assert(arrow.visible, "activate() must show the arrow.")
	_assert(arrow.is_physics_processing(), "activate() must start the arrow moving.")

	var mesh: Node3D = arrow.get_node("Mesh") as Node3D
	var head_direction: Vector3 = (mesh.global_transform.basis * Vector3(0.0, 0.0, 1.0)).normalized()
	_assert(head_direction.dot(Vector3.FORWARD) > 0.99,
		"The arrow head must point along its travel direction.")
	_assert(absf(head_direction.y) < 0.01,
		"The arrow must fly parallel to the ground.")

	var flame_fx: GPUParticles3D = null
	for child in arrow.get_children():
		if child is GPUParticles3D:
			flame_fx = child
			break
	_assert(flame_fx != null and flame_fx.local_coords,
		"Flame particles must follow the arrow instead of trailing behind it.")
	_assert(flame_fx != null and flame_fx.position.z < -0.3,
		"Flame must emit at the arrow's leading tip, not at its rear.")

	var start_z: float = arrow.global_position.z
	await get_tree().physics_frame
	await get_tree().physics_frame
	_assert(arrow.global_position.z < start_z, "The arrow must travel along its direction.")

	var waited: int = 0
	while finished.is_empty() and waited < 60:
		await get_tree().physics_frame
		waited += 1
	_assert(finished.size() == 1, "An expired arrow must emit finished exactly once.")
	_assert(not arrow.visible, "A finished arrow must hide for pooling.")
	_assert(not arrow.is_physics_processing(), "A finished arrow must stop moving.")

	arrow.queue_free()
	_end_test("Arrow Flight & Lifecycle")


## Verifies the ArrowPool spawns on arrow_fired and recycles spent arrows.
func _test_arrow_pool() -> void:
	_start_test("Arrow Pool Spawning & Recycling")

	var pool: Node = ARROW_POOL_SCRIPT.new()
	add_child(pool)
	await get_tree().process_frame
	_assert(pool.get_active_count() == 0, "A fresh pool must hold no active arrows.")

	if has_node("/root/EventBus"):
		get_node("/root/EventBus").arrow_fired.emit(Vector3.ZERO, Vector3.FORWARD, GameConfig.ARROW_TYPE_NORMAL)
	await get_tree().process_frame
	_assert(pool.get_active_count() == 1, "arrow_fired must spawn a pooled arrow.")

	var arrow: Arrow = null
	for child in pool.get_children():
		if child is Arrow and child.is_physics_processing():
			arrow = child
			break
	_assert(arrow != null, "The pool must have an active arrow in flight.")
	if arrow != null:
		arrow.lifetime = 0.05
		arrow.activate(arrow.global_position, Vector3.FORWARD, GameConfig.ARROW_TYPE_NORMAL)
		var waited: int = 0
		while pool.get_active_count() > 0 and waited < 60:
			await get_tree().physics_frame
			waited += 1
		_assert(pool.get_active_count() == 0, "A finished arrow must return to the pool.")

	pool.queue_free()
	_end_test("Arrow Pool Spawning & Recycling")


## Verifies arrow types destroy the right hazards and leave others intact.
func _test_arrow_hit_resolution() -> void:
	_start_test("Arrow Hit Resolution")

	# A normal arrow destroys a standard destructible target.
	var target: StaticBody3D = TARGET_SCENE.instantiate() as StaticBody3D
	add_child(target)
	_assert(target.required_arrow_types().has(GameConfig.ARROW_TYPE_NORMAL),
		"The archery target must be vulnerable to normal arrows.")
	_assert(target.receive_arrow(GameConfig.ARROW_TYPE_NORMAL),
		"A normal arrow must destroy the archery target.")
	_assert(target.is_destroyed, "A destroyed target must be flagged.")
	target.restore()

	# A flame arrow leaves a normal-only target intact.
	_assert(not target.receive_arrow(GameConfig.ARROW_TYPE_FLAME),
		"A flame arrow must not destroy a normal-only target.")
	_assert(not target.is_destroyed, "A mismatched arrow must leave the target intact.")
	target.queue_free()

	# A flame arrow burns a tree while a normal arrow does not.
	var tree: StaticBody3D = TREE_SCENE.instantiate() as StaticBody3D
	add_child(tree)
	_assert(tree.is_lethal_hazard(), "Trees must stay lethal to the player.")
	_assert(tree.collision_layer == GameConfig.LAYER_OBSTACLE,
		"Trees must stay on LAYER_OBSTACLE.")
	_assert(tree.required_arrow_types().has(GameConfig.ARROW_TYPE_FLAME),
		"Trees must be vulnerable to flame arrows.")
	_assert(not tree.receive_arrow(GameConfig.ARROW_TYPE_NORMAL),
		"A normal arrow must not burn a tree.")
	_assert(tree.receive_arrow(GameConfig.ARROW_TYPE_FLAME),
		"A flame arrow must burn the tree down.")
	await get_tree().process_frame
	_assert(tree.collision_layer == 0, "A burned tree must stop blocking the lane.")

	tree.restore()
	await get_tree().process_frame
	_assert(tree.collision_layer == GameConfig.LAYER_OBSTACLE,
		"restore() must return the tree to LAYER_OBSTACLE.")
	tree.queue_free()

	_end_test("Arrow Hit Resolution")


## Verifies an arrow topples the ladder around its base and stays stuck while it falls.
func _test_ladder_topple() -> void:
	_start_test("Ladder Topple & Stuck Arrow")

	var barrier: StaticBody3D = BARRIER_SCENE.instantiate() as StaticBody3D
	barrier.position = Vector3(0.0, 0.0, -8.0)
	add_child(barrier)
	await get_tree().physics_frame

	_assert(barrier.has_method("stick_arrow"), "The ladder barrier must accept stuck arrows.")

	var arrow: Arrow = ARROW_SCENE.instantiate() as Arrow
	add_child(arrow)
	arrow.activate(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD, GameConfig.ARROW_TYPE_NORMAL)

	var waited: int = 0
	while arrow.get_parent() != barrier and waited < 60:
		await get_tree().physics_frame
		waited += 1

	_assert(arrow.get_parent() == barrier, "An arrow must embed in the ladder it knocks down.")
	_assert(not arrow.is_physics_processing(), "A stuck arrow must stop flying.")

	var planted_position: Vector3 = arrow.global_position
	for _frame in range(8):
		await get_tree().physics_frame
	_assert(barrier.collision_layer == GameConfig.LAYER_TARGET,
		"A toppling ladder must keep blocking the lane until it is nearly flat.")

	for _frame in range(60):
		await get_tree().physics_frame

	_assert(barrier.global_transform.basis.get_euler().x < -0.3,
		"The ladder must topple forward around its base.")
	_assert(not arrow.global_position.is_equal_approx(planted_position),
		"A stuck arrow must ride the toppling ladder.")
	_assert(barrier.collision_layer == 0, "A knocked-down ladder must stop blocking the lane.")

	# A flame arrow also topples the ladder.
	var flame_barrier: StaticBody3D = BARRIER_SCENE.instantiate() as StaticBody3D
	flame_barrier.position = Vector3(0.0, 0.0, -20.0)
	add_child(flame_barrier)
	await get_tree().physics_frame
	_assert(flame_barrier.receive_arrow(GameConfig.ARROW_TYPE_FLAME),
		"A flame arrow must knock the ladder down too.")
	_assert(flame_barrier.is_destroyed, "A flame-struck ladder must start toppling.")

	arrow.queue_free()
	flame_barrier.queue_free()
	barrier.queue_free()
	_end_test("Ladder Topple & Stuck Arrow")


## Verifies a recycled chunk presents its ladder upright instead of keeping it toppled.
func _test_ladder_resets_on_chunk_reuse() -> void:
	_start_test("Ladder Reset On Chunk Reuse")

	var chunk: Node3D = ROCKY_CHUNK_SCENE.instantiate() as Node3D
	add_child(chunk)
	await get_tree().physics_frame

	var generator: Node = chunk.get_node_or_null("ChunkHazards")
	_assert(generator != null, "The rocky chunk must generate its hazards.")
	if generator == null:
		chunk.queue_free()
		_end_test("Ladder Reset On Chunk Reuse")
		return

	# Force every generated row to be a ladder so the reset can be observed.
	var ladder_palette: Array[PackedScene] = [BARRIER_SCENE]
	generator.hazard_scenes = ladder_palette

	chunk.activate(Vector3.ZERO)
	await get_tree().process_frame

	var barrier: StaticBody3D = _find_ladder(chunk)
	_assert(barrier != null, "The rocky chunk must present a ladder barrier.")
	if barrier == null:
		chunk.queue_free()
		_end_test("Ladder Reset On Chunk Reuse")
		return

	barrier.receive_arrow(GameConfig.ARROW_TYPE_NORMAL)
	for _frame in range(60):
		await get_tree().physics_frame
	_assert(barrier.global_transform.basis.get_euler().x < -0.3,
		"The ladder must lie toppled before the chunk is recycled.")

	chunk.activate(Vector3(0.0, 0.0, -120.0))
	await get_tree().process_frame

	_assert(not is_instance_valid(barrier), "The toppled ladder must be discarded on reuse.")

	var reset_barrier: StaticBody3D = _find_ladder(chunk)
	_assert(reset_barrier != null, "A recycled chunk must present a ladder barrier again.")
	if reset_barrier != null:
		_assert(not reset_barrier.is_destroyed, "A recycled chunk must restore its ladder.")
		_assert(absf(reset_barrier.global_transform.basis.get_euler().x) < 0.01,
			"A recycled chunk must present an upright ladder.")
		_assert(reset_barrier.collision_layer == GameConfig.LAYER_TARGET,
			"A restored ladder must block its lane again.")

	chunk.queue_free()
	_end_test("Ladder Reset On Chunk Reuse")


## Returns the first generated ladder barrier under a chunk.
func _find_ladder(chunk: Node) -> StaticBody3D:
	for node in chunk.find_children("*", "StaticBody3D", true, false):
		if node is TopplingBarrier:
			return node as StaticBody3D
	return null


## Verifies arrow pickups report their type and hide on player contact.
func _test_arrow_pickup() -> void:
	_start_test("Arrow Pickup Collection")

	var pickup: Area3D = PICKUP_SCENE.instantiate() as Area3D
	add_child(pickup)
	_assert(pickup.collision_layer == GameConfig.LAYER_PICKUP,
		"Pickups must sit on LAYER_PICKUP.")
	_assert(pickup.collision_mask == GameConfig.LAYER_PLAYER,
		"Pickups must watch the player layer.")

	var rest_position: Vector3 = pickup.global_position
	for _frame in range(10):
		await get_tree().physics_frame
	_assert(pickup.global_position.is_equal_approx(rest_position),
		"Pickups must stay planted instead of bobbing.")

	var pickup_mesh: Node3D = pickup.get_node("Mesh") as Node3D
	_assert(not is_zero_approx(pickup_mesh.rotation.x),
		"Pickups must tilt the arrow into the ground.")
	_assert(is_zero_approx(MeshFit.local_bounds(pickup_mesh).end.z),
		"Pickups must pivot on the arrow tip, not the mesh centre.")

	var flame_pickup: Area3D = FLAME_PICKUP_SCENE.instantiate() as Area3D
	flame_pickup.position = Vector3(50.0, 0.0, 0.0)
	add_child(flame_pickup)
	var flame_fx: GPUParticles3D = null
	for child in flame_pickup.get_children():
		if child is GPUParticles3D:
			flame_fx = child
			break
	_assert(flame_fx != null and flame_fx.position.length() < 0.01,
		"Flame pickups must burn at the buried tip, not at the shaft end.")
	flame_pickup.queue_free()

	var picked: Dictionary = {"type": "", "value": 0}
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").collectible_picked.connect(func(t: String, v: int) -> void:
			picked["type"] = t
			picked["value"] = v
		)

	var player: CharacterBody3D = PLAYER_SCENE.instantiate() as CharacterBody3D
	player.add_to_group("player")
	add_child(player)
	player.global_position = pickup.global_position

	var waited: int = 0
	while picked["type"] == "" and waited < 30:
		await get_tree().physics_frame
		waited += 1
	_assert(picked["type"] == "arrow_normal", "Collecting must report the arrow type.")
	_assert(picked["value"] == 1, "Collecting must report the arrow amount.")

	# The collect effect flies and shrinks the arrow before it hides.
	await get_tree().create_timer(GameConfig.PICKUP_COLLECT_TIME + 0.2).timeout
	_assert(not pickup.visible, "A collected pickup must hide after its collect effect.")

	pickup.restore()
	_assert(pickup.visible, "restore() must show the pickup again.")

	player.queue_free()
	pickup.queue_free()
	_end_test("Arrow Pickup Collection")


## Verifies the player picks the arrow type that matches the hazard ahead.
func _test_smart_arrow_selection() -> void:
	_start_test("Smart Arrow Selection")

	var ability: Node = get_node_or_null("/root/AbilityManager")
	_assert(ability != null, "The AbilityManager autoload must exist.")
	if ability == null:
		_end_test("Smart Arrow Selection")
		return

	var tree: StaticBody3D = TREE_SCENE.instantiate() as StaticBody3D
	add_child(tree)
	tree.global_position = Vector3(0.0, 0.0, -10.0)

	var player: CharacterBody3D = PLAYER_SCENE.instantiate() as CharacterBody3D
	player.add_to_group("player")
	add_child(player)
	player.global_position = Vector3.ZERO
	await get_tree().physics_frame

	ability.reset_ammo()
	var origin: Vector3 = player.global_position + Vector3(0.0, GameConfig.ARROW_MUZZLE_HEIGHT, 0.0)
	var chosen: String = player._preferred_arrow_type(origin, Vector3.FORWARD)
	_assert(chosen == GameConfig.ARROW_TYPE_FLAME,
		"A burnable tree ahead must select a flame arrow.")

	# Without flame ammo the scan falls back to the normal arrow.
	ability.ammo[GameConfig.ARROW_TYPE_FLAME] = 0
	chosen = player._preferred_arrow_type(origin, Vector3.FORWARD)
	_assert(chosen == GameConfig.ARROW_TYPE_NORMAL,
		"Without flame ammo the scan must fall back to a normal arrow.")

	player.queue_free()
	tree.queue_free()
	_end_test("Smart Arrow Selection")


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
