class_name GameHUD
extends Control

signal resume_requested
signal menu_requested
signal new_world_requested

var count_label: Label
var timer_label: Label
var hint_label: Label
var toast_label: Label
var pause_overlay: Control
var world_name_label: Label
var mode_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UIFactory.game_theme()
	_build_hud()
	_build_pause()
	AppState.collection_changed.connect(_on_collection_changed)
	AppState.toast_requested.connect(show_toast)
	_on_collection_changed(AppState.collected_ids.size(), AppState.REQUIRED_COLLECTIBLES)

func _build_hud() -> void:
	var top_margin := UIFactory.make_margin(24, 20, 24, 0)
	top_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	add_child(top_margin)
	var top := HBoxContainer.new()
	top_margin.add_child(top)
	var objective_panel := PanelContainer.new()
	objective_panel.custom_minimum_size = Vector2(390, 0)
	top.add_child(objective_panel)
	var objective_box := VBoxContainer.new()
	objective_panel.add_child(objective_box)
	world_name_label = UIFactory.label(str(AppState.current_world.get("world_name", "Неизвестный мир")), 19, Color.WHITE)
	objective_box.add_child(world_name_label)
	objective_box.add_child(UIFactory.label("Найди три предмета и доберись до выхода", 14, UIFactory.MUTED))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(fill)
	var stats_panel := PanelContainer.new()
	stats_panel.custom_minimum_size = Vector2(236, 0)
	top.add_child(stats_panel)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 18)
	stats_panel.add_child(stats)
	count_label = UIFactory.label("◆  0 / 3", 19, UIFactory.CYAN)
	stats.add_child(count_label)
	timer_label = UIFactory.label("◷  00:00", 17, UIFactory.MUTED)
	stats.add_child(timer_label)
	var mode_margin := UIFactory.make_margin(24, 0, 24, 18)
	mode_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	add_child(mode_margin)
	var bottom := HBoxContainer.new()
	mode_margin.add_child(bottom)
	mode_label = UIFactory.label("", 12, UIFactory.MUTED)
	mode_label.text = {"ai":"AI WORLD • ПРОВЕРЕННЫЙ JSON", "offline":"OFFLINE WORLD • АЛГОРИТМИЧЕСКИЙ", "demo":"DEMO WORLD • ПРЕСЕТ"}.get(AppState.generation_mode, AppState.generation_mode)
	bottom.add_child(mode_label)
	var bottom_fill := Control.new()
	bottom_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(bottom_fill)
	bottom.add_child(UIFactory.label("WASD ДВИЖЕНИЕ  •  SHIFT БЕГ  •  SPACE ПРЫЖОК  •  ESC ПАУЗА", 12, UIFactory.MUTED))
	var center := CenterContainer.new()
	UIFactory.full_rect(center)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var crosshair := UIFactory.label("+", 25, Color(1, 1, 1, 0.8))
	center.add_child(crosshair)
	var hint_center := CenterContainer.new()
	hint_center.anchor_left = 0.25
	hint_center.anchor_right = 0.75
	hint_center.anchor_top = 0.62
	hint_center.anchor_bottom = 0.75
	add_child(hint_center)
	hint_label = UIFactory.label("", 15, Color.WHITE)
	hint_label.add_theme_stylebox_override("normal", UIFactory.style(Color(0.02, 0.04, 0.08, 0.74), 8))
	hint_center.add_child(hint_label)
	var toast_center := CenterContainer.new()
	toast_center.anchor_left = 0.2
	toast_center.anchor_right = 0.8
	toast_center.anchor_top = 0.15
	toast_center.anchor_bottom = 0.28
	add_child(toast_center)
	toast_label = UIFactory.label("", 18, Color.WHITE)
	toast_label.visible = false
	toast_label.add_theme_stylebox_override("normal", UIFactory.style(Color(0.04, 0.10, 0.16, 0.96), 10, UIFactory.CYAN, 1))
	toast_center.add_child(toast_label)

func _build_pause() -> void:
	pause_overlay = Control.new()
	UIFactory.full_rect(pause_overlay)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.visible = false
	add_child(pause_overlay)
	UIFactory.overlay(pause_overlay, 0.8)
	var center := CenterContainer.new()
	UIFactory.full_rect(center)
	pause_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 0)
	center.add_child(panel)
	var margin := UIFactory.make_margin(34, 30, 34, 30)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var title := UIFactory.label("ПАУЗА", 36, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := UIFactory.label("Мир замер. Продолжить исследование?", 15, UIFactory.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	var resume := UIFactory.button("ПРОДОЛЖИТЬ", 56)
	resume.pressed.connect(func(): resume_requested.emit())
	box.add_child(resume)
	var create := UIFactory.button("СОЗДАТЬ НОВЫЙ МИР")
	create.pressed.connect(func(): new_world_requested.emit())
	box.add_child(create)
	var menu := UIFactory.button("В ГЛАВНОЕ МЕНЮ")
	menu.pressed.connect(func(): menu_requested.emit())
	box.add_child(menu)

func set_pause(value: bool) -> void:
	pause_overlay.visible = value

func is_paused() -> bool:
	return pause_overlay.visible

func set_interaction_hint(text: String) -> void:
	hint_label.text = text
	hint_label.visible = not text.is_empty()

func show_toast(text: String) -> void:
	if toast_label == null:
		return
	toast_label.text = "  %s  " % text
	toast_label.modulate = Color.WHITE
	toast_label.visible = true
	var tween := create_tween()
	tween.tween_interval(2.2)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func(): toast_label.visible = false)

func _on_collection_changed(current: int, total: int) -> void:
	if count_label:
		count_label.text = "◆  %d / %d" % [current, total]
		count_label.add_theme_color_override("font_color", UIFactory.SUCCESS if current >= total else UIFactory.CYAN)

func _process(_delta: float) -> void:
	if timer_label and not pause_overlay.visible:
		timer_label.text = "◷  %s" % UIFactory.format_time(AppState.elapsed_seconds())
