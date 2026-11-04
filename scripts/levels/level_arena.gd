@tool
class_name LevelArena
extends LevelMarker

## Arena-Platzhalter. Position = Auslöser (Fußpunkt), rect = abgesperrter Bereich.
## Jedes Kind (Node2D) ist eine Welle, deren LevelEnemy-Kinder die Spawns sind.

@export var rect := Rect2(0, -700, 1600, 1780):
	set(value):
		rect = value
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(rect.position - global_position, rect.size), Color(0.9, 0.3, 0.3), false, 6.0)
	draw_rect(Rect2(-40, -400, 80, 1400), Color(0.9, 0.3, 0.3, 0.25))
	draw_caption("Arena (Auslöser + Bereich)", Vector2(0, -420), 28, Color(0.9, 0.3, 0.3))


## Pro Welle eine Liste von Spawns: Vector2 (Rekrut) oder [Vector2, Typ].
func waves() -> Array:
	var result := []
	for wave in get_children():
		var spawns := []
		for child in wave.get_children():
			if child is LevelEnemy:
				var enemy := child as LevelEnemy
				spawns.append(enemy.global_position if enemy.enemy_type == "recruit" else [enemy.global_position, enemy.enemy_type])
		result.append(spawns)
	return result
