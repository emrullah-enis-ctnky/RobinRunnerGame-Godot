class_name VFXSpawner
extends RefCounted
## Spawns lightweight, curved-world-compatible one-shot and continuous stylized particle VFX.

const CURVED_ALPHA_SHADER: Shader = preload("res://shaders/curved_particle.gdshader")
const CURVED_ADD_SHADER: Shader = preload("res://shaders/curved_flame_particle.gdshader")

static var _soft_puff_tex: ImageTexture
static var _splinter_tex: ImageTexture


## Builds a continuous foot-dust emitter attached to the player character.
static func build_run_dust(parent: Node3D) -> GPUParticles3D:
	var fx := GPUParticles3D.new()
	fx.name = "RunDust"
	fx.amount = 18
	fx.lifetime = 0.42
	fx.local_coords = false
	fx.position = Vector3(0.0, 0.08, 0.18)
	fx.visibility_aabb = AABB(Vector3(-4.0, -2.0, -4.0), Vector3(8.0, 4.0, 8.0))
	fx.emitting = false

	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc.emission_box_extents = Vector3(0.22, 0.04, 0.12)
	proc.direction = Vector3(0.0, 0.65, 1.0)
	proc.spread = 32.0
	proc.initial_velocity_min = 0.8
	proc.initial_velocity_max = 1.9
	proc.gravity = Vector3(0.0, -1.2, 0.0)
	proc.damping_min = 1.5
	proc.damping_max = 2.5
	proc.scale_min = 0.6
	proc.scale_max = 1.25
	proc.scale_curve = _grow_fade_curve()
	proc.color_ramp = _gradient_ramp([
		[0.0, Color(0.68, 0.56, 0.40, 0.65)],
		[0.5, Color(0.58, 0.48, 0.35, 0.40)],
		[1.0, Color(0.50, 0.42, 0.32, 0.0)],
	])
	fx.process_material = proc
	fx.draw_pass_1 = _make_quad(Vector2(0.28, 0.28), _get_soft_puff_tex(), false)

	parent.add_child(fx)
	return fx


## Spawns a radial dust puff ring where the runner lands after a jump.
static func spawn_landing_dust(parent: Node, world_pos: Vector3) -> GPUParticles3D:
	if parent == null or not parent.is_inside_tree():
		return null

	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	proc.emission_ring_radius = 0.25
	proc.emission_ring_inner_radius = 0.05
	proc.emission_ring_height = 0.05
	proc.emission_ring_axis = Vector3.UP
	proc.direction = Vector3(0.0, 0.4, 0.0)
	proc.spread = 85.0
	proc.initial_velocity_min = 1.4
	proc.initial_velocity_max = 2.8
	proc.gravity = Vector3(0.0, -2.5, 0.0)
	proc.damping_min = 2.0
	proc.damping_max = 3.5
	proc.scale_min = 0.7
	proc.scale_max = 1.35
	proc.scale_curve = _grow_fade_curve()
	proc.color_ramp = _gradient_ramp([
		[0.0, Color(0.72, 0.60, 0.44, 0.72)],
		[0.6, Color(0.58, 0.48, 0.36, 0.35)],
		[1.0, Color(0.48, 0.40, 0.30, 0.0)],
	])
	return _spawn_one_shot(parent, world_pos + Vector3(0.0, 0.08, 0.0), 16, 0.45, 0.7, proc, _make_quad(Vector2(0.32, 0.32), _get_soft_puff_tex(), false))


## Spawns a dramatic fire, glowing ember, and dark ash/smoke burst when a flame arrow burns a tree.
static func spawn_tree_burn(parent: Node, world_pos: Vector3) -> Node3D:
	if parent == null or not parent.is_inside_tree():
		return null

	var root := Node3D.new()
	root.name = "TreeBurnVFX"
	root.add_to_group("vfx_burst")
	parent.add_child(root)
	root.global_position = world_pos

	# 1. Rising flame & ember eruption (additive)
	var fire_proc := ParticleProcessMaterial.new()
	fire_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	fire_proc.emission_box_extents = Vector3(0.55, 1.1, 0.55)
	fire_proc.direction = Vector3.UP
	fire_proc.spread = 38.0
	fire_proc.initial_velocity_min = 2.2
	fire_proc.initial_velocity_max = 5.4
	fire_proc.gravity = Vector3(0.0, 1.8, 0.0)
	fire_proc.damping_min = 0.8
	fire_proc.damping_max = 1.6
	fire_proc.scale_min = 0.7
	fire_proc.scale_max = 1.5
	fire_proc.scale_curve = _shrink_curve()
	fire_proc.color_ramp = _gradient_ramp([
		[0.0, Color(1.0, 0.96, 0.65, 1.0)],
		[0.35, Color(1.0, 0.55, 0.12, 0.95)],
		[0.75, Color(0.85, 0.18, 0.02, 0.65)],
		[1.0, Color(0.3, 0.05, 0.0, 0.0)],
	])
	var fire_fx := _make_burst_node(36, 0.75, fire_proc, _make_quad(Vector2(0.55, 0.65), _get_soft_puff_tex(), true))
	fire_fx.position = Vector3(0.0, 1.15, 0.0)
	root.add_child(fire_fx)
	fire_fx.emitting = true

	# 2. Billowing charcoal ash & smoke cloud (alpha)
	var ash_proc := ParticleProcessMaterial.new()
	ash_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	ash_proc.emission_box_extents = Vector3(0.65, 1.2, 0.65)
	ash_proc.direction = Vector3.UP
	ash_proc.spread = 50.0
	ash_proc.initial_velocity_min = 1.2
	ash_proc.initial_velocity_max = 3.2
	ash_proc.gravity = Vector3(0.0, 0.6, 0.0)
	ash_proc.damping_min = 1.0
	ash_proc.damping_max = 2.0
	ash_proc.scale_min = 0.9
	ash_proc.scale_max = 1.9
	ash_proc.scale_curve = _grow_fade_curve()
	ash_proc.color_ramp = _gradient_ramp([
		[0.0, Color(0.24, 0.20, 0.18, 0.85)],
		[0.55, Color(0.16, 0.14, 0.14, 0.55)],
		[1.0, Color(0.10, 0.10, 0.10, 0.0)],
	])
	var ash_fx := _make_burst_node(28, 1.05, ash_proc, _make_quad(Vector2(0.65, 0.65), _get_soft_puff_tex(), false))
	ash_fx.position = Vector3(0.0, 1.35, 0.0)
	root.add_child(ash_fx)
	ash_fx.emitting = true

	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 1.4
	timer.timeout.connect(root.queue_free)
	root.add_child(timer)
	timer.start()
	return root


## Spawns a crisp spray of wooden splinters when an arrow strikes a target or barrier.
static func spawn_wood_splinters(parent: Node, world_pos: Vector3) -> GPUParticles3D:
	if parent == null or not parent.is_inside_tree():
		return null

	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc.emission_sphere_radius = 0.12
	proc.direction = Vector3(0.0, 0.5, 1.0)
	proc.spread = 65.0
	proc.initial_velocity_min = 2.4
	proc.initial_velocity_max = 5.5
	proc.gravity = Vector3(0.0, -14.0, 0.0)
	proc.scale_min = 0.55
	proc.scale_max = 1.15
	proc.scale_curve = _shrink_curve()
	proc.color_ramp = _gradient_ramp([
		[0.0, Color(0.86, 0.64, 0.36, 1.0)],
		[0.65, Color(0.62, 0.42, 0.22, 0.90)],
		[1.0, Color(0.45, 0.30, 0.16, 0.0)],
	])
	return _spawn_one_shot(parent, world_pos, 18, 0.55, 0.85, proc, _make_quad(Vector2(0.18, 0.09), _get_splinter_tex(), false))


static func _spawn_one_shot(
	parent: Node,
	world_pos: Vector3,
	amount: int,
	lifetime: float,
	free_delay: float,
	proc: ParticleProcessMaterial,
	quad: QuadMesh
) -> GPUParticles3D:
	var fx := _make_burst_node(amount, lifetime, proc, quad)
	fx.add_to_group("vfx_burst")
	parent.add_child(fx)
	fx.global_position = world_pos
	fx.emitting = true

	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = free_delay
	timer.timeout.connect(fx.queue_free)
	fx.add_child(timer)
	timer.start()
	return fx


static func _make_burst_node(amount: int, lifetime: float, proc: ParticleProcessMaterial, quad: QuadMesh) -> GPUParticles3D:
	var fx := GPUParticles3D.new()
	fx.one_shot = true
	fx.amount = amount
	fx.lifetime = lifetime
	fx.explosiveness = 0.92
	fx.local_coords = false
	fx.visibility_aabb = AABB(Vector3(-16.0, -8.0, -16.0), Vector3(32.0, 18.0, 32.0))
	fx.process_material = proc
	fx.draw_pass_1 = quad
	return fx


static func _make_quad(size: Vector2, tex: Texture2D, additive: bool) -> QuadMesh:
	var mat := ShaderMaterial.new()
	mat.shader = CURVED_ADD_SHADER if additive else CURVED_ALPHA_SHADER
	mat.set_shader_parameter("albedo_texture", tex)
	var quad := QuadMesh.new()
	quad.size = size
	quad.material = mat
	return quad


static func _grow_fade_curve() -> CurveTexture:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.45))
	c.add_point(Vector2(0.4, 1.0))
	c.add_point(Vector2(1.0, 1.35))
	var ct := CurveTexture.new()
	ct.curve = c
	return ct


static func _shrink_curve() -> CurveTexture:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.8))
	c.add_point(Vector2(0.25, 1.0))
	c.add_point(Vector2(1.0, 0.05))
	var ct := CurveTexture.new()
	ct.curve = c
	return ct


static func _gradient_ramp(stops: Array) -> GradientTexture1D:
	var g := Gradient.new()
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for s in stops:
		offsets.append(float(s[0]))
		colors.append(s[1] as Color)
	g.offsets = offsets
	g.colors = colors
	var gt := GradientTexture1D.new()
	gt.gradient = g
	return gt


static func _get_soft_puff_tex() -> ImageTexture:
	if _soft_puff_tex != null:
		return _soft_puff_tex
	var sz: int = 32
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var center := Vector2(sz - 1, sz - 1) * 0.5
	var max_r: float = sz * 0.5
	for y in range(sz):
		for x in range(sz):
			var d: float = clampf(Vector2(x, y).distance_to(center) / max_r, 0.0, 1.0)
			var a: float = pow(1.0 - d, 1.7)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_soft_puff_tex = ImageTexture.create_from_image(img)
	return _soft_puff_tex


static func _get_splinter_tex() -> ImageTexture:
	if _splinter_tex != null:
		return _splinter_tex
	var w: int = 24
	var h: int = 12
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var nx: float = absf((float(x) / float(w - 1)) * 2.0 - 1.0)
			var ny: float = absf((float(y) / float(h - 1)) * 2.0 - 1.0)
			var a: float = 1.0 if (nx + ny * 0.85) < 1.05 else 0.0
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_splinter_tex = ImageTexture.create_from_image(img)
	return _splinter_tex
