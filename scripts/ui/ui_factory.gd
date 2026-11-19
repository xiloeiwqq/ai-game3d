class_name UIFactory
extends RefCounted

const CYAN := Color("53ddff")
const VIOLET := Color("9c74ff")
const INK := Color("07101f")
const PANEL := Color(0.035, 0.065, 0.12, 0.94)
const TEXT := Color("eaf5ff")
const MUTED := Color("92a8bd")
const SUCCESS := Color("6fffc1")
const DANGER := Color("ff6985")

static func game_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 18
	result.set_color("font_color", "Label", TEXT)
	result.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.5))
	result.set_constant("shadow_offset_x", "Label", 1)
	result.set_constant("shadow_offset_y", "Label", 2)
	result.set_color("font_color", "Button", TEXT)
	result.set_color("font_hover_color", "Button", Color.WHITE)
	result.set_color("font_pressed_color", "Button", CYAN)
	result.set_font_size("font_size", "Button", 16)
	result.set_stylebox("normal", "Button", style(Color(0.08, 0.14, 0.23, 0.94), 10, Color(0.22, 0.36, 0.5, 0.7), 1))
	result.set_stylebox("hover", "Button", style(Color(0.10, 0.22, 0.34, 0.98), 10, CYAN, 2))
	result.set_stylebox("pressed", "Button", style(Color(0.08, 0.12, 0.22, 1), 10, VIOLET, 2))
	result.set_stylebox("disabled", "Button", style(Color(0.07, 0.08, 0.11, 0.72), 10, Color(0.2, 0.23, 0.27), 1))
	result.set_color("font_disabled_color", "Button", Color("657486"))
	result.set_stylebox("normal", "LineEdit", style(Color(0.025, 0.05, 0.09, 0.96), 8, Color(0.2, 0.34, 0.46), 1))
	result.set_stylebox("focus", "LineEdit", style(Color(0.025, 0.06, 0.105, 1), 8, CYAN, 2))
	result.set_stylebox("normal", "TextEdit", style(Color(0.025, 0.05, 0.09, 0.96), 12, Color(0.2, 0.34, 0.46), 1))
	result.set_stylebox("focus", "TextEdit", style(Color(0.025, 0.06, 0.105, 1), 12, CYAN, 2))
	result.set_color("font_color", "TextEdit", TEXT)
	result.set_color("font_placeholder_color", "TextEdit", Color("637b90"))
	result.set_font_size("font_size", "TextEdit", 18)
	result.set_stylebox("normal", "OptionButton", style(Color(0.05, 0.1, 0.17, 1), 8, Color(0.2, 0.34, 0.46), 1))
	result.set_stylebox("hover", "OptionButton", style(Color(0.07, 0.15, 0.24, 1), 8, CYAN, 1))
	result.set_stylebox("panel", "Panel", style(PANEL, 16, Color(0.16, 0.29, 0.42, 0.8), 1))
	result.set_stylebox("panel", "PanelContainer", style(PANEL, 16, Color(0.16, 0.29, 0.42, 0.8), 1))
	return result

static func style(color: Color, radius: int = 8, border_color := Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.border_width_left = border_width
	box.border_width_top = border_width
	box.border_width_right = border_width
	box.border_width_bottom = border_width
	box.border_color = border_color
	box.content_margin_left = 18.0
	box.content_margin_right = 18.0
	box.content_margin_top = 12.0
	box.content_margin_bottom = 12.0
	return box

static func full_rect(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func overlay(parent: Control, alpha: float = 0.58) -> ColorRect:
	var value := ColorRect.new()
	value.color = Color(0.012, 0.025, 0.055, alpha)
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	full_rect(value)
	parent.add_child(value)
	return value

static func label(text: String, size: int = 18, color: Color = TEXT) -> Label:
	var value := Label.new()
	value.text = text
	value.add_theme_font_size_override("font_size", size)
	value.add_theme_color_override("font_color", color)
	return value

static func button(text: String, min_height: float = 50.0) -> Button:
	var value := Button.new()
	value.text = text
	value.custom_minimum_size = Vector2(0, min_height)
	value.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return value

static func make_margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin

static func format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]
