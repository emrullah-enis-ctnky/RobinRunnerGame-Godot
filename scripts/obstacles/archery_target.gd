class_name ArcheryTarget
extends Destructible
## Archery target that keeps every arrow embedded instead of being destroyed.

# Shot distance that always lands the bullseye, and the distance where accuracy is worst.
const NEAR_DISTANCE: float = 4.0
const FAR_DISTANCE: float = 35.0
# Aim error at maximum distance, as a fraction of the board radius.
const MAX_SPREAD: float = 1.4

# Bullseye, inner, middle and outer ring boundaries as fractions of the board radius.
const RING_RADII: Array[float] = [0.15, 0.45, 0.72, 0.95]
const BOARD_CENTER: Vector3 = Vector3(0.0, 0.64, 0.0)
const BOARD_RADIUS: float = 0.5
# Front face of the scaled target mesh (measured at z = 0.411), so arrows plant on
# the visible board instead of stopping at the deeper collision box front (z = 0.5).
const BOARD_FACE_Z: float = 0.41

# A new arrow landing this close to an embedded one pushes both apart.
const STACK_RADIUS: float = 0.14
const STACK_TILT_DEGREES: float = 22.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _stuck: Array[Dictionary] = []


## Starts the aiming RNG; the target never hides or clears its collision on a hit.
func _ready() -> void:
	super()
	_rng.randomize()


## Every arrow type reports a hit so the projectile embeds instead of destroying it.
func receive_arrow(_arrow_type: String) -> bool:
	return true


## Embeds an arrow on the target face, at a ring chosen from the shot distance.
func stick_arrow(arrow: Node3D, hit_position: Vector3) -> void:
	if arrow == null:
		return

	var distance: float = FAR_DISTANCE
	if arrow.has_method("travel_distance_to"):
		distance = arrow.travel_distance_to(hit_position)

	var impact: Vector3 = roll_impact_point(hit_position, distance)
	if arrow.has_method("embed_at"):
		arrow.embed_at(to_global(impact))
	arrow.reparent(self, true)

	_stuck.append({"arrow": arrow, "point": impact})
	_separate_overlapping(arrow, impact)


## Returns a target-local impact point; closer shots scatter less, very close shots
## land the bullseye exactly, and long shots spread toward the outer rings.
func roll_impact_point(_hit_position: Vector3, shot_distance: float) -> Vector3:
	var accuracy: float = clampf(
		(shot_distance - NEAR_DISTANCE) / (FAR_DISTANCE - NEAR_DISTANCE), 0.0, 1.0)
	var spread: float = MAX_SPREAD * accuracy

	var radius_fraction: float = 0.0
	if spread > 0.0:
		radius_fraction = minf(absf(_rng.randfn(0.0, spread)), RING_RADII[RING_RADII.size() - 1])

	var angle: float = _rng.randf_range(0.0, TAU)
	return Vector3(
		BOARD_CENTER.x + cos(angle) * radius_fraction * BOARD_RADIUS,
		BOARD_CENTER.y + sin(angle) * radius_fraction * BOARD_RADIUS,
		BOARD_FACE_Z
	)


## Tilts two arrows that landed on top of each other away in opposite directions.
func _separate_overlapping(new_arrow: Node3D, new_point: Vector3) -> void:
	var nearest: Dictionary = {}
	var nearest_distance: float = STACK_RADIUS

	for entry in _stuck:
		var other: Node3D = entry["arrow"]
		if not is_instance_valid(other) or other == new_arrow:
			continue
		var offset: Vector3 = (entry["point"] as Vector3) - new_point
		offset.z = 0.0
		var distance: float = offset.length()
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = entry

	if nearest.is_empty():
		return

	var away: Vector3 = new_point - (nearest["point"] as Vector3)
	away.z = 0.0
	if away.length() < 0.001:
		var random_angle: float = _rng.randf_range(0.0, TAU)
		away = Vector3(cos(random_angle), sin(random_angle), 0.0)

	var direction: Vector3 = away.normalized()
	var tilt: float = deg_to_rad(STACK_TILT_DEGREES) * _rng.randf_range(0.8, 1.2)
	_tilt_around_tip(nearest["arrow"], nearest["point"], -direction, tilt)
	_tilt_around_tip(new_arrow, new_point, direction, tilt)


## Rotates an embedded arrow around its tip so its shaft leans toward the given way.
func _tilt_around_tip(arrow: Node3D, pivot: Vector3, away_direction: Vector3, angle: float) -> void:
	if not is_instance_valid(arrow) or away_direction.length_squared() < 0.0001:
		return

	var axis: Vector3 = Vector3.BACK.cross(away_direction).normalized()
	if axis.length_squared() < 0.0001:
		return

	var rotation := Basis(axis, angle)
	var offset: Vector3 = arrow.position - pivot
	arrow.transform = Transform3D(rotation * arrow.basis, pivot + rotation * offset)


## Drops the arrows left in the target when it is restored.
func _reset_visual_state() -> void:
	for entry in _stuck:
		var arrow: Node3D = entry["arrow"]
		if is_instance_valid(arrow):
			arrow.queue_free()
	_stuck.clear()
