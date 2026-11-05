@tool
class_name LevelPickup
extends LevelMarker

## Schriftrollen-Platzhalter (Mittelpunkt). Die ID muss weltweit eindeutig sein (Weltzustand).

@export var id := "":
	set(value):
		id = value
		queue_redraw()


func _draw() -> void:
	if not draw_sprite(ScrollPickup.TEX_PATH, ScrollPickup.HEIGHT, false, true):
		draw_rect(Rect2(-14, -40, 28, 80), ScrollPickup.PLACEHOLDER)
	draw_caption(id, Vector2(0, -60), 22, Color("ffd9a0"))
