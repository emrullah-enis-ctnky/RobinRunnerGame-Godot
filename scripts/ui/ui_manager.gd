class_name UIManager
extends CanvasLayer
## Coordinates Main Menu, Settings (Audio/Controls/Language), 3-2-1 Countdown, Pause, and Game Over.

const ThemeRef = preload("res://scripts/ui/notebook_ui_theme.gd")
const NotebookCardScript = preload("res://scripts/ui/notebook_card.gd")
const SettingsPanelsScript = preload("res://scripts/ui/settings_panels.gd")

const DEATH_FADE_WAIT: float = 1.25
const SLIDE_DURATION: float = 0.45

enum BackdropMode { MENU, PAUSE, GAME_OVER }

var _backdrop: Control
var _backdrop_mode: int = BackdropMode.MENU
var _main_menu: Control
var _pause_menu: Control
var _game_over_panel: Control
var _countdown_label: Label
var _settings_panels

var _best_label: Label
var _main_settings_btn: Button
var _main_quit_btn: Button
var _pause_resume_btn: Button
var _pause_restart_btn: Button
var _pause_settings_btn: Button
var _pause_menu_btn: Button
var _go_score_name: Label
var _go_best_name: Label
var _go_dist_name: Label
var _go_coins_name: Label
var _go_score_value: Label
var _go_best_value: Label
var _go_new_best_label: Label
var _go_distance_value: Label
var _go_coins_value: Label
var _go_retry_btn: Button
var _go_menu_btn: Button

var _return_to_pause: bool = false
var _last_high_score: int = 0
var _countdown_tween: Tween
var _gameover_tween: Tween
var _is_counting_down: bool = false


## Builds all menu cards, settings sub-panels, countdown label, and connects signals.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 110
	_build_ui()

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.game_started.connect(_on_game_started)
		bus.game_restarted.connect(_on_game_started)
		bus.game_paused.connect(_on_game_paused)
		bus.game_resumed.connect(_on_game_resumed)
		bus.game_over.connect(_on_game_over)

	if has_node("/root/SettingsManager"):
		get_node("/root/SettingsManager").language_changed.connect(func(_l: String) -> void: _refresh_translations())

	if has_node("/root/GameManager"):
		_last_high_score = get_node("/root/GameManager").high_score
	_refresh_translations()
	show_main_menu()


## Captures keybinds when Controls is listening, before anything else consumes the key.
func _input(event: InputEvent) -> void:
	if _settings_panels != null and _settings_panels.is_capturing_key():
		if _settings_panels.handle_input(event):
			get_viewport().set_input_as_handled()


## Handles Esc / P pause toggling during active gameplay or pause.
func _unhandled_input(event: InputEvent) -> void:
	if _is_counting_down or not event.is_action_pressed("pause"):
		return
	if _settings_panels != null and _settings_panels.is_any_visible():
		_on_settings_closed()
		get_viewport().set_input_as_handled()
		return
	if not has_node("/root/GameManager"):
		return
	var gm: Node = get_node("/root/GameManager")
	if gm.current_state == gm.GameState.PLAYING:
		get_tree().paused = true
		gm.pause_game()
		get_viewport().set_input_as_handled()
	elif gm.current_state == gm.GameState.PAUSED:
		get_tree().paused = false
		gm.resume_game()
		get_viewport().set_input_as_handled()


## Shows the Main Menu over a dedicated stylized forest backdrop.
func show_main_menu() -> void:
	_cancel_sequences()
	_hide_all()
	_backdrop_mode = BackdropMode.MENU
	_backdrop.visible = true
	_backdrop.queue_redraw()
	if _best_label != null and has_node("/root/GameManager"):
		var hs: int = get_node("/root/GameManager").high_score
		_best_label.visible = hs > 0
		_best_label.text = "%s: %d" % [_t("lbl_best"), hs]
	_main_menu.visible = true


## Shows the Pause Menu over the paused 3D world.
func show_pause_menu() -> void:
	_hide_all()
	_backdrop_mode = BackdropMode.PAUSE
	_backdrop.visible = true
	_backdrop.queue_redraw()
	_pause_menu.visible = true


## Shows the Game Over summary card, sliding up from the bottom after death fade completes.
func show_game_over(final_score: int, distance_traveled: float, immediate: bool = false) -> void:
	_cancel_sequences()
	_hide_all()

	var hs: int = final_score
	if has_node("/root/GameManager"):
		hs = get_node("/root/GameManager").high_score
	var coins: int = 0
	if has_node("/root/ScoreManager"):
		coins = get_node("/root/ScoreManager").coins_collected

	_go_score_value.text = str(final_score)
	_go_best_value.text = str(hs)
	_go_distance_value.text = "%dm" % int(floor(distance_traveled))
	_go_coins_value.text = str(coins)
	_go_new_best_label.visible = (final_score > 0 and final_score > _last_high_score)
	_last_high_score = hs

	var target_pos: Vector2 = _centered_pos(_game_over_panel.size)
	if immediate:
		_backdrop_mode = BackdropMode.GAME_OVER
		_backdrop.visible = true
		_backdrop.queue_redraw()
		_game_over_panel.position = target_pos
		_game_over_panel.modulate.a = 1.0
		_game_over_panel.visible = true
		return

	var vp_h: float = get_viewport().get_visible_rect().size.y
	if vp_h <= 0.0:
		vp_h = 720.0
	_game_over_panel.position = Vector2(target_pos.x, vp_h + 60.0)
	_game_over_panel.modulate.a = 0.0

	_gameover_tween = create_tween()
	_gameover_tween.tween_interval(DEATH_FADE_WAIT)
	_gameover_tween.tween_callback(func() -> void:
		_backdrop_mode = BackdropMode.GAME_OVER
		_backdrop.visible = true
		_backdrop.queue_redraw()
		_game_over_panel.visible = true
	)
	_gameover_tween.tween_property(_game_over_panel, "position:y", target_pos.y, SLIDE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gameover_tween.parallel().tween_property(_game_over_panel, "modulate:a", 1.0, SLIDE_DURATION * 0.6)


## Starts the 3-2-1 center countdown before launching or restarting a run.
func _start_countdown(is_restart: bool) -> void:
	_cancel_sequences()
	get_tree().paused = false
	_hide_all()

	if is_restart and has_node("/root/GameManager"):
		get_node("/root/GameManager").reset_game()
	if is_restart and has_node("/root/EventBus"):
		get_node("/root/EventBus").game_restarted.emit()

	_is_counting_down = true
	_countdown_label.visible = true

	_countdown_tween = create_tween()
	for num in ["3", "2", "1"]:
		_countdown_tween.tween_callback(func() -> void:
			_countdown_label.text = num
			_countdown_label.pivot_offset = _countdown_label.size * 0.5
			_countdown_label.scale = Vector2(1.45, 1.45)
			_countdown_label.modulate.a = 1.0
		)
		_countdown_tween.tween_property(_countdown_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_countdown_tween.tween_interval(0.50)
		_countdown_tween.tween_property(_countdown_label, "modulate:a", 0.2, 0.15)

	_countdown_tween.tween_callback(func() -> void:
		_is_counting_down = false
		_countdown_label.visible = false
		if has_node("/root/GameManager"):
			get_node("/root/GameManager").start_game()
	)


func _on_game_started() -> void:
	get_tree().paused = false
	_hide_all()


func _on_game_paused() -> void:
	show_pause_menu()


func _on_game_resumed() -> void:
	get_tree().paused = false
	_hide_all()


func _on_game_over(final_score: int, distance_traveled: float) -> void:
	show_game_over(final_score, distance_traveled, false)


func _on_play_pressed() -> void:
	_start_countdown(false)


func _on_resume_pressed() -> void:
	get_tree().paused = false
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").resume_game()


func _on_restart_pressed() -> void:
	_start_countdown(true)


func _on_menu_pressed() -> void:
	_cancel_sequences()
	get_tree().paused = false
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").reset_game()
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").game_restarted.emit()
	show_main_menu()


func _on_settings_pressed(from_pause: bool) -> void:
	_return_to_pause = from_pause
	_hide_all()
	_backdrop_mode = BackdropMode.PAUSE if from_pause else BackdropMode.MENU
	_backdrop.visible = true
	_backdrop.queue_redraw()
	_settings_panels.show_settings()


func _on_settings_closed() -> void:
	if _return_to_pause:
		show_pause_menu()
	else:
		show_main_menu()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _refresh_translations() -> void:
	_main_menu.title_text = _t("title_main")
	_pause_menu.title_text = _t("title_paused")
	_game_over_panel.title_text = _t("title_gameover")

	if _main_settings_btn != null:
		_main_settings_btn.text = _t("btn_settings")
	if _main_quit_btn != null:
		_main_quit_btn.text = _t("btn_quit")
	if _best_label != null and has_node("/root/GameManager"):
		_best_label.text = "%s: %d" % [_t("lbl_best"), get_node("/root/GameManager").high_score]

	_pause_resume_btn.text = _t("btn_resume")
	_pause_restart_btn.text = _t("btn_restart")
	_pause_settings_btn.text = _t("btn_settings")
	_pause_menu_btn.text = _t("btn_main_menu")

	_go_new_best_label.text = _t("lbl_new_best")
	_go_score_name.text = _t("lbl_score")
	_go_best_name.text = _t("lbl_best")
	_go_dist_name.text = _t("lbl_distance")
	_go_coins_name.text = _t("lbl_coins")
	_go_retry_btn.text = _t("btn_play_again")
	_go_menu_btn.text = _t("btn_main_menu")


func _cancel_sequences() -> void:
	_is_counting_down = false
	if _countdown_tween != null and _countdown_tween.is_valid():
		_countdown_tween.kill()
	if _gameover_tween != null and _gameover_tween.is_valid():
		_gameover_tween.kill()
	if _countdown_label != null:
		_countdown_label.visible = false


func _hide_all() -> void:
	_backdrop.visible = false
	_main_menu.visible = false
	_pause_menu.visible = false
	_game_over_panel.visible = false
	if _settings_panels != null:
		_settings_panels.hide_all()
	if _countdown_label != null and not _is_counting_down:
		_countdown_label.visible = false


func _centered_pos(card_size: Vector2) -> Vector2:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	if vp.x <= 0.0:
		vp = Vector2(1152.0, 648.0)
	return (vp - card_size) * 0.5


## Builds the backdrop, menu cards, settings panels, and countdown label.
func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_backdrop = Control.new()
	_backdrop.name = "Backdrop"
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.draw.connect(_draw_backdrop)
	root.add_child(_backdrop)

	_main_menu = _create_card("MainMenu", _t("title_main"), Vector2(330.0, 400.0), false, false)
	root.add_child(_main_menu)
	_populate_main_menu(_main_menu)

	_pause_menu = _create_card("PauseMenu", _t("title_paused"), Vector2(330.0, 390.0), false, false)
	root.add_child(_pause_menu)
	_populate_pause_menu(_pause_menu)

	_game_over_panel = _create_card("GameOverPanel", _t("title_gameover"), Vector2(350.0, 420.0), true, false)
	root.add_child(_game_over_panel)
	_populate_game_over(_game_over_panel)

	_settings_panels = SettingsPanelsScript.new()
	_settings_panels.build(root, self)
	_settings_panels.closed.connect(_on_settings_closed)

	_countdown_label = Label.new()
	_countdown_label.name = "CountdownLabel"
	_countdown_label.set_anchors_preset(Control.PRESET_CENTER)
	_countdown_label.offset_left = -120.0
	_countdown_label.offset_top = -100.0
	_countdown_label.offset_right = 120.0
	_countdown_label.offset_bottom = 100.0
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.visible = false
	_countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ThemeRef.style_label(_countdown_label, 128, ThemeRef.TEXT_GOLD, 10)
	root.add_child(_countdown_label)


## Draws either the opaque stylized forest vista (Main Menu) or a soft dim overlay.
func _draw_backdrop() -> void:
	var s: Vector2 = _backdrop.size
	if _backdrop_mode == BackdropMode.PAUSE:
		_backdrop.draw_rect(Rect2(Vector2.ZERO, s), Color(0.04, 0.08, 0.06, 0.58), true)
		return
	if _backdrop_mode == BackdropMode.GAME_OVER:
		_backdrop.draw_rect(Rect2(Vector2.ZERO, s), Color(0.02, 0.02, 0.03, 0.38), true)
		return

	var bands: int = 12
	var top_col := Color(0.11, 0.31, 0.36)
	var mid_col := Color(0.26, 0.54, 0.44)
	var bot_col := Color(0.54, 0.74, 0.46)
	for i in range(bands):
		var t: float = float(i) / float(bands - 1)
		var col: Color = top_col.lerp(mid_col, t * 2.0) if t < 0.5 else mid_col.lerp(bot_col, (t - 0.5) * 2.0)
		var y0: float = s.y * float(i) / float(bands)
		var bh: float = s.y / float(bands) + 2.0
		_backdrop.draw_rect(Rect2(0.0, y0, s.x, bh), col, true)

	_backdrop.draw_circle(Vector2(s.x * 0.5, s.y * 0.48), minf(s.x, s.y) * 0.48, Color(1.0, 0.92, 0.62, 0.14))
	_backdrop.draw_circle(Vector2(s.x * 0.5, s.y * 0.48), minf(s.x, s.y) * 0.28, Color(1.0, 0.95, 0.75, 0.12))

	_draw_hill_layer(s, 0.64, 0.06, Color(0.17, 0.39, 0.33))
	_draw_hill_layer(s, 0.74, 0.05, Color(0.12, 0.31, 0.25))
	_draw_hill_layer(s, 0.85, 0.04, Color(0.08, 0.22, 0.17))

	var pine_spots: Array[Array] = [
		[0.06, 0.86, 1.15, Color(0.09, 0.26, 0.20)],
		[0.14, 0.82, 0.85, Color(0.11, 0.31, 0.24)],
		[0.22, 0.88, 0.70, Color(0.08, 0.22, 0.17)],
		[0.78, 0.87, 0.75, Color(0.08, 0.22, 0.17)],
		[0.86, 0.83, 0.95, Color(0.11, 0.31, 0.24)],
		[0.94, 0.86, 1.20, Color(0.09, 0.26, 0.20)],
	]
	for p in pine_spots:
		_draw_pine(Vector2(s.x * p[0], s.y * p[1]), s.y * 0.18 * p[2], p[3])

	var sparks: Array[Vector2] = [
		Vector2(0.16, 0.32), Vector2(0.24, 0.54), Vector2(0.12, 0.62),
		Vector2(0.84, 0.28), Vector2(0.76, 0.48), Vector2(0.88, 0.60),
		Vector2(0.32, 0.22), Vector2(0.68, 0.20),
	]
	for sp in sparks:
		var pos := Vector2(s.x * sp.x, s.y * sp.y)
		_backdrop.draw_circle(pos, 7.0, Color(1.0, 0.90, 0.45, 0.16))
		_backdrop.draw_circle(pos, 2.8, Color(1.0, 0.95, 0.70, 0.55))


func _draw_hill_layer(s: Vector2, base_y_ratio: float, wave_amp: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var steps: int = 24
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var y: float = s.y * (base_y_ratio + sin(t * PI * 2.2 + base_y_ratio * 8.0) * wave_amp)
		pts.append(Vector2(s.x * t, y))
	pts.append(Vector2(s.x, s.y))
	pts.append(Vector2(0.0, s.y))
	_backdrop.draw_colored_polygon(pts, color)


func _draw_pine(base: Vector2, height: float, color: Color) -> void:
	var w: float = height * 0.45
	for tier in range(3):
		var y_bot: float = base.y - height * (0.18 + float(tier) * 0.24)
		var y_top: float = y_bot - height * 0.42
		var tier_w: float = w * (1.0 - float(tier) * 0.22)
		var tri := PackedVector2Array([
			Vector2(base.x, y_top),
			Vector2(base.x + tier_w, y_bot),
			Vector2(base.x - tier_w, y_bot),
		])
		_backdrop.draw_colored_polygon(tri, color)


func _create_card(node_name: String, title: String, card_size: Vector2, inset: bool, close_tab: bool) -> Control:
	var card: Control = NotebookCardScript.new()
	card.name = node_name
	card.title_text = title
	card.show_inset = inset
	card.show_close_tab = close_tab
	card.size = card_size
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -card_size.x * 0.5
	card.offset_top = -card_size.y * 0.5
	card.offset_right = card_size.x * 0.5
	card.offset_bottom = card_size.y * 0.5
	return card


func _populate_main_menu(card: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(44.0, 102.0)
	vbox.size = Vector2(card.size.x - 88.0, card.size.y - 126.0)
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	var play_wrap := CenterContainer.new()
	vbox.add_child(play_wrap)
	var play_btn := _create_play_circle_button()
	play_btn.name = "PlayButton"
	play_btn.pressed.connect(_on_play_pressed)
	play_wrap.add_child(play_btn)

	_best_label = Label.new()
	_best_label.name = "BestLabel"
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeRef.style_label(_best_label, 18, ThemeRef.TEXT_GOLD, 4)
	_best_label.visible = false
	vbox.add_child(_best_label)

	_main_settings_btn = _make_button("SettingsButton", _t("btn_settings"), false)
	_main_settings_btn.pressed.connect(func() -> void: _on_settings_pressed(false))
	vbox.add_child(_main_settings_btn)

	if not OS.has_feature("web"):
		_main_quit_btn = _make_button("QuitButton", _t("btn_quit"), false)
		_main_quit_btn.pressed.connect(_on_quit_pressed)
		vbox.add_child(_main_quit_btn)


func _populate_pause_menu(card: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(44.0, 102.0)
	vbox.size = Vector2(card.size.x - 88.0, card.size.y - 126.0)
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	_pause_resume_btn = _make_button("ResumeButton", _t("btn_resume"), true)
	_pause_resume_btn.pressed.connect(_on_resume_pressed)
	vbox.add_child(_pause_resume_btn)

	_pause_restart_btn = _make_button("RestartButton", _t("btn_restart"), false)
	_pause_restart_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(_pause_restart_btn)

	_pause_settings_btn = _make_button("PauseSettingsButton", _t("btn_settings"), false)
	_pause_settings_btn.pressed.connect(func() -> void: _on_settings_pressed(true))
	vbox.add_child(_pause_settings_btn)

	_pause_menu_btn = _make_button("PauseMenuButton", _t("btn_main_menu"), false)
	_pause_menu_btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(_pause_menu_btn)


func _populate_game_over(card: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(46.0, 106.0)
	vbox.size = Vector2(card.size.x - 92.0, card.size.y - 130.0)
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	_go_new_best_label = Label.new()
	_go_new_best_label.text = _t("lbl_new_best")
	_go_new_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeRef.style_label(_go_new_best_label, 18, ThemeRef.TEXT_GOLD, 4)
	_go_new_best_label.visible = false
	vbox.add_child(_go_new_best_label)

	var score_pair: Array[Label] = _add_stat_row(vbox, _t("lbl_score"))
	_go_score_name = score_pair[0]
	_go_score_value = score_pair[1]
	var best_pair: Array[Label] = _add_stat_row(vbox, _t("lbl_best"))
	_go_best_name = best_pair[0]
	_go_best_value = best_pair[1]
	var dist_pair: Array[Label] = _add_stat_row(vbox, _t("lbl_distance"))
	_go_dist_name = dist_pair[0]
	_go_distance_value = dist_pair[1]
	var coin_pair: Array[Label] = _add_stat_row(vbox, _t("lbl_coins"))
	_go_coins_name = coin_pair[0]
	_go_coins_value = coin_pair[1]

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	_go_retry_btn = _make_button("RetryButton", _t("btn_play_again"), true)
	_go_retry_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(_go_retry_btn)

	_go_menu_btn = _make_button("GameOverMenuButton", _t("btn_main_menu"), false)
	_go_menu_btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(_go_menu_btn)


func _add_stat_row(parent: VBoxContainer, label_text: String) -> Array[Label]:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)

	var name_lbl := Label.new()
	name_lbl.text = label_text
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeRef.style_label(name_lbl, 18, ThemeRef.TEXT_WHITE, 3)
	hbox.add_child(name_lbl)

	var val_lbl := Label.new()
	val_lbl.text = "0"
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ThemeRef.style_label(val_lbl, 22, ThemeRef.TEXT_GOLD, 4)
	hbox.add_child(val_lbl)
	return [name_lbl, val_lbl]


func _make_button(btn_name: String, label: String, is_primary: bool) -> Button:
	var btn := Button.new()
	btn.name = btn_name
	btn.text = label
	btn.custom_minimum_size = Vector2(0.0, 48.0)
	ThemeRef.style_button(btn, is_primary, 20)
	return btn


## Creates the iconic circular green Play button with a soft drop shadow and glossy highlight.
func _create_play_circle_button() -> BaseButton:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(96.0, 96.0)
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.draw.connect(func() -> void:
		var center := btn.size * 0.5
		var r: float = 42.0
		var fill: Color = ThemeRef.GREEN_HOVER if btn.is_hovered() else ThemeRef.GREEN_FILL
		if btn.button_pressed:
			fill = ThemeRef.GREEN_PRESSED
		btn.draw_circle(center + Vector2(0.0, 7.0), r + 1.0, Color(0.12, 0.06, 0.02, 0.28))
		btn.draw_circle(center + Vector2(0.0, 5.0), r, ThemeRef.GREEN_LIP)
		btn.draw_circle(center, r, fill)
		btn.draw_arc(center - Vector2(0.0, 2.0), r - 6.0, PI * 1.15, PI * 1.75, 16, Color(0.80, 1.0, 0.62, 0.55), 5.0, true)
		var tri := PackedVector2Array([
			center + Vector2(-10.0, -17.0),
			center + Vector2(19.0, 0.0),
			center + Vector2(-10.0, 17.0),
		])
		btn.draw_colored_polygon(tri, ThemeRef.TEXT_WHITE)
	)
	return btn


func _t(key: String) -> String:
	if has_node("/root/SettingsManager"):
		return get_node("/root/SettingsManager").t(key)
	return key
