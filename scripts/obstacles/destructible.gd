class_name Destructible
extends Obstacle
## Shootable hazard that blocks a lane until a projectile destroys it.

@export var score_reward: int = 50

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
	set_deferred("collision_layer", 0)
	hide()

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.target_destroyed.emit(name, score_reward)


## Re-enables the target so recycled chunks can present it again.
func restore() -> void:
	is_destroyed = false
	set_deferred("collision_layer", GameConfig.LAYER_TARGET)
	show()
