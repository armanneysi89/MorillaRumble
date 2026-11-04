@tool
class_name LevelHint
extends LevelMarker

## Hinweisschild-Platzhalter (Fußpunkt).

@export_multiline var text := "":
	set(value):
		text = value
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-260, -400, 520, 400), Color(1.0, 0.7, 0.3, 0.08))
	draw_rect(Rect2(-8, -120, 16, 120), Color("b8863f"))
	draw_caption(text, Vector2(0, -430), 26, Color("ffd9a0"))
