class_name NotebookUITheme
extends RefCounted
## Shared visual palette, soft beveled StyleBoxes, and typography helpers for RobinRunner's UI.

const PARCHMENT_BG: Color = Color(0.955, 0.885, 0.845)
const PARCHMENT_PAGE_BACK: Color = Color(0.83, 0.69, 0.63)
const PARCHMENT_PATCH: Color = Color(0.91, 0.81, 0.75, 0.7)
const PARCHMENT_INSET: Color = Color(0.84, 0.67, 0.61)
const WOOD_BACKING: Color = Color(0.36, 0.24, 0.21)
const WOOD_BORDER: Color = Color(0.26, 0.17, 0.14)

const RING_BASE: Color = Color(0.47, 0.39, 0.56)
const RING_SHADOW: Color = Color(0.31, 0.25, 0.38)
const RING_HIGHLIGHT: Color = Color(0.75, 0.69, 0.84)

const LEAF_DARK: Color = Color(0.16, 0.52, 0.24)
const LEAF_LIGHT: Color = Color(0.29, 0.70, 0.35)
const LEAF_VEIN: Color = Color(0.44, 0.82, 0.46, 0.65)

const RIBBON_RED: Color = Color(0.86, 0.16, 0.32)
const RIBBON_RED_DARK: Color = Color(0.64, 0.09, 0.22)

const BANNER_GOLD: Color = Color(1.0, 0.71, 0.14)
const BANNER_ORANGE: Color = Color(0.94, 0.50, 0.04)
const BANNER_SHADOW: Color = Color(0.70, 0.32, 0.0, 0.9)

const GREEN_FILL: Color = Color(0.38, 0.79, 0.14)
const GREEN_HOVER: Color = Color(0.46, 0.86, 0.22)
const GREEN_PRESSED: Color = Color(0.30, 0.66, 0.10)
const GREEN_LIP: Color = Color(0.22, 0.50, 0.06)

const ORANGE_FILL: Color = Color(1.0, 0.58, 0.10)
const ORANGE_HOVER: Color = Color(1.0, 0.67, 0.22)
const ORANGE_PRESSED: Color = Color(0.87, 0.47, 0.04)
const ORANGE_LIP: Color = Color(0.73, 0.34, 0.0)

const HUD_PILL_BG: Color = Color(0.24, 0.16, 0.13, 0.82)
const HUD_PILL_BORDER: Color = Color(0.95, 0.82, 0.64, 0.88)

const SLIDER_TRACK: Color = Color(0.29, 0.22, 0.32)
const SLIDER_FILL: Color = Color(0.18, 0.66, 1.0)
const SLIDER_FILL_HI: Color = Color(0.32, 0.78, 1.0)

const TEXT_WHITE: Color = Color(1.0, 0.985, 0.96)
const TEXT_DARK: Color = Color(0.28, 0.16, 0.10)
const TEXT_GOLD: Color = Color(1.0, 0.86, 0.28)
const OUTLINE_COLOR: Color = Color(0.26, 0.13, 0.06, 0.88)


## Applies soft, rounded 3D-pill styling to a Button (green for primary, orange for secondary).
static func style_button(button: Button, is_primary: bool = false, font_size: int = 21) -> void:
	if button == null:
		return

	var fill: Color = GREEN_FILL if is_primary else ORANGE_FILL
	var hover: Color = GREEN_HOVER if is_primary else ORANGE_HOVER
	var pressed: Color = GREEN_PRESSED if is_primary else ORANGE_PRESSED
	var lip: Color = GREEN_LIP if is_primary else ORANGE_LIP

	button.add_theme_stylebox_override("normal", _make_pill_box(fill, lip, 6, true))
	button.add_theme_stylebox_override("hover", _make_pill_box(hover, lip, 6, true))
	button.add_theme_stylebox_override("pressed", _make_pill_box(pressed, lip, 3, false))
	button.add_theme_stylebox_override("focus", _make_focus_box(hover))

	button.add_theme_color_override("font_color", TEXT_WHITE)
	button.add_theme_color_override("font_hover_color", TEXT_WHITE)
	button.add_theme_color_override("font_pressed_color", TEXT_WHITE)
	button.add_theme_color_override("font_focus_color", TEXT_GOLD)
	button.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_font_size_override("font_size", font_size)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


## Applies consistent outlined typography with a subtle drop shadow to any Label.
static func style_label(label: Label, font_size: int, color: Color = TEXT_WHITE, outline_size: int = 4) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", outline_size)
	label.add_theme_color_override("font_shadow_color", Color(0.14, 0.06, 0.02, 0.45))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)


## Draws a miniature wooden-backed cream parchment HUD pill matching the Main Menu notebook theme.
static func draw_hud_pill(canvas: CanvasItem, size: Vector2, accent_top: bool = false) -> void:
	var outer := StyleBoxFlat.new()
	outer.bg_color = WOOD_BACKING
	outer.border_color = WOOD_BORDER
	outer.border_width_bottom = 4
	outer.border_width_left = 1
	outer.border_width_right = 1
	outer.border_width_top = 1
	outer.set_corner_radius_all(16)
	outer.shadow_color = Color(0.08, 0.04, 0.02, 0.34)
	outer.shadow_size = 7
	outer.shadow_offset = Vector2(0, 4)
	outer.draw(canvas.get_canvas_item(), Rect2(Vector2.ZERO, size))

	var inner := StyleBoxFlat.new()
	inner.bg_color = PARCHMENT_BG
	inner.border_color = Color(0.86, 0.74, 0.68)
	inner.set_border_width_all(1)
	inner.set_corner_radius_all(12)
	inner.draw(canvas.get_canvas_item(), Rect2(Vector2(4.0, 4.0), size - Vector2(8.0, 10.0)))

	if accent_top and size.y >= 54.0:
		var banner := StyleBoxFlat.new()
		banner.bg_color = BANNER_GOLD
		banner.border_color = BANNER_ORANGE
		banner.border_width_bottom = 3
		banner.set_corner_radius_all(10)
		banner.draw(canvas.get_canvas_item(), Rect2(Vector2(7.0, 6.0), Vector2(size.x - 14.0, 30.0)))


## Draws a warm orange-amber beveled accent pill (used for combo badges).
static func draw_accent_pill(canvas: CanvasItem, size: Vector2) -> void:
	var box := _make_pill_box(ORANGE_FILL, ORANGE_LIP, 4, true)
	box.set_corner_radius_all(14)
	box.draw(canvas.get_canvas_item(), Rect2(Vector2.ZERO, size))


## Applies the template's rounded dark track and vibrant blue fill styling to an HSlider.
static func style_slider(slider: HSlider) -> void:
	if slider == null:
		return
	var track := StyleBoxFlat.new()
	track.bg_color = SLIDER_TRACK
	track.set_corner_radius_all(8)
	track.content_margin_top = 7
	track.content_margin_bottom = 7

	var fill := StyleBoxFlat.new()
	fill.bg_color = SLIDER_FILL
	fill.set_corner_radius_all(8)
	fill.content_margin_top = 7
	fill.content_margin_bottom = 7

	var fill_hi := StyleBoxFlat.new()
	fill_hi.bg_color = SLIDER_FILL_HI
	fill_hi.set_corner_radius_all(8)
	fill_hi.content_margin_top = 7
	fill_hi.content_margin_bottom = 7

	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill_hi)
	slider.focus_mode = Control.FOCUS_ALL
	slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


## Builds a glowing golden-rimmed StyleBoxFlat for keyboard-focused buttons.
static func _make_focus_box(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = Color(1.0, 0.94, 0.45)
	box.set_border_width_all(3)
	box.border_width_bottom = 6
	box.set_corner_radius_all(18)
	box.content_margin_left = 20
	box.content_margin_right = 20
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	box.shadow_color = Color(1.0, 0.88, 0.30, 0.45)
	box.shadow_size = 8
	box.shadow_offset = Vector2(0, 2)
	return box


## Builds a soft, rounded 3D-beveled pill StyleBoxFlat for buttons.
static func _make_pill_box(fill: Color, lip: Color, bottom_border: int, with_shadow: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = lip
	box.border_width_left = 0
	box.border_width_top = 0
	box.border_width_right = 0
	box.border_width_bottom = bottom_border
	box.set_corner_radius_all(18)
	box.content_margin_left = 20
	box.content_margin_right = 20
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	if with_shadow:
		box.shadow_color = Color(0.16, 0.08, 0.04, 0.28)
		box.shadow_size = 5
		box.shadow_offset = Vector2(0, 3)
	return box


## Builds the shared HUD pill StyleBoxFlat.
static func _make_hud_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = HUD_PILL_BG
	box.border_color = HUD_PILL_BORDER
	box.set_border_width_all(2)
	box.set_corner_radius_all(16)
	box.shadow_color = Color(0.08, 0.04, 0.02, 0.30)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 2)
	return box
