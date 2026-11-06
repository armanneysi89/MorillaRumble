extends State

## Laufen, Springen und Fallen. Verzweigt in alle anderen Zustände.
## Landung und Richtungswechsel haben eigene, kurze Übergänge: Die Figur federt nach einem Sturz ein
## und dreht sich sichtbar, statt sofort umzuklappen.

var p: Morilla
var _was_on_floor := true
## Restzeit der Lande-Verzögerung (Steuerung gedämpft, Figur federt ein).
var _land_lag := 0.0
## Restzeit der Dreh-Animation.
var _turn_t := 0.0
var _turn_from := 1


func enter(_msg: Dictionary = {}) -> void:
	p = actor as Morilla
	_was_on_floor = p.is_on_floor()
	_land_lag = 0.0
	_turn_t = 0.0


func physics_update(delta: float) -> void:
	var on_floor := p.is_on_floor()
	if _check_transitions(on_floor):
		return

	if p.buffered("jump") and p.coyote > 0.0:
		p.consume("jump")
		p.velocity.y = Morilla.JUMP_VELOCITY
		p.coyote = 0.0
		p.visual.squash(Vector2(0.82, 1.2))
		Sound.sfx("jump")
		Effects.dust(p.get_parent(), p.global_position)
	# Variable Sprunghöhe: Loslassen kappt den Aufstieg, aber nie unter die Mindesthöhe.
	if Input.is_action_just_released("jump") and p.velocity.y < Morilla.JUMP_CUT_SPEED:
		p.velocity.y *= Morilla.JUMP_CUT_FACTOR

	_land_lag = maxf(_land_lag - delta, 0.0)
	_turn_t = maxf(_turn_t - delta, 0.0)
	p.apply_gravity(delta)
	# Während der Landeverzögerung reagiert die Figur träger: Der Aufprall hat Gewicht.
	var speed_mult := Morilla.LAND_LAG_SPEED if _land_lag > 0.0 else 1.0
	p.apply_horizontal(delta, speed_mult)
	_track_turn()
	var fall_speed := p.velocity.y
	p.move_and_slide()

	if p.is_on_floor() and not _was_on_floor:
		_on_landed(fall_speed)
	_was_on_floor = p.is_on_floor()
	_animate()


## Landung: Squash, Staub, Klang und Erschütterung skalieren mit der Fallgeschwindigkeit.
## Harte Landungen dämpfen kurz die Steuerung, damit der Aufprall spürbar ist.
## Frame 1 der Lande-Animation ist die weiche, Frame 2 die harte Landung.
func _on_landed(fall_speed: float) -> void:
	var hard := fall_speed > Morilla.HARD_LAND_SPEED
	p.visual.squash(Vector2(1.22, 0.8) if hard else Vector2(1.1, 0.92))
	p.visual.show_frame(&"land", 1 if hard else 0)
	if not hard:
		return
	var t := clampf((fall_speed - Morilla.HARD_LAND_SPEED) / (Morilla.MAX_FALL - Morilla.HARD_LAND_SPEED), 0.0, 1.0)
	Sound.sfx("land", remap(t, 0.0, 1.0, -10.0, 0.0))
	Effects.dust(p.get_parent(), p.global_position)
	Game.shake(remap(t, 0.0, 1.0, 0.04, 0.2))
	_land_lag = Morilla.LAND_LAG_TIME * (0.5 + t)


## Richtungswechsel: Die Figur dreht sich über eine kurze Zeit, statt sofort zu kippen.
func _track_turn() -> void:
	if p.facing == _turn_from or _turn_t > 0.0:
		return
	_turn_from = p.facing
	_turn_t = Morilla.TURN_TIME
	p.visual.squash(Vector2(0.9, 1.08))


func _check_transitions(on_floor: bool) -> bool:
	if p.buffered("dash") and p.can_dash():
		p.consume("dash")
		machine.change(&"dash")
		return true
	if on_floor and Input.is_action_pressed("block"):
		machine.change(&"block")
		return true
	if p.buffered("grab") and on_floor:
		p.consume("grab")
		_try_grab()
		return true
	if p.buffered("summon") and on_floor:
		p.consume("summon")
		if not p.summon_unlocked():
			Game.toast("Diese Technik kennst du noch nicht. Sprich mit Coach Arman.")
		elif p.summon_cooldown > 0.0:
			Game.toast("Der Geist erholt sich noch: %.1f s" % p.summon_cooldown)
		else:
			machine.change(&"summon")
			return true
	if p.consume("heavy_attack"):
		# Schwerer Schlag wird aufgeladen: Taste halten = härter und weitreichender, loslassen = Schlag.
		machine.change(&"charge")
		return true
	if p.consume("light_attack"):
		machine.change(&"attack", {"kind": "light"})
		return true
	if Input.is_action_just_pressed("interact") and on_floor and p.try_interact():
		return true
	return false


## Griff-Taste: Der Suplex greift auch große Gegner, der Kimura nur kleine und mittlere.
## Stehen beide Techniken bereit und ist ein großer Gegner in Reichweite, gewinnt der Suplex.
func _try_grab() -> void:
	var suplex := p.grapple.ability_for("suplex")
	var suplex_ready := p.grapple.is_unlocked("suplex") and p.grapple.cooldown <= 0.0
	var kimura_ready := p.grapple.is_unlocked("kimura") and p.grapple.cooldown <= 0.0
	if suplex_ready and (not kimura_ready or p.grapple.has_large_target(suplex)):
		machine.change(&"suplex")
		return
	if kimura_ready:
		machine.change(&"grapple")
		return
	if not p.grapple.is_unlocked("kimura") and not p.grapple.is_unlocked("suplex"):
		Game.toast("Diese Technik kennst du noch nicht. Sprich mit Coach Mo.")
	elif p.grapple.cooldown > 0.0:
		Game.toast("Der Griff erholt sich noch: %.1f s" % p.grapple.cooldown)


func _animate() -> void:
	var anim := &"idle"
	if not p.is_on_floor():
		anim = &"jump" if p.velocity.y < 0.0 else &"fall"
	elif absf(p.velocity.x) > Morilla.RUN_THRESHOLD:
		anim = &"run"
	elif absf(p.velocity.x) > Morilla.WALK_THRESHOLD:
		anim = &"walk"
	p.visual.play_anim(anim)
	p.visual.face(p.facing)
	if anim == &"run" or anim == &"walk":
		var ref: float = Morilla.SPEED if anim == &"run" else Morilla.SPEED * 0.45
		p.visual.speed_scale = clampf(absf(p.velocity.x) / ref, 0.7, 1.45)
