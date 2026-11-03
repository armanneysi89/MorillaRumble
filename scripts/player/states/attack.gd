extends State

## Leichter und schwerer Angriff (auch in der Luft). Phasen: Anlauf (Telegraph), Aktiv (Hitbox), Erholung.
## Abbruchregeln: Nach dem Anlauf lassen sich Dash, Sprung und Block aus der Erholung abbrechen;
## ein gepufferter Angriff startet nach 60 % der Erholung direkt den nächsten.

enum Phase { WINDUP, ACTIVE, RECOVER }

## Leichter Angriff: Jab, Cross, Hook, Lowkick, Kick. Jeder weitere Druck innerhalb des Kombo-Fensters startet die nächste Stufe.
const COMBO := [
	{
		"anim": &"jab", "windup": 0.04, "active": 0.08, "recover": 0.14,
		"damage": 1, "knockback": Vector2(300, -120), "stun": 0.25, "hit_stop": 0.05, "shake": 0.1, "heavy": false,
		"reach": Vector2(190, 120), "offset": Vector2(150, -165), "lunge": 200.0, "sfx": "whoosh",
	},
	{
		"anim": &"cross", "windup": 0.05, "active": 0.09, "recover": 0.16,
		"damage": 1, "knockback": Vector2(420, -160), "stun": 0.3, "hit_stop": 0.06, "shake": 0.14, "heavy": false,
		"reach": Vector2(210, 130), "offset": Vector2(160, -155), "lunge": 280.0, "sfx": "whoosh",
	},
	{
		"anim": &"hook", "windup": 0.07, "active": 0.1, "recover": 0.18,
		"damage": 1, "knockback": Vector2(520, -200), "stun": 0.35, "hit_stop": 0.07, "shake": 0.2, "heavy": false,
		"reach": Vector2(230, 150), "offset": Vector2(150, -150), "lunge": 300.0, "sfx": "whoosh",
	},
	{
		"anim": &"lowkick", "windup": 0.08, "active": 0.1, "recover": 0.2,
		"damage": 1, "knockback": Vector2(450, -100), "stun": 0.4, "hit_stop": 0.07, "shake": 0.2, "heavy": false,
		"reach": Vector2(240, 90), "offset": Vector2(170, -60), "lunge": 260.0, "sfx": "whoosh",
	},
	{
		"anim": &"kick", "windup": 0.12, "active": 0.14, "recover": 0.34,
		"damage": 2, "knockback": Vector2(820, -420), "stun": 0.6, "hit_stop": 0.14, "shake": 0.4, "heavy": true,
		"reach": Vector2(280, 170), "offset": Vector2(190, -170), "lunge": 380.0, "sfx": "heavy_whoosh",
	},
]
const HEAVY := {
	"anim": &"heavy_attack", "windup": 0.24, "active": 0.12, "recover": 0.34,
	"damage": 2, "knockback": Vector2(760, -400), "stun": 0.55, "hit_stop": 0.16, "shake": 0.45, "heavy": true,
	"reach": Vector2(270, 165), "offset": Vector2(180, -155), "lunge": 420.0, "sfx": "heavy_whoosh",
}
const COMBO_WINDOW := 0.6

var p: Morilla
var _data: Dictionary
var _kind := "light"
var _phase := Phase.WINDUP
var _t := 0.0
var _air := false
var _ghost_t := 0.0


func enter(msg: Dictionary = {}) -> void:
	p = actor as Morilla
	_kind = msg.get("kind", "light")
	_air = not p.is_on_floor()
	_phase = Phase.WINDUP
	_t = 0.0
	if _kind == "light":
		# Die Kombo endet nach dem Kick; danach beginnt sie wieder mit dem Jab.
		p.combo_step = p.combo_step + 1 if p.combo_timer > 0.0 and p.combo_step < COMBO.size() else 1
		_data = COMBO[p.combo_step - 1]
	else:
		p.combo_step = 0
		_data = HEAVY
	p.visual.show_frame(_data["anim"], 0)
	p.visual.face(p.facing)
	_ghost_t = 0.0
	if _kind == "heavy":
		p.visual.squash(Vector2(1.12, 0.88))
		Game.shake(0.06)
	else:
		p.visual.squash(Vector2(0.94, 1.06))
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
			_ghost_t += delta
			if _ghost_t >= 0.035:
				_ghost_t = 0.0
				p.visual.spawn_ghost(Color(1.0, 0.75, 0.45, 0.32))
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
	p.combat.begin_attack(_data)
	if not _air:
		p.velocity.x = p.facing * float(_data["lunge"])
	else:
		p.velocity.y = minf(p.velocity.y, 120.0)
	p.combo_timer = COMBO_WINDOW
	var heavy: bool = _data["heavy"]
	var off: Vector2 = _data["offset"]
	Effects.slash(p.get_parent(), p.global_position + Vector2(off.x * p.facing * 0.8, off.y), p.facing, heavy)
	p.visual.squash(Vector2(1.16, 0.86) if heavy else Vector2(1.08, 0.93))
	if heavy or p.combo_step >= 4:
		p.visual.spawn_ghost(Color(1.0, 0.6, 0.3, 0.5))


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
