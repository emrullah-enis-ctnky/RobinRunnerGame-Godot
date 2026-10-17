class_name ArrowPickup
extends Area3D
## Collectible arrow resting on the track; grants quiver ammo on player contact.

const GameConfig = preload("res://scripts/common/game_config.gd")

# The mesh's native axis is rotated so the arrow lies flat on the ground.
const MESH_LOCAL_ROTATION: Vector3 = Vector3(90.0, 0.0, 0.0)

@export var arrow_type: String = GameConfig.ARROW_TYPE_NORMAL
@export var amount: int = 1

var _base_y: float = 0.0
var _time: float = 0.0
var _flame_head: MeshInstance3D
var _flame_fx: GPUParticles3D


## Wires collision, lays the mesh flat, and restores on a new run.
func _ready() -> void:
	_base_y = position.y
	_orient_mesh()
	if arrow_type == GameConfig.ARROW_TYPE_FLAME:
		_build_flame_visuals()
	body_entered.connect(_on_body_entered)
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").game_restarted.connect(restore)


## Rotates the instanced arrow mesh so it lies flat on the ground.
func _orient_mesh() -> void:
	var mesh: Node3D = get_node_or_null("Mesh")
	if mesh:
		mesh.rotation_degrees = MESH_LOCAL_ROTATION


## Adds the flame glow for flame-arrow pickups.
func _build_flame_visuals() -> void:
	var visuals: Dictionary = FlameVisual.build(self)
	_flame_head = visuals["head"]
	_flame_fx = visuals["fx"]
	_flame_head.visible = true
	_flame_fx.emitting = true


## Bobs and spins the arrow gently to draw the eye.
func _process(delta: float) -> void:
	_time += delta * GameConfig.PICKUP_BOB_SPEED
	rotation.y += GameConfig.PICKUP_SPIN_SPEED * delta
	position.y = _base_y + sin(_time) * GameConfig.PICKUP_BOB_HEIGHT


## Hands the ammo to the quiver and hides the picked-up arrow.
func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").collectible_picked.emit("arrow_" + arrow_type, amount)
	_collect()


## Hides the pickup and stops its idle motion after collection.
func _collect() -> void:
	hide()
	set_process(false)
	set_deferred("monitoring", false)


## Re-enables the pickup so recycled chunks can present it again.
func restore() -> void:
	_time = 0.0
	position.y = _base_y
	show()
	set_process(true)
	set_deferred("monitoring", true)
