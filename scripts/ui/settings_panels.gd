class_name SettingsPanels
extends RefCounted
## Builds and manages the Settings, Language (with flags), and interactive Controls notebook panels.

const ThemeRef = preload("res://scripts/ui/notebook_ui_theme.gd")
const NotebookCardScript = preload("res://scripts/ui/notebook_card.gd")

signal closed

var settings_card: Control
var language_card: Control
var controls_card: Control
var display_card: Control

var _music_slider: HSlider
var _sfx_slider: HSlider
var _music_mute_btn: Button
var _sfx_mute_btn: Button
var _music_lbl: Label
var _sfx_lbl: Label
var _display_btn: Button
var _controls_btn: Button
var _language_btn: Button

var _mode_lbl: Label
var _windowed_btn: Button
var _fullscreen_btn: Button
var _res_lbl: Label
var _res_value_lbl: Label
var _res_prev_btn: Button
var _res_next_btn: Button

var _lang_buttons: Dictionary = {}

var _controls_rows_root: VBoxContainer
var _capture_banner: Label
var _reset_btn: Button

var _capturing_action: String = ""
var _owner_node: Node


## Instantiates all three panels under root and binds SettingsManager signals.
func build(root: Control, owner: Node) -> void:
	_owner_node = owner

	settings_card = _make_card("SettingsPanel", _t("title_settings"), Vector2(360.0, 440.0))
	settings_card.close_requested.connect(_on_close_settings)
	root.add_child(settings_card)
	_populate_settings(settings_card)

	display_card = _make_card("DisplayPanel", _t("title_display"), Vector2(390.0, 355.0))
	display_card.close_requested.connect(show_settings)
	root.add_child(display_card)
	_populate_display(display_card)

	language_card = _make_card("LanguagePanel", _t("title_language"), Vector2(360.0, 345.0))
	language_card.close_requested.connect(show_settings)
	root.add_child(language_card)
	_populate_language(language_card)

	controls_card = _make_card("ControlsPanel", _t("title_controls"), Vector2(490.0, 480.0))
	controls_card.close_requested.connect(show_settings)
	root.add_child(controls_card)
	_populate_controls(controls_card)

	hide_all()

	var sm: Node = _settings()
	if sm != null:
		sm.language_changed.connect(func(_l: String) -> void: refresh_texts())
		sm.controls_changed.connect(_rebuild_controls_rows)
		sm.settings_changed.connect(_sync_audio_controls)


func is_any_visible() -> bool:
	return settings_card.visible or language_card.visible or controls_card.visible or display_card.visible


func is_capturing_key() -> bool:
	return not _capturing_action.is_empty()


func hide_all() -> void:
	_capturing_action = ""
	if _capture_banner != null:
		_capture_banner.visible = false
	settings_card.visible = false
	language_card.visible = false
	controls_card.visible = false
	display_card.visible = false


func show_settings() -> void:
	hide_all()
	_sync_audio_controls()
	refresh_texts()
	settings_card.visible = true
	if _music_slider != null:
		_music_slider.call_deferred("grab_focus")


func show_display() -> void:
	hide_all()
	_refresh_display_controls()
	display_card.visible = true
	if _windowed_btn != null:
		_windowed_btn.call_deferred("grab_focus")


func show_language() -> void:
	hide_all()
	_refresh_language_selection()
	language_card.visible = true
	var sm: Node = _settings()
	var active: String = sm.language if sm != null else "en"
	if _lang_buttons.has(active):
		(_lang_buttons[active] as Control).call_deferred("grab_focus")


func show_controls() -> void:
	hide_all()
	_rebuild_controls_rows()
	controls_card.visible = true
	if _reset_btn != null:
		_reset_btn.call_deferred("grab_focus")


## Steps back one level on Esc/Cancel (sub-panel -> Settings -> close). Returns true if handled.
func navigate_back() -> bool:
	if display_card.visible or language_card.visible or controls_card.visible:
		_play_click()
		show_settings()
		return true
	if settings_card.visible:
		_play_click()
		_on_close_settings()
		return true
	return false


## Handles key/mouse capture when adding a new binding to an action. Returns true if consumed.
func handle_input(event: InputEvent) -> bool:
	if _capturing_action.is_empty():
		return false

	if event is InputEventKey:
		var k: InputEventKey = event as InputEventKey
		if not k.pressed or k.echo:
			return true
		if k.keycode == KEY_ESCAPE:
			_stop_capture()
			return true
		var bound := InputEventKey.new()
		bound.keycode = k.keycode if k.keycode != KEY_NONE else k.physical_keycode
		var sm: Node = _settings()
		if sm != null:
			sm.add_action_event(_capturing_action, bound)
			sm.save_settings()
		_stop_capture()
		return true

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if not mb.pressed:
			return true
		var bound_m := InputEventMouseButton.new()
		bound_m.button_index = mb.button_index
		var sm: Node = _settings()
		if sm != null:
			sm.add_action_event(_capturing_action, bound_m)
			sm.save_settings()
		_stop_capture()
		return true

	return false


## Updates all labels and button texts to match the active language.
func refresh_texts() -> void:
	settings_card.title_text = _t("title_settings")
	display_card.title_text = _t("title_display")
	language_card.title_text = _t("title_language")
	controls_card.title_text = _t("title_controls")

	_music_lbl.text = _t("lbl_music")
	_sfx_lbl.text = _t("lbl_sfx")
	_display_btn.text = _t("btn_display")
	_controls_btn.text = _t("btn_controls")
	_language_btn.text = _t("btn_language")
	_mode_lbl.text = _t("lbl_window_mode")
	_windowed_btn.text = _t("mode_windowed")
	_fullscreen_btn.text = _t("mode_fullscreen")
	_res_lbl.text = _t("lbl_resolution")
	_reset_btn.text = _t("btn_reset_defaults")
	_capture_banner.text = _t("lbl_press_key")
	_refresh_language_selection()
	_refresh_display_controls()
	_rebuild_controls_rows()


func _populate_settings(card: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(44.0, 110.0)
	vbox.size = Vector2(card.size.x - 88.0, card.size.y - 138.0)
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	# Music Row
	_music_lbl = Label.new()
	ThemeRef.style_label(_music_lbl, 15, ThemeRef.TEXT_WHITE, 3)
	vbox.add_child(_music_lbl)

	var music_row := HBoxContainer.new()
	music_row.add_theme_constant_override("separation", 12)
	vbox.add_child(music_row)

	_music_slider = HSlider.new()
	_music_slider.min_value = 0.0
	_music_slider.max_value = 100.0
	_music_slider.step = 1.0
	_music_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_music_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ThemeRef.style_slider(_music_slider)
	_music_slider.value_changed.connect(func(v: float) -> void:
		var sm: Node = _settings()
		if sm != null:
			sm.set_music_volume(v / 100.0)
	)
	music_row.add_child(_music_slider)

	_music_mute_btn = _create_audio_icon_button(true)
	_music_mute_btn.pressed.connect(func() -> void:
		var sm: Node = _settings()
		if sm != null:
			sm.set_music_muted(not sm.music_muted)
	)
	music_row.add_child(_music_mute_btn)

	# SFX Row
	_sfx_lbl = Label.new()
	ThemeRef.style_label(_sfx_lbl, 15, ThemeRef.TEXT_WHITE, 3)
	vbox.add_child(_sfx_lbl)

	var sfx_row := HBoxContainer.new()
	sfx_row.add_theme_constant_override("separation", 12)
	vbox.add_child(sfx_row)

	_sfx_slider = HSlider.new()
	_sfx_slider.min_value = 0.0
	_sfx_slider.max_value = 100.0
	_sfx_slider.step = 1.0
	_sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sfx_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ThemeRef.style_slider(_sfx_slider)
	_sfx_slider.value_changed.connect(func(v: float) -> void:
		var sm: Node = _settings()
		if sm != null:
			sm.set_sfx_volume(v / 100.0)
	)
	sfx_row.add_child(_sfx_slider)

	_sfx_mute_btn = _create_audio_icon_button(false)
	_sfx_mute_btn.pressed.connect(func() -> void:
		var sm: Node = _settings()
		if sm != null:
			sm.set_sfx_muted(not sm.sfx_muted)
	)
	sfx_row.add_child(_sfx_mute_btn)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 4.0)
	vbox.add_child(gap)

	_display_btn = _make_button("DisplayButton", _t("btn_display"), false, 19)
	_display_btn.pressed.connect(show_display)
	vbox.add_child(_display_btn)

	_controls_btn = _make_button("ControlsButton", _t("btn_controls"), false, 19)
	_controls_btn.pressed.connect(show_controls)
	vbox.add_child(_controls_btn)

	_language_btn = _make_button("LanguageButton", _t("btn_language"), false, 19)
	_language_btn.pressed.connect(show_language)
	vbox.add_child(_language_btn)


func _populate_display(card: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(44.0, 114.0)
	vbox.size = Vector2(card.size.x - 88.0, card.size.y - 142.0)
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	_mode_lbl = Label.new()
	ThemeRef.style_label(_mode_lbl, 16, ThemeRef.TEXT_WHITE, 3)
	vbox.add_child(_mode_lbl)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 10)
	vbox.add_child(mode_row)

	_windowed_btn = _make_button("WindowedButton", _t("mode_windowed"), false, 16)
	_windowed_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_windowed_btn.pressed.connect(func() -> void:
		var sm: Node = _settings()
		if sm != null:
			sm.set_fullscreen(false)
			_refresh_display_controls()
	)
	mode_row.add_child(_windowed_btn)

	_fullscreen_btn = _make_button("FullscreenButton", _t("mode_fullscreen"), false, 16)
	_fullscreen_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fullscreen_btn.pressed.connect(func() -> void:
		var sm: Node = _settings()
		if sm != null:
			sm.set_fullscreen(true)
			_refresh_display_controls()
	)
	mode_row.add_child(_fullscreen_btn)

	_res_lbl = Label.new()
	ThemeRef.style_label(_res_lbl, 16, ThemeRef.TEXT_WHITE, 3)
	vbox.add_child(_res_lbl)

	var res_row := HBoxContainer.new()
	res_row.add_theme_constant_override("separation", 10)
	vbox.add_child(res_row)

	_res_prev_btn = _make_button("ResPrevButton", "<", false, 20)
	_res_prev_btn.custom_minimum_size = Vector2(46.0, 44.0)
	_res_prev_btn.pressed.connect(func() -> void: _step_resolution(-1))
	res_row.add_child(_res_prev_btn)

	_res_value_lbl = Label.new()
	_res_value_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_res_value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_res_value_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ThemeRef.style_label(_res_value_lbl, 20, ThemeRef.TEXT_GOLD, 4)
	res_row.add_child(_res_value_lbl)

	_res_next_btn = _make_button("ResNextButton", ">", false, 20)
	_res_next_btn.custom_minimum_size = Vector2(46.0, 44.0)
	_res_next_btn.pressed.connect(func() -> void: _step_resolution(1))
	res_row.add_child(_res_next_btn)


func _step_resolution(delta: int) -> void:
	var sm: Node = _settings()
	if sm == null:
		return
	var avail: Array[Vector2i] = sm.get_available_resolutions()
	if avail.is_empty():
		return
	var idx: int = avail.find(sm.resolution)
	if idx < 0:
		idx = avail.size() - 1
	idx = clampi(idx + delta, 0, avail.size() - 1)
	sm.set_resolution(avail[idx])
	_refresh_display_controls()


func _refresh_display_controls() -> void:
	var sm: Node = _settings()
	if sm == null or _res_value_lbl == null:
		return
	ThemeRef.style_button(_windowed_btn, not sm.fullscreen, 16)
	ThemeRef.style_button(_fullscreen_btn, sm.fullscreen, 16)
	var avail: Array[Vector2i] = sm.get_available_resolutions()
	if sm.fullscreen:
		var native_res: Vector2i = DisplayServer.screen_get_size()
		if native_res.x > 0 and native_res.y > 0:
			_res_value_lbl.text = "%d x %d" % [native_res.x, native_res.y]
		else:
			_res_value_lbl.text = "%d x %d" % [sm.resolution.x, sm.resolution.y]
		_res_prev_btn.disabled = true
		_res_next_btn.disabled = true
	else:
		_res_value_lbl.text = "%d x %d" % [sm.resolution.x, sm.resolution.y]
		var idx: int = avail.find(sm.resolution)
		_res_prev_btn.disabled = (idx <= 0)
		_res_next_btn.disabled = (idx < 0 or idx >= avail.size() - 1)


func _populate_language(card: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(44.0, 112.0)
	vbox.size = Vector2(card.size.x - 88.0, card.size.y - 140.0)
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	var langs: Array[Array] = [
		["en", "English"],
		["tr", "Türkçe"],
		["de", "Deutsch"],
	]
	for entry in langs:
		var code: String = entry[0]
		var label: String = entry[1]
		var btn := _create_flag_language_button(code, label)
		btn.pressed.connect(func() -> void:
			var sm: Node = _settings()
			if sm != null:
				sm.set_language(code)
				sm.save_settings()
		)
		_lang_buttons[code] = btn
		vbox.add_child(btn)


func _populate_controls(card: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(40.0, 108.0)
	vbox.size = Vector2(card.size.x - 80.0, card.size.y - 134.0)
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	_capture_banner = Label.new()
	_capture_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_capture_banner.visible = false
	ThemeRef.style_label(_capture_banner, 17, ThemeRef.TEXT_GOLD, 4)
	vbox.add_child(_capture_banner)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_controls_rows_root = VBoxContainer.new()
	_controls_rows_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_controls_rows_root.add_theme_constant_override("separation", 8)
	scroll.add_child(_controls_rows_root)

	_reset_btn = _make_button("ResetDefaultsButton", _t("btn_reset_defaults"), false, 17)
	_reset_btn.pressed.connect(func() -> void:
		var sm: Node = _settings()
		if sm != null:
			sm.reset_controls_to_defaults()
	)
	vbox.add_child(_reset_btn)


func _rebuild_controls_rows() -> void:
	if _controls_rows_root == null:
		return
	for child in _controls_rows_root.get_children():
		child.queue_free()

	var sm: Node = _settings()
	if sm == null:
		return

	for action in sm.MANAGED_ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_controls_rows_root.add_child(row)

		var name_lbl := Label.new()
		name_lbl.text = _t("act_" + action)
		name_lbl.custom_minimum_size = Vector2(126.0, 34.0)
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ThemeRef.style_label(name_lbl, 16, ThemeRef.TEXT_WHITE, 3)
		row.add_child(name_lbl)

		var keys_box := HBoxContainer.new()
		keys_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		keys_box.add_theme_constant_override("separation", 6)
		row.add_child(keys_box)

		var events: Array[InputEvent] = InputMap.action_get_events(action)
		for i in range(events.size()):
			var chip := Button.new()
			var key_text: String = sm.format_event(events[i])
			chip.text = (key_text + " ×") if events.size() > 1 else key_text
			chip.custom_minimum_size = Vector2(0.0, 34.0)
			ThemeRef.style_button(chip, false, 14)
			var idx: int = i
			var act: String = action
			chip.pressed.connect(func() -> void:
				_play_click()
				sm.remove_action_event(act, idx)
				sm.save_settings()
			)
			keys_box.add_child(chip)

		var add_btn := Button.new()
		add_btn.text = "+"
		add_btn.custom_minimum_size = Vector2(36.0, 34.0)
		ThemeRef.style_button(add_btn, true, 18)
		var cap_act: String = action
		add_btn.pressed.connect(func() -> void:
			_play_click()
			_start_capture(cap_act)
		)
		row.add_child(add_btn)


func _start_capture(action: String) -> void:
	_capturing_action = action
	if _capture_banner != null:
		_capture_banner.text = "%s (%s)" % [_t("lbl_press_key"), _t("act_" + action)]
		_capture_banner.visible = true


func _stop_capture() -> void:
	_capturing_action = ""
	if _capture_banner != null:
		_capture_banner.visible = false


func _sync_audio_controls() -> void:
	var sm: Node = _settings()
	if sm == null:
		return
	if _music_slider != null:
		_music_slider.set_value_no_signal(0.0 if sm.music_muted else sm.music_volume * 100.0)
	if _sfx_slider != null:
		_sfx_slider.set_value_no_signal(0.0 if sm.sfx_muted else sm.sfx_volume * 100.0)
	if _music_mute_btn != null:
		_music_mute_btn.queue_redraw()
	if _sfx_mute_btn != null:
		_sfx_mute_btn.queue_redraw()


func _refresh_language_selection() -> void:
	var sm: Node = _settings()
	var active: String = sm.language if sm != null else "en"
	for code in _lang_buttons.keys():
		var btn: Button = _lang_buttons[code]
		ThemeRef.style_button(btn, code == active, 20)
		btn.queue_redraw()


func _on_close_settings() -> void:
	hide_all()
	closed.emit()


## Creates the template's golden-orange circular Music Note / Speaker mute toggle button.
func _create_audio_icon_button(is_music: bool) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(44.0, 44.0)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_ALL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.focus_entered.connect(btn.queue_redraw)
	btn.focus_exited.connect(btn.queue_redraw)
	btn.pressed.connect(_play_click)
	btn.draw.connect(func() -> void:
		var sm: Node = _settings()
		var muted: bool = false
		if sm != null:
			muted = sm.music_muted if is_music else sm.sfx_muted
		var c := btn.size * 0.5
		var r: float = 19.0
		var fill: Color = Color(0.55, 0.45, 0.45) if muted else ThemeRef.BANNER_GOLD
		var lip: Color = Color(0.35, 0.25, 0.25) if muted else ThemeRef.ORANGE_LIP
		if btn.has_focus():
			btn.draw_arc(c, r + 3.0, 0.0, TAU, 24, Color(1.0, 0.94, 0.45), 3.0, true)
		btn.draw_circle(c + Vector2(0.0, 3.0), r, lip)
		btn.draw_circle(c, r, fill)
		if is_music:
			# Eighth note glyph
			btn.draw_circle(c + Vector2(-4.0, 6.0), 4.5, ThemeRef.TEXT_DARK)
			btn.draw_line(c + Vector2(0.0, 6.0), c + Vector2(0.0, -8.0), ThemeRef.TEXT_DARK, 3.0, true)
			btn.draw_line(c + Vector2(0.0, -8.0), c + Vector2(8.0, -4.0), ThemeRef.TEXT_DARK, 3.0, true)
		else:
			# Speaker cone + waves
			var cone := PackedVector2Array([
				c + Vector2(-9.0, -4.0), c + Vector2(-4.0, -4.0),
				c + Vector2(2.0, -9.0), c + Vector2(2.0, 9.0),
				c + Vector2(-4.0, 4.0), c + Vector2(-9.0, 4.0),
			])
			btn.draw_colored_polygon(cone, ThemeRef.TEXT_DARK)
			if not muted:
				btn.draw_arc(c + Vector2(3.0, 0.0), 5.5, -0.7, 0.7, 8, ThemeRef.TEXT_DARK, 2.2, true)
				btn.draw_arc(c + Vector2(3.0, 0.0), 9.5, -0.7, 0.7, 8, ThemeRef.TEXT_DARK, 2.2, true)
		if muted:
			btn.draw_line(c + Vector2(-11.0, -11.0), c + Vector2(11.0, 11.0), ThemeRef.RIBBON_RED, 3.5, true)
	)
	return btn


## Creates a language selection button with a crisp procedurally drawn country flag on the left.
func _create_flag_language_button(lang_code: String, display_name: String) -> Button:
	var btn := Button.new()
	btn.name = "LangBtn_" + lang_code
	btn.text = "        " + display_name
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0.0, 52.0)
	ThemeRef.style_button(btn, false, 20)
	btn.pressed.connect(_play_click)
	btn.draw.connect(func() -> void:
		var flag_rect := Rect2(16.0, (btn.size.y - 26.0) * 0.5 - 2.0, 40.0, 26.0)
		_draw_flag(btn, flag_rect, lang_code)
	)
	return btn


## Draws stylized UK, Turkish, or German flags inside rect with a clean dark outline.
func _draw_flag(canvas: CanvasItem, r: Rect2, code: String) -> void:
	canvas.draw_rect(r.grow(1.5), ThemeRef.OUTLINE_COLOR, true)
	if code == "tr":
		canvas.draw_rect(r, Color(0.89, 0.04, 0.09), true)
		var moon_c := Vector2(r.position.x + r.size.x * 0.40, r.position.y + r.size.y * 0.50)
		canvas.draw_circle(moon_c, r.size.y * 0.28, Color.WHITE)
		canvas.draw_circle(moon_c + Vector2(r.size.y * 0.09, 0.0), r.size.y * 0.22, Color(0.89, 0.04, 0.09))
		var star_c := Vector2(r.position.x + r.size.x * 0.63, r.position.y + r.size.y * 0.50)
		var pts := PackedVector2Array()
		for i in range(10):
			var ang: float = -PI * 0.5 + float(i) * PI / 5.0
			var rad: float = r.size.y * (0.15 if i % 2 == 0 else 0.06)
			pts.append(star_c + Vector2(cos(ang), sin(ang)) * rad)
		canvas.draw_colored_polygon(pts, Color.WHITE)
	elif code == "de":
		var h3: float = r.size.y / 3.0
		canvas.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, h3), Color(0.08, 0.08, 0.08), true)
		canvas.draw_rect(Rect2(r.position.x, r.position.y + h3, r.size.x, h3), Color(0.86, 0.04, 0.04), true)
		canvas.draw_rect(Rect2(r.position.x, r.position.y + h3 * 2.0, r.size.x, h3 + 0.5), Color(1.0, 0.81, 0.0), true)
	else:
		# UK Union Jack
		canvas.draw_rect(r, Color(0.01, 0.13, 0.41), true)
		var tl := r.position
		var br := r.position + r.size
		var tr := Vector2(br.x, tl.y)
		var bl := Vector2(tl.x, br.y)
		canvas.draw_line(tl, br, Color.WHITE, 4.5)
		canvas.draw_line(tr, bl, Color.WHITE, 4.5)
		canvas.draw_line(tl, br, Color(0.80, 0.08, 0.16), 2.0)
		canvas.draw_line(tr, bl, Color(0.80, 0.08, 0.16), 2.0)
		var cx: float = r.position.x + r.size.x * 0.5
		var cy: float = r.position.y + r.size.y * 0.5
		canvas.draw_rect(Rect2(cx - 4.0, r.position.y, 8.0, r.size.y), Color.WHITE, true)
		canvas.draw_rect(Rect2(r.position.x, cy - 4.0, r.size.x, 8.0), Color.WHITE, true)
		canvas.draw_rect(Rect2(cx - 2.2, r.position.y, 4.4, r.size.y), Color(0.80, 0.08, 0.16), true)
		canvas.draw_rect(Rect2(r.position.x, cy - 2.2, r.size.x, 4.4), Color(0.80, 0.08, 0.16), true)


func _make_card(node_name: String, title: String, card_size: Vector2) -> Control:
	var card: Control = NotebookCardScript.new()
	card.name = node_name
	card.title_text = title
	card.show_inset = true
	card.show_close_tab = true
	card.size = card_size
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -card_size.x * 0.5
	card.offset_top = -card_size.y * 0.5
	card.offset_right = card_size.x * 0.5
	card.offset_bottom = card_size.y * 0.5
	return card


func _make_button(btn_name: String, label: String, is_primary: bool, font_size: int) -> Button:
	var btn := Button.new()
	btn.name = btn_name
	btn.text = label
	btn.custom_minimum_size = Vector2(0.0, 44.0)
	ThemeRef.style_button(btn, is_primary, font_size)
	btn.pressed.connect(func() -> void:
		if _owner_node != null and _owner_node.has_node("/root/AudioManager"):
			_owner_node.get_node("/root/AudioManager").play_ui_click()
	)
	return btn


func _play_click() -> void:
	if _owner_node != null and _owner_node.has_node("/root/AudioManager"):
		_owner_node.get_node("/root/AudioManager").play_ui_click()


func _settings() -> Node:
	if _owner_node != null and _owner_node.has_node("/root/SettingsManager"):
		return _owner_node.get_node("/root/SettingsManager")
	return null


func _t(key: String) -> String:
	var sm: Node = _settings()
	if sm != null:
		return sm.t(key)
	return key
