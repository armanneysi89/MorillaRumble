class_name VitaliSequence
extends Node

## Inszenierte Begegnung mit Baby Mo und Vitali: sechs einzeln animierte Einstellungen (ComfyUI-Clips, siehe
## tools/gen_quarry.py) auf einer Vollbild-Bühne, dazu die normale Dialogbox. Überspringen (Tab / Zurück-Taste / Knopf)
## bricht sauber ab; der Aufrufer bekommt dann `true` und spielt den Dialog live nach.
## Jede Einstellung wird einzeln animiert und hart geschnitten – keine Storyboard-Collage, kein Perspektiv-Morphing.

signal _wake

const DIR := "res://assets/cutscenes/vitali/"
## Schuss -> loop (Dialog-Einstellungen laufen als Ping-Pong-Schleife, die anderen einmal).
const SHOTS := {
	"yard": ["1_vorhof", false],
	"baby_mo": ["2_baby_mo", true],
	"throne_point": ["3_thron_zeigen", true],
	"throne_reveal": ["4_thron_enthuellung", false],
	"vitali_hat": ["5_vitali_hut", true],
	"before_throne": ["6_vor_dem_thron", false],
}
## Einmal-Clips laufen bis zum Ende, aber höchstens so lange (Sicherheitsnetz, falls das Video hängt).
const ONCE_TIMEOUT := 8.0
## Schleifen-Clips sind Dialoghintergründe: kurz halten, damit die Szene nicht leer steht.
const LOOP_HOLD := 2.6
const STILL_HOLD := 3.5
const INTERLUDE := "Der Gürtelthron"

var _stage: CutsceneStage
var _dialogue: DialogueBox
var _skipped := false
var _wait_id := 0
var _has_video := false
var _looping := false


## script: {"yard": [...], "reveal": [...], "talk": [...]} jeweils [Sprecher, Text]-Paare.
## on_black läuft, sobald alles schwarz ist (Spielerin umsetzen, Figuren platzieren). Gibt zurück, ob übersprungen wurde.
func play(dialogue: DialogueBox, script: Dictionary, on_black: Callable) -> bool:
	_dialogue = dialogue
	_skipped = false
	_stage = CutsceneStage.new()
	add_child(_stage)
	_stage.skip_requested.connect(_skip)

	_show("yard")
	await _stage.open(0.7)
	await _hold()
	await _cut("baby_mo")
	await _talk(script["yard"])
	await _cut("throne_point")
	await _hold()
	await _interlude()
	await _cut("throne_reveal")
	await _hold()
	await _cut("vitali_hat")
	await _talk(script["reveal"])
	await _cut("before_throne")
	await _hold()

	await _stage.fade(1.0, 0.5)
	on_black.call()
	await get_tree().create_timer(0.4).timeout
	await _stage.close(0.8)
	_stage.queue_free()
	return _skipped


func _show(key: String) -> void:
	var def: Array = SHOTS[key]
	_looping = bool(def[1])
	_has_video = _stage.show_shot({"video": DIR + def[0] + ".ogv", "still": DIR + def[0] + ".jpg", "loop": def[1]})


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
## Schleifen-Clips enden nie von selbst, deshalb bekommen sie eine feste Haltezeit.
func _hold() -> void:
	if _skipped:
		return
	_wait_id += 1
	var id := _wait_id
	var wake := func() -> void:
		if id == _wait_id:
			_wait_id += 1
			_wake.emit()
	if _looping:
		get_tree().create_timer(LOOP_HOLD, false).timeout.connect(wake)
	else:
		_stage.video_finished.connect(wake, CONNECT_ONE_SHOT)
		get_tree().create_timer(ONCE_TIMEOUT if _has_video else STILL_HOLD, false).timeout.connect(wake)
	await _wake


func _skip() -> void:
	if _skipped:
		return
	_skipped = true
	_dialogue.cancel()
	_wait_id += 1
	_wake.emit()
