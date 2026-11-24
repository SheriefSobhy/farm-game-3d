extends Node3D
## One farm plot. Reads its state from Game.plots[index] and shows the right crop stage.

const SIZE := 2.4
const STAGE_MODELS := {  # paths, loaded through ModelUtil
	1: "res://assets/models/nature/crops_leafsStageA.glb",
	2: "res://assets/models/nature/crops_wheatStageA.glb",
	3: "res://assets/models/nature/crops_wheatStageB.glb",
}
const STAGE_SCALE := {1: 1.1, 2: 1.35, 3: 1.45}
const DIRT_ROW := "res://assets/models/nature/crops_dirtRow.glb"
const TALL_COLOR := Color("b9d94a")
const RIPE_COLOR := Color("f5c63c")
const ROWS := 3
const PER_ROW := 3

var index := 0
var _stage := -1
var _crop_root: Node3D
var _tufts: Array[Node3D] = []
var _sway_time := 0.0


func _ready() -> void:
	_sway_time = randf() * 10.0
	_build_soil()
	_crop_root = Node3D.new()
	_crop_root.position.y = 0.2
	add_child(_crop_root)
	refresh(true)


func _build_soil() -> void:
	var base := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(SIZE, 0.22, SIZE)
	base.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("8a5a36")
	mat.roughness = 1.0
	box.material = mat
	base.position.y = 0.06
	add_child(base)
	# rim
	var rim := MeshInstance3D.new()
	var rbox := BoxMesh.new()
	rbox.size = Vector3(SIZE + 0.18, 0.12, SIZE + 0.18)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color("6b4126")
	rmat.roughness = 1.0
	rbox.material = rmat
	rim.mesh = rbox
	rim.position.y = 0.0
	add_child(rim)
	for r in ROWS:
		var row: Node3D = ModelUtil.load_model(DIRT_ROW)
		row.scale = Vector3(SIZE * 0.95, 3.0, 1.15)
		row.position = Vector3(0, 0.2, (r - (ROWS - 1) / 2.0) * SIZE / ROWS)
		add_child(row)


func _process(delta: float) -> void:
	refresh()
	if _stage > 3 or _stage == 3:
		_sway_time += delta
		var ripe := _stage > 3
		var amp := 0.12 if ripe else 0.04
		for i in _tufts.size():
			var t := _tufts[i]
			t.rotation.z = sin(_sway_time * 2.2 + i * 0.7) * amp
			t.rotation.x = cos(_sway_time * 1.7 + i * 0.9) * amp * 0.5


## Rebuild crop meshes if the stage changed.
func refresh(force := false) -> void:
	var s := Game.plot_stage(index)
	if s == _stage and not force:
		return
	var grew := s > _stage and _stage > 0
	_stage = s
	for c in _crop_root.get_children():
		c.queue_free()
	_tufts.clear()
	if s == 0:
		return
	var model_stage := mini(s, 3)
	var path: String = STAGE_MODELS[model_stage]
	var sc: float = STAGE_SCALE[model_stage]
	for r in ROWS:
		for k in PER_ROW:
			var t: Node3D = ModelUtil.load_model(path)
			var x := (k - (PER_ROW - 1) / 2.0) * SIZE / PER_ROW
			var z := (r - (ROWS - 1) / 2.0) * SIZE / ROWS
			t.position = Vector3(x + randf_range(-0.08, 0.08), 0, z + randf_range(-0.05, 0.05))
			t.rotation.y = randf_range(-0.4, 0.4)
			t.scale = Vector3.ONE * sc * randf_range(0.9, 1.08)
			_crop_root.add_child(t)
			_tufts.append(t)
			if s > 3:
				ModelUtil.tint(t, ModelUtil.color_material(RIPE_COLOR))
			elif s == 3:
				ModelUtil.tint(t, ModelUtil.color_material(TALL_COLOR))
	if grew:
		pop()


## Little bounce animation.
func pop() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1.08, 0.9, 1.08), 0.08)
	tw.tween_property(self, "scale", Vector3(0.96, 1.08, 0.96), 0.1)
	tw.tween_property(self, "scale", Vector3.ONE, 0.12)


func shake() -> void:
	var tw := create_tween()
	var p := position
	for i in 4:
		tw.tween_property(self, "position", p + Vector3(0.12 if i % 2 == 0 else -0.12, 0, 0), 0.04)
	tw.tween_property(self, "position", p, 0.04)


func get_pick_aabb() -> AABB:
	return AABB(global_position + Vector3(-SIZE / 2, -0.1, -SIZE / 2), Vector3(SIZE, 1.4, SIZE))


func top_world_position() -> Vector3:
	return global_position + Vector3(0, 0.9, 0)


func burst() -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = 28
	p.lifetime = 0.9
	p.explosiveness = 0.95
	var m := BoxMesh.new()
	m.size = Vector3(0.14, 0.14, 0.14)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("ffd54a")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material = mat
	p.mesh = m
	p.direction = Vector3.UP
	p.spread = 55.0
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 7.0
	p.gravity = Vector3(0, -14, 0)
	p.angular_velocity_min = -360
	p.angular_velocity_max = 360
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	p.color = Color.WHITE
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(SIZE * 0.4, 0.2, SIZE * 0.4)
	p.position = Vector3(0, 0.6, 0)
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)
