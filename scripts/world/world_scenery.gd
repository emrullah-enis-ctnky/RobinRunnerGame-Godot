class_name WorldScenery
extends Node3D
## Populates rich flanking forest banks and distant low-poly mountains around the track.
## Side forest strips leapfrog forward seamlessly while distant mountains track player Z.

const TREE_SCENE: PackedScene = preload("res://assets/models/tree.glb")
const TREE_HIGH_SCENE: PackedScene = preload("res://assets/models/tree-high.glb")
const ROCK_HIGH_SCENE: PackedScene = preload("res://assets/models/rocks-high.glb")
const ROCK_LOW_SCENE: PackedScene = preload("res://assets/models/rocks-low.glb")
const TENT_SCENE: PackedScene = preload("res://assets/models/tent.glb")

const STRIP_LENGTH: float = 30.0
const STRIP_COUNT: int = 6

@export var player_path: NodePath = NodePath("../Player")

var _player: Node3D
var _horizon_root: Node3D
var _strips: Array[Node3D] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Builds the distant mountain backdrop and scrolling side-forest strips.
func _ready() -> void:
	_rng.randomize()
	_player = get_node_or_null(player_path) as Node3D
	_build_horizon_backdrop()
	_build_forest_strips()
	reset_scenery()

	if has_node("/root/EventBus"):
		get_node("/root/EventBus").game_restarted.connect(reset_scenery)


## Keeps distant mountains anchored to the horizon and wraps side forest strips ahead.
func _process(_delta: float) -> void:
	if _player == null:
		return
	var pz: float = _player.global_position.z
	if _horizon_root != null:
		_horizon_root.global_position.z = pz

	for strip in _strips:
		if strip.global_position.z > pz + STRIP_LENGTH * 1.4:
			var min_z: float = _furthest_strip_z()
			strip.global_position.z = min_z - STRIP_LENGTH


## Resets all forest strips and horizon backdrop back to the starting Z alignment.
func reset_scenery() -> void:
	var start_z: float = 15.0
	for i in range(_strips.size()):
		_strips[i].position = Vector3(0.0, 0.0, start_z - float(i) * STRIP_LENGTH)
	if _horizon_root != null:
		_horizon_root.position = Vector3.ZERO


func _furthest_strip_z() -> float:
	var min_z: float = 99999.0
	for strip in _strips:
		if strip.global_position.z < min_z:
			min_z = strip.global_position.z
	return min_z


## Creates stylized low-poly valley ground and distant mountain silhouettes on the horizon.
func _build_horizon_backdrop() -> void:
	_horizon_root = Node3D.new()
	_horizon_root.name = "HorizonBackdrop"
	add_child(_horizon_root)

	# Broad valley floor below the elevated track
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(360.0, 360.0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.18, 0.34, 0.16)
	floor_mat.roughness = 0.95
	floor_mesh.material = floor_mat

	var floor_inst := MeshInstance3D.new()
	floor_inst.mesh = floor_mesh
	floor_inst.position = Vector3(0.0, -3.4, -75.0)
	_horizon_root.add_child(floor_inst)

	# Stylized distant mountain peaks ringing the left, right, and far ahead horizon
	var peak_mat := StandardMaterial3D.new()
	peak_mat.albedo_color = Color(0.20, 0.31, 0.29)
	peak_mat.roughness = 0.92
	peak_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var snow_peak_mat := StandardMaterial3D.new()
	snow_peak_mat.albedo_color = Color(0.28, 0.38, 0.39)
	snow_peak_mat.roughness = 0.88

	var peaks: Array[Array] = [
		# [x, z, radius, height, use_alt]
		[-78.0, -140.0, 42.0, 52.0, true],
		[-32.0, -165.0, 48.0, 62.0, false],
		[22.0,  -170.0, 46.0, 58.0, true],
		[76.0,  -145.0, 44.0, 54.0, false],
		[-92.0, -70.0,  36.0, 40.0, false],
		[94.0,  -75.0,  38.0, 44.0, true],
		[-88.0, -10.0,  34.0, 34.0, true],
		[90.0,  -12.0,  34.0, 36.0, false],
	]
	for p in peaks:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.6
		cone.bottom_radius = p[2]
		cone.height = p[3]
		cone.radial_segments = 6
		cone.rings = 1
		cone.material = snow_peak_mat if p[4] else peak_mat

		var mi := MeshInstance3D.new()
		mi.mesh = cone
		mi.position = Vector3(p[0], -3.5 + p[3] * 0.5, p[1])
		mi.rotation.y = _rng.randf_range(0.0, TAU)
		_horizon_root.add_child(mi)


## Builds STRIP_COUNT reusable flanking forest strips with Kenney trees, rocks, and occasional tents.
func _build_forest_strips() -> void:
	var bank_mat := StandardMaterial3D.new()
	bank_mat.albedo_color = Color(0.22, 0.42, 0.19)
	bank_mat.roughness = 0.92

	for i in range(STRIP_COUNT):
		var strip := Node3D.new()
		strip.name = "ForestStrip_%d" % i
		add_child(strip)
		_strips.append(strip)

		for side in [-1.0, 1.0]:
			# Grassy roadside ridge slightly below the track deck
			var bank_mesh := BoxMesh.new()
			bank_mesh.size = Vector3(26.0, 2.2, STRIP_LENGTH)
			bank_mesh.material = bank_mat
			var bank := MeshInstance3D.new()
			bank.mesh = bank_mesh
			bank.position = Vector3(side * 18.5, -2.3, -STRIP_LENGTH * 0.5)
			strip.add_child(bank)

			# Dense stylized pine/tree clusters along the bank
			for t_idx in range(7):
				var prop_scene: PackedScene = TREE_HIGH_SCENE if _rng.randf() < 0.55 else TREE_SCENE
				var prop: Node3D = prop_scene.instantiate() as Node3D
				var x_off: float = side * _rng.randf_range(7.2, 29.0)
				var z_off: float = -_rng.randf_range(1.5, STRIP_LENGTH - 1.5)
				var sc: float = _rng.randf_range(2.2, 4.2)
				prop.position = Vector3(x_off, -1.25, z_off)
				prop.scale = Vector3.ONE * sc
				prop.rotation.y = _rng.randf_range(0.0, TAU)
				strip.add_child(prop)

			# Roadside rocks & occasional camp tent for visual variety
			for r_idx in range(2):
				var r_scene: PackedScene = ROCK_HIGH_SCENE if _rng.randf() < 0.5 else ROCK_LOW_SCENE
				var rock: Node3D = r_scene.instantiate() as Node3D
				rock.position = Vector3(side * _rng.randf_range(6.8, 22.0), -1.25, -_rng.randf_range(2.0, STRIP_LENGTH - 2.0))
				rock.scale = Vector3.ONE * _rng.randf_range(1.6, 3.0)
				rock.rotation.y = _rng.randf_range(0.0, TAU)
				strip.add_child(rock)

			if i % 2 == 0 and side > 0.0:
				var tent: Node3D = TENT_SCENE.instantiate() as Node3D
				tent.position = Vector3(side * _rng.randf_range(11.0, 18.0), -1.25, -_rng.randf_range(6.0, STRIP_LENGTH - 6.0))
				tent.scale = Vector3.ONE * 2.2
				tent.rotation.y = _rng.randf_range(0.0, TAU)
				strip.add_child(tent)
