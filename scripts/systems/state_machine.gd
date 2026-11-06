class_name StateMachine
extends Node

signal state_changed(from_state: StringName, to_state: StringName)

var current: State
var current_name: StringName = &""

var _states := {}


func setup(actor: Node) -> void:
	for child in get_children():
		if child is State:
			var state: State = child
			state.actor = actor
			state.machine = self
			_states[StringName(child.name.to_lower())] = state


func start(state_name: StringName, msg: Dictionary = {}) -> void:
	if not _states.has(state_name):
		push_error("Unbekannter Zustand: %s" % state_name)
		return
	_enter(state_name, msg)


## Wechselt den Zustand. Ein Wechsel in denselben Zustand wird ignoriert: Sonst liefen exit() und
## enter() erneut und würden Lande-Effekte, Squash und Puffer doppelt auslösen.
func change(state_name: StringName, msg: Dictionary = {}) -> void:
	if not _states.has(state_name):
		push_error("Unbekannter Zustand: %s" % state_name)
		return
	if state_name == current_name:
		return
	var from := current_name
	if current:
		current.exit()
	_enter(state_name, msg)
	state_changed.emit(from, state_name)


func is_in(state_name: StringName) -> bool:
	return current_name == state_name


func physics_update(delta: float) -> void:
	if current:
		current.physics_update(delta)


func _enter(state_name: StringName, msg: Dictionary) -> void:
	current_name = state_name
	current = _states[state_name]
	current.enter(msg)
