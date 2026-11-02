class_name UiTheme
extends RefCounted

## Gemeinsame Stile für Menü, Pause, Dialog und Hinweise (Morilla-Farben: Schwarz, Rot, warmes Orange).

const ACCENT := Color("ffb347")
const RED := Color("d62828")
const INK := Color(0.05, 0.04, 0.12)
const TEXT := Color("fff1d6")


static func panel_style(bg: Color, border: Color, radius := 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	return sb


static func make_button(label: String, font_size := 46) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(520, 88)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", panel_style(Color(INK, 0.78), Color(ACCENT, 0.5)))
	b.add_theme_stylebox_override("hover", panel_style(Color(0.35, 0.05, 0.08, 0.92), ACCENT))
	b.add_theme_stylebox_override("focus", panel_style(Color(0.35, 0.05, 0.08, 0.92), ACCENT))
	b.add_theme_stylebox_override("pressed", panel_style(Color(RED, 0.95), Color.WHITE))
	return b
