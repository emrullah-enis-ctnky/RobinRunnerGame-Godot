class_name CurvedWorldController
extends Node
## Drives global shader parameters for a subtle Subway-Surfers-style curved horizon trail.
## Also converts StandardMaterial3D surfaces on world/chunk meshes to use the curved shader.

const CURVED_SHADER: Shader = preload("res://shaders/curved_world.gdshader")

@export var player_path: NodePath = NodePath("../Player")
@export var max_horizontal_curve: float = 0.00095
@export var vertical_curve: float = 0.00038
@export var meander_frequency: float = 0.0065

# Shared cache mapping original StandardMaterial3D -> curved ShaderMaterial
static var _material_cache: Dictionary = {}

var _player: Node3D
var _phase_offset: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Initializes curve phase and resets globals cleanly on run restart.
func _ready() -> void:
	_rng.randomize()
	_player = get_node_or_null(player_path) as Node3D
	_randomize_phase()
	_push_globals()

	if has_node("/root/EventBus"):
		get_node("/root/EventBus").game_restarted.connect(_randomize_phase)


## Smoothly updates the trail curvature origin and meandering horizontal bend each frame.
func _process(_delta: float) -> void:
	_push_globals()


## Clears the global curvature when leaving the scene tree (keeps unit tests clean).
func _exit_tree() -> void:
	RenderingServer.global_shader_parameter_set("curve_origin", Vector3.ZERO)
	RenderingServer.global_shader_parameter_set("curve_strength", Vector2.ZERO)


func _randomize_phase() -> void:
	_phase_offset = _rng.randf_range(0.0, TAU)


func _push_globals() -> void:
	var pz: float = _player.global_position.z if is_instance_valid(_player) else 0.0
	var travel: float = maxf(0.0, -pz)
	# Layered slow sines meander smoothly left -> straight -> right along the forest trail
	var wave: float = 0.65 * sin(travel * meander_frequency + _phase_offset) \
		+ 0.35 * sin(travel * meander_frequency * 0.43 + _phase_offset * 1.7)
	var strength := Vector2(wave * max_horizontal_curve, vertical_curve)
	RenderingServer.global_shader_parameter_set("curve_origin", Vector3(0.0, 0.0, pz))
	RenderingServer.global_shader_parameter_set("curve_strength", strength)


## Recursively converts StandardMaterial3D surfaces under root to curved_world.gdshader
## and widens extra_cull_margin so bent meshes never frustum-pop early.
static func apply_to_tree(root: Node) -> void:
	if root == null:
		return
	if root is MeshInstance3D:
		_apply_to_mesh_instance(root as MeshInstance3D)
	for child in root.get_children():
		apply_to_tree(child)


static func _apply_to_mesh_instance(mi: MeshInstance3D) -> void:
	if mi.mesh == null:
		return
	mi.extra_cull_margin = maxf(mi.extra_cull_margin, 80.0)
	var surf_count: int = mi.mesh.get_surface_count()
	for s in range(surf_count):
		var mat: Material = mi.get_active_material(s)
		if mat == null:
			continue
		if mat is ShaderMaterial:
			continue
		if mat is StandardMaterial3D:
			mi.set_surface_override_material(s, _convert_standard_material(mat as StandardMaterial3D))


static func _convert_standard_material(std: StandardMaterial3D) -> ShaderMaterial:
	var key: int = std.get_instance_id()
	if _material_cache.has(key):
		var cached = _material_cache[key]
		if is_instance_valid(cached):
			return cached as ShaderMaterial

	var sm := ShaderMaterial.new()
	sm.shader = CURVED_SHADER
	sm.set_shader_parameter("albedo_color", std.albedo_color)
	if std.albedo_texture != null:
		sm.set_shader_parameter("use_albedo_texture", true)
		sm.set_shader_parameter("albedo_texture", std.albedo_texture)
	else:
		sm.set_shader_parameter("use_albedo_texture", false)
	sm.set_shader_parameter("roughness", std.roughness)
	sm.set_shader_parameter("metallic", std.metallic)
	if std.emission_enabled:
		sm.set_shader_parameter("emission_color", std.emission)
		sm.set_shader_parameter("emission_energy", std.emission_energy_multiplier)
	else:
		sm.set_shader_parameter("emission_color", Color.BLACK)
		sm.set_shader_parameter("emission_energy", 0.0)

	_material_cache[key] = sm
	return sm
