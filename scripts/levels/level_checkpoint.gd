@tool
class_name LevelCheckpoint
extends LevelMarker

## Checkpoint-Platzhalter (Fußpunkt). Die ID muss pro Level eindeutig sein.

@export var id := "cp":
	set(value):
		id = value
		queue_redraw()


func _draw() -> void:
	if not draw_sprite("res://assets/environments/dojo/props/gong.png", 260.0):
		draw_rect(Rect2(-50, -260, 100, 260), Color("8a5a2b"))
	draw_caption(id, Vector2(0, -280), 24, Color("ffd9a0"))
