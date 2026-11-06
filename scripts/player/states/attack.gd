extends State

## Leichter und schwerer Angriff (auch in der Luft). Phasen: Anlauf (Telegraph), Aktiv (Hitbox), Erholung.
## Abbruchregeln: Nach dem Anlauf lassen sich Dash, Sprung und Block aus der Erholung abbrechen;
## ein gepufferter Angriff startet nach 60 % der Erholung direkt den nächsten.
## Der schwere Schlag trägt die Ladung aus dem Charge-Zustand: mehr Schaden, kürzerer Anlauf,
## längere Aktivphase, größerer Radius und mehr Rückstoß.

enum Phase { WINDUP, ACTIVE, RECOVER }

## Skalierung des schweren Schlags bei voller Ladung (charge 0..1).
const CHARGE_DAMAGE := 2
const CHARGE_REACH := 0.6
const CHARGE_KNOCKBACK := 0.85
const CHARGE_STUN := 0.55
const CHARGE_ACTIVE := 0.75
const CHARGE_RECOVER := 0.45
const CHARGE_LUNGE := 0.65
const CHARGE_SHAKE := 0.5
## Voll geladener Schlag holt schneller aus als unaufgeladener.
const CHARGE_WINDUP := 0.58
## Ab dieser Ladung wird der Treffer als maximal hart behandelt (KO-Text, Schockwelle).
## Zentrale Schwelle der Spielfigur – HUD und Charge-Zustand lesen denselben Wert.
const CHARGE_FULL = Morilla.CHARGE_FULL

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
## Anteil der Laufgeschwindigkeit, den ein Luftangriff zulässt.
const AIR_ATTACK_SPEED := 0.6
## Abstand zwischen zwei Afterimages während der aktiven Phase.
const GHOST_INTERVAL := 0.035
## Ab dieser Kombo-Stufe hinterlässt der Angriff ein zusätzliches Afterimage.
const GHOST_COMBO_STEP := 4
## Anteil der Erholung, ab dem der nächste Angriff angenommen wird.
const COMBO_CANCEL_AT := 0.6

var p: Morilla
var _data: Dictionary
var _kind := "light"
var _phase := Phase.WINDUP
var _t := 0.0
var _air := false
var _ghost_t := 0.0
## Übernommene Ladung (0 = unaufgeladen, 1 = voll geladen).
var _charge := 0.0


func enter(msg: Dictionary = {}) -> void:
	p = actor as Morilla
	_kind = msg.get("kind", "light")
	_air = not p.is_on_floor()
	_phase = Phase.WINDUP
	_t = 0.0
	_charge = 0.0
	if _kind == "light":
		# Die Kombo endet nach dem Kick; danach beginnt sie wieder mit dem Jab.
		p.combo_step = p.combo_step + 1 if p.combo_timer > 0.0 and p.combo_step < COMBO.size() else 1
		_data = COMBO[p.combo_step - 1]
	else:
		p.combo_step = 0
		_charge = clampf(float(msg.get("charge", 0.0)), 0.0, 1.0)
		_data = _heavy_data(_charge)
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
	# Der Luftangriff gilt nur, solange die Figur wirklich in der Luft ist. Wird sie während des
	# Angriffs wieder festen Boden, gelten sofort die Bodenregeln (Reibung, Lunge, kein Schweben).
	if p.is_on_floor():
		_air = false
	if _air:
		p.velocity.x = move_toward(p.velocity.x, p.input_dir * Morilla.SPEED * AIR_ATTACK_SPEED, Morilla.AIR_ACCEL * delta)
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
			if _ghost_t >= GHOST_INTERVAL:
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
	var reach: Vector2 = _data["reach"]
	Effects.slash(p.get_parent(), p.global_position + Vector2(off.x * p.facing * 0.8, off.y), p.facing, heavy, reach.x)
	p.visual.squash(Vector2(1.16, 0.86) if heavy else Vector2(1.08, 0.93))
	if heavy or p.combo_step >= GHOST_COMBO_STEP:
		p.visual.spawn_ghost(Color(1.0, 0.6, 0.3, 0.5))
	if _charge >= CHARGE_FULL:
		p.visual.spawn_ghost(Color(1.0, 0.7, 0.35, 0.6))
		Effects.shockwave(p.get_parent(), p.global_position + Vector2(p.facing * 90.0, -150.0), Color(1.0, 0.62, 0.28, 0.9), 300.0, 0.3)
		Sound.sfx("heavy_hit", -12.0, 0.85)

## Baut die Werte des schweren Schlags aus der Ladung: 0 = Basis, 1 = voll geladen.
## Mehr Ladung heißt mehr Schaden, kürzerer Anlauf, längere Aktivphase, größerer Radius und mehr Rückstoß.
func _heavy_data(charge: float) -> Dictionary:
	var data: Dictionary = HEAVY.duplicate()
	if charge <= 0.0:
		return data
	var reach: Vector2 = data["reach"]
	var knock: Vector2 = data["knockback"]
	data["windup"] = float(data["windup"]) * (1.0 - CHARGE_WINDUP * charge)
	data["active"] = float(data["active"]) * (1.0 + CHARGE_ACTIVE * charge)
	data["recover"] = float(data["recover"]) * (1.0 + CHARGE_RECOVER * charge)
	data["damage"] = int(data["damage"]) + roundi(CHARGE_DAMAGE * charge)
	data["reach"] = reach * (1.0 + CHARGE_REACH * charge)
	data["offset"] = Vector2(data["offset"]) * (1.0 + CHARGE_REACH * charge * 0.55)
	data["knockback"] = knock * (1.0 + CHARGE_KNOCKBACK * charge)
	data["stun"] = float(data["stun"]) * (1.0 + CHARGE_STUN * charge)
	data["hit_stop"] = float(data["hit_stop"]) * (1.0 + 0.6 * charge)
	data["shake"] = minf(float(data["shake"]) + CHARGE_SHAKE * charge, 1.0)
	data["lunge"] = float(data["lunge"]) * (1.0 + CHARGE_LUNGE * charge)
	data["charge"] = charge
	return data


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
	if recover_t >= recover_total * COMBO_CANCEL_AT:
		if p.consume("heavy_attack"):
			# Aufgeladener Schlag: erst laden, dann losschlagen.
			machine.change(&"charge")
			return true
		if p.consume("light_attack"):
			machine.change(&"attack", {"kind": "light"})
			return true
	return false
