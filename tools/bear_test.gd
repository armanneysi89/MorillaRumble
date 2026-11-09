extends SceneTree

## Prüft den Bär-Geist des Suplex (kein Spielcode). Aufruf (mit eigenem Spielstand!):
##   XDG_DATA_HOME=/tmp/x godot --path . --resolution 1280x720 --script tools/bear_test.gd
##
## Geprüft wird:
##   - der Bär-Geist erscheint während des Wurfs und schlägt beim Aufprall zu
##   - mehrere Gegner im Umkreis werden gleichzeitig außer Gefecht gesetzt
##   - der geworfene Gegner wird nicht doppelt getroffen
##   - bei einem statischen Ziel (Bruchplatte) erscheint kein Geist
##   - bricht der Suplex ab, löst sich der Geist ohne Treffer auf
## Screenshots landen in /tmp/bear_shots.
##
## WICHTIG: Dieses Skript darf KEINE Spielklassen (Enemy, BearSpirit, ...) namentlich nennen.
## Ein SceneTree-Skript wird vor den Autoloads kompiliert; jede Referenz auf ein Skript, das
## `Sound`/`Progression` benutzt, scheitert dann mit "Identifier not found". Deshalb Duck-Typing
## und Pfade erst zur Laufzeit laden.

const LEVEL := "res://scenes/levels/quarry_level.tscn"
const SHOTS := "/tmp/bear_shots"
const ENEMY_SCENE_PATH := "res://scenes/enemies/white_belt_recruit.tscn"
const ENEMY_DATA_PATH := "res://resources/enemies/white_belt_recruit.tres"
## Enemy.S.STUNNED (Reihenfolge in scripts/enemies/enemy.gd: IDLE, PATROL, CHASE, WINDUP, ATTACK,
## RECOVER, HURT, STUNNED, GRABBED, DEAD).
const STATE_STUNNED := 7
const STATE_DEAD := 9

var _fails := 0
var _shot_no := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)
	_run.call_deferred()


func _run() -> void:
	var prog := root.get_node("Progression")
	prog.new_game()
	prog.set_flag("intro_quarry_seen")
	prog.set_flag("vitali_met")
	prog.unlock_ability("kimura", false)
	prog.unlock_ability("suplex", false)
	var level := await _load_level()
	_check("Level geladen", level != null)
	_check("Suplex-Geist konfiguriert", _suplex_ability().spirit_targets > 0)
	_check("Bär-Spec vorhanden", CharacterSpecs.ALL.has("bear"))
	_check("Bär hat Frames", SpriteLibrary.build(CharacterSpecs.get_spec("bear")).get_frame_count(&"slam") > 0)

	await _test_multi_hit(level)
	await _test_slab(level)
	await _test_abort(level)

	print("RESULT bear fails=%d" % _fails)
	quit(_fails)


func _suplex_ability() -> AbilityData:
	return root.get_node("Progression").get_ability("suplex")


func _load_level() -> Node:
	var level := (load(LEVEL) as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	await _frames(6)
	return level


## Drei Gegner um die Spielfigur: Der Suplex trifft einen, der Bär reißt die anderen beiden mit um.
func _test_multi_hit(level: Node) -> void:
	var player = level.player
	# Bestehende Gegner entfernen, damit der Test kontrolliert bleibt.
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await _frames(2)
	var base: Vector2 = level._slab.global_position + Vector2(-900, 0)
	player.global_position = base
	player.velocity = Vector2.ZERO
	player.facing = 1
	await _frames(10)
	var thrown := _spawn_enemy(base + Vector2(110, 0))
	var near_a := _spawn_enemy(base + Vector2(-260, 0))
	var near_b := _spawn_enemy(base + Vector2(-420, 0))
	var far := _spawn_enemy(base + Vector2(-1400, 0))
	await _frames(6)
	_check("Gegner erzeugt", is_instance_valid(thrown) and is_instance_valid(near_a) and is_instance_valid(near_b))
	player.grapple.cooldown = 0.0
	player.machine.change(&"suplex")
	# Der Geist fährt erst beim Anheben aus Morilla (nach Anlauf + Klinch), nicht sofort.
	_check("Bär-Geist erscheint beim Wurf", await _wait_for_bear(1.5))
	_shot("01_geist_erscheint")
	# Wurf abwarten (Klinch + Anheben + Wurf + Aufprall).
	var t := 0.0
	while t < 4.0 and not player.machine.is_in(&"locomotion"):
		await create_timer(0.05).timeout
		t += 0.05
	_shot("02_aufprall")
	_check("Geworfener Gegner betäubt oder besiegt", _is_stunned(thrown) or _is_dead(thrown))
	_check("Nachbar A umgerissen", _is_stunned(near_a))
	_check("Nachbar B umgerissen", _is_stunned(near_b))
	_check("Ferner Gegner unberührt", not _is_stunned(far))
	_check("Geworfener Gegner nur einmal getroffen", _damage_taken(thrown) <= 3)
	# Geist löst sich wieder auf.
	t = 0.0
	while t < 3.0 and _find_bear() != null:
		await create_timer(0.05).timeout
		t += 0.05
	_check("Bär-Geist löst sich auf", _find_bear() == null)
	for e in [thrown, near_a, near_b, far]:
		if is_instance_valid(e):
			e.queue_free()
	await _frames(2)


## Bruchplatte: statisches Ziel, kein Geist.
func _test_slab(level: Node) -> void:
	var player = level.player
	player.global_position = level._slab.global_position + Vector2(-120, 0)
	player.velocity = Vector2.ZERO
	player.facing = 1
	await _frames(10)
	player.grapple.cooldown = 0.0
	player.machine.change(&"suplex")
	await _frames(4)
	_check("Kein Geist bei statischem Ziel", _find_bear() == null)
	var t := 0.0
	while t < 4.0 and not player.machine.is_in(&"locomotion"):
		await create_timer(0.05).timeout
		t += 0.05
	_check("Platte zerbrochen", bool(root.get_node("Progression").get_flag("slab_quarry_side")))


## Abbruch: Wird der Zustand vor dem Aufprall verlassen, verschwindet der Geist ohne Treffer.
func _test_abort(level: Node) -> void:
	var player = level.player
	var base: Vector2 = level._slab.global_position + Vector2(-1600, 0)
	player.global_position = base
	player.velocity = Vector2.ZERO
	player.facing = 1
	await _frames(10)
	var victim := _spawn_enemy(base + Vector2(110, 0))
	var bystander := _spawn_enemy(base + Vector2(-300, 0))
	await _frames(6)
	player.grapple.cooldown = 0.0
	player.machine.change(&"suplex")
	_check("Geist vor Abbruch da", await _wait_for_bear(1.5))
	player.machine.change(&"locomotion")
	await _frames(2)
	var t := 0.0
	while t < 2.0 and _find_bear() != null:
		await create_timer(0.05).timeout
		t += 0.05
	_check("Geist nach Abbruch weg", _find_bear() == null)
	_check("Umstehender nach Abbruch unverletzt", not _is_stunned(bystander))
	for e in [victim, bystander]:
		if is_instance_valid(e):
			e.queue_free()
	await _frames(2)


func _spawn_enemy(pos: Vector2) -> Node:
	var scene: PackedScene = load(ENEMY_SCENE_PATH)
	var enemy := scene.instantiate()
	enemy.data = load(ENEMY_DATA_PATH)
	enemy.position = pos
	current_scene.add_child(enemy)
	return enemy


## Der Geist ist der einzige Knoten mit einer slam()-Methode in der Szene.
func _find_bear() -> Node:
	for n in current_scene.get_children():
		if n.has_method("slam") and n.has_method("dismiss"):
			return n
	return null


func _is_stunned(enemy: Node) -> bool:
	return is_instance_valid(enemy) and int(enemy.get("state")) == STATE_STUNNED


func _is_dead(enemy: Node) -> bool:
	return is_instance_valid(enemy) and int(enemy.get("state")) == STATE_DEAD


## Wartet, bis der Geist materialisiert ist (er erscheint erst beim Anheben).
func _wait_for_bear(timeout: float) -> bool:
	var t := 0.0
	while t < timeout:
		if _find_bear() != null:
			return true
		await create_timer(0.03).timeout
		t += 0.03
	return _find_bear() != null


func _damage_taken(enemy: Node) -> int:
	if not is_instance_valid(enemy):
		return 0
	var health = enemy.get("health")
	return health.max_hp - health.hp


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
