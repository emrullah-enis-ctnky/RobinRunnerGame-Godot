class_name BurnableTree
extends Obstacle
## Lethal tree that can only be cleared from a lane by a flame arrow.

@export var score_reward: int = 75
@export var destroyed_by: PackedStringArray = ["flame"]

var is_destroyed: bool = false

var _original_layer: int = 0


## Captures the hazard layer and restores the tree whenever a new run starts.
func _ready() -> void:
	_original_layer = collision_layer
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.game_restarted.connect(restore)


## Returns the arrow types that can burn this tree.
func required_arrow_types() -> PackedStringArray:
	return destroyed_by


## Applies an incoming arrow; returns true when it burned the tree down.
func receive_arrow(arrow_type: String) -> bool:
	if is_destroyed or not (arrow_type in destroyed_by):
		return false
	destroy()
	return true


## Clears the lane and broadcasts the score reward for the burned tree.
func destroy() -> void:
	if is_destroyed:
		return

	is_destroyed = true
	set_deferred("collision_layer", 0)
	hide()

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.target_destroyed.emit(name, score_reward)


## Re-enables the tree so recycled chunks can present it again.
func restore() -> void:
	is_destroyed = false
	set_deferred("collision_layer", _original_layer)
	show()
