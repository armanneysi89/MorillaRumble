class_name HintSign
extends Area2D

## Tutorial-Hinweis: Erscheint als Textfeld über dem Boden, sobald die Spielfigur in der Nähe ist.

var text := ""
var width := 640.0

var _panel: PanelContainer


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(520, 400)
	cs.shape = shape
	cs.position = Vector2(0, -200)
	add_child(cs)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(0.06, 0.04, 0.14, 0.82), Color("ffb347"), 14))
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(width, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color("fff1d6"))
	_panel.add_child(label)
	_panel.z_index = 12
	_panel.modulate.a = 0.0
	_panel.position = Vector2(-width * 0.5 - 24.0, -470.0)
	add_child(_panel)

	body_entered.connect(func(b: Node2D) -> void: if b is Morilla: _fade(1.0))
	body_exited.connect(func(b: Node2D) -> void: if b is Morilla: _fade(0.0))


func _fade(alpha: float) -> void:
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", alpha, 0.25)
