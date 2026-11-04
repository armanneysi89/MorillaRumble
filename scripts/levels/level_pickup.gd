@tool
class_name LevelPickup
extends LevelMarker

## Schriftrollen-Platzhalter (Mittelpunkt). Die ID muss weltweit eindeutig sein (Weltzustand).

@export var id := "":
	set(value):
		id = value
		queue_redraw()


func _draw() -> void:
	if not draw_sprite("res://assets/environments/dojo/props/scroll.png", 90.0, false, true):
		draw_rect(Rect2(-14, -40, 28, 80), Color("e8c872"))
	draw_caption(id, Vector2(0, -60), 22, Color("ffd9a0"))
