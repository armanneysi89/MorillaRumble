extends State

## Schweren Schlag aufladen: Die Taste halten lädt auf, loslassen schlägt.
## Je länger gehalten wird, desto härter, schneller im Anlauf und weitreichender wird der Schlag
## (siehe die Ladungs-Werte im Attack-Zustand). Ein Treffer, ein Dash oder Sprung tilgt die Ladung.

## Zeit bis zur vollen Ladung; danach folgt das Überladen (kein zusätzlicher Schaden, nur mehr Druck).
const HOLD_MAX := 1.0
const OVERHOLD_TIME := 0.3
const FULL_AT := 0.94
## Ab dieser Haltedauer zeigt das Aufladen erst Ton und Partikel (ein kurzer Tipp bleibt ein normaler Schlag).
const HOLD_CUE := 0.14
## Bewegung ist während des Ladens stark gedämpft.
const SPEED_MULT := 0.32
const ACCEL_MULT := 0.5
const INTERVALS := {
	"mote": 0.1,
	"mote_full": 0.055,
	"ring": 0.36,
	"shake": 0.26,
}
const STRAIN_STEP := 0.2
const STRAIN_DB := Vector2(-16.0, 1.0)
const GLOW_MIN := 44.0
const GLOW_MAX := 210.0
const GLOW_OFFSET := Vector2(118.0, -150.0)
const SQUASH_FULL := Vector2(0.86, 1.16)
const TINT_FULL := Color(1.0, 0.62, 0.34)
const MOTE_COLOR := Color(1.0, 0.6, 0.28, 0.9)
const MOTE_COLOR_FULL := Color(1.0, 0.9, 0.55, 1.0)
const RING_COLOR := Color(1.0, 0.5, 0.22, 0.7)
const RING_COLOR_FULL := Color(1.0, 0.85, 0.45, 0.95)

var p: Morilla

var _t := 0.0
var _charge := 0.0
var _overheld := false
var _glow: Sprite2D
var _mote_t := 0.0
var _ring_t := 0.0
var _shake_t := 0.0
var _strain_step := 0


func enter(_msg: Dictionary = {}) -> void:
	p = actor as Morilla
	_t = 0.0
	_charge = 0.0
	_overheld = false
	_mote_t = 0.0
	_ring_t = 0.0
	_shake_t = 0.0
	_strain_step = 0
	p.charge_level = 0.0
	p.visual.show_frame(&"heavy_attack", 0)
	p.visual.face(p.facing)
	p.visual.squash(Vector2(1.08, 0.92))
	_glow = Effects.glow(p, GLOW_OFFSET, GLOW_MIN, Color(1.0, 0.45, 0.2, 0.8))
	_glow.z_index = -1


func exit() -> void:
	p.charge_level = 0.0
	if is_instance_valid(_glow):
		_glow.queue_free()
	_glow = null
	p.visual.set_tint(Color.WHITE)


func physics_update(delta: float) -> void:
	_t += delta
	_charge = minf(_t / HOLD_MAX, 1.0)
	p.charge_level = _charge

	p.apply_gravity(delta)
	p.apply_horizontal(delta, SPEED_MULT, ACCEL_MULT)
	p.move_and_slide()
	_update_look()

	if not Input.is_action_pressed("heavy_attack"):
		_strike()
		return
	if p.buffered("dash") and p.can_dash():
		p.consume("dash")
		machine.change(&"dash")
		return
	if p.buffered("jump") and p.coyote > 0.0:
		p.consume("jump")
		machine.change(&"locomotion")
		return
	if p.is_on_floor() and Input.is_action_pressed("block"):
		machine.change(&"block")
		return
	if not p.is_on_floor():
		# Über die Kante gerutscht: der geladene Schlag geht in der Luft weg.
		_strike()
		return
	if not _overheld and _charge >= FULL_AT and _t >= HOLD_MAX + OVERHOLD_TIME:
		_overhold()
	if _t >= HOLD_CUE:
		_emit_energy(delta)
		_strain_sound()
		_shake(delta)


## Der Schlag wird ausgelöst: Die Ladung geht als Multiplikator an den Attack-Zustand.
func _strike() -> void:
	machine.change(&"attack", {"kind": "heavy", "charge": _charge})


## Volle Ladung ist erreicht: Der Körper hält den Druck nicht mehr ganz aus.
func _overhold() -> void:
	_overheld = true
	p.visual.flash(0.12, Color(1.0, 0.85, 0.5))
	p.visual.squash(Vector2(1.12, 0.9))
	Sound.sfx("strain", 0.0, 1.35)
	Sound.sfx("heavy_whoosh", -14.0, 0.8)
	Game.shake(0.16)
	p.velocity.x -= p.facing * 110.0
	Effects.shockwave(p.get_parent(), p.global_position + Vector2(0, -140.0), RING_COLOR_FULL, 240.0, 0.34)


func _update_look() -> void:
	p.visual.squash(Vector2.ONE.lerp(SQUASH_FULL, _charge))
	p.visual.set_tint(Color.WHITE.lerp(TINT_FULL, _charge * 0.85))
	if is_instance_valid(_glow):
		_glow.position = GLOW_OFFSET * Vector2(p.facing, 1.0)
		_glow.scale = Vector2.ONE * lerpf(GLOW_MIN, GLOW_MAX, _charge) / 64.0
		_glow.modulate = Color(1.0, lerpf(0.45, 0.85, _charge), lerpf(0.2, 0.5, _charge), lerpf(0.8, 1.0, _charge))


func _emit_energy(delta: float) -> void:
	var full := _charge >= FULL_AT
	_mote_t -= delta
	if _mote_t <= 0.0:
		_mote_t = INTERVALS["mote_full"] if full else INTERVALS["mote"]
		var color: Color = MOTE_COLOR_FULL if full else MOTE_COLOR
		var count := 3 if not full else 6
		var speed := lerpf(180.0, 460.0, _charge)
		Effects.charge_motes(p.get_parent(), p.global_position + Vector2(p.facing * 40.0, -120.0), color, count, speed)
	_ring_t -= delta
	if _ring_t <= 0.0:
		_ring_t = INTERVALS["ring"]
		var color: Color = RING_COLOR_FULL if full else RING_COLOR
		Effects.shockwave(p.get_parent(), p.global_position + Vector2(0, -130.0), color, lerpf(70.0, 200.0, _charge), 0.3)


func _strain_sound() -> void:
	var step := int(_charge / STRAIN_STEP)
	if step <= _strain_step:
		return
	_strain_step = step
	Sound.sfx("strain", lerpf(STRAIN_DB.x, STRAIN_DB.y, _charge), 1.0 + _charge * 0.4)


func _shake(delta: float) -> void:
	_shake_t -= delta
	if _shake_t > 0.0:
		return
	_shake_t = INTERVALS["shake"]
	Game.shake(lerpf(0.02, 0.14, _charge))
