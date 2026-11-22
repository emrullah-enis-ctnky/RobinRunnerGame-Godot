class_name NotebookCard
extends Control
## Procedural forest-explorer notebook card matching the stylized parchment template.

const ThemeRef = preload("res://scripts/ui/notebook_ui_theme.gd")

@export var title_text: String = "ROBIN RUNNER":
	set(value):
		title_text = value
		queue_redraw()
		if _title_label != null:
			_title_label.text = value

@export var show_inset: bool = false:
	set(value):
		show_inset = value
		queue_redraw()

@export var show_close_tab: bool = false:
	set(value):
		show_close_tab = value
		if _close_btn != null:
			_close_btn.visible = value
		queue_redraw()

signal close_requested

var _title_label: Label
var _close_btn: Button


## Builds the golden title banner label and optional red X close tab.
func _ready() -> void:
	_title_label = Label.new()
	_title_label.text = title_text
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ThemeRef.style_label(_title_label, 28, ThemeRef.TEXT_WHITE, 6)
	add_child(_title_label)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.flat = true
	_close_btn.visible = show_close_tab
	_close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_close_btn.add_theme_color_override("font_color", ThemeRef.TEXT_WHITE)
	_close_btn.add_theme_color_override("font_hover_color", ThemeRef.TEXT_GOLD)
	_close_btn.add_theme_color_override("font_outline_color", ThemeRef.OUTLINE_COLOR)
	_close_btn.add_theme_constant_override("outline_size", 4)
	_close_btn.add_theme_font_size_override("font_size", 18)
	_close_btn.pressed.connect(func() -> void: close_requested.emit())
	add_child(_close_btn)

	resized.connect(_layout_chrome)
	_layout_chrome()


## Positions the title label and close button relative to the card size.
func _layout_chrome() -> void:
	if _title_label != null:
		_title_label.position = Vector2(24.0, 32.0)
		_title_label.size = Vector2(size.x - 48.0, 44.0)
	if _close_btn != null:
		_close_btn.position = Vector2(size.x - 10.0, 26.0)
		_close_btn.size = Vector2(36.0, 34.0)
	queue_redraw()


## Draws the leaves, bookmark ribbon, wooden backing, parchment page, spiral rings, and banner.
func _draw() -> void:
	var w: float = size.x
	var h: float = size.y

	# 1. Forest leaves behind the notebook
	_draw_leaf(Vector2(-8.0, h * 0.72), Vector2(-46.0, h * 0.64), 22.0, -0.35)
	_draw_leaf(Vector2(14.0, h * 0.80), Vector2(-34.0, h * 0.86), 19.0, 0.25)
	_draw_leaf(Vector2(w + 6.0, h * 0.42), Vector2(w + 48.0, h * 0.32), 24.0, -0.2)
	_draw_leaf(Vector2(w + 4.0, h * 0.56), Vector2(w + 44.0, h * 0.62), 20.0, 0.3)

	# 2. Hanging crimson bookmark ribbon at bottom-left
	var rib_x: float = 48.0
	var rib_pts := PackedVector2Array([
		Vector2(rib_x, h - 14.0),
		Vector2(rib_x + 36.0, h - 14.0),
		Vector2(rib_x + 36.0, h + 38.0),
		Vector2(rib_x + 18.0, h + 24.0),
		Vector2(rib_x, h + 38.0),
	])
	draw_colored_polygon(rib_pts, ThemeRef.RIBBON_RED)

	# 3. Optional top-right red X ribbon tab
	if show_close_tab:
		var tab_pts := PackedVector2Array([
			Vector2(w - 14.0, 26.0),
			Vector2(w + 28.0, 26.0),
			Vector2(w + 18.0, 43.0),
			Vector2(w + 28.0, 60.0),
			Vector2(w - 14.0, 60.0),
		])
		draw_colored_polygon(tab_pts, ThemeRef.RIBBON_RED)

	# 4. Dark wooden/leather backing
	_draw_rounded_box(Rect2(-6.0, 14.0, w + 12.0, h - 6.0), ThemeRef.WOOD_BACKING, ThemeRef.WOOD_BORDER, 22, 3)

	# 5. Cream parchment page
	_draw_rounded_box(Rect2(6.0, 14.0, w - 12.0, h - 22.0), ThemeRef.PARCHMENT_BG, Color(0.84, 0.72, 0.66), 18, 2)

	# Subtle stylized parchment spots
	draw_circle(Vector2(28.0, h - 42.0), 16.0, ThemeRef.PARCHMENT_PATCH)
	draw_circle(Vector2(w - 30.0, 74.0), 14.0, ThemeRef.PARCHMENT_PATCH)

	# 6. Optional recessed inner panel
	if show_inset:
		_draw_rounded_box(Rect2(28.0, 92.0, w - 56.0, h - 122.0), ThemeRef.PARCHMENT_INSET, Color(0.74, 0.56, 0.50), 14, 2)

	# 7. Three purple-slate spiral rings at the top
	var ring_xs: Array[float] = [w * 0.24, w * 0.50, w * 0.76]
	for rx in ring_xs:
		_draw_spiral_ring(Vector2(rx, 14.0))

	# 8. Golden folded header banner
	var banner_rect := Rect2(20.0, 32.0, w - 40.0, 44.0)
	var shadow_rect := Rect2(20.0, 36.0, w - 40.0, 44.0)
	_draw_rounded_box(shadow_rect, ThemeRef.BANNER_SHADOW, ThemeRef.BANNER_SHADOW, 12, 0)
	_draw_rounded_box(banner_rect, ThemeRef.BANNER_GOLD, ThemeRef.BANNER_ORANGE, 12, 2)


func _draw_rounded_box(rect: Rect2, fill: Color, border: Color, radius: int, border_w: int) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_w)
	box.set_corner_radius_all(radius)
	box.draw(get_canvas_item(), rect)


func _draw_spiral_ring(base: Vector2) -> void:
	var hole_color := Color(0.32, 0.23, 0.20)
	draw_circle(base + Vector2(0.0, 12.0), 8.5, hole_color)
	draw_arc(base + Vector2(0.0, -2.0), 14.0, PI * 0.9, TAU + PI * 0.1, 18, ThemeRef.RING_BASE, 9.0, true)
	draw_arc(base + Vector2(-2.0, -4.0), 14.0, PI * 1.1, PI * 1.75, 12, ThemeRef.RING_HIGHLIGHT, 3.0, true)


func _draw_leaf(stem: Vector2, tip: Vector2, width: float, _tilt: float) -> void:
	var dir: Vector2 = (tip - stem).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var mid: Vector2 = stem.lerp(tip, 0.52)
	var poly := PackedVector2Array([
		stem,
		mid + perp * width,
		tip,
		mid - perp * width,
	])
	draw_colored_polygon(poly, ThemeRef.LEAF_DARK)
	var inner_poly := PackedVector2Array([
		stem.lerp(tip, 0.15),
		mid + perp * (width * 0.65),
		tip.lerp(stem, 0.1),
		mid - perp * (width * 0.2),
	])
	draw_colored_polygon(inner_poly, ThemeRef.LEAF_LIGHT)
