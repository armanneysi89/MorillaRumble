class_name SaunaSequence
extends Node

## Inszenierte Sauna-Begegnung: sechs einzeln animierte Einstellungen (ComfyUI-Clips, siehe tools/gen_sauna.py)
## auf einer Vollbild-Bühne, dazu die normale Dialogbox. Überspringen (Tab / Zurück-Taste / Knopf) bricht sauber
## ab; der Aufrufer bekommt dann `true` und spielt den Hof-Dialog live nach.

signal _wake

const DIR := "res://assets/cutscenes/sauna/"
## Schuss -> [Dateiname, loop, Erzählerstimme]. Nur Einstellungen ohne Dialog haben eine Stimme
## (tools/gen_narration.py); sonst sprechen Erzähler und Dialogfigur gleichzeitig.
const SHOTS := {
	"approach": ["1_anreise", false, true],
	"room": ["2_sauna_innen", true, false],
	"closeup": ["3_sauna_nahaufnahme", true, false],
	"yard": ["4_trainingsplatz", false, true],
	"talk": ["5_arman_gespraech", true, false],
	"octopus": ["6_oktopus", false, true],
}
const ONCE_TIMEOUT := 8.0
const STILL_HOLD := 3.5
## Nachlauf, damit die Stimme nicht hart auf dem letzten Wort endet.
const VOICE_TAIL := 0.5
const INTERLUDE := "Wenig später ..."

var _stage: CutsceneStage
var _dialogue: DialogueBox
var _skipped := false
var _wait_id := 0
var _has_video := false


## script: {"room": [...], "closeup": [...], "talk": [...]} jeweils [Sprecher, Text]-Paare.
## on_black läuft, sobald alles schwarz ist (Spielerin umsetzen, Coach platzieren). Gibt zurück, ob übersprungen wurde.
func play(dialogue: DialogueBox, script: Dictionary, on_black: Callable) -> bool:
	_dialogue = dialogue
	_skipped = false
	_stage = CutsceneStage.new()
	add_child(_stage)
	_stage.skip_requested.connect(_skip)

	_show("approach")
	await _stage.open(0.7)
	await _hold()
	await _cut("room")
	await _talk(script["room"])
	await _cut("closeup")
	await _talk(script["closeup"])
	await _interlude()
	await _cut("yard")
	await _hold()
	await _cut("talk")
	await _talk(script["talk"])
	await _cut("octopus")
	await _hold()

	await _stage.fade(1.0, 0.5)
	on_black.call()
	await get_tree().create_timer(0.4).timeout
	await _stage.close(0.8)
	_stage.queue_free()
	return _skipped


func _show(key: String) -> void:
	var def: Array = SHOTS[key]
	var shot := {"video": DIR + def[0] + ".ogv", "still": DIR + def[0] + ".jpg", "loop": def[1]}
	if bool(def[2]):
		shot["voice"] = DIR + def[0] + ".ogg"
	_has_video = _stage.show_shot(shot)


func _cut(key: String) -> void:
	if _skipped:
		return
	await _stage.fade(1.0, 0.35)
	_show(key)
	await _stage.fade(0.0, 0.5)


func _talk(lines: Array) -> void:
	if _skipped:
		return
	await _dialogue.play_conversation(lines)


func _interlude() -> void:
	if _skipped:
		return
	await _stage.fade(1.0, 0.4)
	await _stage.show_caption(INTERLUDE)


## Wartet auf das Ende des laufenden Clips (bei Standbildern eine feste Zeit); Überspringen weckt sofort.
## Läuft eine Erzählerstimme, wird zusätzlich auf deren Ende gewartet – der Clip ist kürzer als der Satz.
func _hold() -> void:
	if _skipped:
		return
	_wait_id += 1
	var id := _wait_id
	var wake := func() -> void:
		if id == _wait_id:
			_wait_id += 1
			_wake.emit()
	_stage.video_finished.connect(wake, CONNECT_ONE_SHOT)
	get_tree().create_timer(ONCE_TIMEOUT if _has_video else STILL_HOLD, false).timeout.connect(wake)
	await _wake
	await _voice_tail()


## Wartet, bis die Erzählerstimme fertig ist (höchstens ihre Länge plus Nachlauf).
func _voice_tail() -> void:
	if _skipped or not _stage.is_voice_playing():
		return
	_wait_id += 1
	var id := _wait_id
	var wake := func() -> void:
		if id == _wait_id:
			_wait_id += 1
			_wake.emit()
	_stage.voice_finished.connect(wake, CONNECT_ONE_SHOT)
	get_tree().create_timer(_stage.voice_length() + VOICE_TAIL, false).timeout.connect(wake)
	await _wake


func _skip() -> void:
	if _skipped:
		return
	_skipped = true
	_dialogue.cancel()
	_stage.stop_voice()
	_wait_id += 1
	_wake.emit()
