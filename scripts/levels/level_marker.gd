@tool
class_name LevelMarker
extends Node2D

## Basis der Editor-Platzhalter. LevelBase ersetzt sie beim Start durch die echten Spielobjekte.

# Pfad -> [Textur, zeichenbereit]
static var _textures := {}

## Standbild einer Figur als [Pfad, Fußpunkt-Y auf der Leinwand, Skalierung] – abgeleitet aus CharacterSpecs,
## damit die Editor-Vorschau nicht hinter den Werten des Spiels zurückbleibt.
static func character_frame(key: String) -> Array:
	if not CharacterSpecs.ALL.has(key):
		return []
	var spec: Dictionary = CharacterSpecs.get_spec(key)
	var def: Array = spec["anims"]["idle"]
	return [SpriteLibrary.frame_path(spec, def[0], "idle", 1), float(spec["anchor_y"]), float(spec["scale"])]


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


## Oberkante der begehbaren Fläche in Texturpixeln (nutzt den Cache von PlatformBlock).
func surface_of(tex: Texture2D) -> float:
	return PlatformBlock.surface_of(tex)


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
	var def := character_frame(key)
	if def.is_empty():
		return false
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
