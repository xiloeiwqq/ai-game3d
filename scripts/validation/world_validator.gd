class_name WorldValidator
extends RefCounted

const MIN_MAP := 12
const MAX_MAP := 40
const MAX_OBJECTS := 140
const REQUIRED_KEYS := ["schema_version", "world_name", "theme_id", "seed", "map", "environment", "player_start", "objects", "collectibles", "exit"]

static func validate(world) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	if typeof(world) != TYPE_DICTIONARY:
		return {"valid": false, "errors": ["Корень JSON должен быть объектом."], "warnings": []}
	for key in REQUIRED_KEYS:
		if not world.has(key):
			errors.append("Отсутствует обязательное поле: %s" % key)
	_validate_allowed_keys(world, "root", REQUIRED_KEYS, errors)
	if not errors.is_empty():
		return {"valid": false, "errors": errors, "warnings": warnings}
	if str(world.get("schema_version")) != "1.0":
		errors.append("Поддерживается только schema_version 1.0.")
	if typeof(world.world_name) != TYPE_STRING or world.world_name.strip_edges().is_empty() or world.world_name.length() > 64:
		errors.append("world_name должен быть непустой строкой длиной до 64 символов.")
	if str(world.theme_id) not in ResourceCatalog.THEMES:
		errors.append("Недопустимая тема: %s" % str(world.theme_id))
	if not _is_integer_number(world.seed) or int(world.seed) < 0 or int(world.seed) > 2147483647:
		errors.append("seed должен быть целым числом от 0 до 2147483647.")
	if typeof(world.map) != TYPE_DICTIONARY:
		errors.append("map должен быть объектом.")
		return {"valid": false, "errors": errors, "warnings": warnings}
	var map: Dictionary = world.map
	_validate_allowed_keys(map, "map", ["width", "depth", "cell_size"], errors)
	for key in ["width", "depth", "cell_size"]:
		if not map.has(key):
			errors.append("map.%s отсутствует." % key)
	if not errors.is_empty():
		return {"valid": false, "errors": errors, "warnings": warnings}
	if not _is_integer_number(map.width) or int(map.width) < MIN_MAP or int(map.width) > MAX_MAP:
		errors.append("map.width должен быть целым числом от %d до %d." % [MIN_MAP, MAX_MAP])
	if not _is_integer_number(map.depth) or int(map.depth) < MIN_MAP or int(map.depth) > MAX_MAP:
		errors.append("map.depth должен быть целым числом от %d до %d." % [MIN_MAP, MAX_MAP])
	if not _is_number(map.cell_size) or float(map.cell_size) < 2.0 or float(map.cell_size) > 4.0:
		errors.append("map.cell_size должен быть числом от 2.0 до 4.0.")
	if not errors.is_empty():
		return {"valid": false, "errors": errors, "warnings": warnings}
	var width := int(map.width)
	var depth := int(map.depth)
	if float(map.cell_size) < float(ResourceCatalog.data().get("player", {}).get("diameter", 0.72)) + 0.5:
		errors.append("Клетка слишком мала для физической капсулы игрока и безопасного зазора.")
	_validate_environment(world.environment, errors)
	_validate_cell(world.player_start, "player_start", width, depth, errors, false)
	if typeof(world.objects) != TYPE_ARRAY:
		errors.append("objects должен быть массивом.")
	if typeof(world.collectibles) != TYPE_ARRAY:
		errors.append("collectibles должен быть массивом.")
	if not errors.is_empty():
		return {"valid": false, "errors": errors, "warnings": warnings}
	if world.objects.size() > MAX_OBJECTS:
		errors.append("Слишком много объектов: %d (максимум %d)." % [world.objects.size(), MAX_OBJECTS])
	if world.collectibles.size() != 3:
		errors.append("Должно быть ровно три собираемых предмета.")
	var occupied: Dictionary = {}
	var blocked: Dictionary = {}
	for index in world.objects.size():
		_validate_placement(world.objects[index], "objects[%d]" % index, "object", width, depth, occupied, blocked, errors)
	for index in world.collectibles.size():
		_validate_placement(world.collectibles[index], "collectibles[%d]" % index, "collectible", width, depth, occupied, blocked, errors)
	_validate_placement(world.exit, "exit", "exit", width, depth, occupied, blocked, errors)
	var start := _cell(world.player_start)
	if occupied.has(start) or blocked.has(start):
		errors.append("Стартовая позиция пересекается с объектом.")
	if errors.is_empty():
		var reachable := GridPathfinder.reachable(width, depth, blocked, start)
		for index in world.collectibles.size():
			var target := _cell(world.collectibles[index])
			if not reachable.has(target):
				errors.append("Предмет %d недоступен от точки старта." % (index + 1))
		var exit_cell := _cell(world.exit)
		if not reachable.has(exit_cell):
			errors.append("Выход недоступен от точки старта.")
		var free_ratio := float(reachable.size()) / float(width * depth)
		if free_ratio < 0.35:
			warnings.append("Доступно менее 35%% карты; уровень может ощущаться тесным.")
	return {"valid": errors.is_empty(), "errors": errors, "warnings": warnings, "blocked": blocked}

static func validate_and_repair(input_world: Dictionary, max_repairs: int = 16) -> Dictionary:
	var world := input_world.duplicate(true)
	var repairs: Array[String] = []
	if typeof(world.get("map")) != TYPE_DICTIONARY:
		return {"valid": false, "world": world, "errors": ["Невозможно исправить: отсутствует map."], "repairs": repairs}
	var width := clampi(int(world.map.get("width", 20)), MIN_MAP, MAX_MAP)
	var depth := clampi(int(world.map.get("depth", 20)), MIN_MAP, MAX_MAP)
	world.map.width = width
	world.map.depth = depth
	world.map.cell_size = clampf(float(world.map.get("cell_size", 2.5)), 2.0, 4.0)
	if typeof(world.get("objects")) != TYPE_ARRAY:
		world.objects = []
	if typeof(world.get("collectibles")) != TYPE_ARRAY:
		world.collectibles = []
	world.objects = world.objects.slice(0, MAX_OBJECTS)
	# Filter unsafe IDs and normalize simple numeric fields. Never accept paths.
	var filtered: Array = []
	for placement in world.objects:
		if typeof(placement) == TYPE_DICTIONARY and ResourceCatalog.has_resource(str(placement.get("resource_id", "")), "object"):
			_normalize_placement(placement, width, depth)
			filtered.append(placement)
		else:
			repairs.append("Удалён объект с неизвестным resource_id.")
	world.objects = filtered
	for placement in world.collectibles:
		if typeof(placement) == TYPE_DICTIONARY:
			_normalize_placement(placement, width, depth)
	if typeof(world.get("exit")) == TYPE_DICTIONARY:
		_normalize_placement(world.exit, width, depth)
	if typeof(world.get("player_start")) == TYPE_DICTIONARY:
		world.player_start.cell_x = clampi(int(world.player_start.get("cell_x", 1)), 0, width - 1)
		world.player_start.cell_z = clampi(int(world.player_start.get("cell_z", 1)), 0, depth - 1)
	var result := validate(world)
	var removed := 0
	while not result.valid and removed < max_repairs and not world.objects.is_empty() and _only_spatial_errors(result.errors):
		var removed_item: Dictionary = world.objects.pop_back()
		repairs.append("Удалён блокирующий объект %s для восстановления маршрута." % str(removed_item.get("resource_id", "")))
		removed += 1
		result = validate(world)
	return {"valid": result.valid, "world": world, "errors": result.errors, "warnings": result.get("warnings", []), "repairs": repairs}

static func _validate_environment(value, errors: Array[String]) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("environment должен быть объектом.")
		return
	_validate_allowed_keys(value, "environment", ["floor_id", "sky_id", "lighting_id"], errors)
	for key in ["floor_id", "sky_id", "lighting_id"]:
		if not value.has(key) or typeof(value[key]) != TYPE_STRING:
			errors.append("environment.%s отсутствует или имеет неверный тип." % key)
	if value.has("floor_id") and not ResourceCatalog.is_floor(str(value.floor_id)):
		errors.append("Неизвестный floor_id: %s" % str(value.floor_id))
	if value.has("sky_id") and not ResourceCatalog.is_sky(str(value.sky_id)):
		errors.append("Неизвестный sky_id: %s" % str(value.sky_id))
	if value.has("lighting_id") and not ResourceCatalog.is_lighting(str(value.lighting_id)):
		errors.append("Неизвестный lighting_id: %s" % str(value.lighting_id))

static func _validate_placement(value, label: String, category: String, width: int, depth: int, occupied: Dictionary, blocked: Dictionary, errors: Array[String]) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("%s должен быть объектом." % label)
		return
	_validate_allowed_keys(value, label, ["resource_id", "cell_x", "cell_z", "rotation"], errors)
	for key in ["resource_id", "cell_x", "cell_z", "rotation"]:
		if not value.has(key):
			errors.append("%s.%s отсутствует." % [label, key])
	if not value.has("resource_id"):
		return
	var resource_id := str(value.resource_id)
	if resource_id.contains("/") or resource_id.contains("\\") or resource_id.contains(".."):
		errors.append("%s.resource_id содержит запрещённый путь." % label)
		return
	if not ResourceCatalog.has_resource(resource_id, category):
		errors.append("%s содержит неизвестный или неверный resource_id: %s" % [label, resource_id])
		return
	_validate_cell(value, label, width, depth, errors, true)
	if not value.has("rotation") or not _is_integer_number(value.rotation) or int(value.rotation) not in ResourceCatalog.ROTATIONS:
		errors.append("%s.rotation должен быть 0, 90, 180 или 270." % label)
		return
	if not value.has("cell_x") or not value.has("cell_z") or not _is_integer_number(value.cell_x) or not _is_integer_number(value.cell_z):
		return
	var origin := _cell(value)
	var footprint := ResourceCatalog.footprint(resource_id, int(value.rotation))
	for x in range(origin.x, origin.x + footprint.x):
		for z in range(origin.y, origin.y + footprint.y):
			var cell := Vector2i(x, z)
			if x < 0 or z < 0 or x >= width or z >= depth:
				errors.append("%s выходит за границы карты с учётом габаритов." % label)
				continue
			if occupied.has(cell):
				errors.append("%s пересекается с %s в клетке (%d,%d)." % [label, str(occupied[cell]), x, z])
			else:
				occupied[cell] = label
			if ResourceCatalog.is_blocking(resource_id):
				blocked[cell] = true

static func _validate_cell(value, label: String, width: int, depth: int, errors: Array[String], needs_rotation: bool) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("%s должен быть объектом." % label)
		return
	if not needs_rotation:
		_validate_allowed_keys(value, label, ["cell_x", "cell_z"], errors)
	for key in ["cell_x", "cell_z"]:
		if not value.has(key) or not _is_integer_number(value[key]):
			errors.append("%s.%s должен быть целым числом." % [label, key])
			return
	var cell := _cell(value)
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= depth:
		errors.append("%s находится за границами карты." % label)

static func _normalize_placement(placement: Dictionary, width: int, depth: int) -> void:
	placement.cell_x = clampi(int(placement.get("cell_x", 0)), 0, width - 1)
	placement.cell_z = clampi(int(placement.get("cell_z", 0)), 0, depth - 1)
	var rotation := int(placement.get("rotation", 0))
	placement.rotation = ResourceCatalog.ROTATIONS[clampi(int(roundf(float(rotation) / 90.0)), 0, 3)]

static func _only_spatial_errors(errors: Array) -> bool:
	if errors.is_empty():
		return false
	for message in errors:
		var text := str(message)
		if not ("недоступ" in text or "пересека" in text or "Стартовая" in text):
			return false
	return true

static func _validate_allowed_keys(value: Dictionary, label: String, allowed: Array, errors: Array[String]) -> void:
	for key in value:
		if str(key) not in allowed:
			errors.append("%s содержит неожиданное поле: %s" % [label, str(key)])

static func _is_number(value) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT

static func _is_integer_number(value) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and is_equal_approx(value, roundf(value)))

static func _cell(value: Dictionary) -> Vector2i:
	return Vector2i(int(value.get("cell_x", -1)), int(value.get("cell_z", -1)))
