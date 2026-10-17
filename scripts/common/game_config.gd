class_name GameConfig
extends RefCounted
## Global configuration and gameplay constants for RobinRunner.

# Lane Definitions
const LANE_LEFT: int = -1
const LANE_CENTER: int = 0
const LANE_RIGHT: int = 1

const LANE_WIDTH: float = 2.0
const LANE_POSITIONS: Dictionary = {
	LANE_LEFT: -2.0,
	LANE_CENTER: 0.0,
	LANE_RIGHT: 2.0
}
const LANE_SWITCH_SPEED: float = 14.0

# Player Movement & Physics
const INITIAL_FORWARD_SPEED: float = 12.0
const MAX_FORWARD_SPEED: float = 28.0
const SPEED_ACCELERATION_PER_SECOND: float = 0.08
const JUMP_VELOCITY: float = 7.5
const GRAVITY: float = 22.0

# Ability & Combat Constants
const ARROW_TYPE_NORMAL: String = "normal"
const ARROW_TYPE_FLAME: String = "flame"
const START_AMMO_NORMAL: int = 3
const START_AMMO_FLAME: int = 1
const ARROW_SPEED: float = 40.0
const ARROW_LIFETIME: float = 3.0
const ARROW_SCAN_RANGE: float = 45.0
const ARROW_MUZZLE_HEIGHT: float = 1.0
const SHOOT_DRAW_TIME: float = 0.12
const SHOOT_RELEASE_TIME: float = 0.28

# Pickup Idle Motion
const PICKUP_BOB_HEIGHT: float = 0.12
const PICKUP_BOB_SPEED: float = 2.0
const PICKUP_SPIN_SPEED: float = 1.2

# Track & World Generation
const CHUNK_LENGTH: float = 30.0
const INITIAL_CHUNKS_COUNT: int = 6
const CHUNK_DESPAWN_DISTANCE_BEHIND: float = 40.0

# Collision Layer Bitmasks (layer 1 -> 1 << 0)
const LAYER_PLAYER: int = 1 << 0
const LAYER_ENVIRONMENT: int = 1 << 1
const LAYER_OBSTACLE: int = 1 << 2
const LAYER_TARGET: int = 1 << 3
const LAYER_PROJECTILE: int = 1 << 4
const LAYER_PICKUP: int = 1 << 5

# Hazard Resolution
const STUMBLE_DURATION: float = 0.6
const STUMBLE_SPEED_FACTOR: float = 0.45
const DAMAGE_WINDOW_DURATION: float = 5.0


## Returns the 3D X coordinate for a specific lane index.
static func get_lane_x(lane_index: int) -> float:
	return LANE_POSITIONS.get(lane_index, 0.0)


## Clamps lane index to stay within valid lane bounds (-1 to 1).
static func clamp_lane(lane_index: int) -> int:
	return clampi(lane_index, LANE_LEFT, LANE_RIGHT)
