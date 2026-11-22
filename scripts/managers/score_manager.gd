extends Node
## Tracks distance score, coin collection, and combo multipliers for each run.

const GameConfig = preload("res://scripts/common/game_config.gd")

var coins_collected: int = 0
var combo_count: int = 0
var combo_multiplier: float = 1.0

var _combo_timer: float = 0.0
var _last_distance_score: int = 0


## Connects to EventBus lifecycle, distance, and collectible signals.
func _ready() -> void:
	reset_run()
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.game_started.connect(reset_run)
		bus.game_restarted.connect(reset_run)
		bus.distance_updated.connect(_on_distance_updated)
		bus.collectible_picked.connect(_on_collectible_picked)
		bus.player_damaged.connect(_on_player_damaged)


## Counts down the active coin combo window during active gameplay.
func _process(delta: float) -> void:
	if combo_count <= 0:
		return
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm.current_state != gm.GameState.PLAYING:
			return

	_combo_timer -= delta
	if _combo_timer <= 0.0:
		_reset_combo()


## Resets all per-run scoring, coin, and combo state.
func reset_run() -> void:
	coins_collected = 0
	_last_distance_score = 0
	_reset_combo()
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").coins_updated.emit(coins_collected)


## Converts traveled meters into incremental integer distance score.
func _on_distance_updated(distance_meters: float) -> void:
	var target_score: int = int(floor(distance_meters * GameConfig.SCORE_PER_METER))
	var delta_score: int = target_score - _last_distance_score
	if delta_score <= 0:
		return
	_last_distance_score = target_score
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").add_score(delta_score)


## Banks coin pickups with the active combo multiplier and refreshes the combo window.
func _on_collectible_picked(collectible_type: String, value: int) -> void:
	if collectible_type != GameConfig.COLLECTIBLE_TYPE_COIN:
		return

	coins_collected += 1
	combo_count += 1
	_combo_timer = GameConfig.COMBO_WINDOW_SECONDS
	combo_multiplier = _compute_multiplier(combo_count)

	var awarded: int = maxi(1, int(round(float(value) * combo_multiplier)))
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").add_score(awarded)

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.coins_updated.emit(coins_collected)
		bus.combo_updated.emit(combo_count, combo_multiplier)


## Breaks the active coin combo when the player takes hazard damage.
func _on_player_damaged(_window_duration: float) -> void:
	_reset_combo()


## Computes the combo multiplier from the current streak length.
func _compute_multiplier(streak: int) -> float:
	var steps: int = int(streak / GameConfig.COMBO_STEP_COINS)
	return minf(1.0 + float(steps) * GameConfig.COMBO_MULTIPLIER_STEP, GameConfig.COMBO_MAX_MULTIPLIER)


## Clears the active combo streak back to 1.0x.
func _reset_combo() -> void:
	if combo_count == 0 and is_equal_approx(combo_multiplier, 1.0):
		_combo_timer = 0.0
		return
	combo_count = 0
	combo_multiplier = 1.0
	_combo_timer = 0.0
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").combo_updated.emit(combo_count, combo_multiplier)
