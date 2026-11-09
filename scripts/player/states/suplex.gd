extends State

## Suplex (Coach Vitalis Technik): Klinch, anheben, rückwärts werfen, Aufprall, Erholung.
## Nutzt denselben Griff-Mechanismus wie der Kimura (PlayerGrapple), unterscheidet sich aber in den Phasen,
## der Wurfrichtung (hinter den Werfer) und darin, dass auch große Gegner (size_class 2) geworfen werden können.
## Das Gleichgewichtsfenster ist die Klinch-Phase: Nur wer den Gegner dort hält, wirft ihn auch.

enum Phase { APPROACH, CLINCH, LIFT, THROW, IMPACT, RECOVER, WHIFF }

const WHIFF_TIME := 0.32
## Höhe, auf die der Gegner beim Anheben gehoben wird.
const LIFT_HEIGHT := 150.0
## Wie weit hinter den Werfer der Gegner beim Wurf fliegt.
const THROW_DISTANCE := 210.0
const THROW_ARC := 120.0

## Höhe über dem Fußpunkt, auf der der Bär-Geist aus Morillas Körper austritt (Brusthöhe).
const SPIRIT_HEIGHT := 170.0

var p: Morilla
var ab: AbilityData
var _phase := Phase.APPROACH
var _t := 0.0
var _lift := 0.0
var _throw_from := Vector2.ZERO
## Wurde ein Ziel tatsächlich gebunden? Nur dann kostet der Griff die volle Abklingzeit.
var _bound := false
## Bär-Geist, der während des Wurfs aus Morilla fährt und beim Aufprall zuschlägt.
var _spirit: BearSpirit


func enter(_msg: Dictionary = {}) -> void:
	p = actor as Morilla
	p.grapple.active = p.grapple.ability_for("suplex")
	ab = p.grapple.ability()
	_phase = Phase.APPROACH
	_t = 0.0
	_lift = 0.0
	_bound = false
	p.velocity.x = p.facing * 240.0
	p.visual.show_frame(&"grab", 0)
	p.visual.face(p.facing)
	Sound.sfx("whoosh")


func exit() -> void:
	# Bricht der Zustand vor dem Aufprall ab, löst sich der Geist ohne Treffer auf.
	if is_instance_valid(_spirit):
		_spirit.dismiss()
	_spirit = null
	p.grapple.release(false, _bound)
	p.grapple.active = null


func physics_update(delta: float) -> void:
	_t += delta
	p.apply_gravity(delta)
	match _phase:
		Phase.APPROACH:
			p.velocity.x = move_toward(p.velocity.x, 0.0, 1800.0 * delta)
			if _t >= ab.lunge_time:
				_establish_clinch()
		Phase.CLINCH:
			p.velocity.x = 0.0
			if not _target_ok():
				_to(Phase.RECOVER)
			else:
				p.grapple.pin(delta)
				if _t >= ab.control_time:
					_begin_lift()
		Phase.LIFT:
			p.velocity.x = 0.0
			if not _target_ok():
				_to(Phase.RECOVER)
			else:
				_lift = minf(_lift + delta / maxf(ab.execute_time * 0.45, 0.01), 1.0)
				_hold_target()
				if _lift >= 1.0:
					_begin_throw()
		Phase.THROW:
			p.velocity.x = 0.0
			if not _target_ok():
				_to(Phase.RECOVER)
			else:
				_arc_target()
				if _t >= ab.execute_time * 0.55:
					_impact()
		Phase.IMPACT:
			p.velocity.x = move_toward(p.velocity.x, 0.0, 2400.0 * delta)
			if _t >= 0.18:
				_to(Phase.RECOVER)
		Phase.RECOVER:
			p.velocity.x = move_toward(p.velocity.x, 0.0, 2400.0 * delta)
			if _t >= ab.recover_time:
				machine.change(&"locomotion")
				return
		Phase.WHIFF:
			p.velocity.x = move_toward(p.velocity.x, 0.0, 2400.0 * delta)
			if _t >= WHIFF_TIME:
				machine.change(&"locomotion")
				return
	p.move_and_slide()


func _to(phase: Phase) -> void:
	_phase = phase
	_t = 0.0


func _target_ok() -> bool:
	if not p.grapple.is_bound():
		return false
	var target := p.grapple.target
	if target is Enemy:
		return not (target as Enemy).health.is_dead()
	return true


## Klinch: Reichweite und Eignung prüfen, dann Kontrolle herstellen. Hier liegt das Gleichgewichtsfenster.
func _establish_clinch() -> void:
	var target := p.grapple.find_target(ab)
	if target == null:
		_to(Phase.WHIFF)
		return
	p.grapple.bind(target)
	_bound = true
	p.visual.show_frame(&"suplex", 0)
	Sound.sfx("grab")
	Game.hit_stop(0.06)
	Effects.float_text(p.get_parent(), p.global_position + Vector2(0, -260), "GRIFF!", Color("ffd166"), 40)
	_to(Phase.CLINCH)


func _begin_lift() -> void:
	p.visual.show_frame(&"suplex", 1)
	Sound.sfx("strain")
	Game.shake(0.18)
	# Der Geist fährt schon beim Anheben aus Morilla, damit er beim Aufprall vollständig da ist.
	_summon_spirit()
	_to(Phase.LIFT)


## Der Gegner wird über den Kopf gehoben und bleibt am Kontaktpunkt.
func _hold_target() -> void:
	var target := p.grapple.target
	if target is StaticBody2D:
		return
	var want := p.global_position + Vector2(p.facing * 40.0, -LIFT_HEIGHT * _lift)
	target.global_position = target.global_position.lerp(want, minf(0.35, 0.35 * _lift + 0.1))
	target.visual.face(-p.facing)


func _begin_throw() -> void:
	p.visual.show_frame(&"suplex", 2)
	_throw_from = p.grapple.target.global_position
	Sound.sfx("heavy_whoosh")
	Game.shake(0.25)
	_to(Phase.THROW)


## Der Bär-Geist fährt während des Wurfs aus Morillas Körper. Er wartet auf den Aufprall und schlägt dann zu.
## Bei statischen Zielen (Bruchplatte) erscheint kein Geist – dort gibt es keine Gegner umzuwerfen.
func _summon_spirit() -> void:
	if ab == null or ab.spirit_targets <= 0:
		return
	if p.grapple.target is StaticBody2D:
		return
	var spot := p.global_position + Vector2(0, -SPIRIT_HEIGHT)
	var tree := p.get_tree()
	# Das geworfene Ziel wird gemerkt: `p.grapple.target` ist beim Aufprall bereits freigegeben und
	# würde sonst ein zweites Mal getroffen.
	var thrown := p.grapple.target
	_spirit = BearSpirit.summon(p.get_parent(), spot, ab, func(at: Vector2) -> Array:
		return BearSpirit.enemies_near(at, ab, tree, thrown))


## Rückwärtsbogen: Der Gegner fliegt in einem Bogen hinter den Werfer.
func _arc_target() -> void:
	var target := p.grapple.target
	if target is StaticBody2D:
		return
	var t := clampf(_t / maxf(ab.execute_time * 0.55, 0.01), 0.0, 1.0)
	var end := p.global_position + Vector2(-p.facing * THROW_DISTANCE, -20.0)
	var pos := _throw_from.lerp(end, t)
	pos.y -= sin(t * PI) * THROW_ARC
	target.global_position = pos
	target.visual.face(p.facing)


## Aufprall: Schaden, Betäubung, Staub und Erschütterung.
## Das Ziel kann zwischen Halten und Aufprall freigegeben worden sein (Tod, Unterbrechung) – dann
## gibt es keinen Aufprall, aber der Zustand läuft sauber weiter.
func _impact() -> void:
	var target := p.grapple.target
	if not is_instance_valid(target):
		# Ohne Aufprall gibt es keinen Schlag: Der Geist löst sich sofort auf.
		if is_instance_valid(_spirit):
			_spirit.dismiss()
			_spirit = null
		p.grapple.release(false, _bound)
		_to(Phase.RECOVER)
		return
	var info := HitInfo.new()
	info.source = p
	info.direction = -p.facing
	info.damage = maxi(roundi(ab.damage * Progression.damage_multiplier()), 1)
	info.stun = ab.stun_time
	info.knockback = Vector2(260.0, -180.0)
	info.heavy = true
	var pos := target.global_position + Vector2(0, -60)
	target.apply_suplex_hit(info)
	# Der Bär-Geist schlägt genau in dem Moment zu, in dem der Gegner auf dem Boden aufkommt.
	if is_instance_valid(_spirit):
		_spirit.slam(target.global_position)
		_spirit = null
	p.grapple.release(true, _bound)
	p.visual.show_frame(&"suplex", 3)
	Sound.sfx("submit")
	Sound.sfx("land", -4.0)
	Effects.hit_spark(p.get_parent(), pos, true)
	Effects.shockwave(p.get_parent(), pos, Color(1.0, 0.7, 0.35), 260.0, 0.35)
	Effects.dust(p.get_parent(), pos)
	Effects.float_text(p.get_parent(), pos + Vector2(0, -140), "SUPLEX!", Color("ff8a5c"))
	Game.hit_stop(ab.hit_stop)
	Game.shake(0.6)
	_to(Phase.IMPACT)