class_name FlameVisual
extends RefCounted
## Builds the shared emissive head and fire emitter used by flame arrows and pickups.

const DEFAULT_OFFSET: Vector3 = Vector3(0.0, 0.0, -0.6)


## Adds a glowing head and a hidden fire emitter to a parent node.
## Returns a dictionary with the "head" (MeshInstance3D) and "fx" (GPUParticles3D).
static func build(parent: Node3D, offset: Vector3 = DEFAULT_OFFSET) -> Dictionary:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.5, 0.1)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.45, 0.05)
	material.emission_energy_multiplier = 2.5

	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.07
	head_mesh.height = 0.14
	head_mesh.material = material

	var head := MeshInstance3D.new()
	head.mesh = head_mesh
	head.position = offset
	head.visible = false
	parent.add_child(head)

	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 30.0
	process.initial_velocity_min = 0.2
	process.initial_velocity_max = 0.6
	process.gravity = Vector3(0.0, 0.5, 0.0)
	process.scale_min = 0.1
	process.scale_max = 0.3
	process.color = Color(1.0, 0.5, 0.1)

	var fx := GPUParticles3D.new()
	fx.amount = 12
	fx.lifetime = 0.5
	fx.position = offset
	fx.draw_pass_1 = head_mesh
	fx.process_material = process
	fx.emitting = false
	parent.add_child(fx)

	return {"head": head, "fx": fx}
