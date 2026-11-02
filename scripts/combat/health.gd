class_name Health
extends Node

signal changed(hp: int, max_hp: int)
signal damaged(amount: int)
signal died

@export var max_hp := 3

var hp := 3
var invulnerable_time := 0.0


func _ready() -> void:
	hp = max_hp
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	invulnerable_time = maxf(invulnerable_time - delta, 0.0)
	if invulnerable_time <= 0.0:
		set_physics_process(false)


func is_dead() -> bool:
	return hp <= 0


func is_invulnerable() -> bool:
	return invulnerable_time > 0.0


func make_invulnerable(time: float) -> void:
	invulnerable_time = maxf(invulnerable_time, time)
	set_physics_process(true)


## Gibt true zurück, wenn der Schaden angerechnet wurde.
func take_damage(amount: int, ignore_invulnerability := false) -> bool:
	if is_dead() or (is_invulnerable() and not ignore_invulnerability):
		return false
	hp = maxi(hp - amount, 0)
	damaged.emit(amount)
	changed.emit(hp, max_hp)
	if hp == 0:
		died.emit()
	return true


func heal(amount: int) -> void:
	if is_dead():
		return
	hp = mini(hp + amount, max_hp)
	changed.emit(hp, max_hp)


func set_max(value: int, refill := false) -> void:
	max_hp = value
	hp = max_hp if refill else mini(hp, max_hp)
	changed.emit(hp, max_hp)


func revive() -> void:
	hp = max_hp
	invulnerable_time = 0.0
	changed.emit(hp, max_hp)
