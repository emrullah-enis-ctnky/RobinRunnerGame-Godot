class_name Destructible
extends Obstacle
## Shootable hazard that blocks a lane until a projectile destroys it.

@export var score_reward: int = 50
@export var destroyed_by: PackedStringArray = ["normal"]

var is_destroyed: bool = false


## Restores the target whenever a new run starts.
func _ready() -> void:
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.game_restarted.connect(restore)


## Clears the lane and broadcasts the score reward for the destroyed target.
func destroy() -> void:
	if is_destroyed:
		return

	is_destroyed = true
	_apply_destroyed_state()

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.target_destroyed.emit(name, score_reward)


## Presents the destroyed state; subclasses override to animate instead of hiding.
func _apply_destroyed_state() -> void:
	set_deferred("collision_layer", 0)
	hide()


## Re-enables the target so recycled chunks can present it again.
func restore() -> void:
	is_destroyed = false
	set_deferred("collision_layer", GameConfig.LAYER_TARGET)
	show()
	_reset_visual_state()


## Restores any custom destruction presentation; subclasses override as needed.
func _reset_visual_state() -> void:
	pass


## Returns the arrow types that can destroy this target.
func required_arrow_types() -> PackedStringArray:
	return destroyed_by


## Applies an incoming arrow; returns true when it destroyed the target.
func receive_arrow(arrow_type: String) -> bool:
	if arrow_type in destroyed_by:
		destroy()
		return true
	return false
