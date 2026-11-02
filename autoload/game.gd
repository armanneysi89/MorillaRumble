extends Node

## Globale Dienste: Eingabe-Aktionen, Hit-Stop, Kamera-Wackeln, Hinweis-Meldungen und Szenenwechsel mit Überblendung.

signal shake_requested(strength: float)
signal toast_requested(text: String)

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const DOJO_SCENE := "res://scenes/levels/dojo_level.tscn"

# Aktion -> Tasten, Gamepad-Tasten, Gamepad-Achse [Achse, Richtung]
const ACTIONS := {
	"move_left": {"keys": [KEY_A, KEY_LEFT], "buttons": [JOY_BUTTON_DPAD_LEFT], "axis": [JOY_AXIS_LEFT_X, -1.0]},
	"move_right": {"keys": [KEY_D, KEY_RIGHT], "buttons": [JOY_BUTTON_DPAD_RIGHT], "axis": [JOY_AXIS_LEFT_X, 1.0]},
	"jump": {"keys": [KEY_SPACE, KEY_W, KEY_UP], "buttons": [JOY_BUTTON_A]},
	"light_attack": {"keys": [KEY_J, KEY_X], "buttons": [JOY_BUTTON_X]},
	"heavy_attack": {"keys": [KEY_K, KEY_C], "buttons": [JOY_BUTTON_Y]},
	"dash": {"keys": [KEY_SHIFT, KEY_Z], "buttons": [JOY_BUTTON_B]},
	"block": {"keys": [KEY_L, KEY_V], "buttons": [JOY_BUTTON_LEFT_SHOULDER]},
	"grab": {"keys": [KEY_F, KEY_G], "buttons": [JOY_BUTTON_RIGHT_SHOULDER]},
	"interact": {"keys": [KEY_E, KEY_ENTER, KEY_KP_ENTER], "buttons": [JOY_BUTTON_DPAD_UP]},
	"pause": {"keys": [KEY_ESCAPE, KEY_P], "buttons": [JOY_BUTTON_START]},
}

var _hitstop_end := 0
var _changing := false
var _fade: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_input_actions()
	var layer := CanvasLayer.new()
	layer.layer = 200
	_fade = ColorRect.new()
	_fade.color = Color(0.02, 0.01, 0.05, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	add_child(layer)


static func ensure_input_actions() -> void:
	for action: String in ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.35)
		var def: Dictionary = ACTIONS[action]
		for key: int in def.get("keys", []):
			var ev := InputEventKey.new()
			ev.physical_keycode = key as Key
			InputMap.action_add_event(action, ev)
		for button: int in def.get("buttons", []):
			var jb := InputEventJoypadButton.new()
			jb.button_index = button as JoyButton
			InputMap.action_add_event(action, jb)
		if def.has("axis"):
			var jm := InputEventJoypadMotion.new()
			jm.axis = def["axis"][0] as JoyAxis
			jm.axis_value = def["axis"][1]
			InputMap.action_add_event(action, jm)


func _unhandled_input(event: InputEvent) -> void:
	# Debug-Builds: Tasten 1-5 wechseln die Gürtelstufe, um die Anpassung des Sprites zu prüfen.
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo:
		var idx: int = event.physical_keycode - KEY_1
		if idx >= 0 and idx < Progression.BELTS.size():
			Progression.set_belt(Progression.BELTS[idx])


## Friert das Spiel kurz ein, um Treffern Gewicht zu geben.
func hit_stop(duration: float, time_scale := 0.03) -> void:
	if duration <= 0.0:
		return
	var end := Time.get_ticks_msec() + int(duration * 1000.0)
	if end <= _hitstop_end:
		return
	_hitstop_end = end
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	if Time.get_ticks_msec() >= _hitstop_end:
		Engine.time_scale = 1.0


func shake(strength: float) -> void:
	shake_requested.emit(strength)


func toast(text: String) -> void:
	toast_requested.emit(text)


func change_scene(path: String, fade_time := 0.35) -> void:
	if _changing:
		return
	_changing = true
	await _fade_to(1.0, fade_time)
	Engine.time_scale = 1.0
	_hitstop_end = 0
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0, fade_time)
	_changing = false


func reload_scene(fade_time := 0.5) -> void:
	change_scene(get_tree().current_scene.scene_file_path, fade_time)


func _fade_to(alpha: float, time: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, time)
	await tw.finished
