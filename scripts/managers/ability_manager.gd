extends Node
## Global quiver manager: tracks collected arrows and resolves the type to fire.

const GameConfig = preload("res://scripts/common/game_config.gd")
const AMMO_PREFIX: String = "arrow_"

var ammo: Dictionary = {}


## Initializes the quiver and connects to the global life-cycle signals.
func _ready() -> void:
	reset_ammo()
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.game_restarted.connect(reset_ammo)
		bus.collectible_picked.connect(_on_collectible_picked)


## Restores the quiver to its starting counts and broadcasts the update.
func reset_ammo() -> void:
	ammo = {
		GameConfig.ARROW_TYPE_NORMAL: GameConfig.START_AMMO_NORMAL,
		GameConfig.ARROW_TYPE_FLAME: GameConfig.START_AMMO_FLAME
	}
	_emit_ammo()


## Returns how many arrows of a given type remain.
func get_ammo(arrow_type: String) -> int:
	return int(ammo.get(arrow_type, 0))


## Returns true when at least one arrow of the given type remains.
func has_ammo(arrow_type: String) -> bool:
	return get_ammo(arrow_type) > 0


## Returns the total number of arrows across every type.
func total_ammo() -> int:
	var total: int = 0
	for count in ammo.values():
		total += int(count)
	return total


## Resolves the arrow type (preferring the requested one) and fires it when ammo allows.
## Returns false when no usable arrow remains.
func try_fire(origin: Vector3, direction: Vector3, preferred_type: String) -> bool:
	var fired_type: String = _resolve_type(preferred_type)
	if fired_type.is_empty():
		return false

	ammo[fired_type] = get_ammo(fired_type) - 1
	_emit_ammo()

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.ability_activated.emit()
		bus.arrow_fired.emit(origin, direction, fired_type)
	return true


## Picks a usable type: the preferred one first, then the remaining type.
func _resolve_type(preferred_type: String) -> String:
	if has_ammo(preferred_type):
		return preferred_type
	var fallback: String = GameConfig.ARROW_TYPE_FLAME if preferred_type == GameConfig.ARROW_TYPE_NORMAL else GameConfig.ARROW_TYPE_NORMAL
	return fallback if has_ammo(fallback) else ""


## Adds collected arrow pickups straight into the quiver.
func _on_collectible_picked(collectible_type: String, value: int) -> void:
	if not collectible_type.begins_with(AMMO_PREFIX):
		return
	var arrow_type: String = collectible_type.substr(AMMO_PREFIX.length())
	if not ammo.has(arrow_type):
		return

	ammo[arrow_type] = get_ammo(arrow_type) + value
	_emit_ammo()
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").arrow_type_changed.emit(arrow_type)


## Broadcasts the current quiver counts.
func _emit_ammo() -> void:
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").arrow_ammo_updated.emit(
			get_ammo(GameConfig.ARROW_TYPE_NORMAL),
			get_ammo(GameConfig.ARROW_TYPE_FLAME)
		)
