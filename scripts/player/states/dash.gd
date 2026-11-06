extends State

## Schneller Ausweichschritt. In der Luft nur einmal bis zur nächsten Landung.
## Unverwundbar ist nur ein Fenster am Anfang des Dashs, nicht der ganze Schritt: Wer zu früh
## oder zu spät ausweicht, wird getroffen. Das macht den Dash zum Timing-Werkzeug statt zum Freifahrtschein.

const DASH_SPEED := 1250.0
const DASH_TIME := 0.17
## Unverwundbarkeits-Fenster ab dem Start des Dashs.
const IFRAME_TIME := 0.11
const GHOST_INTERVAL := 0.035

var p: Morilla
var _t := 0.0
var _ghost_t := 0.0
var _iframe_t := 0.0


func enter(_msg: Dictionary = {}) -> void:
	p = actor as Morilla
	_t = DASH_TIME
	_ghost_t = 0.0
	_iframe_t = IFRAME_TIME
	p.dash_cooldown = Morilla.DASH_COOLDOWN
	if not p.is_on_floor():
		p.air_dash_available = false
	if absf(p.input_dir) > 0.0:
		p.facing = 1 if p.input_dir > 0.0 else -1
	p.hurtbox.enabled = false
	p.velocity = Vector2(p.facing * DASH_SPEED, 0.0)
	p.visual.show_frame(&"dash", 0)
	p.visual.face(p.facing)
	Sound.sfx("dash")
	Effects.dust(p.get_parent(), p.global_position)


func exit() -> void:
	p.hurtbox.enabled = true
	p.velocity.x = clampf(p.velocity.x, -Morilla.SPEED, Morilla.SPEED)


func physics_update(delta: float) -> void:
	_t -= delta
	_ghost_t -= delta
	_iframe_t -= delta
	# Das Unverwundbarkeits-Fenster endet vor dem Dash: Der Rest ist verwundbar.
	if _iframe_t <= 0.0 and not p.hurtbox.enabled:
		p.hurtbox.enabled = true
	if _ghost_t <= 0.0:
		_ghost_t = GHOST_INTERVAL
		p.visual.spawn_ghost()
	p.velocity.y = 0.0
	p.velocity.x = p.facing * DASH_SPEED
	p.move_and_slide()
	if _t <= 0.0 or p.is_on_wall():
		machine.change(&"locomotion")
