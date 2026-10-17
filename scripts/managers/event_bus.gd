extends Node
## Global event bus for decoupled communication across systems.

# Game Lifecycle Signals
signal game_started
signal game_paused
signal game_resumed
signal game_over(final_score: int, distance_traveled: float)
signal game_restarted

# Player Movement & State Signals
signal player_lane_changed(new_lane_index: int, target_x: float)
signal player_jumped
signal player_landed
signal player_hit_hazard(hazard_type: String)
signal player_damaged(window_duration: float)
signal player_died

# Combat & Ability Signals
signal arrow_ammo_updated(normal_count: int, flame_count: int)
signal arrow_type_changed(arrow_type: String)
signal ability_activated
signal arrow_fired(spawn_position: Vector3, forward_direction: Vector3, arrow_type: String)
signal target_destroyed(target_name: String, score_reward: int)

# Score & Metric Signals
signal score_updated(current_score: int)
signal distance_updated(distance_meters: float)
signal collectible_picked(collectible_type: String, value: int)


## Resets all signals and listeners when switching runs.
func reset_bus() -> void:
	pass
