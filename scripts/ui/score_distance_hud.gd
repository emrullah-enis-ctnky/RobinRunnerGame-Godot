class_name ScoreDistanceHUD
extends CanvasLayer
## Displays the live score, distance traveled, and active coin combo in the top-center HUD.

const ThemeRef = preload("res://scripts/ui/notebook_ui_theme.gd")

@onready var _root: Control = $Root
@onready var _panel: Control = $Root/Panel
@onready var _score_label: Label = $Root/Panel/ScoreLabel
@onready var _distance_label: Label = $Root/Panel/DistanceLabel
@onready var _combo_label: Label = $Root/Panel/ComboLabel


## Connects to EventBus score, distance, combo, and lifecycle signals.
func _ready() -> void:
	ThemeRef.style_label(_score_label, 26, ThemeRef.TEXT_WHITE, 4)
	ThemeRef.style_label(_distance_label, 16, ThemeRef.TEXT_GOLD, 3)
	ThemeRef.style_label(_combo_label, 16, ThemeRef.GREEN_HOVER, 3)

	if _panel != null:
		_panel.draw.connect(_draw_panel)
		_panel.queue_redraw()

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.score_updated.connect(_on_score_updated)
		bus.distance_updated.connect(_on_distance_updated)
		bus.combo_updated.connect(_on_combo_updated)
		bus.game_started.connect(_on_run_reset)
		bus.game_restarted.connect(_on_run_reset)
		bus.game_paused.connect(_refresh_visibility)
		bus.game_resumed.connect(_refresh_visibility)
		bus.game_over.connect(func(_s: int, _d: float) -> void: _refresh_visibility())

	_on_run_reset()


## Updates the score display.
func _on_score_updated(current_score: int) -> void:
	if _score_label != null:
		_score_label.text = str(current_score)


## Updates the distance display in meters.
func _on_distance_updated(distance_meters: float) -> void:
	if _distance_label != null:
		_distance_label.text = "%dm" % int(floor(distance_meters))


## Shows or hides the combo multiplier badge.
func _on_combo_updated(_combo_count: int, multiplier: float) -> void:
	if _combo_label == null:
		return
	_combo_label.visible = multiplier > 1.01
	_combo_label.text = "x%.2g" % multiplier


## Resets HUD text and updates visibility for the active GameManager state.
func _on_run_reset() -> void:
	var score: int = 0
	var dist: float = 0.0
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		score = gm.score
		dist = gm.distance_traveled
	_on_score_updated(score)
	_on_distance_updated(dist)
	_on_combo_updated(0, 1.0)
	_refresh_visibility()


## Shows the score/distance HUD only during active gameplay or pause.
func _refresh_visibility() -> void:
	if _root == null or not has_node("/root/GameManager"):
		return
	var gm: Node = get_node("/root/GameManager")
	_root.visible = (gm.current_state == gm.GameState.PLAYING or gm.current_state == gm.GameState.PAUSED)


func _draw_panel() -> void:
	ThemeRef.draw_hud_pill(_panel, _panel.size)
