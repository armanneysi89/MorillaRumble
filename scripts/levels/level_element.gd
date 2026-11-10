@tool
class_name LevelElement
extends LevelMarker

## Platzhalter für die neuen Spielelemente (Kiste, Feder, Stachel, Aufwind, Kristall).
## Position = Fußpunkt. LevelBase baut daraus das echte Objekt.

@export_enum("crate", "spring", "spike", "wind", "gem") var kind := "crate":
	set(value):
		kind = value
		queue_redraw()
## Eindeutige ID (Weltzustand: zerstörte Kisten und eingesammelte Kristalle bleiben weg).
@export var id := "":
	set(value):
		id = value
		queue_redraw()
## Nur für Kisten: Inhalt ("" = leer, "gem", "tea").
@export var content := "":
	set(value):
		content = value
		queue_redraw()
## Nur für Aufwind: Höhe des Luftstroms.
@export var height := WindVent.HEIGHT:
	set(value):
		height = value
		queue_redraw()


func _draw() -> void:
	match kind:
		"crate":
			if not draw_sprite(BreakCrate.TEX_PATH, BreakCrate.SIZE.y):
				draw_rect(Rect2(-BreakCrate.SIZE.x * 0.5, -BreakCrate.SIZE.y, BreakCrate.SIZE.x, BreakCrate.SIZE.y),
					Color(0.55, 0.4, 0.2, 0.6))
			draw_caption("Kiste %s%s" % [id, "" if content == "" else " (%s)" % content], Vector2(0, -BreakCrate.SIZE.y - 24.0),
				22, Color("e8c08a"))
		"spring":
			if not draw_sprite(SpringPad.TEX_PATH, SpringPad.HEIGHT):
				draw_rect(Rect2(-SpringPad.WIDTH * 0.5, -SpringPad.HEIGHT, SpringPad.WIDTH, SpringPad.HEIGHT),
					Color(0.8, 0.4, 0.25, 0.6))
			draw_caption("Feder", Vector2(0, -SpringPad.HEIGHT - 24.0), 22, Color("ffb08a"))
		"spike":
			if not draw_sprite(SpikeTrap.TEX_PATH, SpikeTrap.HEIGHT):
				draw_rect(Rect2(-SpikeTrap.WIDTH * 0.5, -SpikeTrap.HEIGHT, SpikeTrap.WIDTH, SpikeTrap.HEIGHT),
					Color(0.5, 0.5, 0.55, 0.6))
			draw_caption("Stacheln", Vector2(0, -SpikeTrap.HEIGHT - 24.0), 22, Color("d0d4dc"))
		"wind":
			draw_rect(Rect2(-WindVent.WIDTH * 0.5, -height, WindVent.WIDTH, height), Color(0.55, 0.8, 1.0, 0.12))
			draw_line(Vector2(0, 0), Vector2(0, -height), Color(0.6, 0.85, 1.0, 0.7), 4.0)
			draw_caption("Aufwind", Vector2(0, -height - 24.0), 22, Color("a8d8ff"))
		"gem":
			if not draw_sprite(ScrollPickup.GEM_TEX_PATH, ScrollPickup.GEM_HEIGHT, false, true):
				draw_rect(Rect2(-20, -20, 40, 40), Color(1.0, 0.85, 0.4, 0.7))
			draw_caption("Kristall %s" % id, Vector2(0, -60), 22, Color("ffd9a0"))
