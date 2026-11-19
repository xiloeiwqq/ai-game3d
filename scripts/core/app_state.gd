extends Node

signal collection_changed(current: int, total: int)
signal toast_requested(message: String)
signal exit_activation_changed(active: bool)
signal world_reset

const REQUIRED_COLLECTIBLES := 3

var current_world: Dictionary = {}
var current_description := ""
var generation_mode := "offline"
var collected_ids: Dictionary = {}
var level_started_at := 0
var last_completion_seconds := 0.0
var last_save_path := ""

func begin_world(world_data: Dictionary, description: String, mode: String) -> void:
	current_world = world_data.duplicate(true)
	current_description = description
	generation_mode = mode
	collected_ids.clear()
	level_started_at = Time.get_ticks_msec()
	last_completion_seconds = 0.0
	world_reset.emit()
	collection_changed.emit(0, REQUIRED_COLLECTIBLES)
	exit_activation_changed.emit(false)

func collect(item_id: String) -> bool:
	if collected_ids.has(item_id):
		return false
	collected_ids[item_id] = true
	collection_changed.emit(collected_ids.size(), REQUIRED_COLLECTIBLES)
	if can_exit():
		exit_activation_changed.emit(true)
		toast_requested.emit("Все артефакты найдены — выход активирован!")
	return true

func can_exit() -> bool:
	return collected_ids.size() >= REQUIRED_COLLECTIBLES

func finish_world() -> float:
	last_completion_seconds = maxf(0.0, (Time.get_ticks_msec() - level_started_at) / 1000.0)
	return last_completion_seconds

func elapsed_seconds() -> float:
	if level_started_at <= 0:
		return 0.0
	return maxf(0.0, (Time.get_ticks_msec() - level_started_at) / 1000.0)

func clear_world() -> void:
	current_world.clear()
	current_description = ""
	collected_ids.clear()
	level_started_at = 0
	last_completion_seconds = 0.0
	world_reset.emit()

func reset_for_replay() -> void:
	collected_ids.clear()
	level_started_at = Time.get_ticks_msec()
	last_completion_seconds = 0.0
	world_reset.emit()
	collection_changed.emit(0, REQUIRED_COLLECTIBLES)
	exit_activation_changed.emit(false)
