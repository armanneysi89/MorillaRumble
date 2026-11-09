class_name CutsceneStage
extends CanvasLayer

## Vollbild-Bühne für Zwischensequenzen mitten im Level: Videoclips (Theora) oder Standbilder mit sanftem Zoom,
## schwarze Überblendung und Überspringen-Taste. Liegt unter der Dialogbox (Ebene 15) und über dem HUD.
##
## Ton: Die Bühne spielt nur Musik und Soundeffekte. Gesprochen wird ausschließlich im Intro-Film; die
## Zwischensequenzen im Level erzählen mit Text in der Dialogbox.

signal skip_requested
signal video_finished

const RATIO := 1344.0 / 768.0
const STILL_ZOOM := 1.06
const STILL_TIME := 5.0

var _root: Control
var _video: VideoStreamPlayer
var _still: TextureRect
var _veil: ColorRect
var _caption: Label
var _zoom: Tween


func _ready() -> void:
	layer = 12
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.modulate.a = 0.0
	add_child(_root)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	var box := AspectRatioContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.ratio = RATIO
	_root.add_child(box)
	_still = TextureRect.new()
	_still.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_still.stretch_mode = TextureRect.STRETCH_SCALE
	_still.resized.connect(func() -> void: _still.pivot_offset = _still.size * 0.5)
	box.add_child(_still)
	_video = VideoStreamPlayer.new()
	_video.expand = true
	_video.bus = &"SFX"
	_video.finished.connect(func() -> void: video_finished.emit())
	_video.hide()
	box.add_child(_video)

	_caption = Label.new()
	_caption.set_anchors_preset(Control.PRESET_FULL_RECT)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 56)
	_caption.add_theme_color_override("font_color", UiTheme.TEXT)
	_caption.modulate.a = 0.0

	var hint := Label.new()
	hint.text = "Tab: Szene überspringen"
	hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint.offset_right = -48
	hint.offset_top = 28
	hint.add_theme_font_size_override("font_size", 26)
	hint.add_theme_color_override("font_color", Color(UiTheme.TEXT, 0.7))
	_root.add_child(hint)
	var skip_button := Button.new()
	skip_button.text = "Überspringen"
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	skip_button.offset_left = 40
	skip_button.offset_top = 24
	skip_button.add_theme_font_size_override("font_size", 28)
	skip_button.pressed.connect(func() -> void: skip_requested.emit())
	_root.add_child(skip_button)

	_veil = ColorRect.new()
	_veil.color = Color.BLACK
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.modulate.a = 0.0
	add_child(_veil)
	add_child(_caption)


func _input(event: InputEvent) -> void:
	var key: bool = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB
	var pad: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_BACK
	if key or pad:
		get_viewport().set_input_as_handled()
		skip_requested.emit()


## Zeigt einen Schuss: Video (wenn vorhanden und ladbar), sonst das Standbild mit langsamem Zoom.
## shot: {video, still, loop, sfx}. `sfx` ist ein Klangname aus assets/audio/sfx, der beim Einblenden
## der Einstellung mitläuft (Aufprall, Beschwörung, Rauch) – sonst wirkt der Schnitt stumm.
func show_shot(shot: Dictionary) -> bool:
	_video.stop()
	_video.hide()
	var sfx := str(shot.get("sfx", ""))
	if sfx != "":
		Sound.sfx(sfx, -2.0, 1.0, 0.02)
	if _zoom and _zoom.is_valid():
		_zoom.kill()
	_still.scale = Vector2.ONE
	var still_path := str(shot.get("still", ""))
	_still.texture = load(still_path) as Texture2D if still_path != "" and ResourceLoader.exists(still_path) else null
	var video_path := str(shot.get("video", ""))
	var stream: VideoStream = load(video_path) as VideoStream if video_path != "" and ResourceLoader.exists(video_path) else null
	if stream == null:
		_zoom = create_tween()
		_zoom.tween_property(_still, "scale", Vector2.ONE * STILL_ZOOM, STILL_TIME).set_trans(Tween.TRANS_SINE)
		return false
	_video.stream = stream
	_video.loop = bool(shot.get("loop", false))
	_video.show()
	_video.play()
	return true


## Blendet die Bühne vom Spiel aus ein.
func open(time := 0.7) -> void:
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 1.0, time)
	await tw.finished


## Schwarze Folie über der Bühne (alpha 1 = Schwarz).
func fade(alpha: float, time := 0.45) -> void:
	var tw := create_tween()
	tw.tween_property(_veil, "modulate:a", alpha, time)
	await tw.finished


## Blendet aus dem Schwarz zurück ins Spiel; die Bühne selbst ist dann schon unsichtbar.
func close(time := 0.7) -> void:
	_video.stop()
	_root.modulate.a = 0.0
	await fade(0.0, time)


## Zwischentitel auf Schwarz ("Wenig später ...").
func show_caption(text: String, time := 1.4) -> void:
	_caption.text = text
	var tw := create_tween()
	tw.tween_property(_caption, "modulate:a", 1.0, 0.4)
	tw.tween_interval(time)
	tw.tween_property(_caption, "modulate:a", 0.0, 0.4)
	await tw.finished
