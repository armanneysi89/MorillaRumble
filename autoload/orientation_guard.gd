extends CanvasLayer

## Auf Touch-Geräten im Hochformat: Spiel pausieren und zum Drehen auffordern.

var _cover: ColorRect


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not TouchControls.wanted():
		return
	_cover = ColorRect.new()
	_cover.color = Color(0.05, 0.04, 0.1, 1.0)
	_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	var label := Label.new()
	label.text = "Bitte dreh dein Gerät\nins Querformat"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 110)
	label.add_theme_color_override("font_color", Color("ffb347"))
	_cover.add_child(label)
	add_child(_cover)
	get_tree().root.size_changed.connect(_update)
	_update()


func _update() -> void:
	var win := DisplayServer.window_get_size()
	var portrait := win.y > win.x
	_cover.visible = portrait
	get_tree().paused = portrait
