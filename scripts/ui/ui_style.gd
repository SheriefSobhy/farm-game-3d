class_name UIStyle
extends RefCounted
## Shared look for all UI: rounded glossy panels/buttons and the Fredoka font.

const FONT_FILE := preload("res://assets/fonts/Fredoka.ttf")

const CREAM := Color("fff4d6")
const BROWN := Color("7a4a24")
const DARK_OUTLINE := Color("4a2a12")
const GREEN := Color("5cc93a")
const BLUE := Color("4aa8f0")
const YELLOW := Color("ffcc2e")
const RED := Color("ef4b3c")

static var _font: FontVariation


static func font(weight := 600) -> FontVariation:
	if _font == null or weight != 600:
		var f := FontVariation.new()
		f.base_font = FONT_FILE
		f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		if weight != 600:
			return f
		_font = f
	return _font


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 30
	t.set_color("font_color", "Label", Color.WHITE)
	t.set_color("font_outline_color", "Label", DARK_OUTLINE)
	t.set_constant("outline_size", "Label", 10)
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_outline_color", "Button", DARK_OUTLINE)
	t.set_constant("outline_size", "Button", 10)
	return t


## Rounded panel with a darker "3D" bottom edge and soft drop shadow.
static func glossy(color: Color, radius := 22, border := 4, bottom := 7) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.border_color = color.darkened(0.35)
	s.border_width_left = border
	s.border_width_right = border
	s.border_width_top = border
	s.border_width_bottom = bottom
	s.shadow_color = Color(0, 0, 0, 0.22)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 4)
	s.anti_aliasing = true
	s.corner_detail = 8
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 10
	return s


## White translucent highlight over the top half of a control, for the glossy look.
static func add_gloss(ctrl: Control, radius := 18, inset := 7.0, alpha := 0.32) -> Panel:
	var g := Panel.new()
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 1, 1, alpha)
	s.set_corner_radius_all(radius)
	s.corner_radius_bottom_left = int(radius * 0.6)
	s.corner_radius_bottom_right = int(radius * 0.6)
	s.anti_aliasing = true
	g.add_theme_stylebox_override("panel", s)
	g.anchor_left = 0.0
	g.anchor_right = 1.0
	g.anchor_top = 0.0
	g.anchor_bottom = 0.45
	g.offset_left = inset + 2
	g.offset_right = -inset - 2
	g.offset_top = inset * 0.8
	g.offset_bottom = 0
	ctrl.add_child(g)
	return g


static func glossy_button(text: String, color: Color, min_size := Vector2(160, 84)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	var normal := glossy(color)
	var hover := glossy(color.lightened(0.08))
	var pressed := glossy(color.darkened(0.08))
	pressed.border_width_bottom = 4
	pressed.content_margin_top = 11
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("disabled", glossy(color.lerp(Color.GRAY, 0.6)))
	add_gloss(b)
	return b
