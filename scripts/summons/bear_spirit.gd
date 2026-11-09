class_name BearSpirit
extends Node2D

## Sibirischer Bär-Geist aus Morillas Suplex. Er steigt während des Wurfs aus Morillas Körper auf,
## brüllt beim Aufprall des geworfenen Gegners und reißt alle Gegner im Umkreis mit einem Schlag zu Boden.
## Ziele sind Knoten mit can_be_spirit_targeted() und apply_spirit_hit(info) (siehe Enemy).

signal finished

## Kurz gehalten: Der Aufprall kommt bereits ~0,6 s nach dem Anheben, der Geist muss dann stehen.
const MATERIALIZE_TIME := 0.26
const RISE_TIME := 0.2
const LUNGE_TIME := 0.12
const SLAM_TIME := 0.5
const DISSOLVE_TIME := 0.45
## Sicherheitsnetz: Kommt der Aufprall nicht (Abbruch), löst sich der Geist nach dieser Zeit auf.
const IDLE_TIMEOUT := 2.5
## Senkrechte Reichweite des Aufpralls (Gegner auf Plattformen darüber/darunter).
const VERTICAL_REACH := 420.0
const AMBER := Color(1.0, 0.72, 0.28)
const FUR := Color(0.32, 0.18, 0.09)
## Färbung der umgerissenen Gegner (bernstein statt violett wie beim Oktopus).
const BEAR_TINT := Color(1.0, 0.78, 0.5)

var ability: AbilityData
## Liefert beim Aufprall die zusätzlichen Ziele. Bekommt die Aufprallposition als Argument,
## damit der Radius dort liegt, wo der Gegner tatsächlich einschlägt.
var find_targets: Callable

var _visual: CharacterSprite
var _slammed := false
var _dismissed := false
var _rise: Tween
var _hover: Tween
var _materialize: Tween


## Gegner im Aufprallradius, nächste zuerst, höchstens ab.spirit_targets.
## `exclude` ist der bereits per Suplex getroffene Gegner – er darf nicht doppelt kassieren.
static func enemies_near(center: Vector2, ab: AbilityData, tree: SceneTree, exclude: Node = null) -> Array:
	var found: Array = []
	for node in tree.get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy == exclude or not enemy.can_be_spirit_targeted():
			continue
		var d := enemy.global_position - center
		if absf(d.x) <= ab.spirit_radius and absf(d.y) <= VERTICAL_REACH:
			found.append(enemy)
	found.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return absf(a.global_position.x - center.x) < absf(b.global_position.x - center.x))
	return found.slice(0, ab.spirit_targets)


static func summon(parent: Node, at: Vector2, ab: AbilityData, targets: Callable) -> BearSpirit:
	var spirit := BearSpirit.new()
	spirit.position = at
	spirit.ability = ab
	spirit.find_targets = targets
	parent.add_child(spirit)
	return spirit


func _ready() -> void:
	# Hinter Morilla (z_index 0), damit der Geist aus ihm heraustritt statt ihn zu verdecken.
	z_index = -1
	modulate.a = 0.0
	scale = Vector2.ONE * 0.45
	_visual = CharacterSprite.new()
	add_child(_visual)
	_visual.setup("bear")
	_run()


func _wait(seconds: float) -> bool:
	await get_tree().create_timer(seconds).timeout
	return is_inside_tree()


func _run() -> void:
	var world := get_parent()
	# 1. Aus Morillas Körper materialisieren
	Sound.sfx("summon", -2.0, 0.8)
	Effects.burst(world, global_position, AMBER, 22, 420.0, 0.6, 11.0)
	Effects.shockwave(world, global_position, AMBER, 240.0, 0.4)
	_visual.play_timed(&"materialize", MATERIALIZE_TIME)
	_materialize = create_tween().set_parallel()
	_materialize.tween_property(self, "modulate:a", 1.0, MATERIALIZE_TIME * 0.7)
	_materialize.tween_property(self, "scale", Vector2.ONE, MATERIALIZE_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not await _wait(MATERIALIZE_TIME):
		return
	# Kam der Aufprall schon während des Materialisierens, übernimmt slam() den Rest.
	if _slammed:
		return

	# 2. Über Morilla aufsteigen
	_rise = create_tween()
	_rise.tween_property(self, "position:y", position.y - 120.0, RISE_TIME).set_trans(Tween.TRANS_SINE)
	_visual.play_timed(&"idle", RISE_TIME)
	if not await _wait(RISE_TIME):
		return
	if _slammed:
		return
	_start_hover()

	# 3. Auf den Aufprall warten (slam() kommt aus dem Suplex-Zustand)
	if not await _wait(IDLE_TIMEOUT):
		return
	if not _slammed:
		dismiss()


func _start_hover() -> void:
	_hover = create_tween().set_loops()
	_hover.tween_property(_visual, "position:y", -12.0, 0.6).set_trans(Tween.TRANS_SINE)
	_hover.tween_property(_visual, "position:y", 12.0, 0.6).set_trans(Tween.TRANS_SINE)


## Stößt auf die Aufprallposition herab und reißt alle Gegner im Umkreis um.
func slam(at: Vector2) -> void:
	if _slammed or _dismissed or not is_inside_tree():
		return
	_slammed = true
	# Materialisieren, Aufstieg und Schweben dürfen den Sturz nicht überschreiben.
	if _materialize and _materialize.is_valid():
		_materialize.kill()
		modulate.a = 1.0
		scale = Vector2.ONE
	if _rise and _rise.is_valid():
		_rise.kill()
	if _hover and _hover.is_valid():
		_hover.kill()
		_visual.position.y = 0.0
	# Zum Einschlag schauen, damit der Schlag nicht in die falsche Richtung geht.
	_visual.face(1 if at.x >= global_position.x else -1)
	var tw := create_tween()
	tw.tween_property(self, "global_position", at + Vector2(0, -30.0), LUNGE_TIME).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await tw.finished
	if not is_inside_tree():
		return
	_impact(at)


func _impact(at: Vector2) -> void:
	var world := get_parent()
	Sound.sfx("bear_roar")
	Sound.sfx("bear_slam", -2.0)
	Game.shake(0.9)
	Game.hit_stop(0.12)
	_visual.play_timed(&"slam", SLAM_TIME)
	Effects.shockwave(world, at, AMBER, 760.0, 0.5)
	Effects.shockwave(world, at, Color(1.0, 0.45, 0.2), 520.0, 0.4)
	Effects.burst(world, at, FUR, 34, 700.0, 0.7, 14.0)
	Effects.burst(world, at, AMBER, 22, 560.0, 0.6, 10.0)
	Effects.dust(world, at)
	var targets: Array = find_targets.call(at) if find_targets.is_valid() else []
	var index := 0
	for target: Node2D in targets:
		if not is_instance_valid(target):
			continue
		var info := HitInfo.new()
		info.source = self
		info.direction = 1 if target.global_position.x >= at.x else -1
		info.damage = maxi(roundi(ability.damage * 0.4 * Progression.damage_multiplier()), 1)
		info.stun = ability.stun_time * 0.8
		info.knockback = Vector2(420.0, -520.0)
		info.heavy = true
		var pos := target.global_position + Vector2(0, -90)
		target.apply_spirit_hit(info, BEAR_TINT)
		Effects.hit_spark(world, pos, true)
		Effects.float_text(world, pos + Vector2(0, -150 - (index % 2) * 60), "UMGERISSEN!", AMBER, 38)
		index += 1
	if index > 0:
		Effects.float_text(world, at + Vector2(0, -420), "BÄR!", AMBER, 52)
	if not await _wait(SLAM_TIME):
		return
	_dissolve()


## Bricht der Suplex ab, bevor der Aufprall kommt, löst sich der Geist ohne Treffer auf.
func dismiss() -> void:
	if _slammed:
		return
	_dissolve()


func _dissolve() -> void:
	if _dismissed:
		return
	_dismissed = true
	Sound.sfx("spirit_vanish", -4.0)
	if _visual.has_anim(&"materialize"):
		_visual.speed_scale = 1.0
		_visual.play_backwards(&"materialize")
	var fade := create_tween().set_parallel()
	fade.tween_property(self, "modulate:a", 0.0, DISSOLVE_TIME)
	fade.tween_property(self, "scale", Vector2.ONE * 0.8, DISSOLVE_TIME)
	await fade.finished
	finished.emit()
	queue_free()
