class_name CoachCard
extends Control

## Karte eines Morilla-Sports-Coaches im Hauptmenü: Porträt, Name, Rolle und Disziplinen.

const REF_WIDTH := 176.0

var coach_name := ""
var role := ""
var skills := ""
var portrait: Texture2D
var highlight := false

var _font: FontVariation
var _lift := 0.0
var _hover := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_font = FontVariation.new()
	_font.base_font = ThemeDB.fallback_font
	_font.variation_embolden = 0.6
	_font.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-0.18, 1.0), Vector2.ZERO)
	mouse_entered.connect(func() -> void: _hover = true)
	mouse_exited.connect(func() -> void: _hover = false)
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	var next := move_toward(_lift, 1.0 if _hover else 0.0, delta * 8.0)
	if next != _lift:
		_lift = next
		queue_redraw()


func _draw() -> void:
	var s := size.x / REF_WIDTH
	var top := -_lift * 10.0 * s
	var card := Rect2(Vector2(0.0, top), size)
	var dark := Color(0.05, 0.03, 0.07, 0.94)
	var red := Color(0.42, 0.04, 0.07, 0.96)
	draw_polygon(PackedVector2Array([card.position, card.position + Vector2(card.size.x, 0.0), card.end, card.position + Vector2(0.0, card.size.y)]),
			PackedColorArray([dark, dark, red, red]))
	if portrait:
		var w := card.size.x - 16.0 * s
		var h := w * float(portrait.get_height()) / float(portrait.get_width())
		draw_texture_rect(portrait, Rect2(card.position + Vector2(8.0 * s, 8.0 * s), Vector2(w, h)), false)
	var fade_h := card.size.y * 0.42
	var fade_top := card.end.y - fade_h
	draw_polygon(PackedVector2Array([Vector2(0.0, fade_top), Vector2(card.size.x, fade_top), Vector2(card.size.x, card.end.y), Vector2(0.0, card.end.y)]),
			PackedColorArray([Color(0.1, 0.02, 0.05, 0.0), Color(0.1, 0.02, 0.05, 0.0), Color(0.1, 0.02, 0.05, 0.9), Color(0.1, 0.02, 0.05, 0.9)]))
	var border := Color(1.0, 0.72, 0.4, 0.95) if (_hover or highlight) else Color(0.92, 0.82, 0.76, 0.55)
	draw_rect(card, border, false, 2.0 * maxf(s, 1.0))
	var cx := card.size.x * 0.5
	var y := card.position.y + card.size.y * 0.68
	_centered(coach_name, Vector2(cx, y), int(26.0 * s), Color.WHITE)
	_centered(role, Vector2(cx, y + 24.0 * s), int(15.0 * s), Color(0.95, 0.15, 0.18))
	var line := y + 46.0 * s
	for part in skills.split("\n"):
		_centered(part, Vector2(cx, line), int(13.0 * s), Color(0.96, 0.9, 0.84, 0.92))
		line += 17.0 * s


func _centered(label: String, at: Vector2, font_size: int, color: Color) -> void:
	var w := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := Vector2(at.x - w * 0.5, at.y)
	draw_string_outline(_font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color(0, 0, 0, 0.8))
	draw_string(_font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
