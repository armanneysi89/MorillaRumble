extends SceneTree

## Prüft die Level-Erweiterungen: Kletterrouten, Geheimnisse und Gegnerdruck.
##   XDG_DATA_HOME=/tmp/x godot --path . --script tools/level_content_test.gd
##
## Der Test lädt jedes Level, liest die gebauten Objekte und prüft:
##  - jede Kletterroute ist mit einem Sprung erreichbar (Höhendifferenz <= Sprunghöhe)
##  - jedes Sammelobjekt liegt in Reichweite einer Plattform
##  - jede Pickup-ID ist weltweit eindeutig (sonst überschreiben sich die Flags)
##  - die Gegnerdichte pro 1000 px bleibt spielbar

## Sprunghöhe aus JUMP_VELOCITY und GRAVITY, mit Reserve für den Apex-Multiplikator.
const MAX_STEP_HEIGHT := 200.0
## Waagerechte Reichweite eines Sprungs (SPEED * Flugzeit, großzügig gerechnet).
const MAX_STEP_WIDTH := 420.0
## Obergrenze für Gegner pro 1000 px Levelbreite.
const MAX_ENEMY_DENSITY := 2.5

var _fails := 0
var _pickup_ids := {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var prog := root.get_node("Progression")
	prog.new_game()
	for scene_path in ["res://scenes/levels/dojo_level.tscn", "res://scenes/levels/bamboo_level.tscn",
			"res://scenes/levels/quarry_level.tscn"]:
		await _check_level(scene_path)
	print("RESULT level_content fails=%d" % _fails)
	quit(_fails)


func _check_level(scene_path: String) -> void:
	var level: Node2D = (load(scene_path) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	var name := scene_path.get_file().get_basename()

	# Jede Stufe muss von einer Plattform darunter erreichbar sein.
	# Kleineres y bedeutet weiter oben. Zwei Fälle zählen als erreichbar:
	#   dy > 0  – die andere Plattform liegt tiefer, ein Sprung trägt hinauf
	#   dy == 0 – gleiche Höhe, aber die Flächen überlappen, man kann hinüberlaufen
	var platforms: Array = level.platforms
	var reachable := true
	for i in platforms.size():
		var p: Array = platforms[i]
		var best := INF
		for j in platforms.size():
			if i == j:
				continue
			var q: Array = platforms[j]
			var dy: float = float(q[2]) - float(p[2])
			var overlap: float = minf(float(p[1]) + float(p[3]), float(q[1]) + float(q[3])) - maxf(float(p[1]), float(q[1]))
			if dy == 0.0:
				if overlap > 0.0:
					best = minf(best, 0.0)
				continue
			if dy <= 0.0 or dy > MAX_STEP_HEIGHT:
				continue
			if overlap < -MAX_STEP_WIDTH:
				continue
			best = minf(best, dy)
		# Der Boden (größte Breite) braucht keinen Vorgänger.
		if best == INF and float(p[3]) < 1000.0:
			reachable = false
			print("  unerreichbar: %s bei x=%.0f y=%.0f" % [name, float(p[1]), float(p[2])])
	_check("%s: alle Plattformen erreichbar" % name, reachable)

	# Sammelobjekte: ID eindeutig, Position in der Nähe einer Plattform.
	var pickups: Array = level.pickups
	for pk in pickups:
		var id: String = pk[0]
		_check("%s: Pickup-ID '%s' eindeutig" % [name, id], not _pickup_ids.has(id))
		_pickup_ids[id] = true
		var px: float = float(pk[1])
		var py: float = float(pk[2])
		var near := false
		for p in platforms:
			var dx: float = px - float(p[1])
			if dx < -120.0 or dx > float(p[3]) + 120.0:
				continue
			# Das Objekt muss über der Plattform schweben, nicht darunter.
			if py <= float(p[2]) + 40.0 and py >= float(p[2]) - 700.0:
				near = true
				break
		_check("%s: Pickup '%s' hängt an einer Plattform" % [name, id], near)

	# Gegnerdichte.
	var count: int = level.enemies.size()
	var width: float = level.level_width
	var density := float(count) / maxf(width / 1000.0, 1.0)
	_check("%s: Gegnerdichte %.1f/1000px spielbar" % [name, density], density <= MAX_ENEMY_DENSITY)

	level.queue_free()
	await process_frame


func _check(label: String, ok: bool) -> void:
	if not ok:
		_fails += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", label])
