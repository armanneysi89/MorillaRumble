extends State

## Keine Eingabe (Dialoge, Levelende). Die Figur steht still und atmet.

var p: Morilla


func enter(_msg: Dictionary = {}) -> void:
	p = actor as Morilla
	p.clear_buffers()
	p.visual.play_anim(&"idle")


func physics_update(delta: float) -> void:
	p.apply_gravity(delta)
	p.velocity.x = move_toward(p.velocity.x, 0.0, Morilla.FRICTION * delta)
	p.move_and_slide()
