class_name CoinPickup
extends Area3D
## Collectible spinning star coin that grants score and spawns a gold burst on pickup.

const GameConfig = preload("res://scripts/common/game_config.gd")
const PickupBurst = preload("res://scripts/combat/pickup_burst.gd")

const GOLD_BURST_COLOR: Color = Color(1.0, 0.85, 0.2)
# Never scale to exactly zero: a singular basis is rejected by Jolt Physics.
const COLLECT_MIN_SCALE: float = 0.01

@export var value: int = GameConfig.COIN_SCORE_VALUE

var _base_position: Vector3 = Vector3.ZERO
var _collected: bool = false
var _time: float = 0.0
var _phase: float = 0.0
var _collect_tween: Tween

@onready var _mesh: Node3D = get_node_or_null("Mesh") as Node3D


## Normalizes the coin size to fit the runner, sets idle phase, and connects signals.
func _ready() -> void:
	_base_position = position
	_phase = position.z * 0.45
	if _mesh != null:
		MeshFit.fit_longest_axis(_mesh, GameConfig.COIN_MODEL_DIAMETER)

	body_entered.connect(_on_body_entered)
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").game_restarted.connect(restore)


## Spins and gently bobs the coin while waiting to be collected.
func _process(delta: float) -> void:
	if _collected or not visible or _mesh == null:
		return

	_time += delta
	_mesh.rotate_y(deg_to_rad(GameConfig.COIN_SPIN_SPEED_DEG) * delta)
	_mesh.position.y = sin(_time * GameConfig.COIN_BOB_SPEED + _phase) * GameConfig.COIN_BOB_AMPLITUDE


## Awards the coin score and plays the pop-and-burst feedback on player contact.
func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").collectible_picked.emit(GameConfig.COLLECTIBLE_TYPE_COIN, value)
	_collect()


## Plays a snappy upward pop, fast spin, shrink, and golden spark burst.
func _collect() -> void:
	_collected = true
	set_deferred("monitoring", false)
	PickupBurst.spawn(get_parent(), global_position, GOLD_BURST_COLOR)

	if _collect_tween != null and _collect_tween.is_running():
		_collect_tween.kill()

	_collect_tween = create_tween()
	_collect_tween.set_parallel(true)
	_collect_tween.tween_property(
		self, "position:y", _base_position.y + 0.45, GameConfig.COIN_COLLECT_TIME
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_collect_tween.tween_property(
		self, "scale", Vector3.ONE * COLLECT_MIN_SCALE, GameConfig.COIN_COLLECT_TIME
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if _mesh != null:
		_collect_tween.tween_property(
			_mesh, "rotation:y", _mesh.rotation.y + TAU, GameConfig.COIN_COLLECT_TIME
		)
	_collect_tween.chain().tween_callback(hide)


## Resets the coin so a restarted run or recycled chunk can present it again.
func restore() -> void:
	if _collect_tween != null and _collect_tween.is_running():
		_collect_tween.kill()
	_collected = false
	position = _base_position
	scale = Vector3.ONE
	if _mesh != null:
		_mesh.position.y = 0.0
	set_deferred("monitoring", true)
	show()


## Alias used by TrackChunk._restore_descendants when recycling chunks.
func respawn() -> void:
	restore()
