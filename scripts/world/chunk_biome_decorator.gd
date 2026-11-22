class_name ChunkBiomeDecorator
extends Node3D
## Builds chunk-specific biome scenery flush against the track, plus high overhead framing
## arches, overhanging tree canopies, and woodland stream-bridge crossings.

const CurvedWorld = preload("res://scripts/world/curved_world_controller.gd")

const TREE_SCENE: PackedScene = preload("res://assets/models/tree.glb")
const TREE_HIGH_SCENE: PackedScene = preload("res://assets/models/tree-high.glb")
const PLANT_SCENE: PackedScene = preload("res://assets/models/plant.glb")
const ROCK_HIGH_SCENE: PackedScene = preload("res://assets/models/rocks-high.glb")
const ROCK_LOW_SCENE: PackedScene = preload("res://assets/models/rocks-low.glb")
const ROCK_RAMP_SCENE: PackedScene = preload("res://assets/models/rocks-ramp.glb")
const STONES_SCENE: PackedScene = preload("res://assets/models/stones.glb")
const TENT_SCENE: PackedScene = preload("res://assets/models/tent.glb")
const BUILDING_STRUCT_SCENE: PackedScene = preload("res://assets/models/building-structure.glb")
const BUILDING_ROOF_SCENE: PackedScene = preload("res://assets/models/building-roof.glb")
const FLAG_SCENE: PackedScene = preload("res://assets/models/flag.glb")
const FENCE_SCENE: PackedScene = preload("res://assets/models/fence.glb")

const CHUNK_LEN: float = 30.0

@export_enum("straight", "forest", "rocky") var biome: String = "straight"

var _chunk: TrackChunk
var _decor_root: Node3D
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Connects to the owning TrackChunk.activated signal so biome scenery matches every chunk reuse.
func _ready() -> void:
	_rng.randomize()
	_chunk = _find_chunk()
	if _chunk == null:
		return

	_decor_root = Node3D.new()
	_decor_root.name = "BiomeDecor"
	_chunk.add_child(_decor_root)
	_chunk.activated.connect(_rebuild_decor)


## Rebuilds the chunk's biome-specific banks, props, overhead framing, and optional stream crossing.
func _rebuild_decor() -> void:
	_clear()
	if _decor_root == null:
		return

	var is_stream_bridge: bool = (biome == "straight" and _chunk.global_position.z < -20.0 and _rng.randf() < 0.5)
	if is_stream_bridge:
		_build_stream_bridge_chunk()
	elif biome == "forest":
		_build_forest_biome()
	elif biome == "rocky":
		_build_rocky_biome()
	else:
		_build_meadow_camp_biome()

	# Apply curved-world shader to the entire chunk (track + newly created biome decor)
	CurvedWorld.apply_to_tree(_chunk)


## Forest biome: lush flush moss banks, dense multi-tier trees, bushes, and leaning canopy framing.
func _build_forest_biome() -> void:
	_add_flank_banks(Color(0.20, 0.42, 0.18), -0.18, 0.0, CHUNK_LEN)

	for side in [-1.0, 1.0]:
		# Trail-edge undergrowth hugging the curbs
		for b in range(6):
			var bush: Node3D = PLANT_SCENE.instantiate() as Node3D
			bush.position = Vector3(side * _rng.randf_range(3.6, 5.2), 0.0, -_rng.randf_range(1.5, CHUNK_LEN - 1.5))
			bush.scale = Vector3.ONE * _rng.randf_range(1.1, 1.9)
			bush.rotation.y = _rng.randf_range(0.0, TAU)
			_decor_root.add_child(bush)

		# Dense layered forest corridor
		for t in range(10):
			var scene: PackedScene = TREE_HIGH_SCENE if _rng.randf() < 0.6 else TREE_SCENE
			var tree: Node3D = scene.instantiate() as Node3D
			var dist_x: float = _rng.randf_range(4.8, 25.0)
			tree.position = Vector3(side * dist_x, -0.15, -_rng.randf_range(1.2, CHUNK_LEN - 1.2))
			tree.scale = Vector3.ONE * _rng.randf_range(2.2, 4.4)
			tree.rotation.y = _rng.randf_range(0.0, TAU)
			# Tall roadside trees lean gently inward high above the track to frame the corridor
			if dist_x < 7.2 and t % 3 == 0:
				tree.scale = Vector3.ONE * _rng.randf_range(3.8, 4.6)
				tree.rotation.z = side * deg_to_rad(_rng.randf_range(10.0, 16.0))
			_decor_root.add_child(tree)

	# High rustic woodland timber arch framing the upper vista (4.3m clearance)
	if _rng.randf() < 0.65:
		_add_high_framing_gateway(-_rng.randf_range(9.0, 21.0), true)


## Rocky biome: canyon earth banks, towering rock cliffs, stones, sparse pines, and a high wooden gate.
func _build_rocky_biome() -> void:
	_add_flank_banks(Color(0.36, 0.33, 0.28), -0.18, 0.0, CHUNK_LEN)

	for side in [-1.0, 1.0]:
		# Towering canyon cliff walls close to the track
		for r in range(6):
			var r_scene: PackedScene = ROCK_HIGH_SCENE if r % 2 == 0 else ROCK_RAMP_SCENE
			var cliff: Node3D = r_scene.instantiate() as Node3D
			var dist_x: float = _rng.randf_range(5.2, 16.0)
			cliff.position = Vector3(side * dist_x, -0.25, -float(r) * 5.0 - _rng.randf_range(1.0, 3.5))
			cliff.scale = Vector3(_rng.randf_range(2.6, 4.2), _rng.randf_range(3.0, 5.2), _rng.randf_range(2.6, 4.2))
			cliff.rotation.y = _rng.randf_range(0.0, TAU)
			_decor_root.add_child(cliff)

		# Trailside boulders & stones
		for s in range(4):
			var st: Node3D = (STONES_SCENE if s % 2 == 0 else ROCK_LOW_SCENE).instantiate() as Node3D
			st.position = Vector3(side * _rng.randf_range(3.8, 6.2), 0.0, -_rng.randf_range(1.5, CHUNK_LEN - 1.5))
			st.scale = Vector3.ONE * _rng.randf_range(1.2, 2.2)
			st.rotation.y = _rng.randf_range(0.0, TAU)
			_decor_root.add_child(st)

		# Hardy highland pines further back
		for t in range(4):
			var pine: Node3D = TREE_HIGH_SCENE.instantiate() as Node3D
			pine.position = Vector3(side * _rng.randf_range(14.0, 27.0), -0.15, -_rng.randf_range(2.0, CHUNK_LEN - 2.0))
			pine.scale = Vector3.ONE * _rng.randf_range(2.5, 4.0)
			pine.rotation.y = _rng.randf_range(0.0, TAU)
			_decor_root.add_child(pine)

	_add_high_framing_gateway(-15.0, false)


## Straight clearing biome: open sunlit meadow, archer camp tents, watchtower outpost, and pennants.
func _build_meadow_camp_biome() -> void:
	_add_flank_banks(Color(0.25, 0.48, 0.21), -0.18, 0.0, CHUNK_LEN)

	var camp_side: float = -1.0 if _rng.randf() < 0.5 else 1.0
	# Archer camp outpost on one side
	var tent: Node3D = TENT_SCENE.instantiate() as Node3D
	tent.position = Vector3(camp_side * _rng.randf_range(7.0, 10.5), -0.1, -_rng.randf_range(7.0, 14.0))
	tent.scale = Vector3.ONE * 2.4
	tent.rotation.y = -camp_side * deg_to_rad(_rng.randf_range(40.0, 80.0))
	_decor_root.add_child(tent)

	var outpost: Node3D = Node3D.new()
	outpost.position = Vector3(-camp_side * _rng.randf_range(8.0, 12.0), -0.1, -_rng.randf_range(16.0, 24.0))
	outpost.rotation.y = camp_side * deg_to_rad(30.0)
	var base_b: Node3D = BUILDING_STRUCT_SCENE.instantiate() as Node3D
	base_b.scale = Vector3.ONE * 2.2
	var roof_b: Node3D = BUILDING_ROOF_SCENE.instantiate() as Node3D
	roof_b.position = Vector3(0.0, 2.0, 0.0)
	roof_b.scale = Vector3.ONE * 2.2
	outpost.add_child(base_b)
	outpost.add_child(roof_b)
	_decor_root.add_child(outpost)

	for side in [-1.0, 1.0]:
		# Trailside flags & wildflowers/plants
		var flag: Node3D = FLAG_SCENE.instantiate() as Node3D
		flag.position = Vector3(side * 4.2, 0.0, -_rng.randf_range(6.0, 24.0))
		flag.scale = Vector3.ONE * 1.8
		_decor_root.add_child(flag)

		for p in range(5):
			var bush: Node3D = PLANT_SCENE.instantiate() as Node3D
			bush.position = Vector3(side * _rng.randf_range(3.8, 9.0), -0.05, -_rng.randf_range(1.5, CHUNK_LEN - 1.5))
			bush.scale = Vector3.ONE * _rng.randf_range(1.0, 1.7)
			bush.rotation.y = _rng.randf_range(0.0, TAU)
			_decor_root.add_child(bush)

		# Distant meadow treeline framing the clearing
		for t in range(5):
			var tree: Node3D = (TREE_SCENE if t % 2 == 0 else TREE_HIGH_SCENE).instantiate() as Node3D
			tree.position = Vector3(side * _rng.randf_range(13.5, 27.0), -0.15, -_rng.randf_range(1.5, CHUNK_LEN - 1.5))
			tree.scale = Vector3.ONE * _rng.randf_range(2.4, 4.0)
			tree.rotation.y = _rng.randf_range(0.0, TAU)
			_decor_root.add_child(tree)


## Stream-bridge crossing: splits the banks around a shimmering woodland creek passing beneath the track.
func _build_stream_bridge_chunk() -> void:
	# Front & back grass banks leaving a 12m wide valley channel in the middle (-9..-21)
	_add_flank_banks(Color(0.24, 0.46, 0.20), -0.18, 0.0, 9.0)
	_add_flank_banks(Color(0.24, 0.46, 0.20), -0.18, 21.0, 9.0)

	# Shimmering forest stream cutting across the valley beneath the bridge
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.16, 0.56, 0.78)
	water_mat.roughness = 0.16
	water_mat.metallic = 0.18

	var water_mesh := BoxMesh.new()
	water_mesh.size = Vector3(72.0, 0.3, 12.6)
	water_mesh.subdivide_width = 12
	water_mesh.subdivide_depth = 6
	water_mesh.material = water_mat

	var water := MeshInstance3D.new()
	water.mesh = water_mesh
	water.position = Vector3(0.0, -1.75, -15.0)
	_decor_root.add_child(water)

	# Wooden bridge side railings & riverbank rocks/trees
	for side in [-1.0, 1.0]:
		for z_pos in [-10.5, -13.5, -16.5, -19.5]:
			var rail: Node3D = FENCE_SCENE.instantiate() as Node3D
			rail.position = Vector3(side * 3.45, 0.15, z_pos)
			rail.rotation.y = PI * 0.5
			rail.scale = Vector3(1.5, 1.35, 1.2)
			_decor_root.add_child(rail)

		for bank_z in [-8.2, -21.8]:
			var boulder: Node3D = ROCK_LOW_SCENE.instantiate() as Node3D
			boulder.position = Vector3(side * _rng.randf_range(5.5, 14.0), -0.8, bank_z)
			boulder.scale = Vector3.ONE * _rng.randf_range(1.8, 3.0)
			boulder.rotation.y = _rng.randf_range(0.0, TAU)
			_decor_root.add_child(boulder)

			var tree: Node3D = TREE_HIGH_SCENE.instantiate() as Node3D
			tree.position = Vector3(side * _rng.randf_range(6.5, 20.0), -0.15, bank_z + (-2.5 if bank_z < -15.0 else 2.5))
			tree.scale = Vector3.ONE * _rng.randf_range(2.6, 4.2)
			_decor_root.add_child(tree)

	_add_high_framing_gateway(-10.0, false)


## Adds high-clearance (4.4m) timber overhead framing posts, crossbeam, and banners over the track.
func _add_high_framing_gateway(z_pos: float, rustic: bool) -> void:
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.32, 0.21, 0.13) if rustic else Color(0.40, 0.27, 0.16)
	wood_mat.roughness = 0.88

	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.42, 4.8, 0.42)
	post_mesh.material = wood_mat

	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.mesh = post_mesh
		post.position = Vector3(side * 3.75, 2.3, z_pos)
		_decor_root.add_child(post)

		var flag: Node3D = FLAG_SCENE.instantiate() as Node3D
		flag.position = Vector3(side * 3.75, 4.45, z_pos)
		flag.scale = Vector3.ONE * 1.4
		_decor_root.add_child(flag)

	var beam_mesh := BoxMesh.new()
	beam_mesh.size = Vector3(8.4, 0.45, 0.52)
	beam_mesh.material = wood_mat
	var beam := MeshInstance3D.new()
	beam.mesh = beam_mesh
	beam.position = Vector3(0.0, 4.65, z_pos)
	_decor_root.add_child(beam)


## Builds subdivided flush terrain banks directly abutting both sides of the track (zero gap).
func _add_flank_banks(color: Color, top_y: float, start_offset: float, length: float) -> void:
	var bank_mat := StandardMaterial3D.new()
	bank_mat.albedo_color = color
	bank_mat.roughness = 0.94

	var bank_mesh := BoxMesh.new()
	bank_mesh.size = Vector3(28.0, 2.6, length)
	bank_mesh.subdivide_depth = maxi(4, int(round(length / 2.5)))
	bank_mesh.subdivide_width = 4
	bank_mesh.material = bank_mat

	var center_z: float = -(start_offset + length * 0.5)
	for side in [-1.0, 1.0]:
		var bank := MeshInstance3D.new()
		bank.mesh = bank_mesh
		# Track edge is at +-3.3; 3.25 + 14.0 = 17.25 hugs the track with zero gap
		bank.position = Vector3(side * 17.25, top_y - 1.3, center_z)
		_decor_root.add_child(bank)


func _clear() -> void:
	if _decor_root == null:
		return
	for child in _decor_root.get_children():
		child.queue_free()


func _find_chunk() -> TrackChunk:
	var node: Node = get_parent()
	while node != null:
		if node is TrackChunk:
			return node as TrackChunk
		node = node.get_parent()
	return null
