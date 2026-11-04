@tool
class_name LevelBackdrop
extends LevelMarker

## Hintergrund-Einstellungen des Levels (Himmel, ferne Halle, Säulen). Im Spiel baut LevelBase daraus den
## Parallax-Hintergrund; im Editor zeigt der Knoten eine feste Vorschau (ohne Bewegung) bei Ursprung (0, 0).

const SCREEN := Vector2(1920, 1080)
const PILLAR_SPACING := 620.0

@export var level_width := 8000.0:
	set(value):
		level_width = value
		queue_redraw()
@export_file("*.png") var far_background := "res://assets/environments/dojo/bg_dojo.png":
	set(value):
		far_background = value
		queue_redraw()
@export_file("*.png") var pillar_path := "res://assets/environments/dojo/props/pillar.png":
	set(value):
		pillar_path = value
		queue_redraw()
@export var pillar_tint := Color(0.45, 0.42, 0.6, 0.9):
	set(value):
		pillar_tint = value
		queue_redraw()
@export var sky_top := Color("0b0a22"):
	set(value):
		sky_top = value
		queue_redraw()
@export var sky_bottom := Color("2a1745"):
	set(value):
		sky_bottom = value
		queue_redraw()
@export var petal_color := Color(1.0, 0.72, 0.82, 0.85)
@export var fireflies := false
## Nur Vorschau: Mitte des Kamerabilds (Rahmen), damit man den sichtbaren Ausschnitt abschätzen kann.
@export var preview_camera_x := 960.0:
	set(value):
		preview_camera_x = value
		queue_redraw()


func _ready() -> void:
	super()
	z_index = -100


func _draw() -> void:
	var w := level_width
	draw_polygon(PackedVector2Array([Vector2(0, -400), Vector2(w, -400), Vector2(w, 0), Vector2(0, 0)]), PackedColorArray([sky_top, sky_top, sky_top, sky_top]))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, SCREEN.y), Vector2(0, SCREEN.y)]), PackedColorArray([sky_top, sky_top, sky_bottom, sky_bottom]))
	draw_polygon(PackedVector2Array([Vector2(0, SCREEN.y), Vector2(w, SCREEN.y), Vector2(w, 1400), Vector2(0, 1400)]), PackedColorArray([sky_bottom, sky_bottom, sky_bottom, sky_bottom]))
	_draw_far()
	_draw_pillars()
	draw_rect(Rect2(preview_camera_x - SCREEN.x * 0.5, 0, SCREEN.x, SCREEN.y), Color(1, 1, 1, 0.7), false, 4.0)
	draw_caption("Kamera-Ausschnitt (preview_camera_x)", Vector2(preview_camera_x, 40), 28, Color(1, 1, 1, 0.8))


func _draw_far() -> void:
	if not ResourceLoader.exists(far_background):
		return
	var tex := ready_texture(far_background)
	if tex == null:
		return
	var s := SCREEN.y * 1.2 / tex.get_height()
	var tw := tex.get_width() * s
	var x := 0.0
	while x < level_width:
		draw_texture_rect(tex, Rect2(x, -SCREEN.y * 0.1, tw, tex.get_height() * s), false)
		x += tw


func _draw_pillars() -> void:
	if not ResourceLoader.exists(pillar_path):
		return
	var tex := ready_texture(pillar_path)
	if tex == null:
		return
	var h := SCREEN.y * 0.85
	var w := tex.get_width() * h / tex.get_height()
	var i := 0
	var x := 0.0
	while x < level_width:
		var rect := Rect2(x + w, SCREEN.y * 0.08, -w, h) if i % 2 == 1 else Rect2(x, SCREEN.y * 0.08, w, h)
		draw_texture_rect(tex, rect, false, pillar_tint)
		x += PILLAR_SPACING
		i += 1
