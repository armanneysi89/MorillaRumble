extends State

## Griff-Technik (Kimura) in den Phasen: Greifen, Kontrolle herstellen, Ausführen (Schaden/Betäubung), Erholen.
## exit() löst das Ziel immer wieder, auch bei Unterbrechung durch Treffer oder Tod.

enum Phase { LUNGE, CONTROL, EXECUTE, RECOVER, WHIFF }

const WHIFF_TIME := 0.3

var p: Morilla
var ab: AbilityData
var _phase := Phase.LUNGE
var _t := 0.0


func enter(_msg: Dictionary = {}) -> void:
	p = actor as Morilla
	ab = p.grapple.ability()
	_phase = Phase.LUNGE
	_t = 0.0
	p.velocity.x = p.facing * 260.0
	p.visual.show_frame(&"grab", 0)
	p.visual.face(p.facing)
	Sound.sfx("whoosh")


func exit() -> void:
	p.grapple.release(false)


func physics_update(delta: float) -> void:
	_t += delta
	p.apply_gravity(delta)
	match _phase:
		Phase.LUNGE:
			p.velocity.x = move_toward(p.velocity.x, 0.0, 1800.0 * delta)
			if _t >= ab.lunge_time:
				_establish_control()
		Phase.CONTROL:
			p.velocity.x = 0.0
			if not _target_ok():
				_to(Phase.RECOVER)
			else:
				p.grapple.pin(delta)
				if _t >= ab.control_time:
					_begin_execute()
		Phase.EXECUTE:
			p.velocity.x = 0.0
			if not _target_ok():
				_to(Phase.RECOVER)
			else:
				p.grapple.pin(delta)
				if _t >= ab.execute_time:
					_finish_technique()
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
	return p.grapple.is_bound() and not p.grapple.target.health.is_dead()


## Schritte 2 und 3: Reichweite und Eignung prüfen, dann Kontrolle herstellen.
func _establish_control() -> void:
	var target := p.grapple.find_target(ab)
	if target == null:
		_to(Phase.WHIFF)
		return
	p.grapple.bind(target)
	p.visual.show_frame(&"kimura", 0)
	Sound.sfx("grab")
	Game.hit_stop(0.05)
	_to(Phase.CONTROL)


func _begin_execute() -> void:
	p.visual.show_frame(&"kimura", 1)
	Sound.sfx("strain")
	Game.shake(0.15)
	_to(Phase.EXECUTE)


## Schritte 5 und 6: Schaden und Betäubung anwenden, danach lösen und erholen.
func _finish_technique() -> void:
	var info := HitInfo.new()
	info.source = p
	info.direction = p.facing
	info.damage = maxi(roundi(ab.damage * Progression.damage_multiplier()), 1)
	info.stun = ab.stun_time
	info.heavy = true
	var target := p.grapple.target
	var pos := target.global_position + Vector2(0, -90)
	target.apply_grapple_hit(info)
	p.grapple.release(true)
	Sound.sfx("submit")
	Effects.hit_spark(p.get_parent(), pos, true)
	Effects.float_text(p.get_parent(), pos + Vector2(0, -120), ab.display_name.to_upper() + "!", Color("ff8a5c"))
	Game.hit_stop(ab.hit_stop)
	Game.shake(0.45)
	p.visual.show_frame(&"kimura", 2)
	_to(Phase.RECOVER)
