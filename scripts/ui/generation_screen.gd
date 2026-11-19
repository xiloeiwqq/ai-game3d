class_name GenerationScreen
extends Control

signal retry_requested
signal back_requested

const STAGES := ["Анализируем твою идею", "Подбираем объекты", "Создаём карту игрового мира", "Проверяем проходимость", "Собираем 3D-локацию"]
const SPINNER := ["◐", "◓", "◑", "◒"]

var title_label: Label
var status_label: Label
var mode_label: Label
var spinner_label: Label
var progress: ProgressBar
var stage_labels: Array[Label] = []
var error_panel: PanelContainer
var error_label: Label
var spinner_time := 0.0
var spinner_index := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UIFactory.game_theme()
	UIFactory.overlay(self, 0.96)
	var center := CenterContainer.new()
	UIFactory.full_rect(center)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(690, 510)
	center.add_child(panel)
	var margin := UIFactory.make_margin(42, 34, 42, 34)
	panel.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 15)
	margin.add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	spinner_label = UIFactory.label("◐", 34, UIFactory.CYAN)
	spinner_label.custom_minimum_size.x = 54
	top.add_child(spinner_label)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	heading.add_child(UIFactory.label("ГЕНЕРАЦИЯ МИРА", 13, UIFactory.MUTED))
	title_label = UIFactory.label("Пробуждаем новую реальность...", 28, Color.WHITE)
	heading.add_child(title_label)
	mode_label = UIFactory.label("", 13, UIFactory.CYAN)
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mode_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(mode_label)
	progress = ProgressBar.new()
	progress.min_value = 0
	progress.max_value = 100
	progress.value = 3
	progress.show_percentage = false
	progress.custom_minimum_size.y = 8
	progress.add_theme_stylebox_override("background", UIFactory.style(Color("101c2e"), 4))
	progress.add_theme_stylebox_override("fill", UIFactory.style(UIFactory.CYAN, 4))
	root.add_child(progress)
	var stages_panel := PanelContainer.new()
	stages_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(stages_panel)
	var stages_margin := UIFactory.make_margin(20, 16, 20, 16)
	stages_panel.add_child(stages_margin)
	var stages := VBoxContainer.new()
	stages.add_theme_constant_override("separation", 12)
	stages_margin.add_child(stages)
	for stage in STAGES:
		var label := UIFactory.label("○   %s" % stage, 17, UIFactory.MUTED)
		stage_labels.append(label)
		stages.add_child(label)
	status_label = UIFactory.label("Подготовка модулей...", 15, UIFactory.MUTED)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(status_label)
	error_panel = PanelContainer.new()
	error_panel.visible = false
	error_panel.add_theme_stylebox_override("panel", UIFactory.style(Color(0.20, 0.045, 0.075, 0.95), 12, UIFactory.DANGER, 1))
	root.add_child(error_panel)
	var error_box := VBoxContainer.new()
	error_panel.add_child(error_box)
	error_label = UIFactory.label("", 14, Color("ffd7df"))
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	error_box.add_child(error_label)
	var actions := HBoxContainer.new()
	error_box.add_child(actions)
	var back := UIFactory.button("В КОНСТРУКТОР", 40)
	back.pressed.connect(func(): back_requested.emit())
	actions.add_child(back)
	var retry := UIFactory.button("ПОВТОРИТЬ", 40)
	retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry.pressed.connect(func(): retry_requested.emit())
	actions.add_child(retry)

func begin(world_name: String, mode: String) -> void:
	title_label.text = "Создаём: %s" % world_name.left(48)
	mode_label.text = {"ai": "AI • LLM API", "offline": "OFFLINE • АЛГОРИТМ", "demo": "DEMO • ГОТОВЫЙ JSON"}.get(mode, mode.to_upper())
	set_stage(0, "Подготовка запроса и параметров...")

func set_stage(index: int, status: String) -> void:
	index = clampi(index, 0, STAGES.size() - 1)
	status_label.text = status
	progress.value = 8.0 + index * 21.0
	for item_index in stage_labels.size():
		var label := stage_labels[item_index]
		if item_index < index:
			label.text = "✓   %s" % STAGES[item_index]
			label.add_theme_color_override("font_color", UIFactory.SUCCESS)
		elif item_index == index:
			label.text = "◆   %s..." % STAGES[item_index]
			label.add_theme_color_override("font_color", UIFactory.CYAN)
		else:
			label.text = "○   %s" % STAGES[item_index]
			label.add_theme_color_override("font_color", UIFactory.MUTED)

func complete() -> void:
	for index in stage_labels.size():
		stage_labels[index].text = "✓   %s" % STAGES[index]
		stage_labels[index].add_theme_color_override("font_color", UIFactory.SUCCESS)
	progress.value = 100
	status_label.text = "Твой мир готов!"
	status_label.add_theme_color_override("font_color", UIFactory.SUCCESS)

func show_error(message: String) -> void:
	spinner_label.text = "!"
	spinner_label.add_theme_color_override("font_color", UIFactory.DANGER)
	status_label.text = "Генерация остановлена безопасно"
	error_label.text = message
	error_panel.visible = true

func _process(delta: float) -> void:
	if error_panel and error_panel.visible:
		return
	spinner_time += delta
	if spinner_time >= 0.14:
		spinner_time = 0.0
		spinner_index = (spinner_index + 1) % SPINNER.size()
		spinner_label.text = SPINNER[spinner_index]
