class_name TrackSpawner
extends Node3D
## Manages procedural track chunk generation and recycling in RobinRunner.
## Continuously maintains a connected path ahead of the player using ObjectPools.

const ObjectPool = preload("res://scripts/common/object_pool.gd")
const TrackChunk = preload("res://scripts/world/track_chunk.gd")

@export var chunk_scenes: Array[PackedScene] = []
@export var target_player: Node3D
@export var initial_chunk_count: int = GameConfig.INITIAL_CHUNKS_COUNT
@export var chunk_length: float = GameConfig.CHUNK_LENGTH
@export var despawn_distance_behind: float = GameConfig.CHUNK_DESPAWN_DISTANCE_BEHIND

# Pools mapped by chunk scene resource path
var _chunk_pools: Dictionary = {}
var _chunk_by_pool: Dictionary = {} # Maps TrackChunk instance to its ObjectPool
var active_chunks: Array[TrackChunk] = []
var next_spawn_z: float = 0.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_load_default_chunk_scenes()
	_initialize_pools()
	spawn_initial_track()


func _physics_process(_delta: float) -> void:
	_find_player_if_missing()
	if target_player == null:
		return

	_update_track(target_player.global_position.z)


## Populates initial track chunks ahead of the starting position.
func spawn_initial_track() -> void:
	reset_track()

	for i in range(initial_chunk_count):
		# First two chunks always use the clean straight variant to ensure a safe launch zone
		var prefer_straight: bool = (i < 2)
		_spawn_next_chunk(prefer_straight)


## Resets and recycles all active chunks.
func reset_track() -> void:
	while not active_chunks.is_empty():
		var chunk: TrackChunk = active_chunks.pop_back()
		_recycle_chunk_instance(chunk)

	next_spawn_z = 0.0


## Spawns the next track chunk and advances the spawn Z coordinate.
func _spawn_next_chunk(prefer_straight: bool = false) -> TrackChunk:
	if chunk_scenes.is_empty():
		push_error("TrackSpawner: No chunk scenes configured.")
		return null

	var selected_scene: PackedScene = chunk_scenes[0]
	if not prefer_straight and chunk_scenes.size() > 1:
		var rand_idx: int = _rng.randi_range(0, chunk_scenes.size() - 1)
		selected_scene = chunk_scenes[rand_idx]

	var pool: ObjectPool = _chunk_pools.get(selected_scene)
	if pool == null:
		push_error("TrackSpawner: Pool missing for selected chunk scene.")
		return null

	var chunk_node: Node = pool.acquire()
	if not (chunk_node is TrackChunk):
		push_error("TrackSpawner: Acquired node is not a TrackChunk.")
		return null

	var chunk: TrackChunk = chunk_node as TrackChunk
	_chunk_by_pool[chunk] = pool

	var spawn_pos: Vector3 = Vector3(0.0, 0.0, next_spawn_z)
	chunk.activate(spawn_pos)

	active_chunks.append(chunk)
	next_spawn_z -= chunk_length

	return chunk


## Evaluates player Z position to spawn new chunks ahead and recycle old chunks behind.
func _update_track(player_z: float) -> void:
	# Keep a buffer of initial_chunk_count chunks ahead of the player
	var required_lead: float = float(initial_chunk_count) * chunk_length
	while (player_z - next_spawn_z) < required_lead:
		_spawn_next_chunk()

	# Recycle chunks that have fallen behind the despawn threshold
	while not active_chunks.is_empty():
		var oldest_chunk: TrackChunk = active_chunks[0]
		# Player moves towards negative Z, so oldest_chunk.z - player_z is positive distance behind
		var distance_behind: float = oldest_chunk.global_position.z - player_z
		if distance_behind > despawn_distance_behind:
			active_chunks.remove_at(0)
			_recycle_chunk_instance(oldest_chunk)
		else:
			break


func _recycle_chunk_instance(chunk: TrackChunk) -> void:
	if chunk == null or not is_instance_valid(chunk):
		return

	var pool: ObjectPool = _chunk_by_pool.get(chunk)
	if pool != null:
		pool.release(chunk)
	else:
		chunk.queue_free()


func _initialize_pools() -> void:
	for scene in chunk_scenes:
		if scene != null and not _chunk_pools.has(scene):
			# Prewarm each chunk variant with 3 instances
			var pool: ObjectPool = ObjectPool.new(scene, self, 3, 20)
			_chunk_pools[scene] = pool


func _load_default_chunk_scenes() -> void:
	if not chunk_scenes.is_empty():
		return

	var paths: Array[String] = [
		"res://scenes/world/chunks/track_chunk_straight.tscn",
		"res://scenes/world/chunks/track_chunk_forest.tscn",
		"res://scenes/world/chunks/track_chunk_rocky.tscn"
	]

	for path in paths:
		if ResourceLoader.exists(path):
			var res: PackedScene = load(path)
			if res != null:
				chunk_scenes.append(res)


func _find_player_if_missing() -> void:
	if target_player != null and is_instance_valid(target_player):
		return

	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0] is Node3D:
		target_player = players[0] as Node3D
