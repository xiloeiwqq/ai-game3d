class_name SaveService
extends RefCounted

const WORLD_DIR := "user://generated_worlds"
const HISTORY_PATH := "user://description_history.json"

static func save_world(world: Dictionary, description: String, mode: String) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(WORLD_DIR))
	var stamp := Time.get_datetime_string_from_system(false, true).replace(":", "-")
	var safe_name := _safe_filename(str(world.get("world_name", "world")))
	var path := "%s/%s_%s.json" % [WORLD_DIR, stamp, safe_name]
	var payload := world.duplicate(true)
	payload["_save_meta"] = {"description": description, "generation_mode": mode, "catalog_version": ResourceCatalog.version(), "saved_at": Time.get_datetime_string_from_system(true, true)}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Не удалось открыть файл сохранения."}
	file.store_string(JSON.stringify(payload, "  "))
	file.close()
	append_description(description)
	return {"ok": true, "path": path}

static func load_world(path: String) -> Dictionary:
	if not path.begins_with("res://") and not path.begins_with("user://"):
		return {"ok": false, "error": "Разрешены только локальные пути res:// и user://."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Файл мира не найден: %s" % path}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "error": "Файл содержит некорректный JSON."}
	parsed.erase("_save_meta")
	return {"ok": true, "world": parsed}

static func append_description(description: String) -> void:
	if description.strip_edges().is_empty():
		return
	var history := load_descriptions()
	history.erase(description)
	history.push_front(description)
	if history.size() > 20:
		history.resize(20)
	var file := FileAccess.open(HISTORY_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(history, "  "))

static func load_descriptions() -> Array:
	var file := FileAccess.open(HISTORY_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_ARRAY else []

static func latest_saved_world() -> String:
	var directory := DirAccess.open(WORLD_DIR)
	if directory == null:
		return ""
	var files: Array[String] = []
	for filename in directory.get_files():
		if filename.ends_with(".json"):
			files.append(filename)
	files.sort()
	return "%s/%s" % [WORLD_DIR, files.back()] if not files.is_empty() else ""

static func _safe_filename(value: String) -> String:
	var output := ""
	for character in value.to_lower():
		if character.is_valid_identifier() or character.is_valid_int() or character in ["-", "_"]:
			output += character
		elif character == " ":
			output += "_"
	return output.left(40) if not output.is_empty() else "world"
