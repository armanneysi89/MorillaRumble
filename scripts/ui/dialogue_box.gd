class_name DialogueBox
extends CanvasLayer

## Dialogfeld mit Porträt und Schreibmaschinen-Effekt. Weiter mit E/Enter, Sprung, Schlag, Mausklick oder Tippen.

signal finished

const CHARS_PER_SECOND := 55.0

var _root: Control
var _name: Label
var _text: Label
var _hint: Label
var _portrait: TextureRect
var _lines: Array[String] = []
var _index := 0
var _shown := 0.0
var _active := false


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("dialogue_box")
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(0.05, 0.03, 0.12, 0.94), UiTheme.ACCENT, 18))
	panel.anchor_left = 0.1
	panel.anchor_right = 0.9
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_top = -330
	panel.offset_bottom = -50
	_root.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	panel.add_child(row)

	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(200, 200)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(_portrait)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 40)
	_name.add_theme_color_override("font_color", UiTheme.ACCENT)
	col.add_child(_name)
	_text = Label.new()
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 36)
	_text.add_theme_color_override("font_color", UiTheme.TEXT)
	col.add_child(_text)
	_hint = Label.new()
	_hint.text = "E / Tippen: weiter"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 26)
	_hint.add_theme_color_override("font_color", Color(UiTheme.TEXT, 0.6))
	col.add_child(_hint)


## Zeigt die Zeilen nacheinander und kehrt nach der letzten zurück (mit await verwendbar).
func play(speaker: String, portrait: Texture2D, lines: Array[String]) -> void:
	if _active or lines.is_empty():
		return
	_active = true
	_lines = lines
	_index = 0
	_name.text = speaker
	_portrait.texture = portrait
	_portrait.visible = portrait != null
	_root.visible = true
	_show_line()
	await finished


func _show_line() -> void:
	_text.text = _lines[_index]
	_text.visible_characters = 0
	_shown = 0.0


func _process(delta: float) -> void:
	if not _active:
		return
	_shown += delta * CHARS_PER_SECOND
	_text.visible_characters = int(_shown)


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	var advance := event.is_action_pressed("interact") or event.is_action_pressed("jump") or event.is_action_pressed("light_attack")
	if event is InputEventScreenTouch and event.pressed:
		advance = true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true
	if not advance:
		return
	get_viewport().set_input_as_handled()
	if _text.visible_characters < _text.text.length():
		_text.visible_characters = _text.text.length()
		_shown = float(_text.text.length())
		return
	_index += 1
	if _index >= _lines.size():
		_active = false
		_root.visible = false
		finished.emit()
	else:
		Sound.sfx("ui", -8.0)
		_show_line()
