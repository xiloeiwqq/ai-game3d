class_name SettingsScreen
extends Control

signal back_requested

var volume_slider: HSlider
var sensitivity_slider: HSlider
var fullscreen_check: CheckButton
var motion_check: CheckButton
var volume_value: Label
var sensitivity_value: Label

func _ready() -> void:
	theme = UIFactory.game_theme()
	UIFactory.overlay(self, 0.94)
	var center := CenterContainer.new()
	UIFactory.full_rect(center)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 0)
	center.add_child(panel)
	var margin := UIFactory.make_margin(38, 32, 38, 32)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	box.add_child(UIFactory.label("НАСТРОЙКИ", 34, Color.WHITE))
	box.add_child(UIFactory.label("ЗВУК", 13, UIFactory.CYAN))
	var volume_row := HBoxContainer.new()
	box.add_child(volume_row)
	volume_row.add_child(UIFactory.label("Общая громкость", 17, UIFactory.TEXT))
	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 1
	volume_slider.step = 0.01
	volume_slider.value = GameSettings.master_volume
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.value_changed.connect(_update_values)
	volume_row.add_child(volume_slider)
	volume_value = UIFactory.label("", 15, UIFactory.MUTED)
	volume_value.custom_minimum_size.x = 55
	volume_row.add_child(volume_value)
	box.add_child(UIFactory.label("УПРАВЛЕНИЕ", 13, UIFactory.CYAN))
	var sensitivity_row := HBoxContainer.new()
	box.add_child(sensitivity_row)
	sensitivity_row.add_child(UIFactory.label("Чувствительность мыши", 17, UIFactory.TEXT))
	sensitivity_slider = HSlider.new()
	sensitivity_slider.min_value = 0.0005
	sensitivity_slider.max_value = 0.006
	sensitivity_slider.step = 0.0001
	sensitivity_slider.value = GameSettings.mouse_sensitivity
	sensitivity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sensitivity_slider.value_changed.connect(_update_values)
	sensitivity_row.add_child(sensitivity_slider)
	sensitivity_value = UIFactory.label("", 15, UIFactory.MUTED)
	sensitivity_value.custom_minimum_size.x = 55
	sensitivity_row.add_child(sensitivity_value)
	box.add_child(UIFactory.label("ЭКРАН И ДОСТУПНОСТЬ", 13, UIFactory.CYAN))
	fullscreen_check = CheckButton.new()
	fullscreen_check.text = "Полноэкранный режим"
	fullscreen_check.button_pressed = GameSettings.fullscreen
	box.add_child(fullscreen_check)
	motion_check = CheckButton.new()
	motion_check.text = "Уменьшить анимации"
	motion_check.button_pressed = GameSettings.reduce_motion
	box.add_child(motion_check)
	var note := UIFactory.label("Настройки сохраняются локально и применяются сразу после подтверждения.", 14, UIFactory.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	var save := UIFactory.button("СОХРАНИТЬ", 54)
	save.pressed.connect(_save)
	box.add_child(save)
	var back := UIFactory.button("НАЗАД")
	back.pressed.connect(func(): back_requested.emit())
	box.add_child(back)
	_update_values(0)

func _update_values(_value: float) -> void:
	if volume_value:
		volume_value.text = "%d%%" % int(volume_slider.value * 100)
	if sensitivity_value:
		sensitivity_value.text = "%.1f" % (sensitivity_slider.value * 1000.0)

func _save() -> void:
	GameSettings.master_volume = float(volume_slider.value)
	GameSettings.mouse_sensitivity = float(sensitivity_slider.value)
	GameSettings.fullscreen = fullscreen_check.button_pressed
	GameSettings.reduce_motion = motion_check.button_pressed
	GameSettings.save_settings()
	back_requested.emit()
