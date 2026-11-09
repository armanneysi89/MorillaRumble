class_name CutsceneSequence
extends Node

## Gemeinsame Basis für inszenierte Zwischensequenzen: Vollbild-Bühne, Dialogbox, Überblendungen und
## sauberes Überspringen (Tab / Zurück-Taste / Knopf).
##
## Unterklassen setzen `DIR` und `SHOTS` und beschreiben in `play()` nur noch die Reihenfolge ihrer
## Einstellungen. Alles andere – Warten auf Clip, Zwischentitel, Abbruch – liegt hier.
##
## Gesprochen wird nur im Intro-Film (scenes/ui/intro.tscn). Die Zwischensequenzen im Level erzählen mit
## Text in der Dialogbox; die Bühne bleibt stumm und spielt nur Musik und Soundeffekte.
##
## SHOTS-Format: Schlüssel -> [Dateiname, loop, optional soundeffekt].
## Der Soundeffekt läuft beim Einblenden der Einstellung.

signal _wake

## Ordner der Clips und Standbilder (res://assets/cutscenes/<szene>/).
var DIR := ""
## Einstellungen der Sequenz, siehe Klassenkommentar.
var SHOTS := {}
## Einmal-Clips laufen bis zum Ende, aber höchstens so lange (Sicherheitsnetz, falls das Video hängt).
var once_timeout := 8.0
## Schleifen-Clips enden nie von selbst, deshalb bekommen sie eine feste Haltezeit.
var loop_hold := 2.6
## Standbilder ohne Video werden so lange gehalten.
var still_hold := 3.5
## Text des Zwischentitels auf Schwarz.
var interlude_text := ""
## Eigener Musiktitel der Szene (assets/audio/music/<name>.ogg). Leer = Levelmusik läuft weiter.
## Die Levelmusik wird beim Start gemerkt und am Ende wieder eingesetzt.
var music := ""
## Lautstärke der Szenenmusik relativ zur normalen Musik (1 = volle Lautstärke).
var music_gain := 1.0

var _stage: CutsceneStage
var _dialogue: DialogueBox
var _skipped := false
var _wait_id := 0
var _has_video := false
var _looping := false
var _level_music := ""


## Baut die Bühne auf und verbindet das Überspringen. Von `play()` der Unterklasse aufzurufen.
func begin(dialogue: DialogueBox) -> void:
	_dialogue = dialogue
	_skipped = false
	_stage = CutsceneStage.new()
	add_child(_stage)
	_stage.skip_requested.connect(_skip)
	_start_music()


## Schließt die Bühne: ausblenden, im Schwarz die Szene umstellen, aufräumen.
## Gibt zurück, ob die Sequenz übersprungen wurde.
func finish(on_black: Callable) -> bool:
	await _stage.fade(1.0, 0.5)
	on_black.call()
	await get_tree().create_timer(0.4).timeout
	await _stage.close(0.8)
	_stage.queue_free()
	_restore_music()
	return _skipped


## Merkt sich die Levelmusik und blendet die Szenenmusik ein.
func _start_music() -> void:
	_level_music = Sound.current_music()
	if music == "":
		return
	Sound.play_music(music, 1.2)
	if music_gain < 1.0:
		Sound.duck(1.0 - music_gain, 0.01)


## Stellt nach der Szene die Musik des Levels wieder her (auch beim Überspringen).
func _restore_music() -> void:
	if music == "":
		return
	if _level_music == "":
		Sound.stop_music(1.0)
	else:
		Sound.play_music(_level_music, 1.2)


## Zeigt eine Einstellung ohne Überblendung (für den Anfang der Sequenz).
func show_shot(key: String) -> void:
	var def: Array = SHOTS[key]
	_looping = bool(def[1])
	var shot := {"video": DIR + def[0] + ".ogv", "still": DIR + def[0] + ".jpg", "loop": def[1]}
	if def.size() > 2 and str(def[2]) != "":
		shot["sfx"] = str(def[2])
	_has_video = _stage.show_shot(shot)


## Blendet auf Schwarz, wechselt die Einstellung und blendet zurück.
func cut(key: String) -> void:
	if _skipped:
		return
	await _stage.fade(1.0, 0.35)
	show_shot(key)
	await _stage.fade(0.0, 0.5)


## Spielt einen Dialog über der aktuellen Einstellung.
func talk(lines: Array) -> void:
	if _skipped or lines.is_empty():
		return
	await _dialogue.play_conversation(lines)


## Zwischentitel auf Schwarz ("Wenig später ...").
func interlude() -> void:
	if _skipped or interlude_text == "":
		return
	await _stage.fade(1.0, 0.4)
	await _stage.show_caption(interlude_text)


## Wartet auf das Ende des laufenden Clips (bei Standbildern eine feste Zeit); Überspringen weckt sofort.
func hold() -> void:
	if _skipped:
		return
	_wait_id += 1
	var id := _wait_id
	var wake := func() -> void:
		if id == _wait_id:
			_wait_id += 1
			_wake.emit()
	if _looping:
		get_tree().create_timer(loop_hold, false).timeout.connect(wake)
	else:
		_stage.video_finished.connect(wake, CONNECT_ONE_SHOT)
		get_tree().create_timer(once_timeout if _has_video else still_hold, false).timeout.connect(wake)
	await _wake


## Überspringen: Dialog sofort beenden, alle Wartenden wecken.
func _skip() -> void:
	if _skipped:
		return
	_skipped = true
	_dialogue.cancel()
	_wait_id += 1
	_wake.emit()
