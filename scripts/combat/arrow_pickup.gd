class_name ArrowPickup
extends Area3D
## Collectible arrow planted in the track; grants quiver ammo on player contact.

const GameConfig = preload("res://scripts/common/game_config.gd")
const PickupBurst = preload("res://scripts/combat/pickup_burst.gd")

# Never scale to exactly zero: a singular basis is rejected by Jolt Physics.
const COLLECT_MIN_SCALE: float = 0.01

@export var arrow_type: String = GameConfig.ARROW_TYPE_NORMAL
@export var amount: int = 1

var _base_position: Vector3 = Vector3.ZERO
var _collect_tween: Tween
var _flame_head: MeshInstance3D
var _flame_fx: GPUParticles3D


## Wires collision, plants the arrow in the ground, and restores on a new run.
func _ready() -> void:
	_base_position = position
	_prepare_mesh()
	if arrow_type == GameConfig.ARROW_TYPE_FLAME:
		_build_flame_visuals()
	body_entered.connect(_on_body_entered)
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").game_restarted.connect(restore)


## Normalizes the arrow, moves the pivot to its pointed tip, and plants it.
func _prepare_mesh() -> void:
	var mesh: Node3D = get_node_or_null("Mesh") as Node3D
	if mesh == null:
		return

	MeshFit.fit_longest_axis(mesh, GameConfig.ARROW_MODEL_LENGTH, GameConfig.ARROW_CROSS_SECTION_SCALE)

	# Shift the geometry so the pointed +Z end sits on the pivot; rotation then
	# happens around the tip instead of the mesh centre.
	var tip: Vector3 = MeshFit.local_long_axis_point(mesh, true)
	for child in mesh.get_children():
		if child is Node3D:
			(child as Node3D).position -= tip
	# Randomise the lean around X (X stays below 90 so the arrow always stands
	# above ground) and add a small yaw jitter for variety.
	var tilt: float = GameConfig.PICKUP_TILT_DEGREES + randf_range(-GameConfig.PICKUP_TILT_RANGE_DEGREES, GameConfig.PICKUP_TILT_RANGE_DEGREES)
	var yaw: float = randf_range(-GameConfig.PICKUP_YAW_RANGE_DEGREES, GameConfig.PICKUP_YAW_RANGE_DEGREES)
	mesh.rotation_degrees = Vector3(tilt, yaw, 0.0)
	mesh.position = Vector3(0.0, -GameConfig.PICKUP_BURY_DEPTH, 0.0)


## Adds a fire at the buried tip, rising from the ground around the entry point.
func _build_flame_visuals() -> void:
	var mesh: Node3D = get_node_or_null("Mesh") as Node3D
	var tip: Vector3 = MeshFit.local_long_axis_end(mesh, true) if mesh else Vector3.ZERO
	var surface: Vector3 = tip + Vector3(0.0, GameConfig.PICKUP_BURY_DEPTH, 0.0)
	var visuals: Dictionary = FlameVisual.build(self, surface, true)
	_flame_head = visuals["head"]
	_flame_fx = visuals["fx"]
	_flame_head.visible = true
	_flame_fx.emitting = true


## Hands the ammo to the quiver and flies the arrow up into it.
func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").collectible_picked.emit("arrow_" + arrow_type, amount)
	_collect(body)


## Kicks up a spark burst, then lifts the arrow toward the quiver while shrinking it away.
func _collect(player: Node3D) -> void:
	set_deferred("monitoring", false)
	_stop_flame()
	PickupBurst.spawn(get_parent(), global_position, _burst_color())
	_collect_tween = create_tween()
	_collect_tween.set_parallel(true)
	_collect_tween.tween_property(self, "global_position", player.global_position + Vector3(0.0, 1.2, 0.3), GameConfig.PICKUP_COLLECT_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_collect_tween.tween_property(self, "scale", Vector3.ONE * COLLECT_MIN_SCALE, GameConfig.PICKUP_COLLECT_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_collect_tween.chain().tween_callback(hide)


## Extinguishes the pickup fire the moment the arrow is taken.
func _stop_flame() -> void:
	if _flame_head:
		_flame_head.visible = false
	if _flame_fx:
		_flame_fx.emitting = false


## Returns the spark color that matches the collected arrow type.
func _burst_color() -> Color:
	if arrow_type == GameConfig.ARROW_TYPE_FLAME:
		return PickupBurst.FLAME_COLOR
	return PickupBurst.NORMAL_COLOR


## Re-enables and repositions the pickup so recycled chunks can present it again.
func restore() -> void:
	if _collect_tween and _collect_tween.is_valid():
		_collect_tween.kill()
	scale = Vector3.ONE
	position = _base_position
	show()
	set_deferred("monitoring", true)
	if arrow_type == GameConfig.ARROW_TYPE_FLAME:
		if _flame_head:
			_flame_head.visible = true
		if _flame_fx:
			_flame_fx.emitting = true


## Rolls the spawn chance when a chunk re-activates, keeping pickups sparse.
func respawn() -> void:
	restore()
	var appears: bool = randf() < GameConfig.PICKUP_SPAWN_CHANCE
	visible = appears
	set_deferred("monitoring", appears)
