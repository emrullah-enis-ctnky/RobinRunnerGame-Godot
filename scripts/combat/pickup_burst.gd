class_name PickupBurst
extends RefCounted
## One-shot sparkle burst that sells a ground pickup vanishing into the quiver.

const LIFETIME: float = 0.45
const FREE_DELAY: float = 0.65
const NORMAL_COLOR: Color = Color(1.0, 0.86, 0.45)
const FLAME_COLOR: Color = Color(1.0, 0.52, 0.12)

const SPARK_SIZE: Vector2 = Vector2(0.16, 0.16)


## Spawns the burst at a world position and frees it once the sparks burn out.
static func spawn(parent: Node, world_position: Vector3, color: Color) -> GPUParticles3D:
	if parent == null or not parent.is_inside_tree():
		return null

	var fx := GPUParticles3D.new()
	fx.name = "PickupBurst"
	fx.add_to_group("pickup_burst")
	fx.one_shot = true
	fx.amount = 28
	fx.lifetime = LIFETIME
	fx.explosiveness = 1.0
	fx.local_coords = false
	fx.visibility_aabb = AABB(Vector3(-2.0, -1.0, -2.0), Vector3(4.0, 3.0, 4.0))
	fx.process_material = _spark_process()
	fx.draw_pass_1 = _spark_quad(color)

	parent.add_child(fx)
	fx.global_position = world_position
	fx.emitting = true

	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = FREE_DELAY
	timer.timeout.connect(fx.queue_free)
	fx.add_child(timer)
	timer.start()
	return fx


## Configures an upward, quickly fading spray of sparks.
static func _spark_process() -> ParticleProcessMaterial:
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 75.0
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.06
	process.initial_velocity_min = 1.4
	process.initial_velocity_max = 2.6
	process.gravity = Vector3(0.0, -3.5, 0.0)
	process.damping_min = 0.4
	process.damping_max = 1.1
	process.scale_min = 0.35
	process.scale_max = 0.7
	process.angle_min = -180.0
	process.angle_max = 180.0
	process.angular_velocity_min = -240.0
	process.angular_velocity_max = 240.0
	process.scale_curve = _scale_curve()
	process.color_ramp = _color_ramp()
	return process


## Shrinks each spark away so the burst reads as a quick flash.
static func _scale_curve() -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.35, 0.9))
	curve.add_point(Vector2(1.0, 0.0))

	var texture := CurveTexture.new()
	texture.curve = curve
	return texture


## Holds the pickup color briefly, then fades it to transparent.
static func _color_ramp() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 0.92, 1.0),
		Color(1.0, 0.92, 0.6, 0.85),
		Color(1.0, 0.8, 0.35, 0.0)
	])

	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture


## Builds one additive, camera-facing spark quad in the pickup color.
static func _spark_quad(color: Color) -> QuadMesh:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	material.albedo_texture = _spark_texture()
	material.vertex_color_use_as_albedo = true

	var quad := QuadMesh.new()
	quad.size = SPARK_SIZE
	quad.material = material
	return quad


## Generates the soft round spark silhouette without external textures.
static func _spark_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 0.9, 0.6, 0.6),
		Color(1.0, 0.7, 0.2, 0.0)
	])

	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 32
	texture.height = 32
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture
