class_name State
extends Node

## Basis eines Zustands. Zustände sind Kindknoten einer StateMachine; der Knotenname (kleingeschrieben) ist der Schlüssel.

var actor: Node
var machine: StateMachine


func enter(_msg: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
