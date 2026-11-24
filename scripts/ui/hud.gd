extends CanvasLayer
## Top bar (level, XP, coins, gems) + floating texts, toasts and flying icons.

const ICON_COIN := preload("res://assets/icons/coin.png")
const ICON_GEM := preload("res://assets/icons/gem.png")
const ICON_STAR := preload("res://assets/icons/star.png")
const ITEM_ICONS := {
	"wheat": preload("res://assets/icons/wheat.png"),
}

var root: Control
var level_label: Label
var xp_bar: ProgressBar
var xp_label: Label
var coin_label: Label
var gem_label: Label
var star_icon: TextureRect
var coin_icon: TextureRect
var gem_icon: TextureRect
var _toast: Label
var _toast_box: PanelContainer
var _toast_tween: Tween


func _ready() -> void:
	layer = 10
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIStyle.make_theme()
	add_child(root)
	_build_top_bar()
	_build_toast()
	Game.coins_changed.connect(func(v): _set_count(coin_label, v, coin_icon))
	Game.gems_changed.connect(func(v): _set_count(gem_label, v, gem_icon))
	Game.xp_changed.connect(_on_xp_changed)
	Game.leveled_up.connect(_on_level_up)
	_refresh_all()


func _safe_top() -> float:
	# Leave room for phone notches when the platform reports a safe area.
	var win := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if win.y <= 0 or safe.size.y <= 0:
		return 0.0
	var scale := root.get_viewport_rect().size.y / float(win.y)
	return clampf(safe.position.y * scale, 0.0, 120.0)


func _build_top_bar() -> void:
	var bar := Control.new()
	bar.name = "TopBar"
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_top = 18 + _safe_top()
	bar.offset_bottom = bar.offset_top + 96
	bar.offset_left = 16
	bar.offset_right = -16
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)

	# --- XP bar (behind the star) ---
	var xp_panel := Panel.new()
	xp_panel.add_theme_stylebox_override("panel", UIStyle.glossy(Color("3b7fc4"), 20, 4, 6))
	xp_panel.position = Vector2(54, 18)
	xp_panel.size = Vector2(250, 58)
	xp_panel.add_to_group("ui_block")
	bar.add_child(xp_panel)
	xp_bar = ProgressBar.new()
	xp_bar.show_percentage = false
	xp_bar.position = Vector2(36, 11)
	xp_bar.size = Vector2(200, 32)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("1d4f84")
	bg.set_corner_radius_all(14)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("7be04a")
	fill.set_corner_radius_all(14)
	fill.border_width_bottom = 5
	fill.border_color = Color("49b52a")
	xp_bar.add_theme_stylebox_override("background", bg)
	xp_bar.add_theme_stylebox_override("fill", fill)
	xp_panel.add_child(xp_bar)
	UIStyle.add_gloss(xp_bar, 12, 2.0, 0.25)
	xp_label = Label.new()
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	xp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	xp_label.add_theme_font_size_override("font_size", 24)
	xp_label.add_theme_constant_override("outline_size", 8)
	xp_bar.add_child(xp_label)

	# --- Level star ---
	star_icon = TextureRect.new()
	star_icon.texture = ICON_STAR
	star_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star_icon.size = Vector2(96, 96)
	star_icon.pivot_offset = Vector2(48, 48)
	star_icon.position = Vector2(-4, -2)
	star_icon.add_to_group("ui_block")
	bar.add_child(star_icon)
	level_label = Label.new()
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	level_label.offset_top = 6
	level_label.add_theme_font_size_override("font_size", 34)
	star_icon.add_child(level_label)

	# --- Coins & gems (right side) ---
	var gem_pill := _pill(Color("fff7e6"))
	gem_pill.anchor_left = 1.0
	gem_pill.anchor_right = 1.0
	gem_pill.offset_left = -140
	gem_pill.offset_right = 0
	gem_pill.offset_top = 20
	gem_pill.offset_bottom = 74
	bar.add_child(gem_pill)
	gem_label = _pill_label(gem_pill)
	gem_icon = _pill_icon(bar, ICON_GEM, gem_pill, 70)

	var coin_pill := _pill(Color("fff7e6"))
	coin_pill.anchor_left = 1.0
	coin_pill.anchor_right = 1.0
	coin_pill.offset_left = -340
	coin_pill.offset_right = -176
	coin_pill.offset_top = 20
	coin_pill.offset_bottom = 74
	bar.add_child(coin_pill)
	coin_label = _pill_label(coin_pill)
	coin_icon = _pill_icon(bar, ICON_COIN, coin_pill, 72)


func _pill(color: Color) -> Panel:
	var p := Panel.new()
	var s := UIStyle.glossy(color, 26, 4, 6)
	s.border_color = Color("c9a46a")
	p.add_theme_stylebox_override("panel", s)
	p.add_to_group("ui_block")
	UIStyle.add_gloss(p, 18, 6.0, 0.5)
	return p


func _pill_label(pill: Panel) -> Label:
	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.offset_left = 34
	l.offset_right = -14
	l.offset_bottom = -2
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", Color("5a3410"))
	l.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_font_size_override("font_size", 32)
	pill.add_child(l)
	return l


## Icon that overlaps the left end of a pill.
func _pill_icon(bar: Control, tex: Texture2D, pill: Control, size: float) -> TextureRect:
	var i := TextureRect.new()
	i.texture = tex
	i.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	i.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	i.anchor_left = 1.0
	i.anchor_right = 1.0
	i.offset_left = pill.offset_left - size * 0.42
	i.offset_right = i.offset_left + size
	i.offset_top = 47 - size / 2
	i.offset_bottom = 47 + size / 2
	i.pivot_offset = Vector2(size, size) / 2
	bar.add_child(i)
	return i


func _build_toast() -> void:
	# Centered rounded "pill" under the top bar; the label sizes it.
	var holder := CenterContainer.new()
	holder.set_anchors_preset(Control.PRESET_TOP_WIDE)
	holder.offset_top = 150 + _safe_top()
	holder.offset_bottom = holder.offset_top + 80
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(holder)
	_toast_box = PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.22, 0.13, 0.06, 0.72)
	s.set_corner_radius_all(30)
	s.content_margin_left = 30
	s.content_margin_right = 30
	s.content_margin_top = 8
	s.content_margin_bottom = 10
	s.anti_aliasing = true
	_toast_box.add_theme_stylebox_override("panel", s)
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_box.modulate.a = 0.0
	holder.add_child(_toast_box)
	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 34)
	_toast.add_theme_constant_override("outline_size", 0)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_box.add_child(_toast)


# ---------------- Updates ----------------
func _refresh_all() -> void:
	coin_label.text = str(Game.coins)
	gem_label.text = str(Game.gems)
	_on_xp_changed(Game.level, Game.xp, Game.xp_needed())


func _set_count(label: Label, value: int, icon: Control) -> void:
	label.text = str(value)
	bounce(icon)


func _on_xp_changed(lvl: int, xp: int, needed: int) -> void:
	level_label.text = str(lvl)
	xp_bar.max_value = needed
	var tw := create_tween()
	tw.tween_property(xp_bar, "value", float(xp), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	xp_label.text = "%d / %d" % [xp, needed]


func _on_level_up(lvl: int) -> void:
	bounce(star_icon, 1.5)
	toast("Level %d!" % lvl, UIStyle.YELLOW)


func bounce(c: Control, amount := 1.25) -> void:
	if c == null:
		return
	c.pivot_offset = c.size / 2
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2.ONE * amount, 0.08)
	tw.tween_property(c, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func toast(text: String, color := Color.WHITE) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	if _toast_tween:
		_toast_tween.kill()
	_toast_box.modulate.a = 1.0
	_toast_box.reset_size()
	_toast_box.scale = Vector2.ONE
	_toast_box.pivot_offset = _toast_box.get_combined_minimum_size() / 2
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_box, "scale", Vector2.ONE * 1.1, 0.1)
	_toast_tween.tween_property(_toast_box, "scale", Vector2.ONE, 0.12)
	_toast_tween.tween_interval(1.4)
	_toast_tween.tween_property(_toast_box, "modulate:a", 0.0, 0.4)


## Text that pops up at a screen position and floats upward.
func float_text(text: String, screen_pos: Vector2, color := Color.WHITE, icon: Texture2D = null) -> void:
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 36)
	box.add_child(l)
	if icon:
		var t := TextureRect.new()
		t.texture = icon
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.custom_minimum_size = Vector2(44, 44)
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(t)
	root.add_child(box)
	box.reset_size()
	box.position = screen_pos - box.size / 2
	var tw := box.create_tween()
	tw.set_parallel(true)
	tw.tween_property(box, "position:y", box.position.y - 90, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(box, "modulate:a", 0.0, 0.4).set_delay(0.6)
	tw.chain().tween_callback(box.queue_free)


## An icon that flies along a curve from a screen position to a target control.
func fly_icon(tex: Texture2D, from: Vector2, target: Control, count := 1, on_arrive := Callable()) -> void:
	for i in count:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = Vector2(72, 72)
		icon.pivot_offset = icon.size / 2
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(icon)
		var start := from + Vector2(randf_range(-40, 40), randf_range(-30, 10)) - icon.size / 2
		var end := target.get_global_rect().get_center() - icon.size / 2
		var ctrl := start + Vector2(randf_range(-120, 120), -220)
		icon.position = start
		icon.scale = Vector2.ZERO
		var tw := icon.create_tween()
		tw.tween_interval(i * 0.08)
		tw.tween_property(icon, "scale", Vector2.ONE * 1.2, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_method(func(t: float):
			var a := start.lerp(ctrl, t)
			var b := ctrl.lerp(end, t)
			icon.position = a.lerp(b, t)
			icon.scale = Vector2.ONE * lerpf(1.2, 0.7, t)
		, 0.0, 1.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		var last := i == count - 1
		tw.tween_callback(func():
			icon.queue_free()
			bounce(target)
			if last and on_arrive.is_valid():
				on_arrive.call()
		)
