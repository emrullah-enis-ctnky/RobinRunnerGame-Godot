class_name BurnableTree
extends Obstacle
## Lethal tree that can only be cleared from a lane by a flame arrow.

@export var score_reward: int = 75
@export var destroyed_by: PackedStringArray = ["flame"]

# Dart-like sticking: close shots land near the aim point, far shots scatter to the edges.
const STICK_NEAR_DISTANCE: float = 4.0
const STICK_FAR_DISTANCE: float = 30.0
const STICK_MAX_SPREAD: float = 0.75
const STICK_EDGE_MARGIN: float = 0.05

var is_destroyed: bool = false

var _original_layer: int = 0
var _stuck_arrows: Array[Node3D] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Captures the hazard layer and restores the tree whenever a new run starts.
func _ready() -> void:
	_original_layer = collision_layer
	_rng.randomize()
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


## Catches an arrow that could not burn the tree and plants it like a dart.
## Returns true when the arrow stayed embedded.
func stick_arrow(arrow: Node3D, hit_position: Vector3) -> bool:
	if is_destroyed or arrow == null:
		return false

	var distance: float = STICK_FAR_DISTANCE
	if arrow.has_method("travel_distance_to"):
		distance = arrow.travel_distance_to(hit_position)

	var point: Vector3 = roll_stick_point(hit_position, distance)
	if arrow.has_method("embed_at"):
		arrow.embed_at(to_global(point))
	arrow.reparent(self, true)
	_stuck_arrows.append(arrow)
	return true


## Returns a tree-local impact point: close shots stay on the aim point, far shots
## scatter across the collider face so they often land at the outer edge.
func roll_stick_point(hit_position: Vector3, shot_distance: float) -> Vector3:
	var box: AABB = _collider_box()
	var point: Vector3 = to_local(hit_position)
	if box.size.is_zero_approx():
		return point

	var accuracy: float = clampf(
		(shot_distance - STICK_NEAR_DISTANCE) / (STICK_FAR_DISTANCE - STICK_NEAR_DISTANCE), 0.0, 1.0)
	var half: Vector2 = Vector2(box.size.x, box.size.y) * 0.5
	var aim := Vector2(point.x, point.y)

	if accuracy > 0.0:
		var spread: Vector2 = half * STICK_MAX_SPREAD * accuracy
		aim.x += _rng.randfn(0.0, spread.x)
		aim.y += _rng.randfn(0.0, spread.y)

	point.x = clampf(aim.x, box.position.x + STICK_EDGE_MARGIN, box.end.x - STICK_EDGE_MARGIN)
	point.y = clampf(aim.y, box.position.y + STICK_EDGE_MARGIN, box.end.y - STICK_EDGE_MARGIN)
	point.z = box.end.z
	return point


## Returns the local-space box of the tree's collision shape.
func _collider_box() -> AABB:
	for child in get_children():
		if child is CollisionShape3D:
			var shape: Shape3D = (child as CollisionShape3D).shape
			if shape is BoxShape3D:
				var size: Vector3 = (shape as BoxShape3D).size
				return AABB((child as CollisionShape3D).position - size * 0.5, size)
	return AABB()


## Clears the lane and broadcasts the score reward for the burned tree.
func destroy() -> void:
	if is_destroyed:
		return

	is_destroyed = true
	_clear_stuck_arrows()
	set_deferred("collision_layer", 0)
	hide()

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.target_destroyed.emit(name, score_reward)


## Re-enables the tree so recycled chunks can present it again.
func restore() -> void:
	is_destroyed = false
	_clear_stuck_arrows()
	set_deferred("collision_layer", _original_layer)
	show()


## Drops every arrow left embedded in the tree.
func _clear_stuck_arrows() -> void:
	for arrow in _stuck_arrows:
		if is_instance_valid(arrow):
			arrow.queue_free()
	_stuck_arrows.clear()
