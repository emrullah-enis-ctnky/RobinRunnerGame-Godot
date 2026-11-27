class_name WorldScenery
extends Node3D
## Maintains the distant low-poly mountain ring and broad valley floor anchored to the horizon.
## Per-chunk flanking biomes are handled directly by ChunkBiomeDecorator so scenery matches each chunk.

const CurvedWorld = preload("res://scripts/world/curved_world_controller.gd")

@export var player_path: NodePath = NodePath("../Player")

var _player: Node3D
var _horizon_root: Node3D
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Builds the distant mountain ring and valley floor and hooks run restarts.
func _ready() -> void:
	_rng.randomize()
	_player = get_node_or_null(player_path) as Node3D
	_build_horizon_backdrop()
	reset_scenery()

	if has_node("/root/EventBus"):
		get_node("/root/EventBus").game_restarted.connect(reset_scenery)


## Keeps distant mountains anchored to the horizon ahead of the runner.
func _process(_delta: float) -> void:
	if _player == null or _horizon_root == null:
		return
	_horizon_root.global_position.z = _player.global_position.z


## Resets the horizon anchor back to Z = 0 on run restart.
func reset_scenery() -> void:
	if _horizon_root != null:
		_horizon_root.position = Vector3.ZERO


## Creates the broad valley floor and stylized low-poly mountain silhouettes ringing the horizon.
func _build_horizon_backdrop() -> void:
	_horizon_root = Node3D.new()
	_horizon_root.name = "HorizonBackdrop"
	add_child(_horizon_root)

	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(380.0, 380.0)
	floor_mesh.subdivide_width = 12
	floor_mesh.subdivide_depth = 12
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.18, 0.34, 0.16)
	floor_mat.roughness = 0.95
	floor_mesh.material = floor_mat

	var floor_inst := MeshInstance3D.new()
	floor_inst.mesh = floor_mesh
	floor_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	floor_inst.position = Vector3(0.0, -3.2, -85.0)
	_horizon_root.add_child(floor_inst)

	var peak_mat := StandardMaterial3D.new()
	peak_mat.albedo_color = Color(0.20, 0.31, 0.29)
	peak_mat.roughness = 0.92

	var snow_peak_mat := StandardMaterial3D.new()
	snow_peak_mat.albedo_color = Color(0.28, 0.38, 0.39)
	snow_peak_mat.roughness = 0.88

	var peaks: Array[Array] = [
		[-82.0, -145.0, 44.0, 56.0, true],
		[-34.0, -168.0, 50.0, 66.0, false],
		[24.0,  -172.0, 48.0, 60.0, true],
		[80.0,  -148.0, 45.0, 56.0, false],
		[-96.0, -75.0,  38.0, 42.0, false],
		[96.0,  -78.0,  40.0, 46.0, true],
		[-90.0, -14.0,  34.0, 36.0, true],
		[92.0,  -16.0,  36.0, 38.0, false],
	]
	for p in peaks:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.7
		cone.bottom_radius = p[2]
		cone.height = p[3]
		cone.radial_segments = 6
		cone.rings = 1
		cone.material = snow_peak_mat if p[4] else peak_mat

		var mi := MeshInstance3D.new()
		mi.mesh = cone
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(p[0], -3.3 + p[3] * 0.5, p[1])
		mi.rotation.y = _rng.randf_range(0.0, TAU)
		_horizon_root.add_child(mi)

	CurvedWorld.apply_to_tree(_horizon_root)
