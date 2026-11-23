class_name ChunkCollectibleSpawner
extends Node3D
## Populates coin lines and jump arcs on a track chunk without overlapping tall hazards.

const GameConfig = preload("res://scripts/common/game_config.gd")
const CurvedWorld = preload("res://scripts/world/curved_world_controller.gd")
const COIN_SCENE: PackedScene = preload("res://scenes/collectibles/coin.tscn")

const COIN_SPACING_Z: float = 1.65
const ROW_CANDIDATES: Array[float] = [-6.0, -12.0, -18.0, -24.0]
const JUMP_ARC_HEIGHTS: Array[float] = [0.95, 1.48, 0.95]
const HAZARD_CLEARANCE_Z: float = 2.6
const HAZARD_CLEARANCE_X: float = 0.9

@export var min_groups: int = 1
@export var max_groups: int = 2
@export var line_coin_count: int = 4

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _chunk: TrackChunk
var _pickups_node: Node3D
var _lane_objects: Node3D
var _generated: Array[Node3D] = []


## Finds the owning chunk and schedules coin generation whenever the chunk activates.
func _ready() -> void:
	_rng.randomize()
	_chunk = _find_chunk()
	if _chunk == null:
		return

	_pickups_node = _chunk.get_node_or_null("Pickups")
	_lane_objects = _chunk.get_node_or_null("LaneObjects")
	_chunk.activated.connect(_on_chunk_activated)


## Defers generation so ChunkHazardGenerator finishes placing hazards on the same frame first.
func _on_chunk_activated() -> void:
	call_deferred("generate_now")


## Clears previously spawned coins and builds a fresh coin pattern for the active chunk.
func generate_now() -> void:
	_clear()
	if _pickups_node == null:
		return

	var hazards: Array[Node3D] = _collect_hazards()
	var rows: Array[float] = ROW_CANDIDATES.duplicate()
	_shuffle_floats(rows)

	var target_groups: int = _rng.randi_range(min_groups, max_groups)
	var placed: int = 0

	for row_z in rows:
		if placed >= target_groups:
			break
		if _chunk.global_position.z + row_z > -4.0:
			continue
		if _try_place_group_at(row_z, hazards):
			placed += 1


## Attempts to place either a jump arc over a low hazard or a ground coin line on a clear lane.
func _try_place_group_at(row_z: float, hazards: Array[Node3D]) -> bool:
	var lanes: Array[int] = [GameConfig.LANE_LEFT, GameConfig.LANE_CENTER, GameConfig.LANE_RIGHT]
	_shuffle_ints(lanes)

	# Prefer a jump arc if a low jumpable hazard sits near this Z
	for lane in lanes:
		var lane_x: float = GameConfig.get_lane_x(lane)
		var low_hazard: Node3D = _find_jumpable_hazard_near(lane_x, row_z, hazards)
		if low_hazard != null:
			_spawn_arc(lane_x, low_hazard.position.z)
			return true

	# Otherwise place a ground line in a lane free of any nearby hazards
	for lane in lanes:
		var lane_x: float = GameConfig.get_lane_x(lane)
		if _is_span_clear(lane_x, row_z, line_coin_count, hazards):
			_spawn_line(lane_x, row_z, line_coin_count)
			return true

	return false


## Spawns a straight ground line of coins along -Z in the chosen lane.
func _spawn_line(lane_x: float, start_z: float, count: int) -> void:
	for i in range(count):
		var coin: Node3D = COIN_SCENE.instantiate() as Node3D
		coin.position = Vector3(lane_x, GameConfig.COIN_HOVER_HEIGHT, start_z - float(i) * COIN_SPACING_Z)
		_pickups_node.add_child(coin)
		CurvedWorld.apply_to_tree(coin)
		_generated.append(coin)


## Spawns a 3-coin jump arc centered over a low obstacle.
func _spawn_arc(lane_x: float, center_z: float) -> void:
	var offsets_z: Array[float] = [COIN_SPACING_Z, 0.0, -COIN_SPACING_Z]
	for i in range(3):
		var coin: Node3D = COIN_SCENE.instantiate() as Node3D
		coin.position = Vector3(lane_x, JUMP_ARC_HEIGHTS[i], center_z + offsets_z[i])
		_pickups_node.add_child(coin)
		CurvedWorld.apply_to_tree(coin)
		_generated.append(coin)


## Returns a low, jumpable hazard near (lane_x, center_z) if none of the taller lethal ones block it.
func _find_jumpable_hazard_near(lane_x: float, center_z: float, hazards: Array[Node3D]) -> Node3D:
	for h in hazards:
		if absf(h.position.x - lane_x) > HAZARD_CLEARANCE_X:
			continue
		if absf(h.position.z - center_z) > HAZARD_CLEARANCE_Z:
			continue
		if h.has_method("is_lethal_hazard") and h.is_lethal_hazard():
			return null
		if "overhead" in h.name.to_lower() or "target" in h.name.to_lower():
			return null
		return h
	return null


## Returns true when no hazard sits close to the planned coin line.
func _is_span_clear(lane_x: float, start_z: float, count: int, hazards: Array[Node3D]) -> bool:
	var end_z: float = start_z - float(count - 1) * COIN_SPACING_Z
	var min_z: float = end_z - HAZARD_CLEARANCE_Z * 0.6
	var max_z: float = start_z + HAZARD_CLEARANCE_Z * 0.6

	for h in hazards:
		if absf(h.position.x - lane_x) > HAZARD_CLEARANCE_X:
			continue
		if h.position.z >= min_z and h.position.z <= max_z:
			return false
	return true


## Collects active hazard nodes under LaneObjects for overlap checks.
func _collect_hazards() -> Array[Node3D]:
	var result: Array[Node3D] = []
	if _lane_objects == null:
		return result
	for child in _lane_objects.get_children():
		if child is Node3D and is_instance_valid(child) and not child.is_queued_for_deletion():
			result.append(child as Node3D)
	return result


## Frees all previously generated coins on this chunk.
func _clear() -> void:
	for coin in _generated:
		if is_instance_valid(coin):
			coin.queue_free()
	_generated.clear()


## Walks up the tree to locate the owning TrackChunk.
func _find_chunk() -> TrackChunk:
	var node: Node = get_parent()
	while node != null:
		if node is TrackChunk:
			return node as TrackChunk
		node = node.get_parent()
	return null


func _shuffle_floats(arr: Array[float]) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: float = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func _shuffle_ints(arr: Array[int]) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: int = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
