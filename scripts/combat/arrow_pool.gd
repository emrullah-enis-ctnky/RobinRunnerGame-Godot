class_name ArrowPool
extends Node3D
## Spawns and recycles player arrows in response to the global arrow_fired signal.

const ARROW_SCENE: PackedScene = preload("res://scenes/combat/arrow.tscn")
const PREWARM_COUNT: int = 8
const MAX_COUNT: int = 32

var _pool: ObjectPool


## Builds the pool and starts listening for fired arrows.
func _ready() -> void:
	_pool = ObjectPool.new(ARROW_SCENE, self, PREWARM_COUNT, MAX_COUNT)
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").arrow_fired.connect(_spawn)


## Activates a pooled arrow at the given origin and direction.
func _spawn(origin: Vector3, direction: Vector3, arrow_type: String) -> void:
	var arrow: Arrow = _pool.acquire() as Arrow
	if arrow == null:
		return
	if not arrow.finished.is_connected(_on_arrow_finished):
		arrow.finished.connect(_on_arrow_finished)
	arrow.activate(origin, direction, arrow_type)


## Returns a spent arrow to the pool.
func _on_arrow_finished(arrow: Arrow) -> void:
	_pool.release(arrow)


## Returns the number of arrows currently in flight.
func get_active_count() -> int:
	return _pool.get_active_count() if _pool else 0


## Returns the number of standby arrows waiting in the pool.
func get_available_count() -> int:
	return _pool.get_available_count() if _pool else 0
