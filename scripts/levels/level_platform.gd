@tool
class_name LevelPlatform
extends LevelMarker

## Plattform-Platzhalter. Position = linke Oberkante der begehbaren Fläche.

const COLORS := [Color("8a5a3a"), Color("7a7a8c"), Color("b8863f"), Color("3f7a4a"), Color("7aa03f")]
const TEXTURES := [
	"res://assets/environments/dojo/terrain/ground_wood.png",
	"res://assets/environments/dojo/terrain/ground_stone.png",
	"res://assets/environments/dojo/terrain/platform_wood.png",
	"res://assets/environments/bamboo/terrain/ground_moss.png",
	"res://assets/environments/bamboo/terrain/platform_bamboo.png",
]
# Gleiche Werte wie in PlatformBlock.
const CHUNK_WIDTH := 560.0
const CHUNK_OVERLAP := 200.0
const GROUND_DEPTH := 700.0
const SHELF_THICKNESS := 26.0

@export_enum("Holz:0", "Stein:1", "Regal:2", "Moos:3", "Bambus:4") var kind := 0:
	set(value):
		kind = value
		queue_redraw()
@export var width := 400.0:
	set(value):
		width = value
		queue_redraw()


func _draw() -> void:
	var shelf := kind == 2 or kind == 4
	var tex_path: String = TEXTURES[kind]
	var tex: Texture2D = null
	if ResourceLoader.exists(tex_path):
		tex = ready_texture(tex_path)
		if tex == null:
			return
	if not shelf:
		var fill := Color("10201e") if kind == 3 else Color("1c1a2e")
		draw_colored_polygon(PackedVector2Array([Vector2(70, 60), Vector2(width - 70, 60), Vector2(width - 110, GROUND_DEPTH), Vector2(110, GROUND_DEPTH)]), fill)
	if tex == null:
		var color: Color = COLORS[kind]
		draw_rect(Rect2(0, 0, width, SHELF_THICKNESS if shelf else 24.0), color)
		return
	if shelf:
		_draw_chunk(tex, width * 0.5, (width + 60.0) / tex.get_width(), false)
		return
	var step := CHUNK_WIDTH - CHUNK_OVERLAP
	var count := maxi(int(ceil((width - CHUNK_OVERLAP) / step)), 1)
	var spread := (width + 40.0 - CHUNK_WIDTH) / maxf(count - 1, 1)
	var seed_i := int(global_position.x / 100.0)
	for i in count:
		var x := -20.0 + CHUNK_WIDTH * 0.5 + spread * i if count > 1 else width * 0.5
		var s := CHUNK_WIDTH / tex.get_width() if count > 1 else (width + 40.0) / tex.get_width()
		_draw_chunk(tex, x, s, (i + seed_i) % 3 == 1)


func _draw_chunk(tex: Texture2D, center_x: float, s: float, flip: bool) -> void:
	var w := tex.get_width() * s
	var top := -(surface_of(tex) + 6.0) * s
	var rect := Rect2(center_x + w * 0.5, top, -w, tex.get_height() * s) if flip else Rect2(center_x - w * 0.5, top, w, tex.get_height() * s)
	draw_texture_rect(tex, rect, false)
