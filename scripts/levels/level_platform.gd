@tool
class_name LevelPlatform
extends LevelMarker

## Plattform-Platzhalter. Position = linke Oberkante der begehbaren Fläche.
## Alle Werte (Texturen, Segmentmasse, Füllfarben) stammen von PlatformBlock, damit Vorschau und Spiel nicht
## auseinanderlaufen können.

@export_enum("Holz:0", "Stein:1", "Regal:2", "Moos:3", "Bambus:4", "Fels:5", "Steg:6", "Treppe:7") var kind := 0:
	set(value):
		kind = value
		queue_redraw()
@export var width := 400.0:
	set(value):
		width = value
		queue_redraw()


func _draw() -> void:
	var shelf := kind == PlatformBlock.Kind.SHELF or kind == PlatformBlock.Kind.LOG or kind == PlatformBlock.Kind.PLANK
	var tex_path: String = PlatformBlock.TEXTURES[kind]
	var tex: Texture2D = null
	if ResourceLoader.exists(tex_path):
		tex = ready_texture(tex_path)
		if tex == null:
			return
		if not shelf:
			var fill := PlatformBlock.MOSS_FILL if kind == PlatformBlock.Kind.MOSS else (PlatformBlock.ROCK_FILL if kind == PlatformBlock.Kind.ROCK else PlatformBlock.GROUND_FILL)
			draw_colored_polygon(PackedVector2Array([Vector2(70, 60), Vector2(width - 70, 60), Vector2(width - 110, PlatformBlock.GROUND_DEPTH), Vector2(110, PlatformBlock.GROUND_DEPTH)]), fill)
	if tex == null:
		draw_rect(Rect2(0, 0, width, PlatformBlock.SHELF_THICKNESS if shelf else 24.0), PlatformBlock.TOP_FILL)
		return
	if shelf:
		_draw_chunk(tex, width * 0.5, (width + 60.0) / tex.get_width(), false)
		return
	var step := PlatformBlock.CHUNK_WIDTH - PlatformBlock.CHUNK_OVERLAP
	var count := maxi(int(ceil((width - PlatformBlock.CHUNK_OVERLAP) / step)), 1)
	var spread := (width + 40.0 - PlatformBlock.CHUNK_WIDTH) / maxf(count - 1, 1)
	var seed_i := int(global_position.x / 100.0)
	for i in count:
		var x := -20.0 + PlatformBlock.CHUNK_WIDTH * 0.5 + spread * i if count > 1 else width * 0.5
		var s := PlatformBlock.CHUNK_WIDTH / tex.get_width() if count > 1 else (width + 40.0) / tex.get_width()
		_draw_chunk(tex, x, s, (i + seed_i) % 3 == 1)


func _draw_chunk(tex: Texture2D, center_x: float, s: float, flip: bool) -> void:
	var w := tex.get_width() * s
	var top := -(surface_of(tex) + 6.0) * s
	var rect := Rect2(center_x + w * 0.5, top, -w, tex.get_height() * s) if flip else Rect2(center_x - w * 0.5, top, w, tex.get_height() * s)
	var tint: Color = PlatformBlock.TINTS.get(kind, Color.WHITE)
	draw_texture_rect(tex, rect, false, tint)
