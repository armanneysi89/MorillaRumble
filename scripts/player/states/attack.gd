extends State

## Leichter und schwerer Angriff (auch in der Luft). Phasen: Anlauf (Telegraph), Aktiv (Hitbox), Erholung.
## Abbruchregeln: Nach dem Anlauf lassen sich Dash, Sprung und Block aus der Erholung abbrechen;
## ein gepufferter Angriff startet nach 60 % der Erholung direkt den nächsten.

enum Phase { WINDUP, ACTIVE, RECOVER }

const LIGHT := {
	"anim": &"light_attack", "windup": 0.07, "active": 0.09, "recover": 0.2,
	"damage": 1, "knockback": Vector2(300, -140), "stun": 0.28, "hit_stop": 0.05, "shake": 0.1, "heavy": false,
	"reach": Vector2(160, 110), "offset": Vector2(125, -130), "lunge": 190.0, "sfx": "whoosh",
}
const HEAVY := {
	"anim": &"heavy_attack", "windup": 0.26, "active": 0.1, "recover": 0.36,
	"damage": 2, "knockback": Vector2(560, -300), "stun": 0.5, "hit_stop": 0.12, "shake": 0.3, "heavy": true,
	"reach": Vector2(210, 130), "offset": Vector2(145, -135), "lunge": 290.0, "sfx": "heavy_whoosh",
}
const COMBO_WINDOW := 0.6

var p: Morilla
var _data: Dictionary
var _kind := "light"
var _phase := Phase.WINDUP
var _t := 0.0
var _air := false


func enter(msg: Dictionary = {}) -> void:
	p = actor as Morilla
	_kind = msg.get("kind", "light")
	_data = HEAVY if _kind == "heavy" else LIGHT
	_air = not p.is_on_floor()
	_phase = Phase.WINDUP
	_t = 0.0
	if _kind == "light":
		p.combo_step = p.combo_step % 3 + 1 if p.combo_timer > 0.0 else 1
	else:
		p.combo_step = 0
	p.visual.show_frame(_data["anim"], 0)
	p.visual.face(p.facing)
	if _kind == "heavy":
		p.visual.squash(Vector2(1.08, 0.92))
	Sound.sfx(_data["sfx"])


func exit() -> void:
	p.combat.end_attack()


func physics_update(delta: float) -> void:
	_t += delta
	var windup: float = _data["windup"]
	var active: float = _data["active"]
	var total: float = windup + active + float(_data["recover"])

	p.apply_gravity(delta)
	if _air:
		p.velocity.x = move_toward(p.velocity.x, p.input_dir * Morilla.SPEED * 0.6, Morilla.AIR_ACCEL * delta)
	else:
		p.velocity.x = move_toward(p.velocity.x, 0.0, Morilla.FRICTION * delta)
	p.move_and_slide()

	match _phase:
		Phase.WINDUP:
			if _kind == "light" and p.buffered("dash") and p.can_dash():
				machine.change(&"locomotion")
				return
			if _t >= windup:
				_begin_active()
		Phase.ACTIVE:
			if _t >= windup + active:
				p.combat.end_attack()
				_phase = Phase.RECOVER
		Phase.RECOVER:
			if _check_cancels(_t - windup - active, float(_data["recover"])):
				return
	if _t >= total:
		machine.change(&"locomotion")


func _begin_active() -> void:
	_phase = Phase.ACTIVE
	p.visual.show_frame(_data["anim"], 1)
	var extra := 1 if _kind == "light" and p.combo_step == 3 else 0
	p.combat.begin_attack(_data, extra)
	if not _air:
		p.velocity.x = p.facing * float(_data["lunge"])
	p.combo_timer = COMBO_WINDOW


func _check_cancels(recover_t: float, recover_total: float) -> bool:
	if p.buffered("dash") and p.can_dash():
		machine.change(&"locomotion")
		return true
	if p.buffered("jump") and p.coyote > 0.0:
		machine.change(&"locomotion")
		return true
	if p.is_on_floor() and Input.is_action_pressed("block"):
		machine.change(&"block")
		return true
	if recover_t >= recover_total * 0.6:
		if p.consume("heavy_attack"):
			machine.change(&"attack", {"kind": "heavy"})
			return true
		if p.consume("light_attack"):
			machine.change(&"attack", {"kind": "light"})
			return true
	return false
