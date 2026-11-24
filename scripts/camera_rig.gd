extends Node3D
## Angled top-down camera.
## Touch: one finger drags, two fingers pinch-zoom. Mouse: left-drag + wheel.
## Emits `tapped(screen_pos)` for short taps/clicks that did not drag.

signal tapped(screen_pos: Vector2)

const YAW_DEG := 45.0
const PITCH_DEG := 50.0
const FOV := 46.0            # horizontal field of view (portrait friendly)
const TAP_MAX_MOVE := 14.0   # pixels a finger may move and still count as a tap
const TAP_MAX_TIME := 0.45
const FRICTION := 6.0

var zoom: float = Config.CAMERA_ZOOM_START
var camera: Camera3D

var _touches: Dictionary = {}       # index -> current position
var _press_pos := Vector2.ZERO
var _press_time := 0.0
var _moved := false
var _pinch_dist := 0.0
var _velocity := Vector3.ZERO
var _mouse_down := false
var _ui_blocked := false            # gesture started on top of the UI


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = FOV
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.near = 0.5
	camera.far = 200.0
	add_child(camera)
	camera.make_current()
	_update_camera()


func _process(delta: float) -> void:
	if _touches.is_empty() and not _mouse_down and _velocity.length() > 0.01:
		position += _velocity * delta
		_velocity = _velocity.lerp(Vector3.ZERO, clampf(FRICTION * delta, 0.0, 1.0))
		_clamp_position()


func _update_camera() -> void:
	var yaw := deg_to_rad(YAW_DEG)
	var pitch := deg_to_rad(PITCH_DEG)
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * zoom
	camera.transform = Transform3D(Basis.looking_at(-offset, Vector3.UP), offset)


func _clamp_position() -> void:
	var lim: float = Config.CAMERA_PAN_LIMIT
	position.x = clampf(position.x, -lim, lim)
	position.z = clampf(position.z, -lim, lim)
	position.y = 0.0


func set_zoom(value: float) -> void:
	zoom = clampf(value, Config.CAMERA_ZOOM_MIN, Config.CAMERA_ZOOM_MAX)
	_update_camera()


## Where a screen point hits the ground (y = 0).
func screen_to_ground(screen_pos: Vector2) -> Vector3:
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.0001:
		return from
	var t := -from.y / dir.y
	return from + dir * t


func _pan(from_screen: Vector2, to_screen: Vector2, delta_time: float) -> void:
	var a := screen_to_ground(from_screen)
	var b := screen_to_ground(to_screen)
	var move := a - b
	move.y = 0.0
	position += move
	_clamp_position()
	if delta_time > 0.0:
		_velocity = _velocity.lerp(move / delta_time, 0.5)


func _is_over_ui(pos: Vector2) -> bool:
	for c in get_tree().get_nodes_in_group("ui_block"):
		var ctrl := c as Control
		if ctrl and ctrl.is_visible_in_tree() and ctrl.get_global_rect().has_point(pos):
			return true
	return false


func _begin(pos: Vector2) -> void:
	_press_pos = pos
	_press_time = Time.get_ticks_msec() / 1000.0
	_moved = false
	_velocity = Vector3.ZERO
	_ui_blocked = _is_over_ui(pos)


func _end(pos: Vector2) -> void:
	var dt := Time.get_ticks_msec() / 1000.0 - _press_time
	if not _moved and not _ui_blocked and dt <= TAP_MAX_TIME:
		tapped.emit(pos)


var _last_move_time := 0.0

func _move_dt() -> float:
	var t := Time.get_ticks_msec() / 1000.0
	var dt := t - _last_move_time
	_last_move_time = t
	return clampf(dt, 0.001, 0.1)


func _unhandled_input(event: InputEvent) -> void:
	# ---------- Touch ----------
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() == 1:
				_begin(event.position)
				_last_move_time = Time.get_ticks_msec() / 1000.0
			elif _touches.size() == 2:
				_moved = true
				_pinch_dist = _pinch_distance()
		else:
			var was_single := _touches.size() == 1
			_touches.erase(event.index)
			if was_single:
				_end(event.position)
			elif _touches.size() == 1:
				_velocity = Vector3.ZERO
		return

	if event is InputEventScreenDrag:
		if not _touches.has(event.index):
			return
		var old: Vector2 = _touches[event.index]
		_touches[event.index] = event.position
		if _touches.size() == 1:
			if not _moved and event.position.distance_to(_press_pos) > TAP_MAX_MOVE:
				_moved = true
			if _moved and not _ui_blocked:
				_pan(old, event.position, _move_dt())
		elif _touches.size() >= 2:
			var d := _pinch_distance()
			if _pinch_dist > 1.0 and d > 1.0:
				set_zoom(zoom * _pinch_dist / d)
			_pinch_dist = d
			# move by half the finger motion so the pinch center roughly stays put
			_pan(old, old + (event.position - old) * 0.5, 0.0)
			_velocity = Vector3.ZERO
		return

	# ---------- Mouse (ignore mouse events emulated from touch) ----------
	if event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_mouse_down = true
					_begin(event.position)
					_last_move_time = Time.get_ticks_msec() / 1000.0
				elif _mouse_down:
					_mouse_down = false
					_end(event.position)
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					set_zoom(zoom * 0.9)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					set_zoom(zoom * 1.1)
		return

	if event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and _mouse_down:
		if not _moved and event.position.distance_to(_press_pos) > TAP_MAX_MOVE:
			_moved = true
		if _moved and not _ui_blocked:
			_pan(event.position - event.relative, event.position, _move_dt())
		return

	if event is InputEventMagnifyGesture:
		set_zoom(zoom / event.factor)


func _pinch_distance() -> float:
	var pts := _touches.values()
	if pts.size() < 2:
		return 0.0
	return (pts[0] as Vector2).distance_to(pts[1])
