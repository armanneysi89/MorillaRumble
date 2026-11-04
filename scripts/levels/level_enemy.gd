@tool
class_name LevelEnemy
extends LevelMarker

## Gegner-Platzhalter (Fußpunkt). Innerhalb einer LevelArena zählt er als Spawn der jeweiligen Welle.

@export_enum("recruit", "rival") var enemy_type := "recruit":
	set(value):
		enemy_type = value
		queue_redraw()
@export var patrol_range := 160.0:
	set(value):
		patrol_range = value
		queue_redraw()


func _draw() -> void:
	var color := Color(0.9, 0.25, 0.25) if enemy_type == "recruit" else Color(0.3, 0.45, 0.95)
	if not draw_character(enemy_type):
		draw_rect(Rect2(-35, -170, 70, 170), Color(color, 0.7))
	draw_line(Vector2(-patrol_range, 6), Vector2(patrol_range, 6), color, 4.0)
	draw_caption(enemy_type, Vector2(0, -260), 24, color)
