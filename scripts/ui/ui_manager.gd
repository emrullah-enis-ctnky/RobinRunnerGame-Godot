class_name UIManager
extends CanvasLayer
## Coordinates Main Menu, Controls, Pause, and Game Over screens using the unified notebook theme.

const ThemeRef = preload("res://scripts/ui/notebook_ui_theme.gd")
const NotebookCardScript = preload("res://scripts/ui/notebook_card.gd")

const BACKDROP_MENU: Color = Color(0.05, 0.12, 0.08, 0.28)
const BACKDROP_PAUSE: Color = Color(0.04, 0.08, 0.06, 0.56)
const BACKDROP_GAMEOVER: Color = Color(0.03, 0.03, 0.04, 0.48)

var _backdrop: ColorRect
var _main_menu: Control
var _controls_panel: Control
var _pause_menu: Control
var _game_over_panel: Control

var _best_label: Label
var _go_score_value: Label
var _go_best_value: Label
var _go_new_best_label: Label
var _go_distance_value: Label
var _go_coins_value: Label

var _return_to_pause: bool = false
var _last_high_score: int = 0


## Builds all menu cards, binds EventBus signals, and syncs to the initial READY state.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_build_ui()

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.game_started.connect(_on_game_started)
		bus.game_restarted.connect(_on_game_started)
		bus.game_paused.connect(_on_game_paused)
		bus.game_resumed.connect(_on_game_resumed)
		bus.game_over.connect(_on_game_over)

	if has_node("/root/GameManager"):
		_last_high_score = get_node("/root/GameManager").high_score
	show_main_menu()


## Handles Esc / P pause toggling during active gameplay or pause.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if not has_node("/root/GameManager"):
		return
	var gm: Node = get_node("/root/GameManager")
	if gm.current_state == gm.GameState.PLAYING:
		get_tree().paused = true
		gm.pause_game()
		get_viewport().set_input_as_handled()
	elif gm.current_state == gm.GameState.PAUSED:
		if _controls_panel != null and _controls_panel.visible:
			_close_controls()
		else:
			get_tree().paused = false
			gm.resume_game()
		get_viewport().set_input_as_handled()


## Shows the Main Menu floating over the live 3D forest world.
func show_main_menu() -> void:
	_hide_all()
	_backdrop.color = BACKDROP_MENU
	_backdrop.visible = true
	if _best_label != null and has_node("/root/GameManager"):
		var hs: int = get_node("/root/GameManager").high_score
		_best_label.visible = hs > 0
		_best_label.text = "BEST: %d" % hs
	_main_menu.visible = true


## Shows the Pause Menu over the paused 3D world.
func show_pause_menu() -> void:
	_hide_all()
	_backdrop.color = BACKDROP_PAUSE
	_backdrop.visible = true
	_pause_menu.visible = true


## Shows the Game Over summary card with final score, distance, coins, and best score.
func show_game_over(final_score: int, distance_traveled: float) -> void:
	_hide_all()
	_backdrop.color = BACKDROP_GAMEOVER
	_backdrop.visible = true

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
	_game_over_panel.visible = true


## Hides all menus when gameplay is active.
func _on_game_started() -> void:
	get_tree().paused = false
	_hide_all()


func _on_game_paused() -> void:
	show_pause_menu()


func _on_game_resumed() -> void:
	get_tree().paused = false
	_hide_all()


func _on_game_over(final_score: int, distance_traveled: float) -> void:
	show_game_over(final_score, distance_traveled)


func _on_play_pressed() -> void:
	get_tree().paused = false
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").start_game()


func _on_resume_pressed() -> void:
	get_tree().paused = false
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").resume_game()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").restart_game()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").reset_game()
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").game_restarted.emit()
	show_main_menu()


func _on_controls_pressed(from_pause: bool) -> void:
	_return_to_pause = from_pause
	_hide_all()
	_backdrop.color = BACKDROP_PAUSE if from_pause else BACKDROP_MENU
	_backdrop.visible = true
	_controls_panel.visible = true


func _close_controls() -> void:
	if _return_to_pause:
		show_pause_menu()
	else:
		show_main_menu()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _hide_all() -> void:
	_backdrop.visible = false
	_main_menu.visible = false
	_controls_panel.visible = false
	_pause_menu.visible = false
	_game_over_panel.visible = false


## Builds the full-screen backdrop and the four consistent notebook cards.
func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = BACKDROP_MENU
	root.add_child(_backdrop)

	_main_menu = _create_card("MainMenu", "ROBIN RUNNER", Vector2(320.0, 390.0), false, false)
	root.add_child(_main_menu)
	_populate_main_menu(_main_menu)

	_controls_panel = _create_card("ControlsPanel", "CONTROLS", Vector2(360.0, 410.0), true, true)
	_controls_panel.close_requested.connect(_close_controls)
	root.add_child(_controls_panel)
	_populate_controls(_controls_panel)

	_pause_menu = _create_card("PauseMenu", "PAUSED", Vector2(320.0, 380.0), false, false)
	root.add_child(_pause_menu)
	_populate_pause_menu(_pause_menu)

	_game_over_panel = _create_card("GameOverPanel", "GAME OVER", Vector2(340.0, 410.0), true, false)
	root.add_child(_game_over_panel)
	_populate_game_over(_game_over_panel)


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
	vbox.position = Vector2(40.0, 96.0)
	vbox.size = Vector2(card.size.x - 80.0, card.size.y - 120.0)
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

	var controls_btn := _make_button("ControlsButton", "CONTROLS", false)
	controls_btn.pressed.connect(func() -> void: _on_controls_pressed(false))
	vbox.add_child(controls_btn)

	if not OS.has_feature("web"):
		var quit_btn := _make_button("QuitButton", "QUIT", false)
		quit_btn.pressed.connect(_on_quit_pressed)
		vbox.add_child(quit_btn)


func _populate_controls(card: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(44.0, 108.0)
	vbox.size = Vector2(card.size.x - 88.0, card.size.y - 134.0)
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	var rows: Array[Array] = [
		["Move", "A / D  or  Arrows"],
		["Jump", "Space / W / Up"],
		["Duck / Slide", "S / Down"],
		["Shoot Arrow", "F / Left Click"],
		["Pause", "Esc / P"],
	]
	for pair in rows:
		var hbox := HBoxContainer.new()
		vbox.add_child(hbox)
		var action_lbl := Label.new()
		action_lbl.text = pair[0]
		action_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeRef.style_label(action_lbl, 17, ThemeRef.TEXT_WHITE, 3)
		hbox.add_child(action_lbl)

		var key_lbl := Label.new()
		key_lbl.text = pair[1]
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ThemeRef.style_label(key_lbl, 16, ThemeRef.TEXT_GOLD, 3)
		hbox.add_child(key_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var back_btn := _make_button("BackButton", "BACK", true)
	back_btn.pressed.connect(_close_controls)
	vbox.add_child(back_btn)


func _populate_pause_menu(card: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(40.0, 98.0)
	vbox.size = Vector2(card.size.x - 80.0, card.size.y - 122.0)
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	var resume_btn := _make_button("ResumeButton", "RESUME", true)
	resume_btn.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume_btn)

	var restart_btn := _make_button("RestartButton", "RESTART", false)
	restart_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_btn)

	var controls_btn := _make_button("PauseControlsButton", "CONTROLS", false)
	controls_btn.pressed.connect(func() -> void: _on_controls_pressed(true))
	vbox.add_child(controls_btn)

	var menu_btn := _make_button("PauseMenuButton", "MAIN MENU", false)
	menu_btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(menu_btn)


func _populate_game_over(card: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(44.0, 102.0)
	vbox.size = Vector2(card.size.x - 88.0, card.size.y - 126.0)
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	_go_new_best_label = Label.new()
	_go_new_best_label.text = "NEW HIGH SCORE!"
	_go_new_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeRef.style_label(_go_new_best_label, 18, ThemeRef.TEXT_GOLD, 4)
	_go_new_best_label.visible = false
	vbox.add_child(_go_new_best_label)

	_go_score_value = _add_stat_row(vbox, "SCORE")
	_go_best_value = _add_stat_row(vbox, "BEST")
	_go_distance_value = _add_stat_row(vbox, "DISTANCE")
	_go_coins_value = _add_stat_row(vbox, "COINS")

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var retry_btn := _make_button("RetryButton", "PLAY AGAIN", true)
	retry_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(retry_btn)

	var menu_btn := _make_button("GameOverMenuButton", "MAIN MENU", false)
	menu_btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(menu_btn)


func _add_stat_row(parent: VBoxContainer, label_text: String) -> Label:
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
	return val_lbl


func _make_button(btn_name: String, label: String, is_primary: bool) -> Button:
	var btn := Button.new()
	btn.name = btn_name
	btn.text = label
	btn.custom_minimum_size = Vector2(0.0, 46.0)
	ThemeRef.style_button(btn, is_primary, 20)
	return btn


## Creates the iconic circular green Play button with a cream triangle icon.
func _create_play_circle_button() -> BaseButton:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(88.0, 88.0)
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.draw.connect(func() -> void:
		var center := btn.size * 0.5
		var r: float = 40.0
		var fill: Color = ThemeRef.GREEN_HOVER if btn.is_hovered() else ThemeRef.GREEN_FILL
		if btn.button_pressed:
			fill = ThemeRef.GREEN_PRESSED
		btn.draw_circle(center + Vector2(0.0, 4.0), r, ThemeRef.GREEN_LIP)
		btn.draw_circle(center, r, fill)
		btn.draw_arc(center - Vector2(0.0, 2.0), r - 5.0, PI * 1.15, PI * 1.75, 14, Color(0.75, 1.0, 0.55, 0.6), 4.0, true)
		var tri := PackedVector2Array([
			center + Vector2(-10.0, -16.0),
			center + Vector2(18.0, 0.0),
			center + Vector2(-10.0, 16.0),
		])
		btn.draw_colored_polygon(tri, ThemeRef.TEXT_WHITE)
	)
	return btn
