class_name BrushButton
extends Control

## Menü-Schaltfläche im Pinselstrich-Stil: schwarzer Strich, bei Auswahl roter Strich mit Pfeil.
## Bedienbar per Maus, Touch, Tastatur und Gamepad (ui_accept).

signal pressed

const STROKE_BLACK := "res://assets/ui/brush_black.png"
const STROKE_RED := "res://assets/ui/brush_red.png"

var text := ""
var font_size := 38
var disabled := false:
	set(value):
		disabled = value
		focus_mode = Control.FOCUS_NONE if value else Control.FOCUS_ALL
		queue_redraw()

var _black: Texture2D
var _red: Texture2D
var _font: FontVariation
var _hover := false
var _glow := 0.0
var _press := 0.0


func _init(label := "") -> void:
	text = label


func _ready() -> void:
	custom_minimum_size = Vector2(560, 58)
	focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	if ResourceLoader.exists(STROKE_BLACK):
		_black = load(STROKE_BLACK)
	if ResourceLoader.exists(STROKE_RED):
		_red = load(STROKE_RED)
	_font = FontVariation.new()
	_font.base_font = ThemeDB.fallback_font
	_font.variation_embolden = 0.7
	_font.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-0.2, 1.0), Vector2.ZERO)
	mouse_entered.connect(func() -> void:
		_hover = true
		if not disabled and not has_focus():
			grab_focus())
	mouse_exited.connect(func() -> void: _hover = false)
	focus_entered.connect(func() -> void: Sound.sfx("ui", -14.0, 1.2, 0.02))


func _process(delta: float) -> void:
	var target := 1.0 if (has_focus() or _hover) and not disabled else 0.0
	var next := move_toward(_glow, target, delta * 8.0)
	var next_press := move_toward(_press, 0.0, delta * 6.0)
	if next != _glow or next_press != _press:
		_glow = next
		_press = next_press
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	var clicked: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if clicked or event.is_action_pressed("ui_accept"):
		accept_event()
		_press = 1.0
		pressed.emit()


func _draw() -> void:
	var grow := _glow * 18.0
	var stroke := Rect2(Vector2(-grow * 0.4, -3.0 - _glow * 3.0), Vector2(size.x + grow, size.y + 6.0 + _glow * 6.0))
	var tint := Color(1, 1, 1, 0.45 if disabled else 1.0)
	if _black:
		draw_texture_rect(_black, stroke, false, Color(tint, tint.a * (1.0 - _glow * 0.9)))
	if _red and _glow > 0.0:
		draw_texture_rect(_red, stroke, false, Color(tint, tint.a * _glow))
	var px := (_press * 6.0) + _glow * 8.0
	var text_size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pos := Vector2((size.x - text_size.x) * 0.5 + px, size.y * 0.5 + font_size * 0.34)
	draw_string_outline(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 8, Color(0.0, 0.0, 0.0, 0.85 * tint.a))
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.96, 0.9, tint.a))
	if _glow > 0.0:
		var c := Vector2(pos.x - 42.0 - (1.0 - _glow) * 14.0, size.y * 0.5)
		var chevron := PackedVector2Array([c + Vector2(-9, -15), c + Vector2(7, 0), c + Vector2(-9, 15)])
		draw_polyline(chevron, Color(1, 1, 1, _glow), 6.0, true)
