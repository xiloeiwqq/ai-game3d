class_name MenuPreview
extends Node3D

var showcase: Node3D
var camera: Camera3D
var active := true
var time := 0.0

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("071329")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("668bc0")
	env.ambient_light_energy = 0.58
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("102e48")
	env.fog_density = 0.018
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-48, -34, 0)
	moon.light_color = Color("a8d8ff")
	moon.light_energy = 1.25
	moon.shadow_enabled = true
	add_child(moon)
	showcase = Node3D.new()
	showcase.position = Vector3(7.5, -1.6, -2.0)
	add_child(showcase)
	var island := Node3D.new()
	showcase.add_child(island)
	VisualFactory.add_cylinder(island, 6.7, 5.0, 1.6, Vector3(0, -0.8, 0), Color("243a43"))
	VisualFactory.add_cylinder(island, 5.8, 6.6, 0.35, Vector3(0, 0.05, 0), Color("294f42"))
	_add_object("tree_01", Vector3(-2.8, 0.2, 0.8), -20)
	_add_object("tree_01", Vector3(2.8, 0.2, 1.0), 30)
	_add_object("stone_arch", Vector3(0.2, 0.2, -1.2), 90)
	_add_object("crystal_cluster", Vector3(-1.4, 0.2, -2.3), 0)
	_add_object("obelisk", Vector3(2.0, 0.2, -2.1), 0)
	var portal := Node3D.new()
	portal.position = Vector3(0.2, 0.2, -1.2)
	portal.rotation_degrees.y = 90
	showcase.add_child(portal)
	var portal_surface := VisualFactory.add_box(portal, Vector3(0.1, 2.4, 1.7), Vector3(0, 1.45, 0), Color(0.2, 0.85, 1.0, 0.48), Vector3.ZERO, 0.1, 3.2)
	portal_surface.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 1.5, 0)
	glow.light_color = Color("4adfff")
	glow.light_energy = 2.2
	glow.omni_range = 7
	portal.add_child(glow)
	camera = Camera3D.new()
	camera.position = Vector3(7.5, 5.6, 14.0)
	camera.fov = 58
	add_child(camera)
	camera.look_at(Vector3(7.5, 1.5, -1.8))
	camera.current = true

func _add_object(resource_id: String, position_value: Vector3, rotation_y: float) -> void:
	var node := Node3D.new()
	node.position = position_value
	node.rotation_degrees.y = rotation_y
	showcase.add_child(node)
	VisualFactory.build_object(node, resource_id)

func set_active(value: bool) -> void:
	active = value
	visible = value
	set_process(value)
	if camera:
		camera.current = value

func _process(delta: float) -> void:
	if not active or GameSettings.reduce_motion:
		return
	time += delta
	showcase.rotation.y = sin(time * 0.17) * 0.12
	showcase.position.y = -1.6 + sin(time * 0.55) * 0.08
