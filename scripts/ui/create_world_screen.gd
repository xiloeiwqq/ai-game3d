class_name CreateWorldScreen
extends Control

signal generate_requested(description: String, options: Dictionary)
signal demo_requested(path: String, description: String)
signal back_requested

const DEMOS := [
	["ВОЛШЕБНЫЙ ЛЕС", "res://data/examples/01_enchanted_forest.json", "Создай сказочный лес с гигантскими деревьями, светящимися грибами и тайным порталом."],
	["ЗАБРОШЕННЫЙ ЗАМОК", "res://data/examples/02_abandoned_castle.json", "Создай заброшенный замок в туманной чаще с разрушенными башнями и древними воротами."],
	["МАРСИАНСКАЯ СТАНЦИЯ", "res://data/examples/03_mars_station.json", "Исследуй марсианскую базу с роботами, контейнерами и энергетическими батареями."],
	["ДРЕВНИЙ ХРАМ", "res://data/examples/04_ancient_temple.json", "Создай древний храм с колоннами, обелисками, ловушками и сокровищами."],
	["ЛЕДЯНАЯ ПЕЩЕРА", "res://data/examples/05_ice_cave.json", "Создай ледяную пещеру с кристаллами, ледяными шпилями и сияющим выходом."]
]

var description_edit: TextEdit
var theme_select: OptionButton
var size_select: OptionButton
var difficulty_select: OptionButton
var density_select: OptionButton
var mode_select: OptionButton
var api_note: Label
var error_label: Label
var ai_available := false
var page_scroll: ScrollContainer
var page_margin: MarginContainer
var root_layout: VBoxContainer
var main_layout: BoxContainer
var left_margin: MarginContainer
var right_margin: MarginContainer
var right_panel: PanelContainer
var title_label: Label
var back_button: Button
var history_button: Button
var demo_caption: Label
var demo_grid: GridContainer
var demo_buttons: Array[Button] = []
var option_controls: Array[OptionButton] = []
var generate_button: Button

func _ready() -> void:
	theme = UIFactory.game_theme()
	UIFactory.overlay(self, 0.9)
	page_scroll = ScrollContainer.new()
	page_scroll.name = "PageScroll"
	page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	UIFactory.full_rect(page_scroll)
	add_child(page_scroll)
	page_margin = UIFactory.make_margin(48, 32, 48, 34)
	page_margin.name = "PageMargin"
	page_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_scroll.add_child(page_margin)
	root_layout = VBoxContainer.new()
	root_layout.name = "RootLayout"
	root_layout.add_theme_constant_override("separation", 16)
	page_margin.add_child(root_layout)
	var header := HBoxContainer.new()
	root_layout.add_child(header)
	back_button = UIFactory.button("←  НАЗАД", 42)
	back_button.name = "BackButton"
	back_button.custom_minimum_size.x = 140
	back_button.pressed.connect(func(): back_requested.emit())
	header.add_child(back_button)
	var header_fill := Control.new()
	header_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_fill)
	var step := UIFactory.label("КОНСТРУКТОР МИРА  /  ШАГ 1 ИЗ 2", 14, UIFactory.CYAN)
	step.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(step)
	title_label = UIFactory.label("Какой мир ты хочешь исследовать?", 34, Color.WHITE)
	title_label.name = "ScreenTitle"
	root_layout.add_child(title_label)
	main_layout = BoxContainer.new()
	main_layout.name = "MainLayout"
	main_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_layout.add_theme_constant_override("separation", 18)
	root_layout.add_child(main_layout)
	var left_panel := PanelContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_layout.add_child(left_panel)
	left_margin = UIFactory.make_margin(24, 22, 24, 22)
	left_panel.add_child(left_margin)
	var left := VBoxContainer.new()
	left.name = "DescriptionColumn"
	left.add_theme_constant_override("separation", 12)
	left_margin.add_child(left)
	left.add_child(UIFactory.label("ОПИСАНИЕ МИРА", 14, UIFactory.CYAN))
	description_edit = TextEdit.new()
	description_edit.name = "DescriptionEdit"
	description_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description_edit.custom_minimum_size = Vector2(0, 210)
	description_edit.placeholder_text = "Например: Создай зимний замок среди чёрных сосен. В руинах спрячь три магических кристалла, а выход размести у древних ворот..."
	description_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	left.add_child(description_edit)
	var hint := UIFactory.label("Подсказка: упомяни атмосферу, места, объекты и то, что хочется почувствовать.", 14, UIFactory.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(hint)
	var history := SaveService.load_descriptions()
	if not history.is_empty():
		history_button = UIFactory.button("↻  ВСТАВИТЬ ПОСЛЕДНЕЕ ОПИСАНИЕ", 40)
		history_button.name = "HistoryButton"
		history_button.pressed.connect(func(): description_edit.text = str(history[0]))
		left.add_child(history_button)
	demo_caption = UIFactory.label("БЫСТРЫЙ ОФЛАЙН-ЗАПУСК • ГОТОВЫЕ JSON", 13, UIFactory.MUTED)
	left.add_child(demo_caption)
	demo_grid = GridContainer.new()
	demo_grid.name = "DemoGrid"
	demo_grid.columns = 3
	demo_grid.add_theme_constant_override("h_separation", 8)
	demo_grid.add_theme_constant_override("v_separation", 8)
	left.add_child(demo_grid)
	for index in DEMOS.size():
		var demo: Array = DEMOS[index]
		var demo_button := UIFactory.button(str(demo[0]), 38)
		demo_button.name = "DemoButton%d" % index
		demo_button.tooltip_text = str(demo[2])
		demo_button.pressed.connect(func(): demo_requested.emit(str(demo[1]), str(demo[2])))
		demo_grid.add_child(demo_button)
		demo_buttons.append(demo_button)
	right_panel = PanelContainer.new()
	right_panel.name = "OptionsPanel"
	right_panel.custom_minimum_size.x = 360
	main_layout.add_child(right_panel)
	right_margin = UIFactory.make_margin(22, 22, 22, 22)
	right_panel.add_child(right_margin)
	var right := VBoxContainer.new()
	right.name = "OptionsColumn"
	right.add_theme_constant_override("separation", 8)
	right_margin.add_child(right)
	right.add_child(UIFactory.label("ПАРАМЕТРЫ ГЕНЕРАЦИИ", 14, UIFactory.CYAN))
	mode_select = _add_option(right, "РЕЖИМ", ["ИИ • LLM API", "ОФЛАЙН • АЛГОРИТМ"])
	theme_select = _add_option(right, "ТЕМАТИКА", ["Авто по описанию", "Волшебный лес", "Заброшенный замок", "Марсианская станция", "Древний храм", "Ледяная пещера"])
	size_select = _add_option(right, "РАЗМЕР", ["Маленький", "Средний", "Большой"])
	size_select.select(1)
	difficulty_select = _add_option(right, "СЛОЖНОСТЬ", ["Легко", "Нормально", "Сложно"])
	difficulty_select.select(1)
	density_select = _add_option(right, "ДЕКОРАЦИИ", ["Мало", "Средне", "Много"])
	density_select.select(1)
	api_note = UIFactory.label("", 13, UIFactory.MUTED)
	api_note.name = "ApiNote"
	api_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(api_note)
	var right_fill := Control.new()
	right_fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(right_fill)
	error_label = UIFactory.label("", 14, UIFactory.DANGER)
	error_label.name = "ErrorLabel"
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(error_label)
	generate_button = UIFactory.button("СГЕНЕРИРОВАТЬ МИР  →", 62)
	generate_button.name = "GenerateButton"
	generate_button.add_theme_stylebox_override("normal", UIFactory.style(Color("5b3fb1"), 11, UIFactory.VIOLET, 1))
	generate_button.add_theme_stylebox_override("hover", UIFactory.style(Color("7356d2"), 11, Color.WHITE, 2))
	generate_button.pressed.connect(_submit)
	right.add_child(generate_button)
	_update_api_ui()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()

func set_api_available(value: bool) -> void:
	ai_available = value
	_update_api_ui()

func focus_examples() -> void:
	if description_edit:
		description_edit.placeholder_text = "Выберите один из пяти готовых миров ниже — интернет и API-ключ не требуются."

func _add_option(parent: VBoxContainer, label_text: String, items: Array) -> OptionButton:
	parent.add_child(UIFactory.label(label_text, 12, UIFactory.MUTED))
	var option := OptionButton.new()
	option.custom_minimum_size.y = 42
	for item in items:
		option.add_item(str(item))
	parent.add_child(option)
	option_controls.append(option)
	return option

func _apply_responsive_layout() -> void:
	if page_margin == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var compact := viewport_size.y <= 780.0
	var narrow := viewport_size.x <= 1050.0
	main_layout.vertical = narrow
	var outer_x := 22 if compact else 48
	if narrow:
		outer_x = 14
	_set_margins(page_margin, outer_x, 16 if compact else 32, outer_x, 16 if compact else 34)
	page_margin.custom_minimum_size = Vector2(maxf(0.0, viewport_size.x - 2.0), maxf(560.0, viewport_size.y - 2.0))
	root_layout.add_theme_constant_override("separation", 8 if compact else 16)
	main_layout.add_theme_constant_override("separation", 12 if compact else 18)
	_set_margins(left_margin, 16 if compact else 24, 14 if compact else 22, 16 if compact else 24, 14 if compact else 22)
	_set_margins(right_margin, 16 if compact else 22, 14 if compact else 22, 16 if compact else 22, 14 if compact else 22)
	var left_column := left_margin.get_child(0) as VBoxContainer
	var right_column := right_margin.get_child(0) as VBoxContainer
	left_column.add_theme_constant_override("separation", 7 if compact else 12)
	right_column.add_theme_constant_override("separation", 3 if compact else 8)
	back_button.custom_minimum_size = Vector2(128 if compact else 140, 36 if compact else 42)
	title_label.add_theme_font_size_override("font_size", 30 if compact else 34)
	description_edit.custom_minimum_size.y = 126 if compact else 210
	description_edit.add_theme_font_size_override("font_size", 16 if compact else 18)
	if history_button:
		history_button.custom_minimum_size.y = 34 if compact else 40
	demo_caption.add_theme_font_size_override("font_size", 12 if compact else 13)
	demo_grid.columns = 3 if not narrow else 2
	demo_grid.add_theme_constant_override("h_separation", 6 if compact else 8)
	demo_grid.add_theme_constant_override("v_separation", 6 if compact else 8)
	for button in demo_buttons:
		button.custom_minimum_size.y = 34 if compact else 38
		button.add_theme_font_size_override("font_size", 14 if compact else 16)
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if narrow else Control.SIZE_SHRINK_BEGIN
	right_panel.custom_minimum_size.x = 0 if narrow else (330 if compact else 360)
	for option in option_controls:
		option.custom_minimum_size.y = 36 if compact else 42
		option.add_theme_font_size_override("font_size", 16 if compact else 18)
	api_note.add_theme_font_size_override("font_size", 12 if compact else 13)
	error_label.add_theme_font_size_override("font_size", 12 if compact else 14)
	generate_button.custom_minimum_size.y = 48 if compact else 62
	generate_button.add_theme_font_size_override("font_size", 15 if compact else 16)

func _set_margins(container: MarginContainer, left: int, top: int, right: int, bottom: int) -> void:
	container.add_theme_constant_override("margin_left", left)
	container.add_theme_constant_override("margin_top", top)
	container.add_theme_constant_override("margin_right", right)
	container.add_theme_constant_override("margin_bottom", bottom)

func _update_api_ui() -> void:
	if mode_select == null or api_note == null:
		return
	mode_select.set_item_disabled(0, not ai_available)
	if ai_available:
		mode_select.select(0)
		api_note.text = "● API подключён. Описание будет отправлено выбранной LLM."
		api_note.add_theme_color_override("font_color", UIFactory.SUCCESS)
	else:
		mode_select.select(1)
		api_note.text = "● API не настроен. Офлайн-алгоритм честно помечается и остаётся полностью игровым."
		api_note.add_theme_color_override("font_color", Color("f4bf62"))

func _submit() -> void:
	var text := description_edit.text.strip_edges()
	if text.length() < 12:
		error_label.text = "Опиши мир чуть подробнее — минимум 12 символов."
		description_edit.grab_focus()
		return
	if mode_select.selected == 0 and not ai_available:
		error_label.text = "AI API не настроен. Выбери офлайн-режим или настрой переменные окружения."
		return
	error_label.text = ""
	var themes := ["auto", "fantasy_forest", "abandoned_castle", "mars_station", "ancient_temple", "ice_cave"]
	var sizes := ["small", "medium", "large"]
	var difficulties := ["easy", "normal", "hard"]
	var densities := ["low", "medium", "high"]
	var options := {
		"mode": "ai" if mode_select.selected == 0 else "offline",
		"theme": themes[theme_select.selected],
		"size": sizes[size_select.selected],
		"difficulty": difficulties[difficulty_select.selected],
		"density": densities[density_select.selected]
	}
	generate_requested.emit(text, options)
