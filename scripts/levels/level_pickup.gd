@tool
class_name LevelPickup
extends LevelMarker

## Sammelobjekt-Platzhalter (Mittelpunkt). Die ID muss weltweit eindeutig sein (Weltzustand).

@export var id := "":
	set(value):
		id = value
		queue_redraw()
@export_enum("scroll", "tea") var kind := "scroll":
	set(value):
		kind = value
		queue_redraw()


func _draw() -> void:
	var path := ScrollPickup.TEA_TEX_PATH if kind == "tea" else ScrollPickup.TEX_PATH
	if not draw_sprite(path, 80.0 if kind == "tea" else ScrollPickup.HEIGHT, false, true):
		draw_rect(Rect2(-14, -40, 28, 80), ScrollPickup.PLACEHOLDER)
	draw_caption(id, Vector2(0, -60), 22, Color("ffd9a0"))
