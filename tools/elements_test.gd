extends SceneTree

## Prüft die neuen Spielelemente (Kiste, Feder, Stachel, Aufwind, Kristall).
##   XDG_DATA_HOME=/tmp/x godot --path . --headless --script tools/elements_test.gd
##
## Der Test baut die Elemente direkt auf (ohne Level), damit er schnell und unabhängig bleibt:
##  - Kiste zerbricht bei einem Treffer und lässt ihren Inhalt fallen
##  - Kiste ist ein gültiges Suplex-Ziel
##  - Feder schleudert die Figur nach oben
##  - Stacheln kosten ein Leben und werfen zurück
##  - Aufwind hebt die Figur an
##  - Kristall erhöht den Zähler und nach GEMS_PER_BELT das maximale Leben
##
## Wichtig: SceneTree-Tests können Autoloads nicht beim Kompilieren auflösen. Deshalb werden alle
## Spielklassen erst zur Laufzeit über load() geholt und nur über Duck-Typing benutzt.

const PLAYER_SCENE := "res://scenes/player/morilla.tscn"
const CRATE := "res://scripts/levels/break_crate.gd"
const SPRING := "res://scripts/levels/spring_pad.gd"
const SPIKE := "res://scripts/levels/spike_trap.gd"
const WIND := "res://scripts/levels/wind_vent.gd"
const PICKUP := "res://scripts/levels/scroll_pickup.gd"
const HIT_INFO := "res://scripts/combat/hit_info.gd"
const LAYERS := "res://scripts/combat/layers.gd"

var _fails := 0
var _prog: Node
var _layers: GDScript


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_prog = root.get_node("Progression")
	_layers = load(LAYERS)
	_prog.new_game()
	await _test_crate()
	await _test_spring()
	await _test_spike()
	await _test_wind()
	await _test_gem()
	print("RESULT elements fails=%d" % _fails)
	quit(_fails)


## Baut eine kleine Testwelt mit Boden.
func _world() -> Node2D:
	var world := Node2D.new()
	root.add_child(world)
	var floor_block := StaticBody2D.new()
	floor_block.collision_layer = int(_layers.WORLD)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(4000, 200)
	cs.shape = shape
	cs.position = Vector2(0, 100)
	floor_block.add_child(cs)
	world.add_child(floor_block)
	return world


func _player(world: Node2D, pos: Vector2) -> Node:
	var player := (load(PLAYER_SCENE) as PackedScene).instantiate()
	player.position = pos
	world.add_child(player)
	return player


func _test_crate() -> void:
	var world := _world()
	var player := _player(world, Vector2(0, 0))
	await _frames(6)
	var crate: Node = (load(CRATE) as GDScript).new()
	crate.crate_id = "test_crate"
	crate.content = "gem"
	crate.position = Vector2(120, 0)
	world.add_child(crate)
	await _frames(4)
	_check("Kiste blockiert (Kollision aktiv)", int(crate.collision_layer) != 0)
	_check("Kiste ist Suplex-Ziel", crate.can_be_grappled(_prog.get_ability("suplex")))
	# Treffer auslösen: Die Kiste hat eine Hurtbox auf ENEMY_HURT.
	var info: RefCounted = (load(HIT_INFO) as GDScript).new()
	info.damage = 1
	info.direction = 1
	info.source = player
	crate._on_hit(info)
	await _frames(4)
	_check("Kiste zerbricht bei Treffer", bool(_prog.get_flag("crate_test_crate")))
	_check("Kiste lässt Inhalt fallen", _has_pickup(world, "crate_test_crate_gem"))
	world.queue_free()
	await _frames(2)


func _test_spring() -> void:
	var world := _world()
	var player := _player(world, Vector2(0, -40))
	await _frames(6)
	var pad: Node = (load(SPRING) as GDScript).new()
	pad.position = Vector2(0, 0)
	world.add_child(pad)
	await _frames(4)
	pad._on_body_entered(player)
	await _frames(2)
	_check("Feder schleudert nach oben", player.velocity.y < -1000.0)
	world.queue_free()
	await _frames(2)


func _test_spike() -> void:
	var world := _world()
	var player := _player(world, Vector2(0, -40))
	await _frames(6)
	var hp_before: int = player.health.hp
	var trap: Node = (load(SPIKE) as GDScript).new()
	trap.position = Vector2(0, 0)
	world.add_child(trap)
	await _frames(4)
	trap._on_body_entered(player)
	await _frames(2)
	_check("Stacheln kosten ein Leben", player.health.hp == hp_before - 1)
	_check("Stacheln werfen zurück", absf(player.velocity.x) > 100.0)
	world.queue_free()
	await _frames(2)


func _test_wind() -> void:
	var world := _world()
	var player := _player(world, Vector2(0, -40))
	await _frames(6)
	var vent: Node = (load(WIND) as GDScript).new()
	vent.position = Vector2(0, 0)
	vent.height = 900.0
	world.add_child(vent)
	await _frames(4)
	vent._inside.append(player)
	var y_before: float = player.global_position.y
	await _frames(20)
	_check("Aufwind hebt die Figur an", player.global_position.y < y_before - 40.0)
	world.queue_free()
	await _frames(2)


func _test_gem() -> void:
	var world := _world()
	var player := _player(world, Vector2(0, -40))
	await _frames(6)
	var hp_before: int = _prog.max_hp()
	var gem: Node = (load(PICKUP) as GDScript).new()
	gem.pickup_id = "test_gem"
	gem.kind = "gem"
	# Abseits der Figur platzieren: Sonst löst die Physik den Kontakt zusätzlich aus und
	# das Objekt wird doppelt freigegeben.
	gem.position = Vector2(900, -60)
	world.add_child(gem)
	await _frames(4)
	gem._on_body_entered(player)
	await _frames(2)
	_check("Kristall zählt hoch", _prog.gem_count() == 1)
	# Genug Kristalle für eine volle Ladung: maximales Leben steigt.
	_prog.add_gems(int(_prog.GEMS_PER_BELT) - 1)
	_check("Volle Kristall-Ladung gibt +1 Leben", _prog.max_hp() == hp_before + 1)
	world.queue_free()
	await _frames(2)


func _has_pickup(world: Node, id: String) -> bool:
	for n in world.get_children():
		if n.get("pickup_id") == id:
			return true
	return false


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _check(label: String, ok: bool) -> void:
	if not ok:
		_fails += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", label])
