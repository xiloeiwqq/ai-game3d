class_name MainMenu
extends Control

signal create_requested
signal examples_requested
signal settings_requested
signal about_requested

var status_label: Label

func _ready() -> void:
	theme = UIFactory.game_theme()
	UIFactory.overlay(self, 0.38)
	var margin := UIFactory.make_margin(72, 54, 72, 50)
	UIFactory.full_rect(margin)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)
	var brand := HBoxContainer.new()
	var mark := UIFactory.label("◈", 32, UIFactory.CYAN)
	brand.add_child(mark)
	var studio := UIFactory.label("NEURAL FRONTIER / WORLD LAB", 14, UIFactory.MUTED)
	studio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	brand.add_child(studio)
	root.add_child(brand)
	var spacer_top := Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer_top)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 70)
	root.add_child(content)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 10)
	content.add_child(titles)
	var eyebrow := UIFactory.label("TEXT → SYSTEM → WORLD", 15, UIFactory.CYAN)
	titles.add_child(eyebrow)
	var title := UIFactory.label("AI WORLD\nGENERATOR", 58, Color.WHITE)
	title.add_theme_constant_override("line_spacing", -6)
	titles.add_child(title)
	var subtitle := UIFactory.label("Опиши мир. ИИ создаст его.\nИсследуй его сам.", 22, Color("b9cadd"))
	titles.add_child(subtitle)
	var description := UIFactory.label("Каждая идея становится проходимой 3D-локацией\nс артефактами, тайнами и собственным настроением.", 16, UIFactory.MUTED)
	description.add_theme_constant_override("line_spacing", 4)
	titles.add_child(description)
	var menu_panel := PanelContainer.new()
	menu_panel.custom_minimum_size = Vector2(390, 0)
	content.add_child(menu_panel)
	var menu_margin := UIFactory.make_margin(26, 26, 26, 26)
	menu_panel.add_child(menu_margin)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	menu_margin.add_child(buttons)
	var create_button := UIFactory.button("СОЗДАТЬ МИР  →", 66)
	create_button.add_theme_stylebox_override("normal", UIFactory.style(Color("12647a"), 11, UIFactory.CYAN, 1))
	create_button.add_theme_stylebox_override("hover", UIFactory.style(Color("167e97"), 11, Color.WHITE, 2))
	create_button.pressed.connect(func(): create_requested.emit())
	buttons.add_child(create_button)
	var examples := UIFactory.button("ПРИМЕРЫ МИРОВ")
	examples.pressed.connect(func(): examples_requested.emit())
	buttons.add_child(examples)
	var settings := UIFactory.button("НАСТРОЙКИ")
	settings.pressed.connect(func(): settings_requested.emit())
	buttons.add_child(settings)
	var about := UIFactory.button("ОБ ИГРЕ")
	about.pressed.connect(func(): about_requested.emit())
	buttons.add_child(about)
	status_label = UIFactory.label("●  ПРОВЕРКА AI API...", 13, UIFactory.MUTED)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buttons.add_child(status_label)
	var spacer_bottom := Control.new()
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer_bottom)
	var footer := HBoxContainer.new()
	root.add_child(footer)
	footer.add_child(UIFactory.label("GODOT 4.7  •  PROCEDURAL 3D  •  SAFE JSON", 13, UIFactory.MUTED))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(fill)
	footer.add_child(UIFactory.label("v1.0", 13, UIFactory.MUTED))

func set_api_status(configured: bool) -> void:
	if status_label == null:
		return
	status_label.text = "●  AI API ГОТОВ" if configured else "●  OFFLINE ГОТОВ • AI API НЕ НАСТРОЕН"
	status_label.add_theme_color_override("font_color", UIFactory.SUCCESS if configured else Color("f4bf62"))
