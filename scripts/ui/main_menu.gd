extends Control

## Hauptmenü: Hintergrund, Logo und Buttons (Weiterspielen, Neues Spiel, Beenden). Bedienbar per Tastatur, Gamepad, Maus und Touch.

const BG_PATH := "res://assets/ui/menu_bg.png"
const BG_FALLBACK := "res://assets/environments/dojo/bg_garden.png"

var _buttons: VBoxContainer


func _ready() -> void:
	Sound.play_music("menu")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()

	var column := VBoxContainer.new()
	column.anchor_left = 0.37
	column.anchor_right = 0.73
	column.anchor_top = 0.05
	column.anchor_bottom = 0.88
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 6)
	add_child(column)

	var title := Label.new()
	title.text = "MORILLA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 140)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.08))
	title.add_theme_constant_override("outline_size", 22)
	column.add_child(title)

	var title2 := Label.new()
	title2.text = "RUMBLE"
	title2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title2.add_theme_font_size_override("font_size", 150)
	title2.add_theme_color_override("font_color", UiTheme.RED)
	title2.add_theme_color_override("font_outline_color", Color.WHITE)
	title2.add_theme_constant_override("outline_size", 10)
	column.add_child(title2)

	var sub := Label.new()
	sub.text = "Ein Jiu-Jitsu-Metroidvania"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 40)
	sub.add_theme_color_override("font_color", UiTheme.ACCENT)
	column.add_child(sub)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 40)
	column.add_child(gap)

	_buttons = VBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 18)
	column.add_child(_buttons)

	var has_progress: bool = Save.has_save() and (Progression.abilities.size() > 0 or not Progression.last_checkpoint.is_empty() or Progression.get_flag("level_dojo_cleared"))
	var first: Button
	if has_progress:
		first = _add_button("Weiterspielen", _start)
		_add_button("Neues Spiel", _new_game)
	else:
		first = _add_button("Spiel starten", _new_game)
	if not OS.has_feature("web") and not OS.has_feature("mobile"):
		_add_button("Beenden", func() -> void: get_tree().quit())
	first.grab_focus()

	var help := Label.new()
	help.text = "A/D laufen   Leertaste springen   J/K Schlag   Shift Dash   L Block   F Griff   E Sprechen   Esc Pause"
	help.add_theme_font_size_override("font_size", 26)
	help.add_theme_color_override("font_color", Color(UiTheme.TEXT, 0.75))
	help.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	help.grow_horizontal = Control.GROW_DIRECTION_BOTH
	help.offset_top = -50
	help.offset_bottom = -10
	add_child(help)


func _add_button(label: String, action: Callable) -> Button:
	var b := UiTheme.make_button(label)
	b.pressed.connect(func() -> void:
		Sound.sfx("ui")
		action.call())
	_buttons.add_child(b)
	return b


func _build_background() -> void:
	var bg_path := BG_PATH if ResourceLoader.exists(BG_PATH) else BG_FALLBACK
	if ResourceLoader.exists(bg_path):
		var bg := TextureRect.new()
		bg.texture = load(bg_path)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(bg)
	else:
		var fill := ColorRect.new()
		fill.color = Color("14102e")
		fill.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(fill)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.01, 0.07, 0.12 if bg_path == BG_PATH else 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)


func _start() -> void:
	Game.change_scene(Game.DOJO_SCENE, 0.5)


func _new_game() -> void:
	Progression.new_game()
	Game.change_scene(Game.DOJO_SCENE, 0.5)
