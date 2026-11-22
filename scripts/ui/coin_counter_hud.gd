class_name CoinCounterHUD
extends CanvasLayer
## Displays the current run's collected coin count and animated combo streak in the top-left corner.

const ThemeRef = preload("res://scripts/ui/notebook_ui_theme.gd")
const GOLD_COLOR: Color = Color(1.0, 0.78, 0.12)
const GOLD_RIM_COLOR: Color = Color(0.85, 0.56, 0.04)
const PULSE_COLOR: Color = Color(1.0, 0.92, 0.45)

@onready var _root: Control = $Root
@onready var _panel: Control = $Root/Panel
@onready var _count_label: Label = $Root/Panel/Count
@onready var _combo_badge: Control = $Root/ComboBadge
@onready var _combo_label: Label = $Root/ComboBadge/ComboCount

var _pulse_tween: Tween
var _combo_tween: Tween
var _combo_visible: bool = false


## Connects to EventBus coin, combo, and lifecycle signals and initializes display.
func _ready() -> void:
	ThemeRef.style_label(_count_label, 26, ThemeRef.TEXT_WHITE, 4)
	ThemeRef.style_label(_combo_label, 20, ThemeRef.TEXT_GOLD, 4)

	if _panel != null:
		_panel.draw.connect(_draw_panel)
		_panel.queue_redraw()
	if _combo_badge != null:
		_combo_badge.draw.connect(_draw_combo_badge)
		_combo_badge.visible = false
		_combo_badge.queue_redraw()

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.coins_updated.connect(_on_coins_updated)
		bus.combo_updated.connect(_on_combo_updated)
		bus.game_started.connect(_refresh_visibility)
		bus.game_restarted.connect(_refresh_visibility)
		bus.game_paused.connect(_refresh_visibility)
		bus.game_resumed.connect(_refresh_visibility)
		bus.game_over.connect(func(_s: int, _d: float) -> void: _refresh_visibility())

	var initial: int = 0
	if has_node("/root/ScoreManager"):
		initial = get_node("/root/ScoreManager").coins_collected
	_set_count(initial, false)
	_refresh_visibility()


## Shows the HUD only during active gameplay or pause.
func _refresh_visibility() -> void:
	if _root == null or not has_node("/root/GameManager"):
		return
	var gm: Node = get_node("/root/GameManager")
	_root.visible = (gm.current_state == gm.GameState.PLAYING or gm.current_state == gm.GameState.PAUSED)


## Updates the label and plays a subtle golden pulse when coins increase.
func _on_coins_updated(coin_count: int) -> void:
	_set_count(coin_count, coin_count > 0)


## Shows, pulses, or hides the animated combo streak badge under the coin counter.
func _on_combo_updated(combo_count: int, _multiplier: float) -> void:
	if _combo_badge == null or _combo_label == null:
		return

	if combo_count < 2:
		if _combo_visible:
			_combo_visible = false
			_animate_combo_out()
		return

	_combo_label.text = "%dx" % combo_count
	if not _combo_visible:
		_combo_visible = true
		_animate_combo_in()
	else:
		_animate_combo_pulse()


func _animate_combo_in() -> void:
	if _combo_tween != null and _combo_tween.is_valid():
		_combo_tween.kill()
	_combo_badge.visible = true
	_combo_badge.pivot_offset = _combo_badge.size * 0.5
	_combo_badge.scale = Vector2(0.5, 0.5)
	_combo_badge.modulate.a = 0.0
	_combo_tween = create_tween()
	_combo_tween.set_parallel(true)
	_combo_tween.tween_property(_combo_badge, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_combo_tween.tween_property(_combo_badge, "modulate:a", 1.0, 0.16)


func _animate_combo_pulse() -> void:
	if _combo_tween != null and _combo_tween.is_valid():
		_combo_tween.kill()
	_combo_badge.pivot_offset = _combo_badge.size * 0.5
	_combo_badge.scale = Vector2(1.22, 1.22)
	_combo_badge.modulate.a = 1.0
	_combo_tween = create_tween()
	_combo_tween.tween_property(_combo_badge, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _animate_combo_out() -> void:
	if _combo_tween != null and _combo_tween.is_valid():
		_combo_tween.kill()
	_combo_badge.pivot_offset = _combo_badge.size * 0.5
	_combo_tween = create_tween()
	_combo_tween.set_parallel(true)
	_combo_tween.tween_property(_combo_badge, "scale", Vector2(0.5, 0.5), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_combo_tween.tween_property(_combo_badge, "modulate:a", 0.0, 0.16)
	_combo_tween.chain().tween_callback(_combo_badge.hide)


## Applies the coin count text and optional pickup pulse.
func _set_count(coin_count: int, pulse: bool) -> void:
	if _count_label == null:
		return
	_count_label.text = str(coin_count)
	if not pulse:
		_count_label.modulate = Color.WHITE
		return

	if _pulse_tween != null and _pulse_tween.is_running():
		_pulse_tween.kill()
	_count_label.modulate = PULSE_COLOR
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(1.12, 1.12)
	_pulse_tween = create_tween()
	_pulse_tween.set_parallel(true)
	_pulse_tween.tween_property(_count_label, "modulate", Color.WHITE, 0.22)
	_pulse_tween.tween_property(_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Draws the unified HUD pill frame and stylized golden star coin icon.
func _draw_panel() -> void:
	ThemeRef.draw_hud_pill(_panel, _panel.size)
	var center := Vector2(24.0, _panel.size.y * 0.5)
	_panel.draw_circle(center, 14.0, GOLD_RIM_COLOR)
	_panel.draw_circle(center, 11.0, GOLD_COLOR)
	_draw_star(center, 6.8, 3.3, GOLD_RIM_COLOR)


func _draw_combo_badge() -> void:
	ThemeRef.draw_hud_pill(_combo_badge, _combo_badge.size)


## Draws a 5-point star inside the coin icon.
func _draw_star(center: Vector2, outer_r: float, inner_r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(10):
		var ang: float = -PI * 0.5 + float(i) * PI / 5.0
		var r: float = outer_r if i % 2 == 0 else inner_r
		pts.append(center + Vector2(cos(ang), sin(ang)) * r)
	_panel.draw_colored_polygon(pts, color)
