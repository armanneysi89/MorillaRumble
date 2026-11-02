extends State

## Laufen, Springen und Fallen. Verzweigt in alle anderen Zustände.

var p: Morilla
var _was_on_floor := true


func enter(_msg: Dictionary = {}) -> void:
	p = actor as Morilla
	_was_on_floor = p.is_on_floor()


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
	# Variable Sprunghöhe: Loslassen kappt den Aufstieg.
	if Input.is_action_just_released("jump") and p.velocity.y < -300.0:
		p.velocity.y *= 0.5

	p.apply_gravity(delta)
	p.apply_horizontal(delta)
	var fall_speed := p.velocity.y
	p.move_and_slide()

	if p.is_on_floor() and not _was_on_floor:
		p.visual.squash(Vector2(1.22, 0.8))
		if fall_speed > 350.0:
			Sound.sfx("land", remap(minf(fall_speed, Morilla.MAX_FALL), 350.0, Morilla.MAX_FALL, -10.0, 0.0))
			Effects.dust(p.get_parent(), p.global_position)
			Game.shake(remap(minf(fall_speed, Morilla.MAX_FALL), 350.0, Morilla.MAX_FALL, 0.04, 0.2))
	_was_on_floor = p.is_on_floor()
	_animate()


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
		if not p.grapple.is_unlocked():
			Game.toast("Diese Technik kennst du noch nicht. Sprich mit Coach Mo.")
		elif p.grapple.cooldown <= 0.0:
			machine.change(&"grapple")
			return true
	if p.consume("heavy_attack"):
		machine.change(&"attack", {"kind": "heavy"})
		return true
	if p.consume("light_attack"):
		machine.change(&"attack", {"kind": "light"})
		return true
	if Input.is_action_just_pressed("interact") and on_floor and p.try_interact():
		return true
	return false


func _animate() -> void:
	var anim := &"idle"
	if not p.is_on_floor():
		anim = &"jump" if p.velocity.y < 0.0 else &"fall"
	elif absf(p.velocity.x) > 380.0:
		anim = &"run"
	elif absf(p.velocity.x) > 40.0:
		anim = &"walk"
	p.visual.play_anim(anim)
	p.visual.face(p.facing)
	if anim == &"run" or anim == &"walk":
		var ref: float = Morilla.SPEED if anim == &"run" else Morilla.SPEED * 0.45
		p.visual.speed_scale = clampf(absf(p.velocity.x) / ref, 0.7, 1.45)
