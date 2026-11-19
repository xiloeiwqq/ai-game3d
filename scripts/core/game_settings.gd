extends Node

signal changed

const SETTINGS_PATH := "user://settings.cfg"

var master_volume := 0.8
var mouse_sensitivity := 0.0022
var fullscreen := false
var reduce_motion := false

func _ready() -> void:
	load_settings()
	apply()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = clampf(float(config.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	mouse_sensitivity = clampf(float(config.get_value("controls", "mouse_sensitivity", mouse_sensitivity)), 0.0005, 0.006)
	fullscreen = bool(config.get_value("display", "fullscreen", fullscreen))
	reduce_motion = bool(config.get_value("accessibility", "reduce_motion", reduce_motion))

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("accessibility", "reduce_motion", reduce_motion)
	config.save(SETTINGS_PATH)
	apply()
	changed.emit()

func apply() -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(master_volume, 0.001)))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
