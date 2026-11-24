extends Node3D
## Windmill: a small tower built from Kenney Fantasy Town pieces + a spinning rotor.

const T := "res://assets/models/town/"
const SCALE := 1.6
const IDLE_SPEED := 0.6      # radians / second
const WORK_SPEED := 4.0

var working := false
var _rotor: Node3D
var _speed := IDLE_SPEED
var _body: Node3D


func _ready() -> void:
	_body = Node3D.new()
	_body.scale = Vector3.ONE * SCALE
	add_child(_body)
	# floor 0: stone, door in front (+Z)
	_ring(0, "wall", {"pz": "wall-door"})
	# floor 1-2: wood with windows
	_ring(1, "wall-wood", {"pz": "wall-wood-window-shutters", "nx": "wall-wood-window-round"})
	_ring(2, "wall-wood", {"pz": "wall-wood-window-round"})
	var roof := _piece("roof-high-point")
	roof.position.y = 3.0
	roof.scale = Vector3(1.05, 1.3, 1.05)
	_body.add_child(roof)
	# rotor on the +X face
	_rotor = Node3D.new()
	_rotor.position = Vector3(0.62, 2.45, 0)
	_body.add_child(_rotor)
	var sails := _piece("windmill")
	sails.scale = Vector3.ONE * 0.92
	_rotor.add_child(sails)


func _ring(floor_i: int, default: String, special: Dictionary) -> void:
	var faces := {"px": 0.0, "nz": 90.0, "nx": 180.0, "pz": -90.0}
	for f in faces:
		var w := _piece(special.get(f, default))
		w.position.y = floor_i
		w.rotation_degrees.y = faces[f]
		_body.add_child(w)


func _piece(name: String) -> Node3D:
	return (load(T + name + ".glb") as PackedScene).instantiate()


func _process(delta: float) -> void:
	var target := WORK_SPEED if working else IDLE_SPEED
	_speed = lerpf(_speed, target, clampf(delta * 2.0, 0.0, 1.0))
	_rotor.rotate_x(_speed * delta)


func get_pick_aabb() -> AABB:
	var h := 4.3 * SCALE
	var w := 1.2 * SCALE
	return AABB(global_position + Vector3(-w / 2, 0, -w / 2), Vector3(w, h, w))


func top_world_position() -> Vector3:
	return global_position + Vector3(0, 4.5 * SCALE, 0)


func pop() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1.06, 0.94, 1.06), 0.08)
	tw.tween_property(self, "scale", Vector3(0.97, 1.05, 0.97), 0.1)
	tw.tween_property(self, "scale", Vector3.ONE, 0.12)
