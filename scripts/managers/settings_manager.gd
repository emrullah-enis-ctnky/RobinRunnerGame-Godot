extends Node
## Manages persistent audio volumes, language localization (EN/TR/DE), and multi-key InputMap bindings.

signal settings_changed
signal language_changed(lang_code: String)
signal controls_changed

const SETTINGS_PATH: String = "user://settings.cfg"
const MANAGED_ACTIONS: Array[String] = [
	"move_left",
	"move_right",
	"jump",
	"move_down",
	"shoot",
	"pause",
]

const LANGUAGES: Array[String] = ["en", "tr", "de"]

const STRINGS: Dictionary = {
	"en": {
		"title_main": "ROBIN RUNNER",
		"title_settings": "SETTINGS",
		"title_controls": "CONTROLS",
		"title_language": "LANGUAGE",
		"title_paused": "PAUSED",
		"title_gameover": "GAME OVER",
		"btn_settings": "SETTINGS",
		"btn_controls": "CONTROLS",
		"btn_language": "LANGUAGE",
		"btn_quit": "QUIT",
		"btn_save": "SAVE",
		"btn_back": "BACK",
		"btn_resume": "RESUME",
		"btn_restart": "RESTART",
		"btn_main_menu": "MAIN MENU",
		"btn_play_again": "PLAY AGAIN",
		"btn_reset_defaults": "RESET DEFAULTS",
		"lbl_best": "BEST",
		"lbl_score": "SCORE",
		"lbl_distance": "DISTANCE",
		"lbl_coins": "COINS",
		"lbl_new_best": "NEW HIGH SCORE!",
		"lbl_music": "MUSIC",
		"lbl_sfx": "SOUND",
		"lbl_press_key": "PRESS ANY KEY...",
		"act_move_left": "Move Left",
		"act_move_right": "Move Right",
		"act_jump": "Jump",
		"act_move_down": "Duck / Slide",
		"act_shoot": "Shoot Arrow",
		"act_pause": "Pause",
	},
	"tr": {
		"title_main": "ROBIN RUNNER",
		"title_settings": "AYARLAR",
		"title_controls": "KONTROLLER",
		"title_language": "DİL SEÇİMİ",
		"title_paused": "DURAKLATILDI",
		"title_gameover": "OYUN BİTTİ",
		"btn_settings": "AYARLAR",
		"btn_controls": "KONTROLLER",
		"btn_language": "DİL",
		"btn_quit": "ÇIKIŞ",
		"btn_save": "KAYDET",
		"btn_back": "GERİ",
		"btn_resume": "DEVAM ET",
		"btn_restart": "YENİDEN BAŞLAT",
		"btn_main_menu": "ANA MENÜ",
		"btn_play_again": "TEKRAR OYNA",
		"btn_reset_defaults": "VARSAYILANA DÖN",
		"lbl_best": "REKOR",
		"lbl_score": "SKOR",
		"lbl_distance": "MESAFE",
		"lbl_coins": "ALTIN",
		"lbl_new_best": "YENİ REKOR!",
		"lbl_music": "MÜZİK",
		"lbl_sfx": "SES EFEKTİ",
		"lbl_press_key": "BİR TUŞA BASIN...",
		"act_move_left": "Sola Git",
		"act_move_right": "Sağa Git",
		"act_jump": "Zıpla",
		"act_move_down": "Eğil / Kay",
		"act_shoot": "Ok At",
		"act_pause": "Duraklat",
	},
	"de": {
		"title_main": "ROBIN RUNNER",
		"title_settings": "EINSTELLUNGEN",
		"title_controls": "STEUERUNG",
		"title_language": "SPRACHE",
		"title_paused": "PAUSIERT",
		"title_gameover": "SPIEL VORBEI",
		"btn_settings": "EINSTELLUNGEN",
		"btn_controls": "STEUERUNG",
		"btn_language": "SPRACHE",
		"btn_quit": "BEENDEN",
		"btn_save": "SPEICHERN",
		"btn_back": "ZURÜCK",
		"btn_resume": "WEITER",
		"btn_restart": "NEUSTART",
		"btn_main_menu": "HAUPTMENÜ",
		"btn_play_again": "NOCHMAL",
		"btn_reset_defaults": "ZURÜCKSETZEN",
		"lbl_best": "REKORD",
		"lbl_score": "PUNKTE",
		"lbl_distance": "DISTANZ",
		"lbl_coins": "MÜNZEN",
		"lbl_new_best": "NEUER REKORD!",
		"lbl_music": "MUSIK",
		"lbl_sfx": "EFFEKTE",
		"lbl_press_key": "TASTE DRÜCKEN...",
		"act_move_left": "Nach Links",
		"act_move_right": "Nach Rechts",
		"act_jump": "Springen",
		"act_move_down": "Ducken",
		"act_shoot": "Pfeil Schießen",
		"act_pause": "Pause",
	},
}

var music_volume: float = 0.8
var music_muted: bool = false
var sfx_volume: float = 0.8
var sfx_muted: bool = false
var language: String = "en"

var _default_bindings: Dictionary = {}


## Snapshots default InputMap bindings and loads saved settings from disk.
func _ready() -> void:
	_capture_default_bindings()
	load_settings()
	_apply_audio()


## Returns the localized string for a key in the active language.
func t(key: String) -> String:
	var table: Dictionary = STRINGS.get(language, STRINGS["en"])
	return table.get(key, STRINGS["en"].get(key, key))


## Sets music volume (0.0 to 1.0) and unmutes if raised above zero.
func set_music_volume(val: float) -> void:
	music_volume = clampf(val, 0.0, 1.0)
	if music_volume > 0.01:
		music_muted = false
	_apply_audio()
	settings_changed.emit()


## Toggles music mute on or off.
func set_music_muted(muted: bool) -> void:
	music_muted = muted
	_apply_audio()
	settings_changed.emit()


## Sets sound-effects volume (0.0 to 1.0) and unmutes if raised above zero.
func set_sfx_volume(val: float) -> void:
	sfx_volume = clampf(val, 0.0, 1.0)
	if sfx_volume > 0.01:
		sfx_muted = false
	_apply_audio()
	settings_changed.emit()


## Toggles sound-effects mute on or off.
func set_sfx_muted(muted: bool) -> void:
	sfx_muted = muted
	_apply_audio()
	settings_changed.emit()


## Switches the active language ("en", "tr", "de") and notifies UI listeners.
func set_language(lang_code: String) -> void:
	if not STRINGS.has(lang_code):
		return
	if language == lang_code:
		return
	language = lang_code
	language_changed.emit(language)
	settings_changed.emit()


## Adds a keyboard or mouse binding to an action if not already bound.
func add_action_event(action: String, event: InputEvent) -> bool:
	if not InputMap.has_action(action) or event == null:
		return false
	for existing in InputMap.action_get_events(action):
		if _events_match(existing, event):
			return false
	InputMap.action_add_event(action, event)
	controls_changed.emit()
	settings_changed.emit()
	return true


## Removes a binding at index from an action while keeping at least one binding active.
func remove_action_event(action: String, index: int) -> bool:
	if not InputMap.has_action(action):
		return false
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	if events.size() <= 1 or index < 0 or index >= events.size():
		return false
	InputMap.action_erase_event(action, events[index])
	controls_changed.emit()
	settings_changed.emit()
	return true


## Restores all managed input actions back to the project.godot defaults.
func reset_controls_to_defaults() -> void:
	for action in MANAGED_ACTIONS:
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		var defaults: Array = _default_bindings.get(action, [])
		for ev in defaults:
			if ev is InputEvent:
				InputMap.action_add_event(action, (ev as InputEvent).duplicate())
	controls_changed.emit()
	settings_changed.emit()


## Formats an InputEvent into a concise, readable key/button label.
func format_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var k: InputEventKey = event as InputEventKey
		var code: Key = k.keycode if k.keycode != KEY_NONE else k.physical_keycode
		return OS.get_keycode_string(code)
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_LEFT:
				return "LMB"
			MOUSE_BUTTON_RIGHT:
				return "RMB"
			MOUSE_BUTTON_MIDDLE:
				return "MMB"
			_:
				return "Mouse %d" % mb.button_index
	return event.as_text()


## Persists audio, language, and custom keybindings to user://settings.cfg.
func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "music_muted", music_muted)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "sfx_muted", sfx_muted)
	cfg.set_value("general", "language", language)

	for action in MANAGED_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var serialized: Array = []
		for ev in InputMap.action_get_events(action):
			var data: Dictionary = _serialize_event(ev)
			if not data.is_empty():
				serialized.append(data)
		cfg.set_value("controls", action, serialized)

	cfg.save(SETTINGS_PATH)


## Loads audio, language, and custom keybindings from user://settings.cfg if present.
func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return

	music_volume = clampf(float(cfg.get_value("audio", "music_volume", 0.8)), 0.0, 1.0)
	music_muted = bool(cfg.get_value("audio", "music_muted", false))
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", 0.8)), 0.0, 1.0)
	sfx_muted = bool(cfg.get_value("audio", "sfx_muted", false))

	var saved_lang: String = str(cfg.get_value("general", "language", "en"))
	if STRINGS.has(saved_lang):
		language = saved_lang

	for action in MANAGED_ACTIONS:
		if not cfg.has_section_key("controls", action) or not InputMap.has_action(action):
			continue
		var list = cfg.get_value("controls", action, [])
		if list is Array and not list.is_empty():
			InputMap.action_erase_events(action)
			for item in list:
				if item is Dictionary:
					var ev: InputEvent = _deserialize_event(item as Dictionary)
					if ev != null:
						InputMap.action_add_event(action, ev)


func _capture_default_bindings() -> void:
	_default_bindings.clear()
	for action in MANAGED_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var copies: Array = []
		for ev in InputMap.action_get_events(action):
			copies.append(ev.duplicate())
		_default_bindings[action] = copies


func _apply_audio() -> void:
	_apply_bus("Music", music_volume, music_muted)
	_apply_bus("SFX", sfx_volume, sfx_muted)


func _apply_bus(bus_name: String, vol: float, muted: bool) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, muted or vol <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(vol, 0.0001)))


func _events_match(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		var ka: Key = (a as InputEventKey).keycode if (a as InputEventKey).keycode != KEY_NONE else (a as InputEventKey).physical_keycode
		var kb: Key = (b as InputEventKey).keycode if (b as InputEventKey).keycode != KEY_NONE else (b as InputEventKey).physical_keycode
		return ka == kb
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return (a as InputEventMouseButton).button_index == (b as InputEventMouseButton).button_index
	return false


func _serialize_event(ev: InputEvent) -> Dictionary:
	if ev is InputEventKey:
		var k: InputEventKey = ev as InputEventKey
		var code: int = int(k.keycode if k.keycode != KEY_NONE else k.physical_keycode)
		return {"type": "key", "code": code}
	if ev is InputEventMouseButton:
		return {"type": "mouse", "button": int((ev as InputEventMouseButton).button_index)}
	return {}


func _deserialize_event(data: Dictionary) -> InputEvent:
	var kind: String = str(data.get("type", ""))
	if kind == "key":
		var k := InputEventKey.new()
		k.keycode = int(data.get("code", 0)) as Key
		return k
	if kind == "mouse":
		var mb := InputEventMouseButton.new()
		mb.button_index = int(data.get("button", 1)) as MouseButton
		return mb
	return null
