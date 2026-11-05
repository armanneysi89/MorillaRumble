extends SceneTree

## Prüfskript für die Sauna-Begegnung (kein Spielcode). Aufruf (mit eigenem Spielstand, sonst wird der echte verändert):
##   XDG_DATA_HOME=/tmp/x godot --path . --resolution 1280x720 --script tools/sauna_test.gd -- <modus>
## Modi: flow (volle Sequenz), skip (Überspringen mitten drin), met (Sauna erledigt, Technik fehlt),
##       done (alles erledigt), old (Altspielstand: nur talked_arman).
## Screenshots landen in /tmp/sauna_shots, Prüfergebnisse als PASS/FAIL auf der Konsole.

const LEVEL := "res://scenes/levels/bamboo_level.tscn"
const SHOTS := "/tmp/sauna_shots"

var _fails := 0
var _shot_no := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)
	_run.call_deferred()


func _run() -> void:
	var mode := "flow"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		mode = args[0]
	var prog := root.get_node("Progression")
	prog.new_game()
	prog.set_flag("intro_bamboo_seen")
	prog.set_task("find_arman")
	match mode:
		"met":
			prog.set_flag("sauna_met")
		"done":
			prog.set_flag("sauna_met")
			prog.unlock_ability("octopus", false)
		"old":
			prog.set_flag("talked_arman")
	var level := await _load_level()
	match mode:
		"flow", "skip":
			await _enter_sauna(level, mode == "skip")
		"met", "old":
			await _check_resume(level)
		"done":
			_check("done: Tür gesperrt", not level._sauna.can_interact())
			_check("done: Arman steht im Hain", level._arman.is_inside_tree())
			_check("done: Wiederholungszeilen", level._arman.repeat_lines == level.ARMAN_REPEAT)
	print("RESULT mode=%s fails=%d" % [mode, _fails])
	quit(_fails)


func _load_level() -> Node:
	var level := (load(LEVEL) as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	await _frames(4)
	return level


func _enter_sauna(level: Node, skip: bool) -> void:
	var prog := root.get_node("Progression")
	_check("Arman noch nicht im Hain", not level._arman.is_inside_tree())
	_check("Sauna nicht erledigt", not level._sauna.done)
	level.player.global_position = level._sauna.global_position
	await _frames(3)
	_check("Tür bleibt bei Gegnern zu", not level._sauna_busy and level._sauna.get_prompt() != "E: Sauna betreten")
	level._sauna.interact(level.player)
	_check("Interaktion bei Gegnern wirkungslos", not level._sauna_busy)
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await _frames(3)
	_check("Tür offen ohne Gegner", level._sauna.get_prompt() == "E: Sauna betreten")
	_shot("00_vor_der_sauna")
	level._sauna.interact(level.player)
	_check("Begegnung läuft", level._sauna_busy)
	_check("Spielerin eingefroren", level.player.machine.is_in(&"frozen"))
	var skipped_sent := false
	var live_yard_talk := false
	var t := 0.0
	while level._sauna_busy and t < 180.0:
		await create_timer(0.25).timeout
		t += 0.25
		var dlg = level.dialogue
		if dlg._active:
			_press(dlg)
			if skipped_sent and not level.get_children().any(_is_sequence):
				live_yard_talk = true
		if int(t * 4) % 20 == 0:
			_shot("seq_%03d" % int(t))
		if skip and not skipped_sent and t > 6.0:
			var seq = level.get_children().filter(_is_sequence)[0]
			seq._stage.skip_requested.emit()
			skipped_sent = true
	_check("Begegnung fertig (Zeitlimit)", not level._sauna_busy)
	if skip:
		_check("Hof-Dialog live nachgespielt", live_yard_talk)
	_check("sauna_met gesetzt", bool(prog.get_flag("sauna_met")))
	_check("Oktopus freigeschaltet", prog.has_ability("octopus"))
	_check("Aufgabe find_arman erledigt", prog.quest_state("task") != "find_arman")
	_check("Steuerung zurück", level.player.machine.is_in(&"locomotion"))
	_check("Zeitskala normal", is_equal_approx(Engine.time_scale, 1.0))
	_check("Kamera aktiv", level.camera.is_current())
	_check("Arman auf dem Trainingsplatz", level._arman.is_inside_tree() and absf(level._arman.global_position.x - 4000.0) < 1.0)
	_check("Morilla im Hof", absf(level.player.global_position.x - 3870.0) < 400.0)
	_check("Tür danach gesperrt", not level._sauna.can_interact())
	_shot("99_danach")
	# Laden: neuer Levelstand aus dem gespeicherten Fortschritt.
	level.queue_free()
	await _frames(2)
	prog.load_progress()
	var again := await _load_level()
	_check("Laden: keine Wiederholung", not again._sauna.can_interact() and again._arman.is_inside_tree())
	_check("Laden: Technik bleibt", prog.has_ability("octopus"))


func _check_resume(level: Node) -> void:
	var prog := root.get_node("Progression")
	_check("Arman im Hain", level._arman.is_inside_tree())
	_check("Tür gesperrt", not level._sauna.can_interact())
	_check("Technik fehlt noch", not prog.has_ability("octopus"))
	level._arman.interact(level.player)
	var t := 0.0
	while not prog.has_ability("octopus") and t < 90.0:
		await create_timer(0.25).timeout
		t += 0.25
		if level.dialogue._active:
			_press(level.dialogue)
	_check("Lektion erreichbar, Technik freigeschaltet", prog.has_ability("octopus"))
	_check("Steuerung zurück", level.player.machine.is_in(&"locomotion"))


func _is_sequence(n: Node) -> bool:
	return n.has_method("play") and n.has_signal("_wake")


func _press(dlg) -> void:
	var ev := InputEventAction.new()
	ev.action = &"interact"
	ev.pressed = true
	dlg._unhandled_input(ev)


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
