extends SceneTree

## Prüfskript für Level 3 (Vitalis Steinbruch, kein Spielcode). Aufruf (mit eigenem Spielstand!):
##   XDG_DATA_HOME=/tmp/x godot --path . --resolution 1280x720 --script tools/quarry_test.gd -- <modus>
## Modi: load (nur laden), flow (Begegnung + Lektion), skip (Überspringen), boss (Boss besiegen),
##       slab (Bruchplatte per Suplex), old (Altspielstand: nur talked_vitali), layout (Anordnung prüfen).
## Screenshots landen in /tmp/quarry_shots, Prüfergebnisse als PASS/FAIL auf der Konsole.

const LEVEL := "res://scenes/levels/quarry_level.tscn"
const SHOTS := "/tmp/quarry_shots"

var _fails := 0
var _shot_no := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)
	_run.call_deferred()


func _run() -> void:
	var mode := "load"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		mode = args[0]
	var prog := root.get_node("Progression")
	prog.new_game()
	prog.set_flag("intro_quarry_seen")
	prog.set_flag("sauna_met")
	prog.unlock_ability("octopus", false)
	prog.unlock_ability("kimura", false)
	match mode:
		"old":
			prog.set_flag("talked_vitali")
		"boss", "slab":
			prog.set_flag("vitali_met")
			prog.unlock_ability("suplex", false)
	var level := await _load_level()
	_check("Level geladen", level != null)
	_check("Thron gebaut", level._throne != null)
	_check("Baby Mo da", level._baby_mo != null)
	_check("Vitali da", level._vitali != null)
	_check("Boss-Arena da", level._boss != null)
	_check("Bruchplatte da", level._slab != null)
	_check("Baby Mo größer als Morilla", CharacterSpecs.BABY_MO["scale"] > CharacterSpecs.MORILLA["scale"])
	_check("Vitali kleiner als Morilla", CharacterSpecs.VITALI["scale"] < CharacterSpecs.MORILLA["scale"])
	_check("Baby Mo größer als Vitali", CharacterSpecs.BABY_MO["scale"] > CharacterSpecs.VITALI["scale"])
	# Nur vor der Begegnung sitzt Vitali auf dem Thron; danach steht er daneben.
	if level._vitali_met():
		_check("Vitali steht neben dem Thron", is_equal_approx(level._vitali.position.y, level._throne.position.y))
	else:
		_check("Vitali sitzt auf der Sitzfläche", is_equal_approx(level._vitali.position.y,
			level._throne.position.y - BeltThrone.SIT_FOOT_HEIGHT))
		_check("Vitali vor der Gürtelkaskade", level._vitali.z_index > 2)
	_check("Heller Himmel", level.sky_top.v > 0.5 and level.sky_bottom.v > 0.8)
	_check("Steinbruch-Hintergrund", level.far_background.contains("quarry"))
	_check("Levelbreite 9600", is_equal_approx(level.level_width, 9600.0))
	_shot("00_start")
	match mode:
		"flow", "skip":
			await _run_encounter(level, mode == "skip")
		"boss":
			await _run_boss(level)
		"slab":
			await _run_slab(level)
		"layout":
			_check_layout(level)
			await _run_traverse(level)
		"old":
			_check("Alt: Begegnung übersprungen", level._vitali_met())
	print("RESULT mode=%s fails=%d" % [mode, _fails])
	quit(_fails)


func _load_level() -> Node:
	var level := (load(LEVEL) as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	await _frames(6)
	return level


## Prüft, dass alle Elemente auf festem Boden stehen und links nach rechts sortiert sind.
func _check_layout(level: Node) -> void:
	var ground: Array = level.platforms.filter(func(p: Array) -> bool: return p[0] == PlatformBlock.Kind.ROCK)
	_check("Drei Felsböden", ground.size() == 3)
	var gaps := []
	for i in range(ground.size() - 1):
		gaps.append(ground[i + 1][1] - (ground[i][1] + ground[i][3]))
	_check("Zwei Schluchten", gaps.size() == 2)
	_check("Schlucht 1 vorhanden (> 0)", gaps[0] > 0.0)
	_check("Schlucht 2 vorhanden (> 0)", gaps[1] > 0.0)
	_check("Schlucht 1 überwindbar (<= 420)", gaps[0] <= 420.0)
	_check("Schlucht 2 überwindbar (<= 420)", gaps[1] <= 420.0)
	# Alles, was auf dem Boden steht, muss über einem Felsboden liegen.
	var on_ground := []
	for e in level.enemies:
		on_ground.append(["Gegner", e[0]])
	for c in level.checkpoints:
		on_ground.append(["Checkpoint", c[1]])
	for d in level.dummies:
		on_ground.append(["Puppe", d[0]])
	for h in level.hints:
		on_ground.append(["Hinweis", h[0]])
	for t in level.thrones:
		on_ground.append(["Thron", t[0]])
	for s in level.slabs:
		on_ground.append(["Bruchplatte", s[1]])
	for b in level.bosses:
		on_ground.append(["Boss", b[1]])
	on_ground.append(["Baby Mo", level._baby_mo.position.x])
	on_ground.append(["Vitali", level._vitali.position.x])
	on_ground.append(["Start", level.start.x])
	on_ground.append(["Ausgang", level._gate.position.x])
	var floating := []
	for item in on_ground:
		var x: float = item[1]
		var ok := false
		for g in ground:
			if x >= g[1] and x <= g[1] + g[3]:
				ok = true
				break
		if not ok:
			floating.append("%s@%d" % [item[0], int(x)])
	_check("Alles steht auf Felsboden (%s)" % ", ".join(floating), floating.is_empty())
	# Reihenfolge: Start < Baby Mo < Thron < Bruchplatte < Boss < Ausgang.
	_check("Start vor Baby Mo", level.start.x < level._baby_mo.position.x)
	_check("Baby Mo vor Thron", level._baby_mo.position.x < level._throne.position.x)
	_check("Thron vor Bruchplatte", level._throne.position.x < level._slab.position.x)
	_check("Bruchplatte vor Boss", level._slab.position.x < level._boss.position.x)
	_check("Boss vor Ausgang", level._boss.position.x < level._gate.position.x)
	# Sammelobjekte hängen über Plattformen.
	for p in level.pickups:
		var x: float = p[1]
		var y: float = p[2]
		var supported := false
		for pl in level.platforms:
			if x >= pl[1] and x <= pl[1] + pl[3] and y < pl[2]:
				supported = true
				break
		_check("Sammelobjekt %s hängt über einer Plattform" % p[0], supported)
	_shot("40_layout")


## Prüft, dass die Schluchten im Spiel tatsächlich übersprungen werden können und die
## Bruchplatte ohne Suplex unüberwindbar ist.
func _run_traverse(level: Node) -> void:
	var prog := root.get_node("Progression")
	prog.set_flag("vitali_met")
	prog.unlock_ability("suplex", false)
	# Gegner würden die Spielfigur beim Laufen zurückwerfen – für den Sprungtest entfernen.
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await _frames(2)
	var ground: Array = level.platforms.filter(func(p: Array) -> bool: return p[0] == PlatformBlock.Kind.ROCK)
	for i in range(ground.size() - 1):
		var edge: float = ground[i][1] + ground[i][3]
		var target: float = ground[i + 1][1]
		level.player.global_position = Vector2(edge - 120.0, 700.0)
		level.player.velocity = Vector2.ZERO
		await _frames(20)
		# Nach rechts laufen und am Rand springen.
		var t := 0.0
		while t < 3.0 and level.player.global_position.x < target + 60.0:
			Input.action_press(&"move_right")
			if level.player.is_on_floor() and level.player.global_position.x > edge - 60.0:
				Input.action_press(&"jump")
			await create_timer(0.05).timeout
			t += 0.05
		Input.action_release(&"move_right")
		Input.action_release(&"jump")
		await _frames(10)
		print("  Schlucht %d: Rand=%.0f Ziel=%.0f Spieler=%.0f" % [i + 1, edge, target, level.player.global_position.x])
		_check("Schlucht %d übersprungen" % (i + 1), level.player.global_position.x > target)
	# Bruchplatte: ohne Suplex kommt Morilla nicht durch.
	level.player.global_position = level._slab.global_position + Vector2(-260.0, 0.0)
	level.player.velocity = Vector2.ZERO
	await _frames(20)
	var t2 := 0.0
	while t2 < 2.5:
		Input.action_press(&"move_right")
		if level.player.is_on_floor():
			Input.action_press(&"jump")
		await create_timer(0.05).timeout
		t2 += 0.05
	Input.action_release(&"move_right")
	Input.action_release(&"jump")
	await _frames(10)
	_check("Bruchplatte blockiert ohne Suplex", level.player.global_position.x < level._slab.global_position.x)
	_shot("41_traverse")


func _run_encounter(level: Node, skip: bool) -> void:
	var prog := root.get_node("Progression")
	_check("Begegnung noch nicht erledigt", not level._vitali_met())
	level.player.global_position = level._baby_mo.global_position + Vector2(-260, 0)
	await _frames(4)
	_check("Begegnung läuft", level._vitali_busy)
	_check("Spielerin eingefroren", level.player.machine.is_in(&"frozen"))
	var skipped_sent := false
	var t := 0.0
	while level._vitali_busy and t < 200.0:
		await create_timer(0.25).timeout
		t += 0.25
		if level.dialogue._active:
			_press(level.dialogue)
		if int(t * 4) % 24 == 0:
			_shot("seq_%03d" % int(t))
		if skip and not skipped_sent and t > 6.0:
			var seq = level.get_children().filter(_is_sequence)[0]
			seq._stage.skip_requested.emit()
			skipped_sent = true
	_check("Begegnung fertig (Zeitlimit)", not level._vitali_busy)
	_check("vitali_met gesetzt", bool(prog.get_flag("vitali_met")))
	_check("Steuerung zurück", level.player.machine.is_in(&"locomotion"))
	_check("Zeitskala normal", is_equal_approx(Engine.time_scale, 1.0))
	_check("Kamera aktiv", level.camera.is_current())
	_check("Morilla vor dem Thron", absf(level.player.global_position.x - level._vitali.global_position.x) < 500.0)
	_shot("10_nach_begegnung")
	# Suplex-Lektion über Vitali.
	level._vitali.interact(level.player)
	t = 0.0
	while not prog.has_ability("suplex") and t < 90.0:
		await create_timer(0.25).timeout
		t += 0.25
		if level.dialogue._active:
			_press(level.dialogue)
	_check("Suplex freigeschaltet", prog.has_ability("suplex"))
	_check("Steuerung nach Lektion zurück", level.player.machine.is_in(&"locomotion"))
	_shot("11_suplex_gelernt")
	# Laden: neuer Levelstand aus dem gespeicherten Fortschritt.
	level.queue_free()
	await _frames(2)
	prog.load_progress()
	var again := await _load_level()
	_check("Laden: keine Wiederholung", again._vitali_met())
	_check("Laden: Suplex bleibt", prog.has_ability("suplex"))


func _run_slab(level: Node) -> void:
	var prog := root.get_node("Progression")
	_check("Suplex vorhanden", prog.has_ability("suplex"))
	_check("Platte intakt", not bool(prog.get_flag("slab_quarry_side")))
	level.player.global_position = level._slab.global_position + Vector2(-120, 0)
	level.player.facing = 1
	await _frames(4)
	# Suplex direkt auslösen.
	level.player.machine.change(&"suplex")
	var t := 0.0
	while not bool(prog.get_flag("slab_quarry_side")) and t < 6.0:
		await create_timer(0.1).timeout
		t += 0.1
	_check("Platte per Suplex zerbrochen", bool(prog.get_flag("slab_quarry_side")))
	# Auf das Ende der Suplex-Animation warten.
	t = 0.0
	while not level.player.machine.is_in(&"locomotion") and t < 4.0:
		await create_timer(0.1).timeout
		t += 0.1
	_check("Steuerung zurück", level.player.machine.is_in(&"locomotion"))
	_shot("20_platte_zerbrochen")


func _run_boss(level: Node) -> void:
	var prog := root.get_node("Progression")
	_check("Boss noch nicht besiegt", not bool(prog.get_flag("boss_ironback")))
	level.player.global_position = level._boss.global_position + Vector2(-400, 0)
	await _frames(6)
	_check("Boss-Arena aktiv", level._boss._active)
	_check("Boss erzeugt", is_instance_valid(level._boss.boss))
	_shot("30_boss_start")
	# Boss per Suplex besiegen (Fenster erzwingen).
	var boss = level._boss.boss
	var t := 0.0
	while is_instance_valid(boss) and not boss.health.is_dead() and t < 120.0:
		await create_timer(0.2).timeout
		t += 0.2
		if not is_instance_valid(boss):
			break
		# Boss in ein Suplex-Fenster zwingen und werfen.
		boss._set_boss(boss.B.CHARGE_RECOVER, 3.0)
		level.player.global_position = boss.global_position + Vector2(-100, 0)
		level.player.facing = 1
		level.player.grapple.cooldown = 0.0
		level.player.machine.change(&"suplex")
		await create_timer(1.6).timeout
	_check("Boss besiegt", not is_instance_valid(boss) or boss.health.is_dead())
	_check("boss_ironback gesetzt", bool(prog.get_flag("boss_ironback")))
	_shot("31_boss_besiegt")


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
