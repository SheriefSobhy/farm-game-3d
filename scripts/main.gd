extends Node3D
## Builds the farm world and connects taps to game actions.

const PlotScript := preload("res://scripts/plot.gd")
const MillScript := preload("res://scripts/mill.gd")
const CameraRig := preload("res://scripts/camera_rig.gd")
const Hud := preload("res://scripts/ui/hud.gd")
const N := "res://assets/models/nature/"

const PLOT_SPACING := 2.85
const PLOT_ORIGIN := Vector3(-5.35, 0, 1.0)   # position of plot 0
const PLOT_COLUMNS := 3
const MILL_POS := Vector3(0.6, 0, -4.2)
const FARM_HALF := 11.0                        # fence goes around this square

var cam: Node3D
var hud: CanvasLayer
var plots: Array = []
var mill: Node3D


func _ready() -> void:
	_build_environment()
	_build_ground()
	_build_decor()
	_build_plots()
	mill = MillScript.new()
	mill.position = MILL_POS
	mill.rotation_degrees.y = -25
	add_child(mill)

	cam = CameraRig.new()
	cam.position = Vector3(0.0, 0, 0.0)
	add_child(cam)
	cam.tapped.connect(_on_tapped)

	hud = Hud.new()
	add_child(hud)
	Game.plots_changed.connect(_sync_plots)

	if not _screenshot_mode():
		hud.toast.call_deferred("Tap a plot to plant wheat!")


# ---------------- World ----------------
func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("4fa8ef")
	sm.sky_horizon_color = Color("bfe6ff")
	sm.ground_horizon_color = Color("bfe6ff")
	sm.ground_bottom_color = Color("bfe6ff")
	sm.sun_angle_max = 30.0
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dfe9ff")
	env.ambient_light_energy = 0.3
	env.ambient_light_sky_contribution = 0.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 20, 0)
	sun.light_color = Color("fff1dc")
	sun.light_energy = 0.6
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.7
	sun.shadow_blur = 1.5
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 60.0
	sun.shadow_bias = 0.04
	add_child(sun)


func _build_ground() -> void:
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(160, 160)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("6aa83f")
	mat.roughness = 1.0
	pm.material = mat
	g.mesh = pm
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(g)
	# slightly lighter farm yard inside the fence
	var yard := MeshInstance3D.new()
	var ym := PlaneMesh.new()
	ym.size = Vector2(FARM_HALF * 2, FARM_HALF * 2)
	var ymat := StandardMaterial3D.new()
	ymat.albedo_color = Color("84bb4a")
	ymat.roughness = 1.0
	ym.material = ymat
	yard.mesh = ym
	yard.position.y = 0.01
	yard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(yard)


func _model(file: String, pos: Vector3, scale := 2.5, rot_y := 0.0, shadows := true) -> Node3D:
	var n: Node3D = ModelUtil.load_model(N + file + ".glb")
	n.position = pos
	n.scale = Vector3.ONE * scale
	n.rotation_degrees.y = rot_y
	if not shadows:
		for mi in n.find_children("*", "GeometryInstance3D", true, false):
			(mi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(n)
	return n


func _build_decor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# Fence around the yard: 8 segments per side
	var seg := FARM_HALF * 2.0 / 8.0
	var half := seg / 2.0
	for i in 8:
		var p := -FARM_HALF + half + i * seg
		# fence_simple runs along X and sits on the -Z edge of its tile
		_model("fence_gate" if i == 4 else "fence_simple", Vector3(p, 0, FARM_HALF + half), seg, 0)
		_model("fence_simple", Vector3(p, 0, -FARM_HALF + half), seg, 0)
		_model("fence_simple", Vector3(FARM_HALF - half, 0, p), seg, -90)
		_model("fence_simple", Vector3(-FARM_HALF - half, 0, p), seg, -90)

	# Trees around the outside
	var trees := ["tree_oak", "tree_default", "tree_fat", "tree_detailed", "tree_pineRoundA"]
	for i in 34:
		var a := rng.randf() * TAU
		var r := rng.randf_range(FARM_HALF + 3.0, FARM_HALF + 13.0)
		var pos := Vector3(cos(a) * r, 0, sin(a) * r)
		_model(trees[rng.randi() % trees.size()], pos, rng.randf_range(2.6, 3.6), rng.randf() * 360)
	# A few bushes, rocks, flowers, grass inside and outside
	var small := ["plant_bush", "plant_bushLarge", "plant_bushSmall", "rock_smallA", "rock_smallB",
		"flower_redA", "flower_yellowA", "flower_purpleA", "grass", "grass_large", "mushroom_red"]
	var placed := 0
	while placed < 70:
		var pos := Vector3(rng.randf_range(-FARM_HALF - 8, FARM_HALF + 8), 0, rng.randf_range(-FARM_HALF - 8, FARM_HALF + 8))
		if _blocked(pos):
			continue
		var f: String = small[rng.randi() % small.size()]
		_model(f, pos, rng.randf_range(2.2, 3.2), rng.randf() * 360, f.begins_with("plant") or f.begins_with("rock"))
		placed += 1
	# Cozy props near the mill
	_model("log_stack", MILL_POS + Vector3(-2.4, 0, -1.0), 2.5, 30)
	_model("stump_round", MILL_POS + Vector3(-1.8, 0, 2.2), 2.5, 0)
	_model("sign", Vector3(-1.0, 0, FARM_HALF - 1.6), 2.5, 0)
	for i in 4:
		_model("path_stone", MILL_POS + Vector3(2.4 + i * 2.5, 0, 0.6), 2.5, 0, false)


## Keep small decorations off plots, the mill area and the fence line.
func _blocked(pos: Vector3) -> bool:
	if absf(absf(pos.x) - FARM_HALF) < 1.2 or absf(absf(pos.z) - FARM_HALF) < 1.2:
		return true
	var plot_min := PLOT_ORIGIN - Vector3(1.8, 0, 1.8)
	var plot_max := PLOT_ORIGIN + Vector3(PLOT_SPACING * 2 + 1.8, 0, PLOT_SPACING * 3 + 1.8)
	if pos.x > plot_min.x and pos.x < plot_max.x and pos.z > plot_min.z and pos.z < plot_max.z:
		return true
	if pos.distance_to(MILL_POS) < 4.0:
		return true
	if pos.z > MILL_POS.z - 1.0 and pos.z < MILL_POS.z + 2.0 and pos.x > MILL_POS.x and pos.x < MILL_POS.x + 12.0:
		return true
	# keep the near centre area tidy (future buildings go here)
	if pos.x > 0.0 and pos.x < FARM_HALF and pos.z > -1.0 and pos.z < FARM_HALF:
		return true
	return false


func plot_position(i: int) -> Vector3:
	return PLOT_ORIGIN + Vector3((i % PLOT_COLUMNS) * PLOT_SPACING, 0, (i / PLOT_COLUMNS) * PLOT_SPACING)


func _build_plots() -> void:
	_sync_plots()


func _sync_plots() -> void:
	while plots.size() < Game.plots.size():
		var p := PlotScript.new()
		p.index = plots.size()
		p.position = plot_position(p.index)
		add_child(p)
		plots.append(p)


# ---------------- Input ----------------
func _on_tapped(screen_pos: Vector2) -> void:
	var camera: Camera3D = cam.camera
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var best: Node3D = null
	var best_d := INF
	var candidates: Array = plots.duplicate()
	candidates.append(mill)
	for c in candidates:
		var hit = (c.get_pick_aabb() as AABB).intersects_ray(from, dir)
		if hit != null:
			var d := from.distance_to(hit)
			if d < best_d:
				best_d = d
				best = c
	if best == null:
		return
	if best == mill:
		_tap_mill()
	else:
		_tap_plot(best)


func _screen_of(world: Vector3) -> Vector2:
	return (cam.camera as Camera3D).unproject_position(world)


func _tap_plot(p) -> void:
	var i: int = p.index
	var screen := _screen_of(p.top_world_position())
	if Game.plot_is_ripe(i):
		var amount := Game.harvest(i)
		p.burst()
		p.pop()
		hud.float_text("+%d" % amount, screen, Color.WHITE, hud.ITEM_ICONS["wheat"])
		hud.fly_icon(hud.ITEM_ICONS["wheat"], screen, hud.star_icon, amount)
	elif Game.plots[i].crop == "":
		var err := Game.plant(i, "wheat")
		if err == "":
			p.refresh(true)
			p.pop()
			hud.float_text("-%d" % Config.CROPS.wheat.seed_cost, screen, Color("ffe066"), hud.ICON_COIN)
		else:
			p.shake()
			hud.toast(err, UIStyle.RED)
	else:
		p.pop()
		hud.toast("Ready in %ds" % ceili(Game.plot_time_left(i)))


func _tap_mill() -> void:
	mill.pop()
	mill.working = true
	hud.toast("Mill: turns wheat into flour (soon!)")
	get_tree().create_timer(2.0).timeout.connect(func(): mill.working = false)


# ---------------- Screenshot helper (for development) ----------------
func _screenshot_mode() -> bool:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screenshot="):
			_take_screenshot.call_deferred(a.trim_prefix("--screenshot="))
			return true
	return false


func _take_screenshot(path: String) -> void:
	var t := Game.now()
	var stage_time: float = Config.CROPS.wheat.stage_time
	Game.plots[0] = {"crop": "wheat", "planted_at": t - stage_time * 10}
	Game.plots[1] = {"crop": "wheat", "planted_at": t - stage_time * 1.5}
	Game.plots[2] = {"crop": "wheat", "planted_at": t - stage_time * 0.5}
	for p in plots:
		p.refresh(true)
	for i in 60:
		await get_tree().process_frame
	if "--tap-test" in OS.get_cmdline_user_args():
		# Simulate real finger taps: harvest ripe plot 0, then tap growing plot 2.
		var coins_before := Game.coins
		for idx in [0, 2]:
			# parse_input_event expects window pixels, so convert from viewport coordinates
			var pos := get_viewport().get_final_transform() * _screen_of(plots[idx].global_position)
			for pressed in [true, false]:
				var ev := InputEventScreenTouch.new()
				ev.index = 0
				ev.position = pos
				ev.pressed = pressed
				Input.parse_input_event(ev)
				await get_tree().process_frame
		print("TAPTEST wheat=", Game.item_count("wheat"), " xp=", Game.xp, " coins ", coins_before, "->", Game.coins,
			" plot0=", Game.plots[0].crop, " plot2=", Game.plots[2].crop)
		for i in 14:
			await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	get_tree().quit()
