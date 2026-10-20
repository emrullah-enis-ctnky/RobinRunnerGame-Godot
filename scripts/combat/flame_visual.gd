class_name FlameVisual
extends RefCounted
## Builds the shared emissive head and particle fire used by flame arrows and pickups.

const DEFAULT_OFFSET: Vector3 = Vector3(0.0, 0.0, -0.6)

const OUTER_SIZE: Vector2 = Vector2(0.2, 0.34)


## Adds a glowing head and a hidden fire emitter to a parent node.
## Returns a dictionary with the "head" (MeshInstance3D) and "fx" (GPUParticles3D).
static func build(parent: Node3D, offset: Vector3 = DEFAULT_OFFSET, local_coords: bool = true) -> Dictionary:
	var head := _build_head(offset)
	parent.add_child(head)

	var fx := GPUParticles3D.new()
	fx.amount = 28
	fx.lifetime = 0.32
	fx.local_coords = local_coords
	fx.position = offset
	fx.process_material = _fire_process()
	fx.draw_pass_1 = _flame_quad(OUTER_SIZE, _flame_texture())
	fx.visibility_aabb = AABB(Vector3(-1.0, -1.0, -2.0), Vector3(2.0, 2.0, 4.0))
	fx.emitting = false
	parent.add_child(fx)

	return {"head": head, "fx": fx}


## Creates the small emissive ember that anchors the fire at the arrow point.
static func _build_head(offset: Vector3) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.55, 0.15)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.5, 0.08)
	material.emission_energy_multiplier = 3.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var sphere := SphereMesh.new()
	sphere.radius = 0.035
	sphere.height = 0.07
	sphere.radial_segments = 8
	sphere.rings = 4
	sphere.material = material

	var head := MeshInstance3D.new()
	head.mesh = sphere
	head.position = offset
	head.visible = false
	return head


## Configures the rising, shrinking, fading fire particle motion.
static func _fire_process() -> ParticleProcessMaterial:
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 12.0
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.025
	process.initial_velocity_min = 0.35
	process.initial_velocity_max = 0.9
	process.gravity = Vector3(0.0, 1.2, 0.0)
	process.damping_min = 0.05
	process.damping_max = 0.25
	process.scale_min = 0.4
	process.scale_max = 0.85
	process.angle_min = -180.0
	process.angle_max = 180.0
	process.angular_velocity_min = -180.0
	process.angular_velocity_max = 180.0
	process.scale_curve = _scale_curve()
	process.color_ramp = _color_ramp()
	return process


## Grows the flame quickly, then shrinks it away as it burns out.
static func _scale_curve() -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.6))
	curve.add_point(Vector2(0.25, 1.0))
	curve.add_point(Vector2(1.0, 0.0))

	var texture := CurveTexture.new()
	texture.curve = curve
	return texture


## Fades each particle from a hot core through orange into transparent red.
static func _color_ramp() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 0.9, 1.0),
		Color(1.0, 0.65, 0.2, 0.85),
		Color(1.0, 0.1, 0.0, 0.0)
	])

	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture


## Builds one additive, camera-facing flame quad of the requested size.
static func _flame_quad(size: Vector2, texture: Texture2D) -> QuadMesh:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = texture
	material.vertex_color_use_as_albedo = true

	var quad := QuadMesh.new()
	quad.size = size
	quad.material = material
	return quad


## Generates the soft radial flame silhouette without external textures.
static func _flame_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 0.98, 0.85, 1.0),
		Color(1.0, 0.75, 0.25, 0.9),
		Color(0.95, 0.3, 0.03, 0.35),
		Color(0.5, 0.05, 0.0, 0.0)
	])

	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 96
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.6)
	texture.fill_to = Vector2(1.0, 0.6)
	return texture
