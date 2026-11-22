class_name NotebookUITheme
extends RefCounted
## Shared visual palette, StyleBoxes, and typography helpers for RobinRunner's notebook UI.

const PARCHMENT_BG: Color = Color(0.945, 0.867, 0.827)
const PARCHMENT_PATCH: Color = Color(0.90, 0.79, 0.73)
const PARCHMENT_INSET: Color = Color(0.84, 0.67, 0.61)
const WOOD_BACKING: Color = Color(0.35, 0.24, 0.21)
const WOOD_BORDER: Color = Color(0.23, 0.15, 0.13)

const RING_BASE: Color = Color(0.46, 0.39, 0.53)
const RING_HIGHLIGHT: Color = Color(0.70, 0.64, 0.77)

const LEAF_DARK: Color = Color(0.18, 0.54, 0.24)
const LEAF_LIGHT: Color = Color(0.30, 0.70, 0.34)

const RIBBON_RED: Color = Color(0.83, 0.15, 0.30)
const RIBBON_RED_DARK: Color = Color(0.58, 0.08, 0.20)

const BANNER_GOLD: Color = Color(1.0, 0.68, 0.08)
const BANNER_ORANGE: Color = Color(0.94, 0.48, 0.03)
const BANNER_SHADOW: Color = Color(0.68, 0.30, 0.0)

const GREEN_FILL: Color = Color(0.32, 0.76, 0.10)
const GREEN_HOVER: Color = Color(0.40, 0.84, 0.16)
const GREEN_PRESSED: Color = Color(0.24, 0.60, 0.07)
const GREEN_LIP: Color = Color(0.15, 0.42, 0.03)

const ORANGE_FILL: Color = Color(1.0, 0.55, 0.06)
const ORANGE_HOVER: Color = Color(1.0, 0.66, 0.18)
const ORANGE_PRESSED: Color = Color(0.85, 0.43, 0.02)
const ORANGE_LIP: Color = Color(0.68, 0.28, 0.0)

const HUD_PILL_BG: Color = Color(0.22, 0.15, 0.12, 0.84)
const HUD_PILL_BORDER: Color = Color(0.93, 0.78, 0.58, 0.92)

const TEXT_WHITE: Color = Color(1.0, 0.98, 0.95)
const TEXT_DARK: Color = Color(0.27, 0.16, 0.10)
const TEXT_GOLD: Color = Color(1.0, 0.84, 0.24)
const OUTLINE_COLOR: Color = Color(0.22, 0.12, 0.06)


## Applies consistent primary (green) or secondary (orange) pill styling to a Button.
static func style_button(button: Button, is_primary: bool = false, font_size: int = 22) -> void:
	if button == null:
		return

	var fill: Color = GREEN_FILL if is_primary else ORANGE_FILL
	var hover: Color = GREEN_HOVER if is_primary else ORANGE_HOVER
	var pressed: Color = GREEN_PRESSED if is_primary else ORANGE_PRESSED
	var lip: Color = GREEN_LIP if is_primary else ORANGE_LIP

	button.add_theme_stylebox_override("normal", _make_pill_box(fill, lip, 4))
	button.add_theme_stylebox_override("hover", _make_pill_box(hover, lip, 4))
	button.add_theme_stylebox_override("pressed", _make_pill_box(pressed, lip, 2))
	button.add_theme_stylebox_override("focus", _make_pill_box(hover, lip, 4))

	button.add_theme_color_override("font_color", TEXT_WHITE)
	button.add_theme_color_override("font_hover_color", TEXT_WHITE)
	button.add_theme_color_override("font_pressed_color", TEXT_WHITE)
	button.add_theme_color_override("font_focus_color", TEXT_WHITE)
	button.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	button.add_theme_constant_override("outline_size", 5)
	button.add_theme_font_size_override("font_size", font_size)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


## Applies consistent outlined typography to any Label.
static func style_label(label: Label, font_size: int, color: Color = TEXT_WHITE, outline_size: int = 4) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", outline_size)


## Draws the shared dark-wood & warm-cream HUD pill frame inside a Control's _draw().
static func draw_hud_pill(canvas: CanvasItem, size: Vector2) -> void:
	var box := _make_hud_box()
	box.draw(canvas.get_canvas_item(), Rect2(Vector2.ZERO, size))


## Builds a beveled pill StyleBoxFlat for buttons.
static func _make_pill_box(fill: Color, lip: Color, bottom_border: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = lip
	box.border_width_left = 2
	box.border_width_top = 2
	box.border_width_right = 2
	box.border_width_bottom = bottom_border
	box.set_corner_radius_all(14)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


## Builds the shared HUD pill StyleBoxFlat.
static func _make_hud_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = HUD_PILL_BG
	box.border_color = HUD_PILL_BORDER
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	return box
