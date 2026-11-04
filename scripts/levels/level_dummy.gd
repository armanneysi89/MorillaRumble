@tool
class_name LevelDummy
extends LevelMarker

## Trainingspuppen-Platzhalter (Fußpunkt).


func _draw() -> void:
	if not draw_sprite("res://assets/environments/dojo/props/dummy.png", 230.0):
		draw_rect(Rect2(-45, -230, 90, 230), Color("b89a6a"))
