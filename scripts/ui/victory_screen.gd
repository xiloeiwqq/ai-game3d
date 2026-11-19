class_name VictoryScreen
extends Control

signal replay_requested
signal new_world_requested
signal menu_requested

var title: Label
var time_label: Label
var world_label: Label
var sparkle_time := 0.0
var sparkles: Array[Label] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UIFactory.game_theme()
	UIFactory.overlay(self, 0.78)
	var center := CenterContainer.new()
	UIFactory.full_rect(center)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	panel.add_theme_stylebox_override("panel", UIFactory.style(Color(0.025, 0.055, 0.11, 0.97), 20, UIFactory.SUCCESS, 2))
	center.add_child(panel)
	var margin := UIFactory.make_margin(46, 38, 46, 38)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 13)
	margin.add_child(box)
	var icon := UIFactory.label("◇  ◆  ◇", 30, UIFactory.SUCCESS)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(icon)
	title = UIFactory.label("МИР ПРОЙДЕН!", 44, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	world_label = UIFactory.label("", 20, UIFactory.CYAN)
	world_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(world_label)
	var divider := HSeparator.new()
	box.add_child(divider)
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 42)
	box.add_child(stats)
	var found := UIFactory.label("АРТЕФАКТЫ\n3 / 3", 18, UIFactory.SUCCESS)
	found.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_child(found)
	time_label = UIFactory.label("ВРЕМЯ\n00:00", 18, UIFactory.SUCCESS)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_child(time_label)
	var mode := UIFactory.label("РЕЖИМ\n%s" % AppState.generation_mode.to_upper(), 18, UIFactory.SUCCESS)
	mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_child(mode)
	var replay := UIFactory.button("ИГРАТЬ СНОВА", 58)
	replay.pressed.connect(func(): replay_requested.emit())
	box.add_child(replay)
	var new_world := UIFactory.button("СОЗДАТЬ НОВЫЙ МИР")
	new_world.pressed.connect(func(): new_world_requested.emit())
	box.add_child(new_world)
	var menu := UIFactory.button("В ГЛАВНОЕ МЕНЮ")
	menu.pressed.connect(func(): menu_requested.emit())
	box.add_child(menu)
	_create_sparkles()

func set_result(world_name: String, seconds: float) -> void:
	world_label.text = world_name
	time_label.text = "ВРЕМЯ\n%s" % UIFactory.format_time(seconds)
	title.scale = Vector2(0.8, 0.8)
	title.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(title, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(title, "modulate:a", 1.0, 0.35)

func _create_sparkles() -> void:
	for index in 16:
		var sparkle := UIFactory.label("◆" if index % 2 == 0 else "·", 12 + index % 4 * 3, UIFactory.CYAN if index % 3 else UIFactory.VIOLET)
		sparkle.position = Vector2(70 + (index * 83) % 1120, 50 + (index * 117) % 610)
		sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sparkle)
		sparkles.append(sparkle)

func _process(delta: float) -> void:
	sparkle_time += delta
	if GameSettings.reduce_motion:
		return
	for index in sparkles.size():
		var sparkle := sparkles[index]
		sparkle.position.y += sin(sparkle_time * 1.4 + index) * delta * 5.0
		sparkle.modulate.a = 0.35 + sin(sparkle_time * 2.0 + index) * 0.25
