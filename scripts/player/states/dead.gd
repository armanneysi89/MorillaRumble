extends State

## K. o.: Todesanimation, danach meldet die Spielfigur died (der Level lädt am letzten Checkpoint neu).

const DEATH_TIME := 1.6

var p: Morilla
var _t := 0.0
var _reported := false


func enter(_msg: Dictionary = {}) -> void:
	p = actor as Morilla
	_t = 0.0
	_reported = false
	p.hurtbox.enabled = false
	p.combat.blocking = false
	var dir := p.last_hit.direction if p.last_hit else -p.facing
	p.velocity = Vector2(dir * 280.0, -420.0)
	p.visual.play_timed(&"death", 0.9)
	p.visual.face(p.facing)
	Sound.sfx("death")
	Game.shake(0.5)


func physics_update(delta: float) -> void:
	_t += delta
	p.apply_gravity(delta)
	p.velocity.x = move_toward(p.velocity.x, 0.0, Morilla.FRICTION * 0.4 * delta)
	p.move_and_slide()
	if _t >= DEATH_TIME and not _reported:
		_reported = true
		p.died.emit()
