@tool
class_name LevelSlab
extends LevelMarker

## Markierte Bruchplatte (Fußpunkt). Wird per Suplex zerstört und öffnet einen vorbereiteten Nebenweg.

@export var id := "slab":
	set(value):
		id = value
		queue_redraw()
## Höhe der Platte. Höher als die Sprunghöhe der Spielfigur = unüberwindbare Wand.
@export var height := BreakSlab.HEIGHT:
	set(value):
		height = value
		queue_redraw()


func _draw() -> void:
	if not draw_sprite(BreakSlab.TEX_PATH, height):
		draw_rect(Rect2(-BreakSlab.WIDTH * 0.5, -height, BreakSlab.WIDTH, height), Color(0.6, 0.6, 0.65, 0.5))
	draw_caption(id, Vector2(0, -height - 30.0), 26, Color("cfd6e0"))
