class_name ProceduralGenerator
extends RefCounted

const THEME_DATA := {
	"fantasy_forest": {"name": "Рождённый мечтой лес", "floor": "forest_ground", "sky": "forest_sky", "light": "forest_lighting", "exit": "portal_exit", "objects": ["tree_01", "giant_mushroom", "rock_01", "crystal_cluster", "lantern", "bridge_stone"]},
	"abandoned_castle": {"name": "Забытая цитадель", "floor": "castle_stone", "sky": "storm_sky", "light": "castle_lighting", "exit": "ancient_gate", "objects": ["ruined_wall", "stone_wall", "column_stone", "crate_wood", "statue_ancient", "torch", "dead_tree"]},
	"mars_station": {"name": "Красный рубеж", "floor": "mars_dust", "sky": "mars_sky", "light": "mars_lighting", "exit": "airlock_exit", "objects": ["sci_container", "sci_console", "robot_guard", "rock_01", "boulder", "lantern", "obelisk"]},
	"ancient_temple": {"name": "Храм вечного эха", "floor": "temple_stone", "sky": "temple_sky", "light": "temple_lighting", "exit": "ancient_gate", "objects": ["temple_pillar", "ruined_wall", "stone_arch", "statue_ancient", "obelisk", "torch", "rock_01"]},
	"ice_cave": {"name": "Ледяная бездна", "floor": "ice_floor", "sky": "ice_sky", "light": "ice_lighting", "exit": "portal_exit", "objects": ["ice_spire", "crystal_cluster", "boulder", "rock_01", "pine_snow"]}
}

static func generate(description: String, options: Dictionary = {}) -> Dictionary:
	var theme := _detect_theme(description, str(options.get("theme", "auto")))
	var size_id := str(options.get("size", "medium"))
	var dimensions := {"small": 16, "medium": 22, "large": 30}
	var side: int = dimensions.get(size_id, 22)
	var seed_value := absi(description.hash())
	seed_value = int((seed_value + int(options.get("seed_offset", 0))) % 2147483647)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var theme_data: Dictionary = THEME_DATA[theme]
	var start := Vector2i(1, 1)
	var targets: Array[Vector2i] = [Vector2i(4, side - 5), Vector2i(side / 2, side / 2), Vector2i(side - 5, 5)]
	var exit_cell := Vector2i(side - 2, side - 3)
	var protected := _protected_routes(start, targets + [exit_cell])
	var occupied: Dictionary = {}
	for cell in [start] + targets + [exit_cell, exit_cell + Vector2i(0, 1)]:
		occupied[cell] = true
	var objects: Array = []
	var density := str(options.get("density", "medium"))
	var counts := {"low": int(side * 0.85), "medium": int(side * 1.35), "high": int(side * 2.0)}
	var difficulty_bonus: int = int({"easy": 0, "normal": 5, "hard": 12}.get(str(options.get("difficulty", "normal")), 5))
	var desired: int = mini(MAX_SAFE_OBJECTS(), int(counts.get(density, counts.medium)) + difficulty_bonus)
	var candidates: Array = theme_data.objects
	var attempts := 0
	while objects.size() < desired and attempts < desired * 30:
		attempts += 1
		var resource_id: String = str(candidates[rng.randi_range(0, candidates.size() - 1)])
		var rotation: int = ResourceCatalog.ROTATIONS[rng.randi_range(0, 3)]
		var footprint := ResourceCatalog.footprint(resource_id, rotation)
		var origin := Vector2i(rng.randi_range(1, side - footprint.x - 1), rng.randi_range(1, side - footprint.y - 1))
		if not _can_place(origin, footprint, occupied, protected):
			continue
		objects.append({"resource_id": resource_id, "cell_x": origin.x, "cell_z": origin.y, "rotation": rotation})
		for x in range(origin.x, origin.x + footprint.x):
			for z in range(origin.y, origin.y + footprint.y):
				occupied[Vector2i(x, z)] = true
	var collectible_ids := ["crystal_blue", "crystal_red", "artifact_gold"]
	if theme == "mars_station":
		collectible_ids = ["energy_cell", "energy_cell", "energy_cell"]
	var collectibles: Array = []
	for index in 3:
		collectibles.append({"resource_id": collectible_ids[index], "cell_x": targets[index].x, "cell_z": targets[index].y, "rotation": ResourceCatalog.ROTATIONS[index]})
	var world := {
		"schema_version": "1.0",
		"world_name": _world_name(description, str(theme_data.name)),
		"theme_id": theme,
		"seed": seed_value,
		"map": {"width": side, "depth": side, "cell_size": 2.5},
		"environment": {"floor_id": theme_data.floor, "sky_id": theme_data.sky, "lighting_id": theme_data.light},
		"player_start": {"cell_x": start.x, "cell_z": start.y},
		"objects": objects,
		"collectibles": collectibles,
		"exit": {"resource_id": theme_data.exit, "cell_x": exit_cell.x, "cell_z": exit_cell.y, "rotation": 0}
	}
	return world

static func _detect_theme(description: String, requested: String) -> String:
	if requested in ResourceCatalog.THEMES:
		return requested
	var text := description.to_lower()
	var scores := {
		"fantasy_forest": _score(text, ["лес", "дерев", "сказ", "гриб", "forest", "fairy", "lake", "озер"]),
		"abandoned_castle": _score(text, ["замок", "крепост", "ворот", "castle", "citadel", "рыцар", "башн"]),
		"mars_station": _score(text, ["марс", "косм", "станц", "робот", "баз", "mars", "space", "sci-fi", "энерг"]),
		"ancient_temple": _score(text, ["храм", "подзем", "древн", "колон", "temple", "dungeon", "сокров"]),
		"ice_cave": _score(text, ["лед", "снег", "пещер", "зим", "ice", "snow", "frozen", "аркти"])
	}
	var best := "fantasy_forest"
	var best_score := -1
	for theme in scores:
		if int(scores[theme]) > best_score:
			best_score = int(scores[theme])
			best = theme
	return best

static func _score(text: String, words: Array) -> int:
	var result := 0
	for word in words:
		if str(word) in text:
			result += 1
	return result

static func _world_name(description: String, fallback: String) -> String:
	var cleaned := description.strip_edges().replace("\n", " ")
	if cleaned.length() < 8:
		return fallback
	var first := cleaned.split(".")[0]
	if first.length() > 46:
		first = first.left(43) + "..."
	return first.capitalize()

static func _protected_routes(start: Vector2i, targets: Array) -> Dictionary:
	var protected: Dictionary = {}
	for target in targets:
		var cursor := start
		while cursor.x != target.x:
			protected[cursor] = true
			cursor.x += 1 if target.x > cursor.x else -1
		while cursor.y != target.y:
			protected[cursor] = true
			cursor.y += 1 if target.y > cursor.y else -1
		protected[target] = true
	return protected

static func _can_place(origin: Vector2i, footprint: Vector2i, occupied: Dictionary, protected: Dictionary) -> bool:
	for x in range(origin.x, origin.x + footprint.x):
		for z in range(origin.y, origin.y + footprint.y):
			var cell := Vector2i(x, z)
			if occupied.has(cell) or protected.has(cell):
				return false
	return true

static func MAX_SAFE_OBJECTS() -> int:
	return 110
