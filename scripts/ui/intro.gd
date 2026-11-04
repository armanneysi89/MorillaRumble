class_name IntroCutscene
extends Control

## Intro-Film (ComfyUI-Clips) nach "Neues Spiel". Jede Eingabe überspringt; danach folgt das Dojo.

const VIDEO_PATH := "res://assets/intro/intro.ogv"
const VIDEO_RATIO := 1344.0 / 768.0

var _player: VideoStreamPlayer
var _hint: Label
var _done := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Sound.play_music("dojo")
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var stream := load(VIDEO_PATH) as VideoStream
	if stream == null:
		_finish()
		return
	var box := AspectRatioContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.ratio = VIDEO_RATIO
	add_child(box)
	_player = VideoStreamPlayer.new()
	_player.stream = stream
	_player.expand = true
	_player.finished.connect(_finish)
	box.add_child(_player)
	_player.play()

	_hint = Label.new()
	_hint.text = "Beliebige Taste: überspringen"
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint.offset_right = -48
	_hint.offset_bottom = -32
	_hint.add_theme_font_size_override("font_size", 28)
	_hint.add_theme_color_override("font_color", Color(UiTheme.TEXT, 0.7))
	_hint.modulate.a = 0.0
	add_child(_hint)
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(_hint, "modulate:a", 1.0, 0.6)
	tw.tween_interval(3.0)
	tw.tween_property(_hint, "modulate:a", 0.0, 0.6)


func _input(event: InputEvent) -> void:
	if _done or not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	if _player:
		_player.stop()
	Game.change_scene(Game.DOJO_SCENE, 0.6)
