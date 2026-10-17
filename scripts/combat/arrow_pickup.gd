class_name ArrowPickup
extends Area3D
## Collectible arrow resting on the track; grants quiver ammo on player contact.

const GameConfig = preload("res://scripts/common/game_config.gd")

# The mesh's native axis is rotated so the arrow lies flat on the ground.
const MESH_LOCAL_ROTATION: Vector3 = Vector3(90.0, 0.0, 0.0)
# Never scale to exactly zero: a singular basis is rejected by Jolt Physics.
const COLLECT_MIN_SCALE: float = 0.01

@export var arrow_type: String = GameConfig.ARROW_TYPE_NORMAL
@export var amount: int = 1

var _base_position: Vector3 = Vector3.ZERO
var _base_rotation: Vector3 = Vector3.ZERO
var _time: float = 0.0
var _collect_tween: Tween
var _flame_head: MeshInstance3D
var _flame_fx: GPUParticles3D


## Wires collision, sizes and lays the arrow flat, and restores on a new run.
func _ready() -> void:
	_base_position = position
	_base_rotation = rotation
	_prepare_mesh()
	if arrow_type == GameConfig.ARROW_TYPE_FLAME:
		_build_flame_visuals()
	body_entered.connect(_on_body_entered)
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").game_restarted.connect(restore)


## Normalizes the arrow mesh size and lays it flat on the ground.
func _prepare_mesh() -> void:
	var mesh: Node3D = get_node_or_null("Mesh")
	if mesh:
		MeshFit.fit_longest_axis(mesh, GameConfig.ARROW_MODEL_LENGTH)
		mesh.rotation_degrees = MESH_LOCAL_ROTATION


## Adds the flame glow for flame-arrow pickups.
func _build_flame_visuals() -> void:
	var tip: Vector3 = Vector3(0.0, 0.0, -GameConfig.ARROW_MODEL_LENGTH * 0.5)
	var visuals: Dictionary = FlameVisual.build(self, tip)
	_flame_head = visuals["head"]
	_flame_fx = visuals["fx"]
	_flame_head.visible = true
	_flame_fx.emitting = true


## Bobs and spins the arrow gently to draw the eye.
func _process(delta: float) -> void:
	_time += delta * GameConfig.PICKUP_BOB_SPEED
	rotation.y += GameConfig.PICKUP_SPIN_SPEED * delta
	position = _base_position + Vector3(0.0, sin(_time) * GameConfig.PICKUP_BOB_HEIGHT, 0.0)


## Hands the ammo to the quiver and flies the arrow up into it.
func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").collectible_picked.emit("arrow_" + arrow_type, amount)
	_collect(body)


## Lifts the arrow toward the player's quiver while shrinking it away.
func _collect(player: Node3D) -> void:
	set_deferred("monitoring", false)
	set_process(false)
	_collect_tween = create_tween()
	_collect_tween.set_parallel(true)
	_collect_tween.tween_property(self, "global_position", player.global_position + Vector3(0.0, 1.2, 0.3), GameConfig.PICKUP_COLLECT_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_collect_tween.tween_property(self, "scale", Vector3.ONE * COLLECT_MIN_SCALE, GameConfig.PICKUP_COLLECT_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_collect_tween.chain().tween_callback(hide)


## Re-enables and repositions the pickup so recycled chunks can present it again.
func restore() -> void:
	if _collect_tween and _collect_tween.is_valid():
		_collect_tween.kill()
	scale = Vector3.ONE
	_time = 0.0
	position = _base_position
	rotation = _base_rotation
	show()
	set_process(true)
	set_deferred("monitoring", true)