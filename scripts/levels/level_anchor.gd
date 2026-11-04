@tool
class_name LevelAnchor
extends LevelMarker

## Benannter Fixpunkt (Start, Coach, Ausgang). Das Levelskript liest die Position über den Knotennamen.

@export var label := "":
	set(value):
		label = value
		queue_redraw()
@export_enum("none", "morilla", "mo", "arman") var character := "none":
	set(value):
		character = value
		queue_redraw()
@export_file("*.png") var sprite := "":
	set(value):
		sprite = value
		queue_redraw()
@export var sprite_height := 200.0:
	set(value):
		sprite_height = value
		queue_redraw()


func _draw() -> void:
	var drawn := false
	if character != "none":
		drawn = draw_character(character)
	elif sprite != "":
		drawn = draw_sprite(sprite, sprite_height)
	if not drawn:
		draw_rect(Rect2(-40, -sprite_height, 80, sprite_height), Color(0.3, 0.8, 0.5, 0.5))
	draw_caption(label, Vector2(0, -(380.0 if character != "none" else sprite_height) - 20.0), 28, Color("9df0b8"))
