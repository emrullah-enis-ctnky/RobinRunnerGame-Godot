class_name Arrow
extends Node3D
## Straight-line projectile fired by the player and recycled through ArrowPool.

const GameConfig = preload("res://scripts/common/game_config.gd")

# The model's pointed head sits on +Z, so a half-turn aligns it with the flight path.
const MESH_LOCAL_ROTATION: Vector3 = Vector3(0.0, 180.0, 0.0)

signal finished(arrow)

@export var speed: float = GameConfig.ARROW_SPEED
@export var lifetime: float = GameConfig.ARROW_LIFETIME

var arrow_type: String = GameConfig.ARROW_TYPE_NORMAL

var _direction: Vector3 = Vector3.FORWARD
var _timer: float = 0.0
var _flame_head: MeshInstance3D
var _flame_fx: GPUParticles3D


## Builds the flame visuals once so every pooled arrow reuses them.
func _ready() -> void:
	_prepare_mesh()
	_build_flame_visuals()
	deactivate()


## Normalizes the arrow mesh and turns its pointed +Z head into the travel direction.
func _prepare_mesh() -> void:
	var mesh: Node3D = get_node_or_null("Mesh") as Node3D
	if mesh:
		MeshFit.fit_longest_axis(mesh, GameConfig.ARROW_MODEL_LENGTH, GameConfig.ARROW_CROSS_SECTION_SCALE)
		mesh.rotation_degrees = MESH_LOCAL_ROTATION


## Creates the glowing head and the particle emitter shown only for flame arrows.
func _build_flame_visuals() -> void:
	var mesh: Node3D = get_node_or_null("Mesh") as Node3D
	var tip: Vector3 = MeshFit.local_long_axis_end(mesh, true) if mesh else Vector3.ZERO
	var visuals: Dictionary = FlameVisual.build(self, tip, true)
	_flame_head = visuals["head"]
	_flame_fx = visuals["fx"]


## Sends the arrow flying from an origin along a direction for the given type.
func activate(origin: Vector3, direction: Vector3, type: String) -> void:
	arrow_type = type
	_direction = direction.normalized()
	_timer = lifetime
	global_position = origin
	look_at(global_position + _direction, Vector3.UP)

	var is_flame: bool = arrow_type == GameConfig.ARROW_TYPE_FLAME
	_flame_head.visible = is_flame
	_flame_fx.emitting = is_flame
	show()
	set_physics_process(true)


## Parks the arrow for pooling until the next shot.
func deactivate() -> void:
	hide()
	set_physics_process(false)
	if _flame_fx:
		_flame_fx.emitting = false


## Advances the arrow and resolves any impact along the travelled segment.
func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_finish()
		return

	var step: Vector3 = _direction * speed * delta
	var hit: Dictionary = _raycast(global_position, global_position + step)
	if hit.is_empty():
		global_position += step
	else:
		_resolve_hit(hit.get("collider"))
		_finish()


## Queries the physics world for the first shootable surface along a segment.
func _raycast(from: Vector3, to: Vector3) -> Dictionary:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = GameConfig.LAYER_OBSTACLE | GameConfig.LAYER_TARGET
	query.collide_with_areas = false
	return space.intersect_ray(query)


## Applies the arrow type to the hit body when it can be destroyed.
func _resolve_hit(body: Object) -> void:
	if body != null and body.has_method("receive_arrow"):
		body.receive_arrow(arrow_type)


## Ends the flight and notifies the pool for recycling.
func _finish() -> void:
	deactivate()
	finished.emit(self)
