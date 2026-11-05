@tool
class_name LevelDummy
extends LevelMarker

## Trainingspuppen-Platzhalter (Fußpunkt).


func _draw() -> void:
	if not draw_sprite(TrainingDummy.TEX_PATH, TrainingDummy.HEIGHT):
		draw_rect(Rect2(-45, -TrainingDummy.HEIGHT, 90, TrainingDummy.HEIGHT), TrainingDummy.PLACEHOLDER)
