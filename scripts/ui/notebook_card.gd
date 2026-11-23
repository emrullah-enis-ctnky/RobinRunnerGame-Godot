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
	ThemeRef.style_label(_title_label, 26, ThemeRef.TEXT_WHITE, 5)
	add_child(_title_label)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.flat = true
	_close_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_close_btn.visible = show_close_tab
	_close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_close_btn.add_theme_color_override("font_color", ThemeRef.TEXT_WHITE)
	_close_btn.add_theme_color_override("font_hover_color", ThemeRef.TEXT_GOLD)
	_close_btn.add_theme_color_override("font_focus_color", ThemeRef.TEXT_GOLD)
	_close_btn.add_theme_color_override("font_outline_color", ThemeRef.OUTLINE_COLOR)
	_close_btn.add_theme_constant_override("outline_size", 4)
	_close_btn.add_theme_font_size_override("font_size", 18)
	_close_btn.focus_mode = Control.FOCUS_ALL
	_close_btn.pressed.connect(func() -> void:
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_ui_click()
		close_requested.emit()
	)
	add_child(_close_btn)

	resized.connect(_layout_chrome)
	_layout_chrome()


## Positions the title label and close button relative to the card size.
func _layout_chrome() -> void:
	if _title_label != null:
		_title_label.position = Vector2(22.0, 34.0)
		_title_label.size = Vector2(size.x - 44.0, 48.0)
	if _close_btn != null:
		_close_btn.position = Vector2(size.x - 6.0, 30.0)
		_close_btn.size = Vector2(36.0, 34.0)
	queue_redraw()


## Draws the curved leaves, bookmark ribbon, stacked pages, parchment, chunky rings, and banner.
func _draw() -> void:
	var w: float = size.x
	var h: float = size.y

	# 1. Smooth curved forest leaves behind the notebook
	_draw_curved_leaf(Vector2(4.0, h * 0.72), Vector2(-52.0, h * 0.62), 22.0)
	_draw_curved_leaf(Vector2(10.0, h * 0.82), Vector2(-42.0, h * 0.90), 19.0)
	_draw_curved_leaf(Vector2(w - 4.0, h * 0.42), Vector2(w + 56.0, h * 0.30), 24.0)
	_draw_curved_leaf(Vector2(w - 6.0, h * 0.56), Vector2(w + 48.0, h * 0.64), 20.0)

	# 2. Hanging crimson bookmark ribbon at bottom-left with soft fold
	var rib_x: float = 48.0
	var rib_pts := PackedVector2Array([
		Vector2(rib_x, h - 14.0),
		Vector2(rib_x + 38.0, h - 14.0),
		Vector2(rib_x + 38.0, h + 42.0),
		Vector2(rib_x + 19.0, h + 27.0),
		Vector2(rib_x, h + 42.0),
	])
	draw_colored_polygon(rib_pts, ThemeRef.RIBBON_RED)
	var rib_fold := PackedVector2Array([
		Vector2(rib_x + 22.0, h - 14.0),
		Vector2(rib_x + 38.0, h - 14.0),
		Vector2(rib_x + 38.0, h + 42.0),
		Vector2(rib_x + 22.0, h + 30.0),
	])
	draw_colored_polygon(rib_fold, ThemeRef.RIBBON_RED_DARK)

	# 3. Optional top-right red X ribbon tab
	if show_close_tab:
		var tab_pts := PackedVector2Array([
			Vector2(w - 10.0, 28.0),
			Vector2(w + 34.0, 28.0),
			Vector2(w + 22.0, 46.0),
			Vector2(w + 34.0, 64.0),
			Vector2(w - 10.0, 64.0),
		])
		draw_colored_polygon(tab_pts, ThemeRef.RIBBON_RED)

	# 4. Dark wooden/leather backing with soft drop shadow
	_draw_rounded_box(Rect2(-8.0, 14.0, w + 16.0, h - 4.0), ThemeRef.WOOD_BACKING, ThemeRef.WOOD_BORDER, 24, 2, true)

	# 5. Stacked back page layers peeking at the sides
	_draw_rounded_box(Rect2(-2.0, 18.0, w + 4.0, h - 14.0), ThemeRef.PARCHMENT_PAGE_BACK, Color(0.75, 0.59, 0.53), 20, 0, false)

	# 6. Warm cream parchment front page
	_draw_rounded_box(Rect2(6.0, 14.0, w - 12.0, h - 22.0), ThemeRef.PARCHMENT_BG, Color(0.88, 0.77, 0.71), 20, 1, false)

	# Soft stylized parchment spots
	draw_circle(Vector2(34.0, h - 44.0), 18.0, ThemeRef.PARCHMENT_PATCH)
	draw_circle(Vector2(54.0, h - 28.0), 9.0, ThemeRef.PARCHMENT_PATCH)
	draw_circle(Vector2(w - 34.0, 82.0), 14.0, ThemeRef.PARCHMENT_PATCH)

	# 7. Optional recessed inner panel
	if show_inset:
		_draw_rounded_box(Rect2(28.0, 96.0, w - 56.0, h - 126.0), ThemeRef.PARCHMENT_INSET, Color(0.76, 0.58, 0.52), 16, 1, false)

	# 8. Three chunky 3D-shaded purple binder rings at the top
	var ring_xs: Array[float] = [w * 0.24, w * 0.50, w * 0.76]
	for rx in ring_xs:
		_draw_spiral_ring(Vector2(rx, 16.0))

	# 9. Golden folded header banner with soft shadow and bottom lip
	var banner_rect := Rect2(18.0, 34.0, w - 36.0, 48.0)
	var shadow_rect := Rect2(18.0, 38.0, w - 36.0, 48.0)
	_draw_rounded_box(shadow_rect, ThemeRef.BANNER_SHADOW, ThemeRef.BANNER_SHADOW, 16, 0, true)
	_draw_rounded_box(banner_rect, ThemeRef.BANNER_GOLD, ThemeRef.BANNER_ORANGE, 16, 0, false)
	# Subtle top sheen on banner
	_draw_rounded_box(Rect2(26.0, 38.0, w - 52.0, 10.0), Color(1.0, 0.88, 0.45, 0.45), Color.TRANSPARENT, 6, 0, false)


func _draw_rounded_box(rect: Rect2, fill: Color, border: Color, radius: int, border_w: int, with_shadow: bool) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_w)
	box.set_corner_radius_all(radius)
	if with_shadow:
		box.shadow_color = Color(0.08, 0.04, 0.02, 0.35)
		box.shadow_size = 16
		box.shadow_offset = Vector2(0, 8)
	box.draw(get_canvas_item(), rect)


func _draw_spiral_ring(base: Vector2) -> void:
	var hole_color := Color(0.30, 0.20, 0.17)
	draw_circle(base + Vector2(0.0, 14.0), 9.5, hole_color)
	draw_arc(base + Vector2(0.0, 0.0), 17.0, PI * 0.88, TAU + PI * 0.12, 22, ThemeRef.RING_SHADOW, 12.0, true)
	draw_arc(base + Vector2(0.0, -2.0), 17.0, PI * 0.88, TAU + PI * 0.12, 22, ThemeRef.RING_BASE, 9.5, true)
	draw_arc(base + Vector2(-2.0, -5.0), 16.0, PI * 1.12, PI * 1.72, 14, ThemeRef.RING_HIGHLIGHT, 3.5, true)


## Draws a smooth curved teardrop leaf using quadratic Bezier sampling.
func _draw_curved_leaf(stem: Vector2, tip: Vector2, half_width: float) -> void:
	var dir: Vector2 = (tip - stem).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var ctrl_a: Vector2 = stem.lerp(tip, 0.45) + perp * (half_width * 1.35)
	var ctrl_b: Vector2 = stem.lerp(tip, 0.45) - perp * (half_width * 1.10)

	var pts := PackedVector2Array()
	var steps: int = 10
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		pts.append(_quad_bezier(stem, ctrl_a, tip, t))
	for i in range(steps, -1, -1):
		var t: float = float(i) / float(steps)
		pts.append(_quad_bezier(stem, ctrl_b, tip, t))

	draw_colored_polygon(pts, ThemeRef.LEAF_DARK)

	var light_pts := PackedVector2Array()
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		light_pts.append(_quad_bezier(stem, ctrl_a, tip, t))
	for i in range(steps, -1, -1):
		var t: float = float(i) / float(steps)
		light_pts.append(stem.lerp(tip, t))
	draw_colored_polygon(light_pts, ThemeRef.LEAF_LIGHT)

	draw_line(stem.lerp(tip, 0.12), tip.lerp(stem, 0.12), ThemeRef.LEAF_VEIN, 2.0, true)


func _quad_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var u: float = 1.0 - t
	return u * u * a + 2.0 * u * t * b + t * t * c
