@tool
class_name LevelDecor
extends LevelMarker

## Dekor-Platzhalter (Fußpunkt). Die Zeichenreihenfolge steuert z_index im Inspektor.

const PATHS: Array[String] = [
	"res://assets/environments/bamboo/props/%s.png",
	"res://assets/environments/dojo/props/%s.png",
]

@export_enum("pillar", "banner", "lantern", "weapon_rack", "cherry_tree", "bamboo_cluster", "bamboo_stalks", "shrine", "stone_lantern") var kind := "pillar":
	set(value):
		kind = value
		queue_redraw()
@export var height := 200.0:
	set(value):
		height = value
		queue_redraw()
@export var flip := false:
	set(value):
		flip = value
		queue_redraw()


func _draw() -> void:
	for pattern in PATHS:
		if draw_sprite(pattern % kind, height, flip):
			return
	draw_rect(Rect2(-30, -height, 60, height), Color(1, 0, 1, 0.5))
