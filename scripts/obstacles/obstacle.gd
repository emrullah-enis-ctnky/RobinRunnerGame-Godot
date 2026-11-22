class_name Obstacle
extends StaticBody3D
## Base class for static track hazards that stagger or end a run on contact.

@export var hazard_type: String = "obstacle"
@export var is_lethal: bool = false

# Only structures tall enough to read as a wall catch arrows like a dart.
const STICK_MIN_TOP_HEIGHT: float = 1.2
# Close shots land on the aim point; far shots scatter toward the collider edges.
const STICK_NEAR_DISTANCE: float = 4.0
const STICK_FAR_DISTANCE: float = 30.0
const STICK_MAX_SPREAD: float = 0.75
const STICK_EDGE_MARGIN: float = 0.05

var _stuck_arrows: Array[Node3D] = []


## Plain obstacles do not react to arrows; shootable subclasses override this.
func receive_arrow(_arrow_type: String) -> bool:
	return false


## Returns true when the obstacle is tall enough to catch an arrow like a dart.
func can_stick_arrow() -> bool:
	var box: AABB = _collider_box()
	if box.size.is_zero_approx():
		return false
	return to_global(Vector3(0.0, box.end.y, 0.0)).y >= STICK_MIN_TOP_HEIGHT


## Plants an arrow the obstacle could not destroy, with distance-based scatter.
## Returns true when the arrow stayed embedded.
func stick_arrow(arrow: Node3D, hit_position: Vector3) -> bool:
	if arrow == null or not can_stick_arrow():
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


## Returns a local-space impact point: close shots stay on the aim point, far shots
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
		aim.x += randfn(0.0, spread.x)
		aim.y += randfn(0.0, spread.y)

	point.x = clampf(aim.x, box.position.x + STICK_EDGE_MARGIN, box.end.x - STICK_EDGE_MARGIN)
	point.y = clampf(aim.y, box.position.y + STICK_EDGE_MARGIN, box.end.y - STICK_EDGE_MARGIN)
	point.z = box.end.z
	return point


## Returns the local-space box of the obstacle's collision shape.
func _collider_box() -> AABB:
	for child in get_children():
		if child is CollisionShape3D:
			var shape: Shape3D = (child as CollisionShape3D).shape
			if shape is BoxShape3D:
				var size: Vector3 = (shape as BoxShape3D).size
				return AABB((child as CollisionShape3D).position - size * 0.5, size)
	return AABB()


## Drops every arrow left embedded in the obstacle.
func _clear_stuck_arrows() -> void:
	for arrow in _stuck_arrows:
		if is_instance_valid(arrow):
			arrow.queue_free()
	_stuck_arrows.clear()


## Returns the hazard label reported to the EventBus when the player collides.
func get_hazard_type() -> String:
	return hazard_type


## Returns true when a single contact must end the run, bypassing the stumble allowance.
func is_lethal_hazard() -> bool:
	return is_lethal
