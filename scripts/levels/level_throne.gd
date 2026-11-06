@tool
class_name LevelThrone
extends LevelMarker

## Gürtelthron-Platzhalter (Fußpunkt). Das Levelskript baut daraus den Thron aus Gürteln und setzt Vitali davor.

@export var height := 620.0:
	set(value):
		height = value
		queue_redraw()


func _draw() -> void:
	if not draw_sprite(BeltThrone.TEX_PATH, height):
		draw_rect(Rect2(-260, -height, 520, height), Color(0.55, 0.4, 0.75, 0.4))
	draw_caption("Gürtelthron", Vector2(0, -height - 30.0), 28, Color("d9b8ff"))
