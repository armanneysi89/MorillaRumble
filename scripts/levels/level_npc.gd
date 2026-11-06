@tool
class_name LevelNpc
extends LevelMarker

## NPC-Platzhalter (Fußpunkt) für Figuren, die das Levelskript selbst aufbaut (Baby Mo, Vitali).
## Das Levelskript liest die Position über den Knotennamen.

@export var label := "":
	set(value):
		label = value
		queue_redraw()
@export_enum("none", "baby_mo", "vitali") var character := "none":
	set(value):
		character = value
		queue_redraw()


func _draw() -> void:
	var drawn := false
	if character != "none":
		drawn = draw_character(character)
	if not drawn:
		draw_rect(Rect2(-50, -320, 100, 320), Color(0.4, 0.7, 0.9, 0.5))
	draw_caption(label, Vector2(0, -360), 28, Color("9dd0f0"))
