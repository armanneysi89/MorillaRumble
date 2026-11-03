class_name OctopusSpirit
extends Node2D

## Oktopus-Geist aus Coach Armans Spezialtechnik: erscheint, fesselt mehrere Gegner mit Tentakeln, entlädt eine Tintenwelle
## und löst sich wieder auf. Ziele sind Knoten mit spirit_bind(duration) und apply_spirit_hit(info).

signal finished

const MATERIALIZE_TIME := 0.45
const CHARGE_TIME := 0.3
const WHIP_TIME := 0.2
const WHIP_GAP := 0.08
const HOLD_TIME := 0.35
const BLAST_TIME := 0.6
const DISSOLVE_TIME := 0.6
const BIND_TIME := 2.5
const VERTICAL_REACH := 520.0
const PURPLE := Color(0.62, 0.35, 1.0)
const INK := Color(0.2, 0.08, 0.35)

var ability: AbilityData
## Liefert beim Zuschlagen die aktuellen Ziele (Gegner bewegen sich während der Beschwörung).
var find_targets: Callable

var _visual: CharacterSprite
var _tentacles: Array[SpiritTentacle] = []
var _dim: ColorRect


## Gegner in Reichweite, nächste zuerst, höchstens ab.max_targets.
static func enemies_near(center: Vector2, ab: AbilityData, tree: SceneTree) -> Array:
	var found: Array = []
	for node in tree.get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or not enemy.can_be_spirit_targeted():
			continue
		var d := enemy.global_position - center
		if absf(d.x) <= ab.reach and absf(d.y) <= VERTICAL_REACH:
			found.append(enemy)
	found.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return absf(a.global_position.x - center.x) < absf(b.global_position.x - center.x))
	return found.slice(0, ab.max_targets)


static func summon(parent: Node, at: Vector2, ab: AbilityData, targets: Callable) -> OctopusSpirit:
	var spirit := OctopusSpirit.new()
	spirit.position = at
	spirit.ability = ab
	spirit.find_targets = targets
	parent.add_child(spirit)
	return spirit


func _ready() -> void:
	z_index = 6
	modulate.a = 0.0
	scale = Vector2.ONE * 0.5
	_visual = CharacterSprite.new()
	add_child(_visual)
	_visual.setup("octopus")
	_add_dim()
	_run()


func _add_dim() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	_dim = ColorRect.new()
	_dim.color = Color(0.1, 0.0, 0.22, 0.0)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_dim)
	add_child(layer)


func _wait(seconds: float) -> bool:
	await get_tree().create_timer(seconds).timeout
	return is_inside_tree()


func _run() -> void:
	var world := get_parent()
	# 1. Materialisieren
	Sound.sfx("summon")
	Game.shake(0.4)
	Effects.shockwave(world, global_position, PURPLE, 340.0, 0.55)
	Effects.burst(world, global_position, PURPLE, 28, 560.0, 0.7, 12.0)
	_visual.play_timed(&"materialize", MATERIALIZE_TIME)
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "modulate:a", 1.0, MATERIALIZE_TIME * 0.8)
	tw.tween_property(self, "scale", Vector2.ONE, MATERIALIZE_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_dim, "color:a", 0.3, MATERIALIZE_TIME)
	if not await _wait(MATERIALIZE_TIME):
		return
	_start_hover()

	# 2. Aufladen
	Sound.sfx("summon_charge", -4.0)
	_visual.play_timed(&"charge", CHARGE_TIME)
	if not await _wait(CHARGE_TIME):
		return

	# 3. Fesseln
	var targets: Array = find_targets.call() if find_targets.is_valid() else []
	_visual.play_timed(&"strike", WHIP_TIME + WHIP_GAP * targets.size())
	var index := 0
	for target: Node2D in targets:
		_whip(target, index, targets.size(), WHIP_GAP * index)
		index += 1
	if not await _wait(WHIP_GAP * targets.size() + WHIP_TIME + HOLD_TIME):
		return

	# 4. Tintenwelle
	_blast(targets)
	if not await _wait(BLAST_TIME):
		return

	# 5. Auflösen
	Sound.sfx("spirit_vanish", -3.0)
	_visual.speed_scale = 1.0
	_visual.play_backwards(&"materialize")
	var fade := create_tween().set_parallel()
	fade.tween_property(self, "modulate:a", 0.0, DISSOLVE_TIME)
	fade.tween_property(self, "scale", Vector2.ONE * 0.75, DISSOLVE_TIME)
	fade.tween_property(_dim, "color:a", 0.0, DISSOLVE_TIME)
	if not await _wait(DISSOLVE_TIME):
		return
	finished.emit()
	queue_free()


func _start_hover() -> void:
	var bob := create_tween().set_loops()
	bob.tween_property(_visual, "position:y", -14.0, 0.7).set_trans(Tween.TRANS_SINE)
	bob.tween_property(_visual, "position:y", 14.0, 0.7).set_trans(Tween.TRANS_SINE)


func _whip(target: Node2D, index: int, count: int, delay: float) -> void:
	if delay > 0.0 and not await _wait(delay):
		return
	if not is_instance_valid(target):
		return
	var tentacle := SpiritTentacle.new()
	tentacle.position = Vector2(lerpf(-150.0, 150.0, float(index) / maxf(count - 1, 1.0)), 90.0)
	tentacle.target = target
	add_child(tentacle)
	_tentacles.append(tentacle)
	Sound.sfx("tentacle", -3.0)
	var tw := create_tween()
	tw.tween_property(tentacle, "extend", 1.0, WHIP_TIME).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		if is_instance_valid(target):
			target.spirit_bind(BIND_TIME)
			Effects.burst(get_parent(), target.global_position + Vector2(0, -90), PURPLE, 12, 320.0, 0.4, 8.0)
			Effects.shockwave(get_parent(), target.global_position + Vector2(0, -90), PURPLE, 110.0, 0.25))


func _blast(targets: Array) -> void:
	var world := get_parent()
	Sound.sfx("ink_blast")
	Game.shake(0.75)
	Game.hit_stop(0.1)
	_visual.play_timed(&"blast", BLAST_TIME)
	Effects.shockwave(world, global_position, PURPLE, 720.0, 0.55)
	Effects.shockwave(world, global_position, Color(1.0, 0.3, 0.4), 480.0, 0.4)
	Effects.burst(world, global_position, INK, 40, 760.0, 0.8, 16.0)
	Effects.burst(world, global_position, PURPLE, 24, 600.0, 0.6, 10.0)
	for tentacle in _tentacles:
		if is_instance_valid(tentacle):
			var tw := create_tween()
			tw.tween_property(tentacle, "extend", 0.0, 0.25).set_ease(Tween.EASE_IN)
			tw.tween_callback(tentacle.queue_free)
	_tentacles.clear()
	var index := 0
	for target: Node2D in targets:
		if not is_instance_valid(target):
			continue
		var info := HitInfo.new()
		info.source = self
		info.direction = 1 if target.global_position.x >= global_position.x else -1
		info.damage = maxi(roundi(ability.damage * Progression.damage_multiplier()), 1)
		info.stun = ability.stun_time
		info.knockback = Vector2(320.0, -420.0)
		info.heavy = true
		var pos := target.global_position + Vector2(0, -90)
		target.apply_spirit_hit(info)
		Effects.hit_spark(world, pos, true)
		Effects.float_text(world, pos + Vector2(0, -150 - (index % 2) * 60), "BETÄUBT!", Color(0.8, 0.6, 1.0), 40)
		index += 1
