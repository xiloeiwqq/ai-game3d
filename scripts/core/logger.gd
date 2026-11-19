class_name AppLogger
extends RefCounted

const LOG_DIR := "user://logs"
const LOG_PATH := "user://logs/app.log"

static func info(message: String) -> void:
	_write("INFO", message)

static func warning(message: String) -> void:
	_write("WARN", message)

static func error(message: String) -> void:
	push_error(message)
	_write("ERROR", message)

static func _write(level: String, message: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LOG_DIR))
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(LOG_PATH) else FileAccess.WRITE_READ
	var file := FileAccess.open(LOG_PATH, mode)
	if file == null:
		return
	file.seek_end()
	file.store_line("[%s] [%s] %s" % [Time.get_datetime_string_from_system(true, true), level, message])
	file.close()
