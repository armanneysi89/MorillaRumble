extends State

## Getroffen: kurze Betäubung mit Rückstoß, danach Unverwundbarkeit (Blinken).

const IFRAMES := 1.2

var p: Morilla
var _t := 0.0


func enter(msg: Dictionary = {}) -> void:
	p = actor as Morilla
	var info: HitInfo = msg.get("info")
	var dir := 1
	var knock := Vector2(300.0, -300.0)
	_t = 0.3
	if info:
		dir = info.direction
		knock = info.knockback
		_t = maxf(info.stun, 0.3)
	p.velocity = Vector2(dir * knock.x, knock.y)
	p.health.make_invulnerable(IFRAMES)
	p.visual.play_anim(&"hurt", true)
	p.visual.flash(0.2, Color(1.0, 0.35, 0.3))
	Sound.sfx("hurt")
	Game.hit_stop(0.08)
	Game.shake(0.35)


func physics_update(delta: float) -> void:
	_t -= delta
	p.apply_gravity(delta)
	p.velocity.x = move_toward(p.velocity.x, 0.0, Morilla.FRICTION * 0.3 * delta)
	p.move_and_slide()
	if _t <= 0.0:
		machine.change(&"locomotion")
