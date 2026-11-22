class_name ChunkBiomeDecorator
extends Node3D
## Builds dense, chunk-specific biome scenery flush against the trail, plus high overhead
## framing arches, overhanging tree canopies, and woodland stream-bridge crossings.

const CurvedWorld = preload("res://scripts/world/curved_world_controller.gd")

const TREE_SCENE: PackedScene = preload("res://assets/models/tree.glb")
const TREE_HIGH_SCENE: PackedScene = preload("res://assets/models/tree-high.glb")
const PLANT_SCENE: PackedScene = preload("res://assets/models/plant.glb")
const PATCH_GRASS_SCENE: PackedScene = preload("res://assets/models/patch-grass.glb")
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

# Shared reusable materials across chunks to prevent per-activation shader rebuilds
static var _mat_forest_bank: StandardMaterial3D
static var _mat_rocky_bank: StandardMaterial3D
static var _mat_meadow_bank: StandardMaterial3D
static var _mat_water: StandardMaterial3D
static var _mat_wood_rustic: StandardMaterial3D
static var _mat_wood_bright: StandardMaterial3D

var _chunk: TrackChunk
var _decor_root: Node3D
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Attaches BiomeDecor as a child of self (never parent during _ready) and hooks chunk activation.
func _ready() -> void:
	_rng.randomize()
	_ensure_shared_materials()
	_decor_root = Node3D.new()
	_decor_root.name = "BiomeDecor"
	add_child(_decor_root)

	_chunk = _find_chunk()
	if _chunk != null:
		_chunk.activated.connect(_rebuild_decor)


## Rebuilds the chunk's biome-specific banks, dense props, framing arches, and stream crossings.
func _rebuild_decor() -> void:
	_clear()
	if _decor_root == null or _chunk == null:
		return

	var is_stream_bridge: bool = (biome == "straight" and _chunk.global_position.z < -20.0 and _rng.randf() < 0.45)
	if is_stream_bridge:
		_build_stream_bridge_chunk()
	elif biome == "forest":
		_build_forest_biome()
	elif biome == "rocky":
		_build_rocky_biome()
	else:
		_build_meadow_camp_biome()

	CurvedWorld.apply_to_tree(_chunk)


## Forest biome: lush mossy banks, dense multi-layer woods, trail-edge bushes, and leaning canopies.
func _build_forest_biome() -> void:
	_add_flank_banks(_mat_forest_bank, -0.05, 0.0, CHUNK_LEN)

	for side in [-1.0, 1.0]:
		# Dense trail-edge undergrowth & grass tufts hugging the path
		for b in range(10):
			var p_scene: PackedScene = PLANT_SCENE if b % 3 != 0 else PATCH_GRASS_SCENE
			var bush: Node3D = p_scene.instantiate() as Node3D
			bush.position = Vector3(side * _rng.randf_range(3.35, 5.2), 0.0, -float(b) * 2.9 - _rng.randf_range(0.4, 2.2))
			bush.scale = Vector3.ONE * _rng.randf_range(1.2, 2.2)
			bush.rotation.y = _rng.randf_range(0.0, TAU)
			_decor_root.add_child(bush)

		# Foreground trees right along the forest trail corridor (some leaning overhead)
		for f in range(8):
			var scene: PackedScene = TREE_HIGH_SCENE if f % 2 == 0 else TREE_SCENE
			var tree: Node3D = scene.instantiate() as Node3D
			var dist_x: float = _rng.randf_range(4.4, 8.8)
			tree.position = Vector3(side * dist_x, -0.08, -float(f) * 3.6 - _rng.randf_range(0.5, 2.8))
			tree.scale = Vector3.ONE * _rng.randf_range(2.6, 4.2)
			tree.rotation.y = _rng.randf_range(0.0, TAU)
			if dist_x < 6.4 and f % 3 == 0:
				tree.scale = Vector3.ONE * _rng.randf_range(4.0, 4.8)
				tree.rotation.z = side * deg_to_rad(_rng.randf_range(11.0, 17.0))
			_decor_root.add_child(tree)

		# Deep background forest wall filling out to 28m
		for bg in range(10):
			var bg_scene: PackedScene = TREE_HIGH_SCENE if _rng.randf() < 0.65 else TREE_SCENE
			var bg_tree: Node3D = bg_scene.instantiate() as Node3D
			bg_tree.position = Vector3(side * _rng.randf_range(9.5, 27.5), -0.1, -_rng.randf_range(1.0, CHUNK_LEN - 1.0))
			bg_tree.scale = Vector3.ONE * _rng.randf_range(3.2, 5.2)
			bg_tree.rotation.y = _rng.randf_range(0.0, TAU)
			_decor_root.add_child(bg_tree)

	if _rng.randf() < 0.6:
		_add_high_framing_gateway(-_rng.randf_range(10.0, 20.0), true)


## Rocky biome: canyon earth banks, dense stacked rock cliffs, trailside stones, and canyon gate.
func _build_rocky_biome() -> void:
	_add_flank_banks(_mat_rocky_bank, -0.05, 0.0, CHUNK_LEN)

	for side in [-1.0, 1.0]:
		# Continuous canyon cliff walls close to the trail
		for r in range(8):
			var r_scene: PackedScene = ROCK_HIGH_SCENE if r % 2 == 0 else ROCK_RAMP_SCENE
			var cliff: Node3D = r_scene.instantiate() as Node3D
			cliff.position = Vector3(side * _rng.randf_range(5.0, 11.0), -0.15, -float(r) * 3.7 - _rng.randf_range(0.4, 2.2))
			cliff.scale = Vector3(_rng.randf_range(2.8, 4.4), _rng.randf_range(3.4, 5.8), _rng.randf_range(2.8, 4.4))
			cliff.rotation.y = _rng.randf_range(0.0, TAU)
			_decor_root.add_child(cliff)

		# Outer towering rocky ridges
		for rr in range(6):
			var ridge: Node3D = ROCK_HIGH_SCENE.instantiate() as Node3D
			ridge.position = Vector3(side * _rng.randf_range(12.5, 25.0), -0.2, -_rng.randf_range(1.5, CHUNK_LEN - 1.5))
			ridge.scale = Vector3(_rng.randf_range(3.8, 5.6), _rng.randf_range(4.5, 7.2), _rng.randf_range(3.8, 5.6))
			ridge.rotation.y = _rng.randf_range(0.0, TAU)
			_decor_root.add_child(ridge)

		# Trail-edge boulders, stones & hardy scrub
		for s in range(7):
			var st: Node3D = (STONES_SCENE if s % 2 == 0 else ROCK_LOW_SCENE).instantiate() as Node3D
			st.position = Vector3(side * _rng.randf_range(3.5, 5.6), 0.0, -float(s) * 4.1 - _rng.randf_range(0.5, 2.4))
			st.scale = Vector3.ONE * _rng.randf_range(1.3, 2.4)
			st.rotation.y = _rng.randf_range(0.0, TAU)
			_decor_root.add_child(st)

		# Sparse alpine pines perched between canyon cliffs
		for t in range(5):
			var pine: Node3D = TREE_HIGH_SCENE.instantiate() as Node3D
			pine.position = Vector3(side * _rng.randf_range(10.0, 26.0), -0.1, -_rng.randf_range(1.5, CHUNK_LEN - 1.5))
			pine.scale = Vector3.ONE * _rng.randf_range(2.8, 4.5)
			pine.rotation.y = _rng.randf_range(0.0, TAU)
			_decor_root.add_child(pine)

	_add_high_framing_gateway(-15.0, false)


## Straight clearing biome: lush meadow banks, archer camp tents, wooden outpost, fences & treeline.
func _build_meadow_camp_biome() -> void:
	_add_flank_banks(_mat_meadow_bank, -0.05, 0.0, CHUNK_LEN)

	var camp_side: float = -1.0 if _rng.randf() < 0.5 else 1.0
	# Archer camp tents on one side
	for k in range(2):
		var tent: Node3D = TENT_SCENE.instantiate() as Node3D
		tent.position = Vector3(camp_side * _rng.randf_range(6.8, 10.5), -0.05, -6.5 - float(k) * 11.0 - _rng.randf_range(0.0, 3.0))
		tent.scale = Vector3.ONE * _rng.randf_range(2.2, 2.7)
		tent.rotation.y = -camp_side * deg_to_rad(_rng.randf_range(35.0, 85.0))
		_decor_root.add_child(tent)

	# Wooden watchtower / outpost on opposite side
	var outpost := Node3D.new()
	outpost.position = Vector3(-camp_side * _rng.randf_range(7.8, 11.5), -0.05, -_rng.randf_range(11.0, 21.0))
	outpost.rotation.y = camp_side * deg_to_rad(25.0)
	var base_b: Node3D = BUILDING_STRUCT_SCENE.instantiate() as Node3D
	base_b.scale = Vector3.ONE * 2.4
	var roof_b: Node3D = BUILDING_ROOF_SCENE.instantiate() as Node3D
	roof_b.position = Vector3(0.0, 2.15, 0.0)
	roof_b.scale = Vector3.ONE * 2.4
	outpost.add_child(base_b)
	outpost.add_child(roof_b)
	_decor_root.add_child(outpost)

	for side in [-1.0, 1.0]:
		# Trailside flags, rustic wooden fences & plants
		for fl in range(2):
			var flag: Node3D = FLAG_SCENE.instantiate() as Node3D
			flag.position = Vector3(side * 4.0, 0.0, -7.0 - float(fl) * 14.0)
			flag.scale = Vector3.ONE * 1.9
			_decor_root.add_child(flag)

		for p in range(8):
			var bush: Node3D = (PLANT_SCENE if p % 2 == 0 else PATCH_GRASS_SCENE).instantiate() as Node3D
			bush.position = Vector3(side * _rng.randf_range(3.4, 7.5), -0.02, -float(p) * 3.6 - _rng.randf_range(0.3, 2.0))
			bush.scale = Vector3.ONE * _rng.randf_range(1.1, 1.9)
			bush.rotation.y = _rng.randf_range(0.0, TAU)
			_decor_root.add_child(bush)

		# Dense treeline wrapping behind the camp meadow
		for t in range(11):
			var tree: Node3D = (TREE_SCENE if t % 2 == 0 else TREE_HIGH_SCENE).instantiate() as Node3D
			tree.position = Vector3(side * _rng.randf_range(11.0, 27.5), -0.08, -_rng.randf_range(1.0, CHUNK_LEN - 1.0))
			tree.scale = Vector3.ONE * _rng.randf_range(2.6, 4.6)
			tree.rotation.y = _rng.randf_range(0.0, TAU)
			_decor_root.add_child(tree)


## Stream-bridge crossing: splits the banks around a shimmering woodland creek beneath the track.
func _build_stream_bridge_chunk() -> void:
	_add_flank_banks(_mat_meadow_bank, -0.05, 0.0, 9.0)
	_add_flank_banks(_mat_meadow_bank, -0.05, 21.0, 9.0)

	var water_mesh := BoxMesh.new()
	water_mesh.size = Vector3(76.0, 0.3, 12.6)
	water_mesh.subdivide_width = 12
	water_mesh.subdivide_depth = 6
	water_mesh.material = _mat_water

	var water := MeshInstance3D.new()
	water.mesh = water_mesh
	water.position = Vector3(0.0, -1.65, -15.0)
	_decor_root.add_child(water)

	for side in [-1.0, 1.0]:
		for z_pos in [-10.5, -13.5, -16.5, -19.5]:
			var rail: Node3D = FENCE_SCENE.instantiate() as Node3D
			rail.position = Vector3(side * 3.45, 0.12, z_pos)
			rail.rotation.y = PI * 0.5
			rail.scale = Vector3(1.5, 1.4, 1.2)
			_decor_root.add_child(rail)

		for bank_z in [-7.8, -22.2]:
			for b in range(3):
				var boulder: Node3D = ROCK_LOW_SCENE.instantiate() as Node3D
				boulder.position = Vector3(side * _rng.randf_range(4.5, 18.0), -0.5, bank_z + _rng.randf_range(-1.2, 1.2))
				boulder.scale = Vector3.ONE * _rng.randf_range(1.8, 3.2)
				boulder.rotation.y = _rng.randf_range(0.0, TAU)
				_decor_root.add_child(boulder)

			for tr in range(4):
				var tree: Node3D = TREE_HIGH_SCENE.instantiate() as Node3D
				tree.position = Vector3(side * _rng.randf_range(5.0, 24.0), -0.08, bank_z + (-3.2 if bank_z < -15.0 else 3.2) + _rng.randf_range(-1.8, 1.8))
				tree.scale = Vector3.ONE * _rng.randf_range(2.8, 4.6)
				tree.rotation.y = _rng.randf_range(0.0, TAU)
				_decor_root.add_child(tree)

	_add_high_framing_gateway(-10.0, false)


## Adds high-clearance (4.4m) timber overhead framing posts, crossbeam, and banners over the track.
func _add_high_framing_gateway(z_pos: float, rustic: bool) -> void:
	var wood_mat: StandardMaterial3D = _mat_wood_rustic if rustic else _mat_wood_bright
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.45, 4.9, 0.45)
	post_mesh.material = wood_mat

	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.mesh = post_mesh
		post.position = Vector3(side * 3.75, 2.35, z_pos)
		_decor_root.add_child(post)

		var flag: Node3D = FLAG_SCENE.instantiate() as Node3D
		flag.position = Vector3(side * 3.75, 4.5, z_pos)
		flag.scale = Vector3.ONE * 1.5
		_decor_root.add_child(flag)

	var beam_mesh := BoxMesh.new()
	beam_mesh.size = Vector3(8.4, 0.48, 0.55)
	beam_mesh.material = wood_mat
	var beam := MeshInstance3D.new()
	beam.mesh = beam_mesh
	beam.position = Vector3(0.0, 4.7, z_pos)
	_decor_root.add_child(beam)


## Builds subdivided flush terrain banks directly abutting both sides of the trail.
func _add_flank_banks(bank_mat: StandardMaterial3D, top_y: float, start_offset: float, length: float) -> void:
	var bank_mesh := BoxMesh.new()
	bank_mesh.size = Vector3(30.0, 2.8, length)
	bank_mesh.subdivide_depth = maxi(4, int(round(length / 2.5)))
	bank_mesh.subdivide_width = 4
	bank_mesh.material = bank_mat

	var center_z: float = -(start_offset + length * 0.5)
	for side in [-1.0, 1.0]:
		var bank := MeshInstance3D.new()
		bank.mesh = bank_mesh
		bank.position = Vector3(side * 18.2, top_y - 1.4, center_z)
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


static func _ensure_shared_materials() -> void:
	if _mat_forest_bank != null:
		return
	_mat_forest_bank = StandardMaterial3D.new()
	_mat_forest_bank.albedo_color = Color(0.18, 0.39, 0.16)
	_mat_forest_bank.roughness = 0.94

	_mat_rocky_bank = StandardMaterial3D.new()
	_mat_rocky_bank.albedo_color = Color(0.36, 0.32, 0.26)
	_mat_rocky_bank.roughness = 0.94

	_mat_meadow_bank = StandardMaterial3D.new()
	_mat_meadow_bank.albedo_color = Color(0.24, 0.46, 0.19)
	_mat_meadow_bank.roughness = 0.94

	_mat_water = StandardMaterial3D.new()
	_mat_water.albedo_color = Color(0.16, 0.56, 0.78)
	_mat_water.roughness = 0.16
	_mat_water.metallic = 0.18

	_mat_wood_rustic = StandardMaterial3D.new()
	_mat_wood_rustic.albedo_color = Color(0.32, 0.21, 0.13)
	_mat_wood_rustic.roughness = 0.88

	_mat_wood_bright = StandardMaterial3D.new()
	_mat_wood_bright.albedo_color = Color(0.42, 0.28, 0.16)
	_mat_wood_bright.roughness = 0.86
