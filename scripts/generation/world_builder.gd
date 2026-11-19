class_name WorldBuilder
extends Node3D

signal build_completed(stats: Dictionary)
signal exit_reached

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const OBJECT_SCENE := preload("res://scenes/objects/resource_object.tscn")
const COLLECTIBLE_SCENE := preload("res://scenes/objects/collectible.tscn")
const EXIT_SCENE := preload("res://scenes/objects/exit_portal.tscn")

var world_data: Dictionary
var player: FPSPlayer
var exit_portal: ExitPortal
var _cell_size := 2.5
var _width := 20
var _depth := 20

func build(data: Dictionary) -> Dictionary:
	var started := Time.get_ticks_usec()
	world_data = data.duplicate(true)
	_cell_size = float(data.map.cell_size)
	_width = int(data.map.width)
	_depth = int(data.map.depth)
	_setup_environment(str(data.theme_id), data.environment)
	_create_floor(str(data.environment.floor_id))
	_create_boundaries(str(data.theme_id))
	for placement in data.objects:
		_create_object(placement)
	for index in data.collectibles.size():
		_create_collectible(data.collectibles[index], index)
	_create_exit(data.exit)
	_create_player(data.player_start)
	var elapsed := (Time.get_ticks_usec() - started) / 1000.0
	var stats := {"build_ms": elapsed, "objects": data.objects.size(), "map_cells": _width * _depth}
	build_completed.emit(stats)
	return stats

func _setup_environment(theme: String, environment_data: Dictionary) -> void:
	var palettes := {
		"fantasy_forest": {"sky": Color("132a3a"), "ambient": Color("78a9a0"), "sun": Color("ffe0ad"), "fog": Color("173d3e")},
		"abandoned_castle": {"sky": Color("171b2d"), "ambient": Color("6c7794"), "sun": Color("b9c6e4"), "fog": Color("252b3e")},
		"mars_station": {"sky": Color("3e1718"), "ambient": Color("c8785f"), "sun": Color("ffbe85"), "fog": Color("6b2f28")},
		"ancient_temple": {"sky": Color("171817"), "ambient": Color("9d875c"), "sun": Color("ffd98a"), "fog": Color("302c20")},
		"ice_cave": {"sky": Color("0b2138"), "ambient": Color("77b5db"), "sun": Color("d7f3ff"), "fog": Color("1b4861")}
	}
	var palette: Dictionary = palettes.get(theme, palettes.fantasy_forest)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = palette.sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = palette.ambient
	env.ambient_light_energy = 0.72
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = palette.fog
	env.fog_light_energy = 0.75
	env.fog_density = 0.007 if theme != "ice_cave" else 0.013
	env.fog_sky_affect = 0.55
	var world_environment := WorldEnvironment.new()
	world_environment.environment = env
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_color = palette.sun
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)

func _create_floor(floor_id: String) -> void:
	var colors := {
		"forest_ground": Color("233d2e"), "castle_stone": Color("45474c"), "mars_dust": Color("7a3e2e"),
		"temple_stone": Color("5e5745"), "ice_floor": Color("4f829a"), "snow_ground": Color("b8d4db"), "sand_ground": Color("8d7047")
	}
	var floor_color: Color = colors.get(floor_id, Color("3e4548"))
	var size := Vector3(_width * _cell_size, 0.4, _depth * _cell_size)
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1
	add_child(floor_body)
	VisualFactory.add_box(floor_body, size, Vector3(0, -0.2, 0), floor_color)
	VisualFactory.add_collision_box(floor_body, size, Vector3(0, -0.2, 0))
	# A sparse inlaid grid makes scale and paths readable without expensive textures.
	var line_color := floor_color.lightened(0.08)
	for x in range(0, _width + 1, 2):
		var px := (x - _width / 2.0) * _cell_size
		VisualFactory.add_box(floor_body, Vector3(0.025, 0.012, _depth * _cell_size), Vector3(px, 0.012, 0), line_color)
	for z in range(0, _depth + 1, 2):
		var pz := (z - _depth / 2.0) * _cell_size
		VisualFactory.add_box(floor_body, Vector3(_width * _cell_size, 0.012, 0.025), Vector3(0, 0.012, pz), line_color)

func _create_boundaries(theme: String) -> void:
	var width_world := _width * _cell_size
	var depth_world := _depth * _cell_size
	var wall_color := Color("24313c")
	if theme == "mars_station": wall_color = Color("603329")
	elif theme == "ice_cave": wall_color = Color("37647a")
	elif theme == "fantasy_forest": wall_color = Color("18382c")
	var boundary := StaticBody3D.new()
	boundary.name = "WorldBoundary"
	boundary.collision_layer = 1
	add_child(boundary)
	var thickness := 1.0
	var height := 4.5
	for item in [
		[Vector3(width_world + thickness * 2.0, height, thickness), Vector3(0, height / 2.0, -depth_world / 2.0 - thickness / 2.0)],
		[Vector3(width_world + thickness * 2.0, height, thickness), Vector3(0, height / 2.0, depth_world / 2.0 + thickness / 2.0)],
		[Vector3(thickness, height, depth_world), Vector3(-width_world / 2.0 - thickness / 2.0, height / 2.0, 0)],
		[Vector3(thickness, height, depth_world), Vector3(width_world / 2.0 + thickness / 2.0, height / 2.0, 0)]]:
		VisualFactory.add_box(boundary, item[0], item[1], wall_color)
		VisualFactory.add_collision_box(boundary, item[0], item[1])

func _create_object(placement: Dictionary) -> void:
	var node := OBJECT_SCENE.instantiate() as ResourceObject
	node.configure(str(placement.resource_id))
	node.position = _placement_position(placement)
	node.rotation_degrees.y = float(placement.rotation)
	add_child(node)

func _create_collectible(placement: Dictionary, index: int) -> void:
	var node := COLLECTIBLE_SCENE.instantiate() as Collectible
	node.configure(str(placement.resource_id), str(index))
	node.position = _placement_position(placement)
	node.rotation_degrees.y = float(placement.rotation)
	add_child(node)

func _create_exit(placement: Dictionary) -> void:
	exit_portal = EXIT_SCENE.instantiate() as ExitPortal
	exit_portal.configure(str(placement.resource_id))
	exit_portal.position = _placement_position(placement)
	exit_portal.rotation_degrees.y = float(placement.rotation)
	exit_portal.reached.connect(func(): exit_reached.emit())
	AppState.exit_activation_changed.connect(exit_portal.set_active)
	add_child(exit_portal)

func _create_player(start: Dictionary) -> void:
	player = PLAYER_SCENE.instantiate() as FPSPlayer
	player.position = _cell_position(int(start.cell_x), int(start.cell_z)) + Vector3(0, 0.08, 0)
	add_child(player)

func _placement_position(placement: Dictionary) -> Vector3:
	var base := _cell_position(int(placement.cell_x), int(placement.cell_z))
	var footprint := ResourceCatalog.footprint(str(placement.resource_id), int(placement.rotation))
	base.x += (footprint.x - 1) * _cell_size * 0.5
	base.z += (footprint.y - 1) * _cell_size * 0.5
	return base

func _cell_position(x: int, z: int) -> Vector3:
	return Vector3((x - _width / 2.0 + 0.5) * _cell_size, 0.0, (z - _depth / 2.0 + 0.5) * _cell_size)
