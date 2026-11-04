@tool
class_name LevelMarker
extends Node2D

## Basis der Editor-Platzhalter. LevelBase ersetzt sie beim Start durch die echten Spielobjekte.

# Pfad -> [Textur, zeichenbereit]
static var _textures := {}
static var _surfaces := {}

# Schlüssel -> [Standbild, Fußpunkt-Y auf der Leinwand, Skalierung] (siehe CharacterSpecs)
const CHARACTERS := {
	"morilla": ["res://assets/characters/morilla/idle/morilla_idle_001.png", 470.0, 0.8],
	"mo": ["res://assets/characters/coaches/mo/mo_idle_001.png", 450.0, 0.7],
	"arman": ["res://assets/characters/coaches/arman/arman_idle_001.png", 450.0, 0.7],
	"recruit": ["res://assets/characters/enemies/white_belt_recruit/recruit_idle_001.png", 430.0, 0.66],
	"rival": ["res://assets/characters/enemies/blue_belt_rival/rival_idle_001.png", 430.0, 0.66],
}


func _ready() -> void:
	if not Engine.is_editor_hint():
		hide()


## Liefert die Textur erst, wenn sie zeichenbereit ist (sonst null; ein Neuzeichnen ist dann vorgemerkt).
## Eine erst im Zeichenaufruf geladene Textur wird weiß gezeichnet, deshalb erst im nächsten Frame.
func ready_texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = [load(path), false]
	var entry: Array = _textures[path]
	if entry[1]:
		return entry[0]
	get_tree().process_frame.connect(func() -> void:
		entry[1] = true
		queue_redraw(), CONNECT_ONE_SHOT)
	return null


## Oberkante der begehbaren Fläche in Texturpixeln (wie PlatformBlock.surface_of).
func surface_of(tex: Texture2D) -> float:
	if _surfaces.has(tex):
		return _surfaces[tex]
	var img := tex.get_image()
	var x0 := int(img.get_width() * 0.25)
	var x1 := int(img.get_width() * 0.75)
	var result := 0.0
	for y in img.get_height():
		var solid := 0
		for x in range(x0, x1, 2):
			if img.get_pixel(x, y).a > 0.5:
				solid += 1
		if solid >= (x1 - x0) / 2 * 0.6:
			result = y
			break
	_surfaces[tex] = result
	return result


## Zeichnet ein Sprite am Fußpunkt (oder zentriert). Gibt false zurück, wenn die Textur fehlt.
func draw_sprite(path: String, height: float, flip := false, centered := false) -> bool:
	if not ResourceLoader.exists(path):
		return false
	var tex := ready_texture(path)
	if tex == null:
		return true
	var w := tex.get_width() * height / tex.get_height()
	var y := -height * 0.5 if centered else -height
	var rect := Rect2(w * 0.5, y, -w, height) if flip else Rect2(-w * 0.5, y, w, height)
	draw_texture_rect(tex, rect, false)
	return true


## Zeichnet das Standbild einer Spielfigur am Fußpunkt. Gibt false zurück, wenn die Textur fehlt.
func draw_character(key: String) -> bool:
	if not CHARACTERS.has(key):
		return false
	var def: Array = CHARACTERS[key]
	if not ResourceLoader.exists(def[0]):
		return false
	var tex := ready_texture(def[0])
	if tex == null:
		return true
	var s: float = def[2]
	draw_texture_rect(tex, Rect2(-tex.get_width() * s * 0.5, -float(def[1]) * s, tex.get_width() * s, tex.get_height() * s), false)
	return true


func draw_caption(text: String, at: Vector2, font_size := 28, color := Color.WHITE) -> void:
	draw_multiline_string(ThemeDB.fallback_font, at + Vector2(-300, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 600.0, font_size, -1, color)
