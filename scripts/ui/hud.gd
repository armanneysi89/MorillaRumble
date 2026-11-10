class_name Hud
extends CanvasLayer

## Anzeige: Leben, Gürtel, Techniken, Interaktions-Hinweis, Meldungen, Banner, Vignette und Überblendung.

const BELT_BAR := Vector2(220, 20)
## Ladungsanzeige des schweren Schlags unterhalb des Lebens.
const CHARGE_BAR := Vector2(300, 14)
## Volle Ladung: zentrale Schwelle der Spielfigur.
const CHARGE_FULL_AT = Morilla.CHARGE_FULL

var player: Morilla
var title := ""
var subtitle := ""

var _canvas: Control
var _prompt: Label
var _toast: Label
var _banner_title: Label
var _banner_sub: Label
var _banner: VBoxContainer
var _fade: ColorRect
var _tech: Label
var _goal: Label
var _task: Label
var _toast_tween: Tween
var _banner_tween: Tween
var _hp := 0
var _max_hp := 0
var _belt := Color.WHITE
var _belt_name := ""
var _cd_tenths := -1
var _charge := 0.0
## Zuletzt gezeichnete Kristallzahl (Neuzeichnen nur bei Änderung).
var _gems := -1


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_hud)
	add_child(_canvas)
	_add_vignette()

	_prompt = _label(40, UiTheme.TEXT)
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_left = -500
	_prompt.offset_right = 500
	_prompt.offset_top = -170
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_canvas.add_child(_prompt)

	_toast = _label(40, UiTheme.ACCENT)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -700
	_toast.offset_right = 700
	_toast.offset_top = 150
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	_canvas.add_child(_toast)

	# Unter der Gürtel- und Kristallanzeige, damit sich die Zeilen nicht überlagern.
	_tech = _label(30, Color(UiTheme.TEXT, 0.85))
	_tech.position = Vector2(48, 168)
	_canvas.add_child(_tech)

	var objective := VBoxContainer.new()
	objective.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	objective.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	objective.offset_left = -820
	objective.offset_right = -48
	objective.offset_top = 44
	objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(objective)
	_goal = _label(26, Color(UiTheme.TEXT, 0.7), 6)
	_task = _label(34, UiTheme.ACCENT, 8)
	for l: Label in [_goal, _task]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		objective.add_child(l)
	Progression.task_changed.connect(_update_task)
	_update_task()

	_banner = VBoxContainer.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.offset_left = -800
	_banner.offset_right = 800
	_banner.offset_top = -220
	_banner.offset_bottom = -60
	_banner.modulate.a = 0.0
	_canvas.add_child(_banner)
	_banner_title = _label(96, Color.WHITE, 18)
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_title)
	_banner_sub = _label(44, UiTheme.ACCENT)
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_sub)

	_fade = ColorRect.new()
	_fade.color = Color(0.02, 0.01, 0.05, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	Game.toast_requested.connect(show_toast)
	Progression.belt_changed.connect(_on_belt_changed)
	Progression.ability_unlocked.connect(func(_id: String) -> void: _update_tech())
	_on_belt_changed(Progression.belt)
	_update_tech()
	if title != "":
		show_banner(title, subtitle, 3.5)


func _exit_tree() -> void:
	if Progression.task_changed.is_connected(_update_task):
		Progression.task_changed.disconnect(_update_task)
	if Game.toast_requested.is_connected(show_toast):
		Game.toast_requested.disconnect(show_toast)
	if Progression.belt_changed.is_connected(_on_belt_changed):
		Progression.belt_changed.disconnect(_on_belt_changed)


func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var tenths := ceili(player.summon_cooldown * 10.0)
	if tenths != _cd_tenths:
		_cd_tenths = tenths
		_update_tech()
	# Die Ladung des schweren Schlags läuft framegenau, daher nur bei Änderung neu zeichnen.
	var charge := snappedf(player.charge_level, 0.02)
	if charge != _charge:
		_charge = charge
		_canvas.queue_redraw()
	# Kristalle ändern sich nur beim Einsammeln.
	var gems := Progression.gem_count()
	if gems != _gems:
		_gems = gems
		_canvas.queue_redraw()


func bind_player(p: Morilla) -> void:
	player = p
	_hp = p.health.hp
	_max_hp = p.health.max_hp
	p.health.changed.connect(func(hp: int, max_hp: int) -> void:
		_hp = hp
		_max_hp = max_hp
		_canvas.queue_redraw())
	p.interactable_changed.connect(func(text: String) -> void: _prompt.text = text)
	_canvas.queue_redraw()


func show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.6)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func show_banner(main: String, sub := "", time := 3.0) -> void:
	_banner_title.text = main
	_banner_sub.text = sub
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.5)
	_banner_tween.tween_interval(time)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.8)


func fade_to(alpha: float, time: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, time)
	await tw.finished


func _on_belt_changed(belt_id: String) -> void:
	var data := Progression.belt_data(belt_id)
	_belt = data.color
	_belt_name = data.display_name
	_canvas.queue_redraw()


func _update_task() -> void:
	_goal.text = Progression.main_goal_text()
	_goal.visible = _goal.text != ""
	_task.text = Progression.task_text()
	_task.visible = _task.text != ""


func _update_tech() -> void:
	var lines: PackedStringArray = []
	for id in Progression.abilities:
		var ab := Progression.get_ability(id)
		if ab == null:
			continue
		var line := "%s  %s" % [ab.input_hint, ab.display_name]
		if ab.max_targets > 0 and player and is_instance_valid(player) and player.summon_cooldown > 0.0:
			line += "  %.1f s" % player.summon_cooldown
		lines.append(line)
	_tech.text = "\n".join(lines)


func _label(size: int, color: Color, outline := 10) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.08))
	l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _add_vignette() -> void:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.55, 1.0])
	grad.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0.02, 0.0, 0.08, 0.55)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	tex.width = 256
	tex.height = 256
	var rect := TextureRect.new()
	rect.texture = tex
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	move_child(rect, 0)


func _draw_hud() -> void:
	# Leben als rote Segmente, leere als dunkle Rahmen.
	var origin := Vector2(48, 48)
	for i in _max_hp:
		var r := Rect2(origin + Vector2(i * 54, 0), Vector2(46, 26))
		_canvas.draw_rect(r, Color(0.05, 0.02, 0.08, 0.8))
		if i < _hp:
			_canvas.draw_rect(r.grow(-3), UiTheme.RED)
			_canvas.draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(r.size.x - 6, 8)), Color(1, 0.55, 0.5, 0.6))
		_canvas.draw_rect(r, Color(UiTheme.ACCENT, 0.7), false, 2.0)
	# Gürtelanzeige
	var belt_pos := origin + Vector2(0, 46)
	_canvas.draw_rect(Rect2(belt_pos, BELT_BAR), Color(0.05, 0.02, 0.08, 0.8))
	_canvas.draw_rect(Rect2(belt_pos + Vector2(3, 3), BELT_BAR - Vector2(6, 6)), _belt)
	_canvas.draw_rect(Rect2(belt_pos, BELT_BAR), Color(UiTheme.ACCENT, 0.7), false, 2.0)
	_canvas.draw_string(ThemeDB.fallback_font, belt_pos + Vector2(BELT_BAR.x + 14, 18), _belt_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UiTheme.TEXT)
	# Kristalle: acht Punkte, gefüllt bis zur nächsten vollen Ladung (+1 maximales Leben).
	if _gems >= 0:
		var gem_pos := belt_pos + Vector2(0, 34)
		var per := Progression.GEMS_PER_BELT
		var filled := _gems % per
		for i in per:
			var c := gem_pos + Vector2(i * 26, 0)
			var pts := PackedVector2Array([c + Vector2(0, -9), c + Vector2(8, 0), c + Vector2(0, 9), c + Vector2(-8, 0)])
			_canvas.draw_colored_polygon(pts, Color("ffd166") if i < filled else Color(0.05, 0.02, 0.08, 0.8))
			_canvas.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(UiTheme.ACCENT, 0.6), 1.5)
	# Ladung des schweren Schlags: wächst von links nach rechts, voll leuchtet gelb.
	if _charge > 0.01:
		var charge_pos := origin + Vector2(0, 76)
		var full := _charge >= CHARGE_FULL_AT
		var fill_col := Color("ffd166") if full else Color("ff7a45")
		_canvas.draw_rect(Rect2(charge_pos, CHARGE_BAR), Color(0.05, 0.02, 0.08, 0.8))
		var w := (CHARGE_BAR.x - 6.0) * clampf(_charge, 0.0, 1.0)
		_canvas.draw_rect(Rect2(charge_pos + Vector2(3, 3), Vector2(w, CHARGE_BAR.y - 6.0)), fill_col)
		_canvas.draw_rect(Rect2(charge_pos, CHARGE_BAR), Color(UiTheme.ACCENT, 0.7), false, 2.0)
		var caption := "GELADEN" if full else "LÄDT"
		_canvas.draw_string(ThemeDB.fallback_font, charge_pos + Vector2(CHARGE_BAR.x + 12, 13), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(UiTheme.TEXT, 0.85))
