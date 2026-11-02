class_name GameCamera
extends Camera2D

## Kamera mit weichem Folgen, Vorausschau, Raumgrenzen, Arena-Rahmung und Wackeln. Hängt als Kind am Spieler.

const LOOK_AHEAD := 240.0
const LOOK_SPEED := 2.2
const VERTICAL_OFFSET := -150.0
const SHAKE_DECAY := 2.4
const SHAKE_MAX := 26.0

var target: Morilla

var _look := 0.0
var _trauma := 0.0
var _room_limits := Rect2i()
var _noise_t := 0.0


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 7.0
	limit_smoothed = true
	make_current()
	Game.shake_requested.connect(_on_shake)


func _exit_tree() -> void:
	if Game.shake_requested.is_connected(_on_shake):
		Game.shake_requested.disconnect(_on_shake)


func set_room(rect: Rect2i) -> void:
	_room_limits = rect
	_apply_limits(rect)


## Rahmt einen Kampfbereich: Die Kamera darf diesen Raum nicht verlassen.
func lock_arena(rect: Rect2i) -> void:
	_apply_limits(rect)


func release_arena() -> void:
	_apply_limits(_room_limits)


func _apply_limits(rect: Rect2i) -> void:
	limit_left = rect.position.x
	limit_top = rect.position.y
	limit_right = rect.end.x
	limit_bottom = rect.end.y


func _process(delta: float) -> void:
	var want := 0.0
	if target:
		want = target.facing * LOOK_AHEAD * clampf(absf(target.velocity.x) / 400.0, 0.35, 1.0)
	_look = lerpf(_look, want, minf(delta * LOOK_SPEED, 1.0))
	_trauma = maxf(_trauma - delta * SHAKE_DECAY, 0.0)
	_noise_t += delta * 60.0
	var s := _trauma * _trauma * SHAKE_MAX
	var jitter := Vector2(sin(_noise_t * 1.7), cos(_noise_t * 2.3)) * s
	offset = Vector2(_look, VERTICAL_OFFSET) + jitter


func _on_shake(strength: float) -> void:
	_trauma = minf(_trauma + strength, 1.0)
