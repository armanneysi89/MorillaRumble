@tool
class_name LevelBoss
extends LevelMarker

## Boss-Platzhalter (Fußpunkt). Das Levelskript baut daraus den Eisenrücken und sperrt die Arena ab.

@export var boss_id := "ironback":
	set(value):
		boss_id = value
		queue_redraw()
@export var arena_width := 1900.0:
	set(value):
		arena_width = value
		queue_redraw()


func _draw() -> void:
	if not draw_character("ironback"):
		draw_rect(Rect2(-90, -420, 180, 420), Color(0.5, 0.45, 0.4, 0.6))
	draw_line(Vector2(-arena_width * 0.5, 6), Vector2(arena_width * 0.5, 6), Color(0.9, 0.5, 0.2), 4.0)
	draw_caption("Boss: " + boss_id, Vector2(0, -460), 28, Color("ffb066"))
