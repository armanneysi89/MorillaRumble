@tool
class_name LevelCheckpoint
extends LevelMarker

## Checkpoint-Platzhalter (Fußpunkt). Die ID muss pro Level eindeutig sein.

@export var id := "cp":
	set(value):
		id = value
		queue_redraw()


func _draw() -> void:
	if not draw_sprite(Checkpoint.TEX_PATH, Checkpoint.HEIGHT):
		draw_rect(Rect2(-50, -Checkpoint.HEIGHT, 100, Checkpoint.HEIGHT), Checkpoint.PLACEHOLDER)
	draw_caption(id, Vector2(0, -280), 24, Color("ffd9a0"))
