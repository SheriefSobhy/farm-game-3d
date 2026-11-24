class_name ModelUtil
extends RefCounted
## Loads Kenney models and gives them one consistent bright, warm palette.
## (The Nature Kit .glb files ship with metallic=1 and washed-out colors,
## so we swap each named material for our own shared material.)

const PALETTE := {
	"grass": Color("5fbf3a"),
	"leafsGreen": Color("5cbd3c"),
	"leafsDark": Color("3f9a4a"),
	"dirt": Color("a06a40"),
	"dirtDark": Color("7a4b2c"),
	"wood": Color("d6995a"),
	"woodDark": Color("a8683a"),
	"woodInner": Color("f0d29a"),
	"woodBark": Color("8b5a33"),
	"woodBarkDark": Color("6e4426"),
	"stone": Color("d9d5cc"),
	"stoneDark": Color("b3aca3"),
	"colorRed": Color("ef4b4b"),
	"colorYellow": Color("ffd23f"),
	"colorPurple": Color("b07be8"),
	"_defaultMat": Color("f4efe6"),
}

static var _cache: Dictionary = {}
static var _scenes: Dictionary = {}


static func material(name: String, fallback := Color.WHITE) -> StandardMaterial3D:
	if _cache.has(name):
		return _cache[name]
	var m := StandardMaterial3D.new()
	m.albedo_color = PALETTE.get(name, fallback)
	m.metallic = 0.0
	m.roughness = 0.85
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	_cache[name] = m
	return m


static func color_material(c: Color) -> StandardMaterial3D:
	return material("#" + c.to_html(false), c)


## Instantiate a .glb and fix its materials.
static func load_model(path: String) -> Node3D:
	if not _scenes.has(path):
		_scenes[path] = load(path)
	var n: Node3D = (_scenes[path] as PackedScene).instantiate()
	fix(n)
	return n


static func fix(root: Node) -> void:
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var inst := mi as MeshInstance3D
		var mesh := inst.mesh
		if mesh == null:
			continue
		for s in mesh.get_surface_count():
			var src := mesh.surface_get_material(s) as StandardMaterial3D
			if src == null or src.albedo_texture != null:
				continue  # textured (Fantasy Town / Food kits) are already fine
			inst.set_surface_override_material(s, material(src.resource_name, src.albedo_color))


## Replace every surface with one material (used for crop color stages).
static func tint(root: Node, mat: Material) -> void:
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = mat


static func no_shadows(root: Node) -> void:
	for gi in root.find_children("*", "GeometryInstance3D", true, false):
		(gi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
