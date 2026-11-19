class_name VisualFactory
extends RefCounted

static func material(color: Color, metallic: float = 0.0, roughness: float = 0.75, emission: float = 0.0, transparent: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metallic
	result.roughness = roughness
	if emission > 0.0:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = emission
	if transparent:
		result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		result.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return result

static func add_box(parent: Node3D, size: Vector3, position: Vector3, color: Color, rotation := Vector3.ZERO, metallic := 0.0, emission := 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.material_override = material(color, metallic, 0.75, emission)
	parent.add_child(instance)
	return instance

static func add_cylinder(parent: Node3D, top_radius: float, bottom_radius: float, height: float, position: Vector3, color: Color, metallic := 0.0, emission := 0.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 12
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material(color, metallic, 0.72, emission)
	parent.add_child(instance)
	return instance

static func add_sphere(parent: Node3D, radius: float, position: Vector3, color: Color, scale := Vector3.ONE, emission := 0.0) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	instance.scale = scale
	instance.material_override = material(color, 0.0, 0.82, emission)
	parent.add_child(instance)
	return instance

static func add_torus(parent: Node3D, inner_radius: float, outer_radius: float, position: Vector3, color: Color, rotation := Vector3.ZERO, emission := 0.0) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 24
	mesh.ring_segments = 10
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.material_override = material(color, 0.15, 0.28, emission)
	parent.add_child(instance)
	return instance

static func add_collision_box(parent: CollisionObject3D, size: Vector3, position: Vector3) -> CollisionShape3D:
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = position
	parent.add_child(collision)
	return collision

static func build_object(parent: Node3D, resource_id: String) -> void:
	var kind := str(ResourceCatalog.get_resource(resource_id).get("kind", "rock"))
	match kind:
		"tree": _tree(parent)
		"pine": _pine(parent)
		"dead_tree": _dead_tree(parent)
		"mushroom": _mushroom(parent)
		"rock": _rock(parent, false)
		"boulder": _rock(parent, true)
		"wall": _wall(parent, false)
		"ruined_wall": _wall(parent, true)
		"tower": _tower(parent)
		"column": _column(parent, false)
		"pillar": _column(parent, true)
		"arch": _arch(parent)
		"bridge": _bridge(parent)
		"crate": _crate(parent)
		"door": _door(parent)
		"container": _container(parent)
		"console": _console(parent)
		"robot": _robot(parent)
		"statue": _statue(parent)
		"obelisk": _obelisk(parent)
		"torch": _torch(parent, false)
		"lantern": _torch(parent, true)
		"ice_spire": _ice_spire(parent)
		"crystal_cluster": _crystal_cluster(parent)
		_: _rock(parent, false)

static func build_collectible(parent: Node3D, resource_id: String) -> MeshInstance3D:
	var color := Color.from_string(str(ResourceCatalog.get_resource(resource_id).get("color", "48cfff")), Color.CYAN)
	var pivot := Node3D.new()
	pivot.name = "FloatingVisual"
	pivot.position.y = 1.05
	parent.add_child(pivot)
	var core: MeshInstance3D
	if resource_id == "artifact_gold":
		core = add_torus(pivot, 0.14, 0.34, Vector3.ZERO, color, Vector3(PI / 2.0, 0, 0), 3.0)
		add_sphere(pivot, 0.13, Vector3.ZERO, Color(1.0, 0.94, 0.5), Vector3.ONE, 4.0)
	elif resource_id == "energy_cell":
		core = add_cylinder(pivot, 0.2, 0.2, 0.65, Vector3.ZERO, color, 0.55, 3.0)
		add_torus(pivot, 0.21, 0.27, Vector3(0, 0.25, 0), Color.WHITE, Vector3.ZERO, 2.0)
		add_torus(pivot, 0.21, 0.27, Vector3(0, -0.25, 0), Color.WHITE, Vector3.ZERO, 2.0)
	else:
		core = add_box(pivot, Vector3(0.42, 0.68, 0.42), Vector3.ZERO, color, Vector3(0, 0, PI / 4.0), 0.15, 4.0)
		add_box(pivot, Vector3(0.25, 0.30, 0.25), Vector3(0, 0.45, 0), color.lightened(0.25), Vector3(0, PI / 4.0, PI / 4.0), 0.1, 3.0)
	add_torus(pivot, 0.48, 0.52, Vector3.ZERO, color, Vector3(PI / 2.0, 0, 0), 2.5)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.4
	light.omni_range = 4.5
	light.shadow_enabled = false
	pivot.add_child(light)
	return core

static func build_exit(parent: Node3D, resource_id: String) -> MeshInstance3D:
	var sci := resource_id == "airlock_exit"
	var ancient := resource_id == "ancient_gate"
	var frame_color := Color("687a91") if sci else Color("716c70")
	if ancient:
		frame_color = Color("8b795c")
	add_box(parent, Vector3(0.65, 3.8, 0.65), Vector3(0, 1.9, -1.45), frame_color, Vector3.ZERO, 0.45 if sci else 0.0)
	add_box(parent, Vector3(0.65, 3.8, 0.65), Vector3(0, 1.9, 1.45), frame_color, Vector3.ZERO, 0.45 if sci else 0.0)
	add_box(parent, Vector3(0.65, 0.65, 3.55), Vector3(0, 3.65, 0), frame_color, Vector3.ZERO, 0.45 if sci else 0.0)
	var surface := add_box(parent, Vector3(0.12, 2.9, 2.35), Vector3(0, 1.65, 0), Color(0.20, 0.28, 0.34, 0.45), Vector3.ZERO, 0.1, 0.35)
	surface.name = "PortalSurface"
	return surface

static func _tree(parent: Node3D) -> void:
	add_cylinder(parent, 0.28, 0.42, 3.5, Vector3(0, 1.75, 0), Color("61442f"))
	add_sphere(parent, 1.35, Vector3(0, 3.9, 0), Color("2d7452"), Vector3(1.0, 0.82, 1.0))
	add_sphere(parent, 0.95, Vector3(-0.65, 4.35, 0.2), Color("3b9564"), Vector3.ONE)
	add_sphere(parent, 0.9, Vector3(0.7, 4.2, -0.2), Color("28684b"), Vector3.ONE)

static func _pine(parent: Node3D) -> void:
	add_cylinder(parent, 0.18, 0.28, 3.2, Vector3(0, 1.6, 0), Color("554235"))
	add_cylinder(parent, 0.0, 1.25, 2.7, Vector3(0, 2.5, 0), Color("285d51"))
	add_cylinder(parent, 0.0, 0.95, 2.3, Vector3(0, 3.6, 0), Color("347568"))
	add_cylinder(parent, 0.0, 0.7, 1.8, Vector3(0, 4.45, 0), Color("c7e8e7"))

static func _dead_tree(parent: Node3D) -> void:
	add_cylinder(parent, 0.2, 0.38, 3.9, Vector3(0, 1.95, 0), Color("4b3c39"))
	add_box(parent, Vector3(0.25, 2.0, 0.25), Vector3(0.45, 3.2, 0), Color("54423c"), Vector3(0, 0, -0.7))
	add_box(parent, Vector3(0.22, 1.5, 0.22), Vector3(-0.4, 3.45, 0.1), Color("493936"), Vector3(0.2, 0, 0.8))

static func _mushroom(parent: Node3D) -> void:
	add_cylinder(parent, 0.2, 0.35, 1.55, Vector3(0, 0.78, 0), Color("d8c9ad"))
	add_sphere(parent, 0.9, Vector3(0, 1.72, 0), Color("9159bd"), Vector3(1.0, 0.38, 1.0), 0.5)
	for offset in [Vector3(0.3, 1.92, 0.2), Vector3(-0.35, 1.9, 0.05), Vector3(0.0, 1.9, -0.4)]:
		add_sphere(parent, 0.08, offset, Color("c8f6ff"), Vector3.ONE, 2.0)

static func _rock(parent: Node3D, large: bool) -> void:
	var scale := Vector3(1.45, 1.1, 1.25) if large else Vector3(0.72, 0.62, 0.65)
	var position := Vector3(0, 1.15, 0) if large else Vector3(0, 0.6, 0)
	add_sphere(parent, 1.0, position, Color("657078"), scale)
	add_sphere(parent, 0.55, position + Vector3(0.55, 0.25, -0.25), Color("78838a"), scale * 0.65)

static func _wall(parent: Node3D, ruined: bool) -> void:
	var color := Color("716b68")
	for y in (2 if ruined else 3):
		for z in 3:
			if ruined and y == 1 and z == 2:
				continue
			add_box(parent, Vector3(1.35, 0.78, 1.05), Vector3(0, 0.4 + y * 0.76, -1.05 + z * 1.05), color.lightened(0.04 * ((y + z) % 2)), Vector3(0, 0.02 * (z - 1), 0))

static func _tower(parent: Node3D) -> void:
	add_cylinder(parent, 1.55, 1.72, 5.2, Vector3(0, 2.6, 0), Color("666269"))
	for index in 8:
		var angle := TAU * index / 8.0
		add_box(parent, Vector3(0.55, 0.65, 0.55), Vector3(cos(angle) * 1.45, 5.4, sin(angle) * 1.45), Color("79747b"), Vector3(0, -angle, 0))

static func _column(parent: Node3D, ornate: bool) -> void:
	var color := Color("928a7c") if ornate else Color("797576")
	add_cylinder(parent, 0.42, 0.52, 3.5 if ornate else 3.1, Vector3(0, 2.0, 0), color)
	add_box(parent, Vector3(1.05, 0.35, 1.05), Vector3(0, 0.18, 0), color.lightened(0.08))
	add_box(parent, Vector3(1.0, 0.35, 1.0), Vector3(0, 3.65 if ornate else 3.45, 0), color.lightened(0.08))
	if ornate:
		add_torus(parent, 0.43, 0.55, Vector3(0, 0.55, 0), Color("b09c6a"))

static func _arch(parent: Node3D) -> void:
	add_box(parent, Vector3(1.1, 3.5, 0.7), Vector3(0, 1.75, -1.35), Color("77716e"))
	add_box(parent, Vector3(1.1, 3.5, 0.7), Vector3(0, 1.75, 1.35), Color("77716e"))
	add_box(parent, Vector3(1.1, 0.8, 3.4), Vector3(0, 3.35, 0), Color("857d78"))

static func _bridge(parent: Node3D) -> void:
	add_box(parent, Vector3(5.6, 0.35, 1.7), Vector3(0, 0.18, 0), Color("807b75"))
	for x in [-2.3, -1.2, 0.0, 1.2, 2.3]:
		add_box(parent, Vector3(0.12, 0.8, 0.12), Vector3(x, 0.55, -0.75), Color("a39b8b"))
		add_box(parent, Vector3(0.12, 0.8, 0.12), Vector3(x, 0.55, 0.75), Color("a39b8b"))

static func _crate(parent: Node3D) -> void:
	add_box(parent, Vector3(1.15, 1.15, 1.15), Vector3(0, 0.58, 0), Color("765038"))
	for y in [0.08, 1.07]:
		add_box(parent, Vector3(1.25, 0.1, 1.25), Vector3(0, y, 0), Color("9a7048"))

static func _door(parent: Node3D) -> void:
	add_box(parent, Vector3(0.38, 2.75, 1.45), Vector3(0, 1.38, 0), Color("5c3f33"))
	add_torus(parent, 0.1, 0.15, Vector3(-0.22, 1.35, 0.42), Color("c2a45e"), Vector3(0, 0, PI / 2.0), 0.25)

static func _container(parent: Node3D) -> void:
	add_box(parent, Vector3(1.65, 1.65, 3.25), Vector3(0, 0.83, 0), Color("6d7983"), Vector3.ZERO, 0.65)
	for z in [-1.2, -0.4, 0.4, 1.2]:
		add_box(parent, Vector3(1.75, 0.08, 0.08), Vector3(0, 1.05, z), Color("aab5bd"), Vector3.ZERO, 0.8)
	add_box(parent, Vector3(0.04, 0.18, 1.0), Vector3(-0.84, 1.25, 0), Color("ff824f"), Vector3.ZERO, 0.1, 2.0)

static func _console(parent: Node3D) -> void:
	add_box(parent, Vector3(1.4, 1.0, 0.85), Vector3(0, 0.5, 0), Color("404b55"), Vector3.ZERO, 0.7)
	add_box(parent, Vector3(1.1, 0.08, 0.6), Vector3(0, 1.05, -0.08), Color("57d6ff"), Vector3(-0.25, 0, 0), 0.2, 2.2)

static func _robot(parent: Node3D) -> void:
	add_cylinder(parent, 0.36, 0.45, 0.85, Vector3(0, 0.9, 0), Color("8a949b"), 0.75)
	add_sphere(parent, 0.38, Vector3(0, 1.55, 0), Color("626f79"), Vector3(1.0, 0.8, 1.0))
	add_box(parent, Vector3(0.08, 0.12, 0.38), Vector3(-0.37, 1.58, 0), Color("ff4e4e"), Vector3.ZERO, 0.2, 3.0)
	add_box(parent, Vector3(0.2, 0.8, 0.2), Vector3(-0.48, 0.65, 0), Color("65717a"))
	add_box(parent, Vector3(0.2, 0.8, 0.2), Vector3(0.48, 0.65, 0), Color("65717a"))

static func _statue(parent: Node3D) -> void:
	add_box(parent, Vector3(1.1, 0.45, 1.1), Vector3(0, 0.23, 0), Color("77797a"))
	add_cylinder(parent, 0.35, 0.48, 1.6, Vector3(0, 1.22, 0), Color("868787"))
	add_sphere(parent, 0.32, Vector3(0, 2.3, 0), Color("8e908f"), Vector3(0.85, 1.05, 0.85))
	add_box(parent, Vector3(0.18, 1.6, 0.18), Vector3(0.48, 1.65, 0), Color("9a8361"), Vector3(0, 0, 0.12), 0.4)

static func _obelisk(parent: Node3D) -> void:
	add_box(parent, Vector3(0.8, 3.0, 0.8), Vector3(0, 1.55, 0), Color("333b49"), Vector3(0, PI / 4.0, 0), 0.25)
	add_box(parent, Vector3(0.58, 0.58, 0.58), Vector3(0, 3.25, 0), Color("7e64d8"), Vector3(0, PI / 4.0, PI / 4.0), 0.2, 1.7)

static func _torch(parent: Node3D, futuristic: bool) -> void:
	var color := Color("63ddff") if futuristic else Color("ff923d")
	add_cylinder(parent, 0.08, 0.1, 1.45, Vector3(0, 0.73, 0), Color("64686d") if futuristic else Color("513c2c"), 0.7 if futuristic else 0.0)
	add_sphere(parent, 0.19, Vector3(0, 1.55, 0), color, Vector3(0.8, 1.35, 0.8), 4.0)
	var light := OmniLight3D.new()
	light.position.y = 1.55
	light.light_color = color
	light.light_energy = 2.0
	light.omni_range = 5.0
	light.shadow_enabled = false
	parent.add_child(light)

static func _ice_spire(parent: Node3D) -> void:
	add_cylinder(parent, 0.05, 0.62, 3.4, Vector3(0, 1.7, 0), Color(0.50, 0.84, 0.96, 0.92), 0.15, 0.65)
	add_cylinder(parent, 0.02, 0.32, 2.0, Vector3(0.48, 1.0, 0.18), Color("9edfff"), 0.1, 0.4)

static func _crystal_cluster(parent: Node3D) -> void:
	for item in [[Vector3.ZERO, 1.5, 0.3], [Vector3(0.35, 0, 0.2), 1.0, -0.25], [Vector3(-0.3, 0, 0.25), 0.85, 0.2]]:
		var offset: Vector3 = item[0]
		var height: float = item[1]
		var tilt: float = item[2]
		var crystal := add_cylinder(parent, 0.05, 0.28, height, offset + Vector3(0, height / 2.0, 0), Color("65cffa"), 0.15, 1.6)
		crystal.rotation.z = tilt
