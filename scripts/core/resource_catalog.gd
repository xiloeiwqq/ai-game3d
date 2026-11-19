class_name ResourceCatalog
extends RefCounted

const CATALOG_PATH := "res://data/catalog/resources.json"
const THEMES := ["fantasy_forest", "abandoned_castle", "mars_station", "ancient_temple", "ice_cave"]
const ROTATIONS := [0, 90, 180, 270]

static var _catalog: Dictionary = {}

static func data() -> Dictionary:
	if _catalog.is_empty():
		var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
		if file == null:
			push_error("Resource catalog missing: %s" % CATALOG_PATH)
			return {}
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) != TYPE_DICTIONARY:
			push_error("Resource catalog contains invalid JSON")
			return {}
		_catalog = parsed
	return _catalog

static func version() -> String:
	return str(data().get("catalog_version", "unknown"))

static func has_resource(resource_id: String, category: String = "") -> bool:
	var resources: Dictionary = data().get("resources", {})
	if not resources.has(resource_id):
		return false
	return category.is_empty() or str(resources[resource_id].get("category", "")) == category

static func get_resource(resource_id: String) -> Dictionary:
	return data().get("resources", {}).get(resource_id, {})

static func is_floor(resource_id: String) -> bool:
	return resource_id in data().get("floors", [])

static func is_sky(resource_id: String) -> bool:
	return resource_id in data().get("skies", [])

static func is_lighting(resource_id: String) -> bool:
	return resource_id in data().get("lighting", [])

static func ids_for(category: String, theme: String = "") -> Array:
	var result: Array = []
	for id in data().get("resources", {}):
		var item: Dictionary = data()["resources"][id]
		if str(item.get("category", "")) != category:
			continue
		var themes: Array = item.get("themes", [])
		if theme.is_empty() or themes.is_empty() or theme in themes:
			result.append(id)
	return result

static func footprint(resource_id: String, rotation: int) -> Vector2i:
	var raw: Array = get_resource(resource_id).get("footprint", [1, 1])
	var value := Vector2i(int(raw[0]), int(raw[1]))
	if rotation % 180 != 0:
		value = Vector2i(value.y, value.x)
	return value

static func is_blocking(resource_id: String) -> bool:
	return bool(get_resource(resource_id).get("blocking", false))
