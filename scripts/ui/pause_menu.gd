class_name PauseMenu
extends CanvasLayer

## Pausemenü (Esc / P / Start). Läuft auch bei pausiertem Baum weiter.

var _root: Control
var _first: Button


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.06, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.add_theme_constant_override("separation", 22)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.add_child(box)

	var title := Label.new()
	title.text = "PAUSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 90)
	title.add_theme_color_override("font_color", UiTheme.ACCENT)
	box.add_child(title)

	_first = UiTheme.make_button("Weiter")
	_first.pressed.connect(close)
	box.add_child(_first)
	var restart := UiTheme.make_button("Letzter Checkpoint")
	restart.pressed.connect(func() -> void:
		close()
		Game.reload_scene())
	box.add_child(restart)
	var menu := UiTheme.make_button("Hauptmenü")
	menu.pressed.connect(func() -> void:
		close()
		Game.change_scene(Game.MENU_SCENE))
	box.add_child(menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if _root.visible:
			close()
		else:
			open()


func open() -> void:
	_root.visible = true
	get_tree().paused = true
	_first.grab_focus()


func close() -> void:
	_root.visible = false
	get_tree().paused = false
