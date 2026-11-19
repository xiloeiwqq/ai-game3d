class_name AboutScreen
extends Control

signal back_requested

func _ready() -> void:
	theme = UIFactory.game_theme()
	UIFactory.overlay(self, 0.94)
	var center := CenterContainer.new()
	UIFactory.full_rect(center)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(panel)
	var margin := UIFactory.make_margin(42, 34, 42, 34)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	box.add_child(UIFactory.label("ОБ AI WORLD GENERATOR", 34, Color.WHITE))
	var intro := UIFactory.label("Это полноценная игра-конструктор: описание превращается в строгий JSON, проходит проверку безопасности и проходимости, а затем собирается в исследуемый 3D-мир.", 18, Color("c8d8e7"))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(intro)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)
	box.add_child(grid)
	for item in [["◈  ДВА РЕЖИМА", "Реальный LLM API или честный офлайн-алгоритм"], ["◇  БЕЗОПАСНОСТЬ", "Белый список ресурсов; никакого исполнения кода"], ["◆  ПРОХОДИМОСТЬ", "Сетка занятости и BFS ко всем целям"], ["▣  ВОСПРОИЗВОДИМОСТЬ", "Seed, версия каталога и сохранённый JSON"], ["✦  3D-КАТАЛОГ", "Процедурные модели, материалы и физические габариты"], ["⌁  ЦЕЛЬ", "Найди 3 артефакта и активируй выход"]]:
		var left := UIFactory.label(str(item[0]), 16, UIFactory.CYAN)
		left.custom_minimum_size.x = 210
		grid.add_child(left)
		var right := UIFactory.label(str(item[1]), 15, UIFactory.MUTED)
		right.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		grid.add_child(right)
	var controls := UIFactory.label("УПРАВЛЕНИЕ\nWASD — движение  •  мышь — обзор  •  Space — прыжок  •  Shift — бег  •  Esc — пауза", 15, UIFactory.MUTED)
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(controls)
	var tech := UIFactory.label("Godot 4.7 • GDScript • JSON 1.0 • OpenAI-compatible HTTP API", 13, UIFactory.MUTED)
	tech.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tech)
	var back := UIFactory.button("НАЗАД", 52)
	back.pressed.connect(func(): back_requested.emit())
	box.add_child(back)
