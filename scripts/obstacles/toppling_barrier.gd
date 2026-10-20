class_name TopplingBarrier
extends Destructible
## Ladder barrier that tips over around its base after an arrow knocks it down.

const MAX_FALL_ANGLE: float = PI * 0.5
# The ladder keeps blocking the lane until it is only 30 degrees above the ground.
const COLLISION_CLEAR_ANGLE: float = MAX_FALL_ANGLE - deg_to_rad(30.0)
# A rod pivoting at its base accelerates at (3g / 2L) * sin(angle); GameConfig.GRAVITY
# already runs hotter than real gravity, so the factor is tuned to a snappy fall.
const GRAVITY_FACTOR: float = 3.5

@export var fall_height: float = 1.6
@export var start_tilt_degrees: float = 3.0

var _falling: bool = false
var _angle: float = 0.0
var _angular_speed: float = 0.0
var _base_basis: Basis = Basis.IDENTITY
var _fall_axis: Vector3 = Vector3.LEFT
var _stuck_arrows: Array[Node3D] = []
var _collision_cleared: bool = false


## Captures the upright pose and parks the fall simulation until the barrier is hit.
func _ready() -> void:
	super()
	_base_basis = global_transform.basis
	# The pivot is the model origin at the ladder's bottom centre, so a basis rotation
	# around it reads as the whole ladder tipping over that point.
	set_physics_process(false)


## Starts the fall in place of the default hide-on-destroy behaviour.
func _apply_destroyed_state() -> void:
	_falling = true
	_angle = deg_to_rad(start_tilt_degrees)
	_angular_speed = 0.0
	_collision_cleared = false
	# Tips the ladder toward the runner's travel direction (-Z).
	_fall_axis = Vector3.UP.cross(Vector3.FORWARD).normalized()
	set_physics_process(true)


## Advances the fall: the lean grows slowly at first, then accelerates like a falling rod.
func _physics_process(delta: float) -> void:
	if not _falling:
		return

	var gravity_accel: float = GRAVITY_FACTOR * GameConfig.GRAVITY / fall_height
	_angular_speed += gravity_accel * sin(_angle) * delta
	_angle = minf(_angle + _angular_speed * delta, MAX_FALL_ANGLE)
	global_transform.basis = Basis(_fall_axis, _angle) * _base_basis

	# Keep the lane blocked while the ladder still stands steeply enough to hit.
	if not _collision_cleared and _angle >= COLLISION_CLEAR_ANGLE:
		_collision_cleared = true
		set_deferred("collision_layer", 0)

	if _angle >= MAX_FALL_ANGLE:
		_falling = false
		set_physics_process(false)


## Embeds a spent arrow in the barrier so it topples along with it.
func stick_arrow(arrow: Node3D, hit_position: Vector3) -> void:
	if arrow == null:
		return

	if arrow.has_method("embed_at"):
		arrow.embed_at(hit_position)
	arrow.reparent(self, true)
	_stuck_arrows.append(arrow)


## Returns the barrier upright and drops the arrows left stuck in it.
func _reset_visual_state() -> void:
	_falling = false
	_angle = 0.0
	_angular_speed = 0.0
	_collision_cleared = false
	global_transform.basis = _base_basis
	set_physics_process(false)

	for arrow in _stuck_arrows:
		if is_instance_valid(arrow):
			arrow.queue_free()
	_stuck_arrows.clear()
