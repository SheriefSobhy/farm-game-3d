extends Node
## Renders small 3D models to transparent PNG icons in res://assets/icons/.
## Run from a terminal:  Godot --path . res://tools/bake_icons.tscn
## (Only needed when you want to change the icons.)

const SIZE := 256
const OUT := "res://assets/icons/"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _bake("coin", _coin(), Vector3(0, 0, 0), 1.25)
	await _bake("gem", _gem(), Vector3(0, 0.02, 0), 1.25)
	await _bake("star", _star(), Vector3.ZERO, 1.25)
	await _bake("wheat", _wheat(), Vector3(0, 0.55, 0), 1.35)
	print("Icons baked.")
	get_tree().quit()


func _bake(name: String, model: Node3D, center: Vector3, size: float) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(SIZE, SIZE)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 0.97, 0.92)
	e.ambient_light_energy = 0.75
	env.environment = e
	vp.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 30, 0)
	light.light_energy = 1.25
	vp.add_child(light)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = size
	cam.position = center + Vector3(0, 0.25, 3)
	vp.add_child(cam)
	cam.look_at(center)
	vp.add_child(model)
	for i in 4:
		await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.save_png(OUT + name + ".png")
	vp.queue_free()


func _mat(c: Color, metal := 0.0, rough := 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rough
	return m


func _coin() -> Node3D:
	var root := Node3D.new()
	var outer := MeshInstance3D.new()
	var cy := CylinderMesh.new()
	cy.top_radius = 0.5
	cy.bottom_radius = 0.5
	cy.height = 0.14
	cy.radial_segments = 24
	cy.material = _mat(Color("e08e0b"), 0.1, 0.5)
	outer.mesh = cy
	root.add_child(outer)
	var inner := MeshInstance3D.new()
	var cy2 := CylinderMesh.new()
	cy2.top_radius = 0.37
	cy2.bottom_radius = 0.37
	cy2.height = 0.17
	cy2.radial_segments = 24
	cy2.material = _mat(Color("f5b81c"), 0.1, 0.45)
	inner.mesh = cy2
	root.add_child(inner)
	root.rotation_degrees = Vector3(62, 0, -12)
	return root


func _gem() -> Node3D:
	var root := Node3D.new()
	var mat := _mat(Color("37d67a"), 0.1, 0.15)
	var crown := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.28
	c.bottom_radius = 0.48
	c.height = 0.2
	c.radial_segments = 6
	c.rings = 0
	c.material = mat
	crown.mesh = c
	crown.position.y = 0.14
	root.add_child(crown)
	var pav := MeshInstance3D.new()
	var p := CylinderMesh.new()
	p.top_radius = 0.48
	p.bottom_radius = 0.0
	p.height = 0.5
	p.radial_segments = 6
	p.rings = 0
	p.material = mat
	pav.mesh = p
	pav.position.y = -0.21
	root.add_child(pav)
	root.rotation_degrees = Vector3(12, 15, 0)
	return root


func _star() -> Node3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector2] = []
	for i in 10:
		var r := 0.52 if i % 2 == 0 else 0.24
		var a := PI / 2 + i * TAU / 10
		pts.append(Vector2(cos(a), sin(a)) * r)
	var front := 0.1
	var tip := Vector3(0, 0, 0.22)
	# front faces: pyramid towards the viewer for a faceted look
	for i in 10:
		var a := pts[i]
		var b := pts[(i + 1) % 10]
		st.add_vertex(Vector3(a.x, a.y, front))
		st.add_vertex(Vector3(b.x, b.y, front))
		st.add_vertex(tip)
	# side walls
	for i in 10:
		var a := pts[i]
		var b := pts[(i + 1) % 10]
		st.add_vertex(Vector3(a.x, a.y, front))
		st.add_vertex(Vector3(a.x, a.y, -front))
		st.add_vertex(Vector3(b.x, b.y, front))
		st.add_vertex(Vector3(b.x, b.y, front))
		st.add_vertex(Vector3(a.x, a.y, -front))
		st.add_vertex(Vector3(b.x, b.y, -front))
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _mat(Color("ffcf26"), 0.1, 0.35)
	mi.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	var root := Node3D.new()
	root.add_child(mi)
	root.rotation_degrees = Vector3(-8, 0, 0)
	return root


func _wheat() -> Node3D:
	# A chunky wheat sheaf: stalks fanning out from a tied band, fat golden ears on top.
	var root := Node3D.new()
	var stalk_mat := _mat(Color("e9b83a"), 0.0, 0.8)
	var ear_mat := _mat(Color("f7cf45"), 0.0, 0.6)
	var stalk := CylinderMesh.new()
	stalk.top_radius = 0.025
	stalk.bottom_radius = 0.025
	stalk.height = 1.0
	stalk.radial_segments = 6
	stalk.material = stalk_mat
	var ear := CylinderMesh.new()
	ear.top_radius = 0.0
	ear.bottom_radius = 0.085
	ear.height = 0.26
	ear.radial_segments = 6
	ear.material = ear_mat
	var ear_low := CylinderMesh.new()
	ear_low.top_radius = 0.085
	ear_low.bottom_radius = 0.03
	ear_low.height = 0.12
	ear_low.radial_segments = 6
	ear_low.material = ear_mat
	var n := 9
	for i in n:
		var a := (i - (n - 1) / 2.0) / ((n - 1) / 2.0)   # -1..1
		var piv := Node3D.new()
		piv.position = Vector3(0, 0.38, (i % 2) * 0.04)
		piv.rotation = Vector3(0, 0, -a * 0.38)
		root.add_child(piv)
		var s := MeshInstance3D.new()
		s.mesh = stalk
		s.position.y = 0.06
		piv.add_child(s)
		var top := 0.56 - absf(a) * 0.08
		var e := MeshInstance3D.new()
		e.mesh = ear
		e.position.y = top + 0.16
		piv.add_child(e)
		var e2 := MeshInstance3D.new()
		e2.mesh = ear_low
		e2.position.y = top - 0.06
		piv.add_child(e2)
	var band := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.1
	tor.outer_radius = 0.16
	tor.material = _mat(Color("c0602a"), 0.0, 0.7)
	band.mesh = tor
	band.position.y = 0.38
	band.scale = Vector3(1.0, 0.9, 0.8)
	root.add_child(band)
	root.rotation_degrees.y = 10
	return root
