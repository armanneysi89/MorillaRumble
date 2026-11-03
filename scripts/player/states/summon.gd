extends State

## Beschwörung (Oktopus-Geist): kurze Konzentration, dann erscheint der Geist und kämpft allein.
## Morilla bleibt währenddessen unverwundbar und erholt sich kurz.

enum Phase { CHARGE, RECOVER }

const SPIRIT_OFFSET := Vector2(260.0, -460.0)
## Unverwundbarkeit nach dem Erscheinen, bis der Geist die Gegner gefesselt hat.
const PROTECTED_AFTER_CAST := 1.3
const AURA_INTERVAL := 0.06
const AURA_COLOR := Color(0.7, 0.45, 1.0, 0.9)

var p: Morilla
var ab: AbilityData
var _phase := Phase.CHARGE
var _t := 0.0
var _aura_t := 0.0


func enter(_msg: Dictionary = {}) -> void:
	p = actor as Morilla
	ab = p.summon_ability()
	_phase = Phase.CHARGE
	_t = 0.0
	_aura_t = 0.0
	p.visual.show_frame(&"summon", 0)
	p.visual.face(p.facing)
	p.health.make_invulnerable(ab.charge_time + PROTECTED_AFTER_CAST)
	Sound.sfx("summon_charge")


func physics_update(delta: float) -> void:
	_t += delta
	p.apply_gravity(delta)
	p.velocity.x = move_toward(p.velocity.x, 0.0, Morilla.FRICTION * delta)
	p.move_and_slide()
	match _phase:
		Phase.CHARGE:
			_aura_t -= delta
			if _aura_t <= 0.0:
				_aura_t = AURA_INTERVAL
				Effects.burst(p.get_parent(), p.global_position + Vector2(p.facing * 60.0, -150.0), AURA_COLOR, 3, 200.0, 0.4, 7.0)
			if _t >= ab.charge_time:
				_cast()
		Phase.RECOVER:
			if _t >= ab.recover_time:
				machine.change(&"locomotion")


func _cast() -> void:
	p.visual.show_frame(&"summon", 1)
	p.visual.squash(Vector2(1.12, 0.9))
	p.summon_cooldown = ab.cooldown
	var spot := p.global_position + Vector2(SPIRIT_OFFSET.x * p.facing, SPIRIT_OFFSET.y)
	var tree := p.get_tree()
	OctopusSpirit.summon(p.get_parent(), spot, ab, func() -> Array: return OctopusSpirit.enemies_near(p.global_position, ab, tree))
	Effects.shockwave(p.get_parent(), p.global_position + Vector2(p.facing * 60.0, -150.0), AURA_COLOR, 220.0, 0.4)
	_phase = Phase.RECOVER
	_t = 0.0
