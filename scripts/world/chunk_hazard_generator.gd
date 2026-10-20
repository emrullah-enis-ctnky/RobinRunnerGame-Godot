class_name ChunkHazardGenerator
extends Node3D
## Rebuilds a chunk's hazards with a fresh, always-passable layout on every reuse.

const _NO_LANE: int = 99

@export var hazard_scenes: Array[PackedScene] = []
@export var row_offsets: Array[float] = [-8.0, -14.0, -20.0, -26.0]
@export var min_rows: int = 2
@export var max_rows: int = 4
@export_range(0.0, 1.0) var double_row_chance: float = 0.35

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _chunk: TrackChunk
var _lane_objects: Node3D
var _generated: Array[Node3D] = []


## Finds the owning chunk and regenerates the layout every time it is recycled.
func _ready() -> void:
	_rng.randomize()
	_chunk = _find_chunk()
	if _chunk == null:
		return

	_lane_objects = _chunk.get_node_or_null("LaneObjects")
	_chunk.activated.connect(_generate)


## Returns the pooled track chunk this generator belongs to.
func _find_chunk() -> TrackChunk:
	var node: Node = get_parent()
	while node != null:
		if node is TrackChunk:
			return node as TrackChunk
		node = node.get_parent()
	return null


## Clears the previous layout and spawns a new fair set of hazard rows.
func _generate() -> void:
	_clear()
	if _lane_objects == null or hazard_scenes.is_empty():
		return

	var rows: Array[float] = _pick_rows()
	var previous_free_lane: int = _NO_LANE

	for row_z in rows:
		var blocked: Array[int] = []
		if _rng.randf() < double_row_chance:
			var free_lane: int = _pick_free_lane(previous_free_lane)
			for lane in range(3):
				if lane != free_lane:
					blocked.append(lane)
			previous_free_lane = free_lane
		else:
			blocked.append(_pick_blocked_lane(previous_free_lane))
			previous_free_lane = _NO_LANE

		_spawn_row(blocked, row_z)


## Picks the row count and returns the chosen row depths in travel order.
func _pick_rows() -> Array[float]:
	var candidates: Array[float] = []
	for offset in row_offsets:
		candidates.append(offset)
	_shuffle(candidates)

	var count: int = mini(_rng.randi_range(min_rows, max_rows), candidates.size())
	var chosen: Array[float] = []
	for offset in candidates:
		if chosen.size() >= count:
			break
		chosen.append(offset)

	chosen.sort()
	chosen.reverse()
	return chosen


## Returns a free lane at most one lane away from the previous dense row's free lane.
func _pick_free_lane(previous_free_lane: int) -> int:
	if previous_free_lane == _NO_LANE:
		return _rng.randi_range(0, 2)
	return clampi(previous_free_lane + _rng.randi_range(-1, 1), 0, 2)


## Picks a blocked lane that keeps the previous dense row's free lane open.
func _pick_blocked_lane(previous_free_lane: int) -> int:
	if previous_free_lane == _NO_LANE:
		return _rng.randi_range(0, 2)

	var lane: int = _rng.randi_range(0, 2)
	while lane == previous_free_lane:
		lane = _rng.randi_range(0, 2)
	return lane


## Instantiates one distinct hazard per blocked lane in the row.
func _spawn_row(blocked_lanes: Array[int], row_z: float) -> void:
	var palette: Array = hazard_scenes.duplicate()
	_shuffle(palette)

	for i in range(blocked_lanes.size()):
		var scene: PackedScene = palette[i % palette.size()]
		var hazard: Node3D = scene.instantiate() as Node3D
		if hazard == null:
			continue
		hazard.position = Vector3(GameConfig.get_lane_x(blocked_lanes[i] - 1), 0.0, row_z)
		_lane_objects.add_child(hazard)
		_generated.append(hazard)


## Detaches the previous layout immediately so it cannot overlap the new one.
func _clear() -> void:
	for hazard in _generated:
		if not is_instance_valid(hazard):
			continue
		if hazard.get_parent() != null:
			hazard.get_parent().remove_child(hazard)
		hazard.queue_free()
	_generated.clear()


## Shuffles an array in place with the chunk-local RNG.
func _shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var swap: Variant = items[i]
		items[i] = items[j]
		items[j] = swap
