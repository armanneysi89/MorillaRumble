class_name BeltData
extends Resource

## Eine Gürtelstufe: Farbe für den Sprite-Shader sowie Boni auf Leben und Schaden.

@export var id := "white"
@export var display_name := "Weißgurt"
@export var color := Color.WHITE
@export var max_hp_bonus := 0
@export var damage_multiplier := 1.0
## Techniken, die mit dem Erreichen dieses Gürtels automatisch freigeschaltet werden.
@export var granted_abilities: PackedStringArray = []
