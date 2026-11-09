extends SceneTree

## Prüfskript für die Rettungsszene im Mondbambus-Hain (kein Spielcode). Aufruf mit eigenem Spielstand:
##   XDG_DATA_HOME=/tmp/x godot --path . --resolution 1280x720 --script tools/rescue_test.gd -- <modus>
## Modi: assets (nur Clips/Standbilder prüfen), play (Sequenz abspielen), skip (Überspringen), level (Einbindung).
## Screenshots landen in /tmp/rescue_shots, Prüfergebnisse als PASS/FAIL auf der Konsole.

const DIR := "res://assets/cutscenes/rescue/"
const SHOTS := "/tmp/rescue_shots"
const SHOT_NAMES := ["1_zu_boden", "2_arman_einsatz", "3_kampf", "4_oktopus", "5_schatten_loest_sich", "6_aufhelfen"]

var _fails := 0
var _shot_no := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)
	_run.call_deferred()


func _run() -> void:
	var mode := "assets"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		mode = args[0]
	_check_assets()
	if mode != "assets":
		await _run_sequence(mode == "skip")
	if mode == "level":
		await _run_level()
	print("RESULT mode=%s fails=%d" % [mode, _fails])
	quit(_fails)


## Jede Einstellung braucht Clip und Standbild; der Kampf-Clip muss deutlich länger sein als die übrigen.
func _check_assets() -> void:
	for name in SHOT_NAMES:
		_check("Clip %s" % name, ResourceLoader.exists(DIR + name + ".ogv"))
		_check("Standbild %s" % name, ResourceLoader.exists(DIR + name + ".jpg"))
	# Eigene Musik je Szene.
	for track in ["intro", "sauna", "bamboo", "quarry", "rescue"]:
		_check("Musik %s" % track, ResourceLoader.exists("res://assets/audio/music/%s.ogg" % track))
	var fight: VideoStream = load(DIR + "3_kampf.ogv") as VideoStream
	var other: VideoStream = load(DIR + "1_zu_boden.ogv") as VideoStream
	_check("Kampf-Clip geladen", fight != null)
	_check("Kampf-Clip ist ein VideoStream", other != null)


## Spielt die Sequenz mit einem Testdialog und macht Screenshots der Einstellungen.
func _run_sequence(skip: bool) -> void:
	var prog := root.get_node("Progression")
	prog.new_game()
	prog.unlock_ability("octopus", false)
	var level := (load("res://scenes/levels/bamboo_level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	await _frames(8)
	var seq: Node = (load("res://scripts/levels/rescue_sequence.gd") as GDScript).new()
	level.add_child(seq)
	var done := [false]
	var script := {
		"save": [["Schattenkämpfer", "Du bist allein, Gorilla."], ["Coach Arman", "Nicht allein. Ich bin hier."]],
		"spirit": [["Coach Arman", "Acht Arme, ein Gedanke. Halte ihn fest."]],
		"after": [["Morilla", "Arman, du bist gekommen."]],
	}
	var run := func() -> void:
		await seq.play(level.dialogue, script, func() -> void: pass)
		done[0] = true
	run.call()
	await _frames(30)
	_shot("01_zu_boden")
	# Eigene Szenenmusik statt der Levelmusik.
	_check("Szenenmusik rescue läuft", _music() == "rescue")
	if skip:
		seq._skip()
		# finish() blendet aus (0,5 s), ruft on_black, wartet 0,4 s und schließt (0,8 s).
		for i in 200:
			if done[0]:
				break
			await _frames(2)
		_check("Überspringen beendet die Sequenz", done[0])
		_check("Levelmusik nach dem Überspringen wieder da", _music() == "bamboo")
		return
	# Durch die Einstellungen klicken: Dialogzeilen weiter, Wartezeiten abkürzen.
	for i in 1200:
		if done[0]:
			break
		if level.dialogue._active:
			_press(level.dialogue)
		await _frames(6)
		if i == 60:
			_shot("02_arman_einsatz")
		elif i == 200:
			_shot("03_kampf")
		elif i == 400:
			_shot("04_oktopus")
		elif i == 700:
			_shot("05_schatten")
	_check("Sequenz läuft bis zum Ende", done[0])
	_check("Levelmusik nach der Szene wieder da", _music() == "bamboo")


## Einbindung im Level: Flag, Technik-Voraussetzung und einmalige Ausführung.
func _run_level() -> void:
	var prog := root.get_node("Progression")
	prog.new_game()
	var level := (load("res://scenes/levels/bamboo_level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	await _frames(8)
	_check("Rettungsflag noch nicht gesetzt", not prog.get_flag("rescue_seen"))
	_check("Arena vorhanden", level.arena != null)
	_check("Tor vorhanden", level.gate != null)
	# Ohne Technik darf die Szene nicht starten (frischer Spielstand hat sie nicht).
	await level._play_rescue_once()
	_check("Ohne Technik kein Rettungsflag", not prog.get_flag("rescue_seen"))
	prog.unlock_ability("octopus", false)
	_shot("10_level")


func _press(dlg) -> void:
	var ev := InputEventAction.new()
	ev.action = &"interact"
	ev.pressed = true
	dlg._unhandled_input(ev)


## Aktueller Musiktitel über den Autoload (im SceneTree-Skript nicht als globaler Name verfügbar).
func _music() -> String:
	return str(root.get_node("Sound").current_music())


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(label: String) -> void:
	_shot_no += 1
	root.get_texture().get_image().save_png("%s/%02d_%s.png" % [SHOTS, _shot_no, label])


func _check(label: String, ok: bool) -> void:
	if not ok:
		_fails += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", label])
