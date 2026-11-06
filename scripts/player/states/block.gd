extends State

## Block gegen frontale Treffer. Die ersten Sekundenbruchteile sind ein Parade-Fenster (siehe PlayerCombat).
## Frame 1 ist die ruhige Deckung, Frame 2 die Pose unter Trefferlast – so sieht man, dass der Block hält.

var p: Morilla
## Restzeit, in der die Treffer-Pose gezeigt wird.
var _impact_t := 0.0


func enter(_msg: Dictionary = {}) -> void:
	p = actor as Morilla
	p.combat.blocking = true
	p.combat.block_time = 0.0
	_impact_t = 0.0
	p.visual.show_frame(&"block", 0)
	p.visual.face(p.facing)
	Sound.sfx("block_up", -6.0)


func exit() -> void:
	p.combat.blocking = false


func physics_update(delta: float) -> void:
	p.combat.block_time += delta
	_impact_t = maxf(_impact_t - delta, 0.0)
	p.apply_gravity(delta)
	p.velocity.x = move_toward(p.velocity.x, 0.0, Morilla.FRICTION * delta)
	p.move_and_slide()
	if not Input.is_action_pressed("block") or not p.is_on_floor():
		machine.change(&"locomotion")
		return
	if p.buffered("dash") and p.can_dash():
		machine.change(&"locomotion")
