class_name Hurtbox
extends Area2D

## Verwundbare Fläche. Der Besitzer verbindet hit_received und entscheidet selbst über Schaden, Blocken und Rückstoß.

signal hit_received(info: HitInfo)

var enabled := true


func receive_hit(info: HitInfo) -> bool:
	if not enabled:
		return false
	hit_received.emit(info)
	return true
