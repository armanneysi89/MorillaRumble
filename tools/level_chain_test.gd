extends SceneTree

## Prüft die Level-Kette (kein Spielcode): Dojo -> Bambushain -> Steinbruch.
##   XDG_DATA_HOME=/tmp/x godot --path . --script tools/level_chain_test.gd

var _fails := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var prog := root.get_node("Progression")
	prog.new_game()
	var game := root.get_node("Game")
	_check("Dojo -> Bambushain", (load("res://scenes/levels/dojo_level.tscn") as PackedScene).instantiate().next_scene == game.BAMBOO_SCENE)
	_check("Bambushain -> Steinbruch", (load("res://scenes/levels/bamboo_level.tscn") as PackedScene).instantiate().next_scene == game.QUARRY_SCENE)
	_check("Steinbruch -> Menü", (load("res://scenes/levels/quarry_level.tscn") as PackedScene).instantiate().next_scene == game.MENU_SCENE)
	_check("Steinbruch-Szene existiert", ResourceLoader.exists(game.QUARRY_SCENE))
	# Weiterspielen führt je nach Fortschritt in das richtige Level.
	_check("Weiterspielen ohne Fortschritt -> Dojo", game.resume_scene() == game.DOJO_SCENE)
	prog.set_flag("level_dojo_cleared")
	_check("Weiterspielen nach Dojo -> Bambushain", game.resume_scene() == game.BAMBOO_SCENE)
	prog.set_flag("level_bamboo_cleared")
	_check("Weiterspielen nach Bambushain -> Steinbruch", game.resume_scene() == game.QUARRY_SCENE)
	prog.new_game()
	prog.discover_checkpoint("quarry", "cp_slab")
	_check("Checkpoint im Steinbruch -> Steinbruch", game.resume_scene() == game.QUARRY_SCENE)
	# Aufgabe nach dem Bambushain.
	prog.set_task("find_vitali")
	_check("Aufgabe 'find_vitali' hat Text", prog.task_text() != "")
	print("RESULT level_chain fails=%d" % _fails)
	quit(_fails)


func _check(label: String, ok: bool) -> void:
	if not ok:
		_fails += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", label])
