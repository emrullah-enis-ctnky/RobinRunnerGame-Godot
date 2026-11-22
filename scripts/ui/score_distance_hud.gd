class_name ScoreDistanceHUD
extends CanvasLayer
## Displays live score, distance, percentage bonus/penalty (%10, -%20), and floating score popups.

const ThemeRef = preload("res://scripts/ui/notebook_ui_theme.gd")

const BONUS_COLOR: Color = Color(0.42, 0.94, 0.28)
const PENALTY_COLOR: Color = Color(1.0, 0.34, 0.32)
const COIN_POPUP_COLOR: Color = Color(1.0, 0.90, 0.30)
const TARGET_POPUP_COLOR: Color = Color(1.0, 0.66, 0.14)

@onready var _root: Control = $Root
@onready var _panel: Control = $Root/Panel
@onready var _score_label: Label = $Root/Panel/ScoreLabel
@onready var _distance_label: Label = $Root/Panel/DistanceLabel
@onready var _combo_label: Label = $Root/Panel/ComboLabel
@onready var _popup_anchor: Control = $Root/PopupAnchor

var _last_pct: int = 0
var _bonus_tween: Tween


## Connects to EventBus score, distance, combo, popup, and lifecycle signals.
func _ready() -> void:
	ThemeRef.style_label(_score_label, 28, ThemeRef.TEXT_WHITE, 5)
	ThemeRef.style_label(_distance_label, 16, ThemeRef.TEXT_GOLD, 3)
	ThemeRef.style_label(_combo_label, 20, BONUS_COLOR, 4)

	if _panel != null:
		_panel.draw.connect(_draw_panel)
		_panel.queue_redraw()

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.score_updated.connect(_on_score_updated)
		bus.distance_updated.connect(_on_distance_updated)
		bus.combo_updated.connect(_on_combo_updated)
		bus.score_popup.connect(_on_score_popup)
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


## Shows percentage bonus (%10, %20...) or stumble penalty (-%20) cleanly.
func _on_combo_updated(_combo_count: int, multiplier: float) -> void:
	if _combo_label == null:
		return

	var pct: int = int(round((multiplier - 1.0) * 100.0))
	if pct == 0:
		_combo_label.visible = false
		_last_pct = 0
		return

	_combo_label.visible = true
	if pct > 0:
		_combo_label.text = "%%%d" % pct
		ThemeRef.style_label(_combo_label, 20, BONUS_COLOR, 4)
	else:
		_combo_label.text = "-%%%d" % absi(pct)
		ThemeRef.style_label(_combo_label, 20, PENALTY_COLOR, 4)

	if pct != _last_pct:
		_last_pct = pct
		_pop_bonus_label()


## Spawns an animated floating +score label beneath the score table for targets and coins.
func _on_score_popup(amount: int, source: String) -> void:
	if _popup_anchor == null or not _root.visible or amount <= 0:
		return

	var is_target: bool = (source == "target")
	var lbl := Label.new()
	lbl.text = "+%d" % amount
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.size = Vector2(140.0, 40.0)

	var font_sz: int = 30 if is_target else 22
	var col: Color = TARGET_POPUP_COLOR if is_target else COIN_POPUP_COLOR
	ThemeRef.style_label(lbl, font_sz, col, 5 if is_target else 4)

	var jitter_x: float = randf_range(-16.0, 16.0) if is_target else randf_range(-42.0, 42.0)
	var start_y: float = 6.0 if is_target else 12.0
	lbl.position = Vector2(-70.0 + jitter_x, start_y)
	lbl.pivot_offset = lbl.size * 0.5
	lbl.scale = Vector2(0.55, 0.55)
	_popup_anchor.add_child(lbl)

	var dur: float = 0.90 if is_target else 0.65
	var peak_scale: Vector2 = Vector2(1.28, 1.28) if is_target else Vector2(1.14, 1.14)
	var travel_y: float = 42.0 if is_target else 30.0

	var tw := create_tween()
	tw.tween_property(lbl, "scale", peak_scale, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", Vector2.ONE, 0.12)
	tw.parallel().tween_property(lbl, "position:y", start_y + travel_y, dur - 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, dur * 0.55).set_delay(dur * 0.35)
	tw.tween_callback(lbl.queue_free)


func _pop_bonus_label() -> void:
	if _bonus_tween != null and _bonus_tween.is_valid():
		_bonus_tween.kill()
	_combo_label.pivot_offset = _combo_label.size * 0.5
	_combo_label.scale = Vector2(1.3, 1.3)
	_bonus_tween = create_tween()
	_bonus_tween.tween_property(_combo_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
