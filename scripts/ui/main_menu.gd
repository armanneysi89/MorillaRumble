extends Control

## Hauptmenü: Key-Art mit Partikeln, Titel-Logo, Pinselstrich-Schaltflächen, Coach-Karten und Optionen/Credits.
## Bedienbar per Tastatur, Gamepad, Maus und Touch.

const BG_PATH := "res://assets/ui/menu_bg.png"
const BG_FALLBACK := "res://assets/environments/dojo/bg_garden.png"
const LOGO_PATH := "res://assets/ui/title_logo.png"
const HELP := "A/D laufen · Leertaste springen · J/K Schlag · Shift Dash\nL Block · F Griff · Q Geist · E Sprechen · Esc Pause"

# Name, Rolle, Disziplinen, Porträt
const COACHES := [
	["MO", "HEADCOACH", "BJJ · NOGI · MMA\nKICKBOXEN", "mo_portrait"],
	["ANDRE", "COACH", "BJJ · NOGI · MMA", "andre_portrait"],
	["MATTHIAS", "CO/COACH", "BJJ · NOGI", "matthias_portrait"],
	["ARMAN", "INKLUSIONS COACH", "BJJ · GRAPPLING\nMMA", "arman_portrait"],
	["VITALI", "CO/COACH", "BJJ · NOGI · MMA", "vitali_portrait"],
	["KEVIN", "KIDS COACH", "BJJ · GRAPPLING", "kevin_portrait"],
]
const CREDITS := "MORILLA RUMBLE\nEin Jiu-Jitsu-Metroidvania\n\nCoaches: Mo · Andre · Matthias · Arman · Vitali · Kevin\n\nEngine: Godot 4\nGrafik: ComfyUI (Qwen Image)\nMusik: CC0-Tracks"

var _settings: Dictionary
var _has_progress := false
var _bg: TextureRect
var _logo: Control
var _menu: VBoxContainer
var _cards: HBoxContainer
var _footer: HBoxContainer
var _petals: CPUParticles2D
var _embers: CPUParticles2D
var _panel: Control
var _return_focus: Control
var _first: BrushButton
var _title_font: FontVariation


func _ready() -> void:
	Sound.play_music("menu")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings = GameSettings.load_all()
	_has_progress = Save.has_save() and (Progression.abilities.size() > 0 or not Progression.last_checkpoint.is_empty() or Progression.get_flag("level_dojo_cleared"))
	_title_font = FontVariation.new()
	_title_font.base_font = ThemeDB.fallback_font
	_title_font.variation_embolden = 0.7
	_title_font.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-0.2, 1.0), Vector2.ZERO)
	_build_background()
	_build_logo()
	_build_menu()
	_build_cards()
	_build_footer()
	resized.connect(_layout_fx)
	_layout_fx()
	_first.grab_focus.call_deferred()
	_intro()


func _unhandled_input(event: InputEvent) -> void:
	if _panel and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_panel()


# --- Aufbau ---

func _build_background() -> void:
	var bg_path := BG_PATH if ResourceLoader.exists(BG_PATH) else BG_FALLBACK
	if ResourceLoader.exists(bg_path):
		_bg = TextureRect.new()
		_bg.texture = load(bg_path)
		_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_bg.pivot_offset_ratio = Vector2(0.5, 0.5)
		add_child(_bg)
		var drift := create_tween().set_loops()
		drift.tween_property(_bg, "scale", Vector2.ONE * 1.05, 16.0).set_trans(Tween.TRANS_SINE)
		drift.tween_property(_bg, "scale", Vector2.ONE, 16.0).set_trans(Tween.TRANS_SINE)
	else:
		var fill := ColorRect.new()
		fill.color = Color("14102e")
		fill.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(fill)

	# Mittelspalte und Boden abdunkeln, damit Logo, Menü und Karten lesbar bleiben.
	_add_gradient_rect(Rect2(0.26, 0.0, 0.54, 1.0), true, [0.0, 0.5, 1.0], [Color(0, 0, 0.04, 0.0), Color(0.02, 0.0, 0.06, 0.5), Color(0, 0, 0.04, 0.0)])
	_add_gradient_rect(Rect2(0.0, 0.55, 1.0, 0.45), false, [0.0, 1.0], [Color(0, 0, 0.04, 0.0), Color(0.02, 0.0, 0.05, 0.7)])

	_petals = CPUParticles2D.new()
	_petals.amount = 46
	_petals.lifetime = 11.0
	_petals.preprocess = 11.0
	_petals.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_petals.emission_rect_extents = Vector2(900.0, 10.0)
	_petals.direction = Vector2(0.3, 1.0)
	_petals.spread = 25.0
	_petals.initial_velocity_min = 40.0
	_petals.initial_velocity_max = 110.0
	_petals.gravity = Vector2(25, 15)
	_petals.angular_velocity_min = -90.0
	_petals.angular_velocity_max = 90.0
	_petals.scale_amount_min = 3.0
	_petals.scale_amount_max = 8.0
	_petals.color = Color(1.0, 0.72, 0.82, 0.85)
	add_child(_petals)

	_embers = CPUParticles2D.new()
	_embers.amount = 34
	_embers.lifetime = 6.0
	_embers.preprocess = 6.0
	_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_embers.emission_rect_extents = Vector2(600.0, 10.0)
	_embers.direction = Vector2(0.0, -1.0)
	_embers.spread = 28.0
	_embers.initial_velocity_min = 40.0
	_embers.initial_velocity_max = 120.0
	_embers.gravity = Vector2(0, -15)
	_embers.scale_amount_min = 2.0
	_embers.scale_amount_max = 5.0
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(1.0, 0.55, 0.2, 0.9), Color(1.0, 0.2, 0.1, 0.0)])
	_embers.color_ramp = ramp
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_embers.material = add
	add_child(_embers)


## Farbverlauf-Fläche; area ist als Anteil der Fenstergröße angegeben (x, y, Breite, Höhe).
func _add_gradient_rect(area: Rect2, horizontal: bool, offsets: Array, colors: Array) -> void:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array(offsets)
	grad.colors = PackedColorArray(colors)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(1, 0) if horizontal else Vector2(0, 1)
	tex.width = 256
	tex.height = 256
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.anchor_left = area.position.x
	rect.anchor_top = area.position.y
	rect.anchor_right = area.end.x
	rect.anchor_bottom = area.end.y
	add_child(rect)


func _build_logo() -> void:
	if ResourceLoader.exists(LOGO_PATH):
		var logo := TextureRect.new()
		logo.texture = load(LOGO_PATH)
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_logo = logo
	else:
		var label := Label.new()
		label.text = "MORILLA RUMBLE"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", _title_font)
		label.add_theme_font_size_override("font_size", 120)
		label.add_theme_color_override("font_color", UiTheme.RED)
		label.add_theme_color_override("font_outline_color", Color.WHITE)
		label.add_theme_constant_override("outline_size", 10)
		_logo = label
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.anchor_left = 0.29
	_logo.anchor_right = 0.75
	_logo.anchor_top = 0.02
	_logo.anchor_bottom = 0.325
	_logo.pivot_offset_ratio = Vector2(0.5, 0.5)
	add_child(_logo)


func _start_breathing() -> void:
	var breathe := create_tween().set_loops()
	breathe.tween_property(_logo, "scale", Vector2.ONE * 1.025, 2.6).set_trans(Tween.TRANS_SINE)
	breathe.tween_property(_logo, "scale", Vector2.ONE, 2.6).set_trans(Tween.TRANS_SINE)


func _build_menu() -> void:
	_menu = VBoxContainer.new()
	_menu.anchor_left = 0.33
	_menu.anchor_right = 0.71
	_menu.anchor_top = 0.335
	_menu.anchor_bottom = 0.615
	_menu.add_theme_constant_override("separation", 0)
	add_child(_menu)

	var start := _add_button("Start Game", _on_start)
	var load_button := _add_button("Load Game", _on_load)
	load_button.disabled = not _has_progress
	_add_button("Options", _open_options)
	_add_button("Credits", _open_credits)
	if not OS.has_feature("web") and not OS.has_feature("mobile"):
		_add_button("Exit", func() -> void: get_tree().quit())
	_first = load_button if _has_progress else start


func _add_button(label: String, action: Callable) -> BrushButton:
	var b := BrushButton.new(label)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func() -> void:
		Sound.sfx("ui")
		_return_focus = b
		action.call())
	_menu.add_child(b)
	return b


func _build_cards() -> void:
	_cards = HBoxContainer.new()
	_cards.anchor_left = 0.405
	_cards.anchor_right = 0.985
	_cards.anchor_top = 0.625
	_cards.anchor_bottom = 0.885
	_cards.add_theme_constant_override("separation", 12)
	add_child(_cards)
	for c: Array in COACHES:
		var card := CoachCard.new()
		card.coach_name = c[0]
		card.role = c[1]
		card.skills = c[2]
		var path := "res://assets/ui/%s.png" % c[3]
		if ResourceLoader.exists(path):
			card.portrait = load(path)
		_cards.add_child(card)


func _build_footer() -> void:
	_footer = HBoxContainer.new()
	_footer.anchor_left = 0.42
	_footer.anchor_right = 0.97
	_footer.anchor_top = 0.915
	_footer.anchor_bottom = 0.98
	_footer.alignment = BoxContainer.ALIGNMENT_CENTER
	_footer.add_theme_constant_override("separation", 24)
	add_child(_footer)
	var label := Label.new()
	label.text = "Press Start"
	label.add_theme_font_override("font", _title_font)
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color(0.95, 0.93, 0.9))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 8)
	_footer.add_child(_footer_line())
	_footer.add_child(label)
	_footer.add_child(_footer_line())
	var pulse := create_tween().set_loops()
	pulse.tween_property(_footer, "modulate:a", 0.35, 1.1).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_footer, "modulate:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE)

	var help := Label.new()
	help.text = HELP
	help.anchor_left = 0.015
	help.anchor_right = 0.4
	help.anchor_top = 0.93
	help.anchor_bottom = 0.99
	help.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	help.add_theme_font_size_override("font_size", 20)
	help.add_theme_color_override("font_color", Color(UiTheme.TEXT, 0.8))
	help.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	help.add_theme_constant_override("outline_size", 6)
	add_child(help)


func _footer_line() -> Control:
	var line := ColorRect.new()
	line.color = Color(0.9, 0.85, 0.8, 0.7)
	line.custom_minimum_size = Vector2(120, 2)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return line


func _layout_fx() -> void:
	_petals.position = Vector2(size.x * 0.5, -30.0)
	_petals.emission_rect_extents = Vector2(size.x * 0.6, 10.0)
	_embers.position = Vector2(size.x * 0.66, size.y * 0.96)
	_embers.emission_rect_extents = Vector2(size.x * 0.32, 10.0)


func _intro() -> void:
	_logo.modulate.a = 0.0
	_logo.scale = Vector2.ONE * 1.3
	var tw := create_tween().set_parallel()
	tw.tween_property(_logo, "modulate:a", 1.0, 0.9)
	tw.tween_property(_logo, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(_start_breathing)
	var delay := 0.35
	for node: Control in _menu.get_children() + _cards.get_children():
		node.modulate.a = 0.0
		var t := create_tween()
		t.tween_interval(delay)
		t.tween_property(node, "modulate:a", 1.0, 0.45)
		delay += 0.09


# --- Aktionen ---

func _on_start() -> void:
	if _has_progress:
		_open_panel("New Game?", _text_block("Dein gespeicherter Fortschritt wird überschrieben."), "Cancel", [["Start New Game", _begin_new_game]])
	else:
		_begin_new_game()


func _begin_new_game() -> void:
	Sound.sfx("menu_start")
	Progression.new_game()
	Game.change_scene(Game.INTRO_SCENE, 0.5)


func _on_load() -> void:
	Sound.sfx("menu_start")
	Game.change_scene(Game.resume_scene(), 0.5)


func _open_options() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	box.add_child(_slider_row("Music", "music"))
	box.add_child(_slider_row("SFX", "sfx"))
	if not OS.has_feature("web") and not OS.has_feature("mobile"):
		var fullscreen := CheckButton.new()
		fullscreen.text = "Fullscreen"
		fullscreen.button_pressed = _settings["fullscreen"]
		fullscreen.add_theme_font_size_override("font_size", 32)
		fullscreen.toggled.connect(func(on: bool) -> void:
			_settings["fullscreen"] = on
			_apply_settings())
		box.add_child(fullscreen)
	_open_panel("Options", box, "Back")


func _open_credits() -> void:
	_open_panel("Credits", _text_block(CREDITS), "Back")


func _slider_row(label_text: String, key: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(190, 0)
	label.add_theme_font_size_override("font_size", 32)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = _settings[key]
	slider.custom_minimum_size = Vector2(420, 40)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(func(v: float) -> void:
		_settings[key] = v
		_apply_settings())
	slider.drag_ended.connect(func(_changed: bool) -> void: Sound.sfx("ui"))
	row.add_child(slider)
	return row


func _apply_settings() -> void:
	GameSettings.apply(_settings)
	GameSettings.save_all(_settings)


func _text_block(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", UiTheme.TEXT)
	return label


## Modales Fenster über dem Menü; extra sind [Beschriftung, Aktion]-Paare vor dem Zurück-Knopf.
func _open_panel(title_text: String, content: Control, back_label: String, extra: Array = []) -> void:
	_close_panel(false)
	_menu.visible = false
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.03, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(center)
	var frame := PanelContainer.new()
	var style := UiTheme.panel_style(Color(0.04, 0.03, 0.09, 0.95), Color(UiTheme.RED, 0.9), 6)
	style.content_margin_left = 56
	style.content_margin_right = 56
	style.content_margin_top = 36
	style.content_margin_bottom = 60
	frame.add_theme_stylebox_override("panel", style)
	center.add_child(frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 26)
	frame.add_child(column)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _title_font)
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 10)
	column.add_child(title)
	content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(content)
	var first: BrushButton = null
	for pair: Array in extra:
		var b := BrushButton.new(pair[0])
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(pair[1])
		column.add_child(b)
		first = first if first else b
	var back := BrushButton.new(back_label)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_close_panel)
	column.add_child(back)
	add_child(_panel)
	(first if first else back).grab_focus.call_deferred()


func _close_panel(restore := true) -> void:
	if _panel:
		_panel.queue_free()
		_panel = null
	if restore:
		_menu.visible = true
		if _return_focus and is_instance_valid(_return_focus):
			_return_focus.grab_focus.call_deferred()
