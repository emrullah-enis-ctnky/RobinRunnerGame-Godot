class_name WindFoliage
extends Node3D
## Swaps the materials of every mesh beneath this node for the wind-sway shader.

const WIND_SHADER: Shader = preload("res://shaders/foliage_wind.gdshader")

## Peak horizontal travel as a fraction of the plant's world height.
@export_range(0.0, 0.5, 0.01) var sway_ratio: float = 0.18


## Applies the wind shader to the meshes nested under this node.
func _ready() -> void:
	_apply_wind(self)


## Walks the subtree and converts every mesh instance to the wind material.
func _apply_wind(node: Node) -> void:
	if node is MeshInstance3D:
		_windify(node)
	for child in node.get_children():
		_apply_wind(child)


## Builds a wind shader material that keeps the mesh's original albedo look.
func _windify(mesh_instance: MeshInstance3D) -> void:
	var material := ShaderMaterial.new()
	material.shader = WIND_SHADER

	var bounds: AABB = mesh_instance.get_aabb()
	var local_height: float = maxf(bounds.size.y, 0.001)
	var world_height: float = local_height * mesh_instance.global_transform.basis.get_scale().y
	material.set_shader_parameter("sway_height", local_height)
	material.set_shader_parameter("sway_amplitude", world_height * sway_ratio)

	var source := _source_material(mesh_instance)
	if source != null:
		material.set_shader_parameter("albedo_texture", source.albedo_texture)
		material.set_shader_parameter("albedo_color", source.albedo_color)

	mesh_instance.material_override = material


## Finds the first standard material assigned to the mesh's surfaces.
func _source_material(mesh_instance: MeshInstance3D) -> StandardMaterial3D:
	var mesh := mesh_instance.mesh
	if mesh == null:
		return null
	for surface in mesh.get_surface_count():
		var material: Material = mesh_instance.get_surface_override_material(surface)
		if material == null:
			material = mesh.surface_get_material(surface)
		if material is StandardMaterial3D:
			return material
	return null