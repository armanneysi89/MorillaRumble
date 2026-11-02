class_name PlatformBlock
extends StaticBody2D

## Begehbare Fläche: Boden (Holz/Stein) oder durchspringbares Regal. Die Textur wird aus überlappenden Segmenten
## zusammengesetzt; fehlt sie, zeichnet ein einfacher Platzhalter die Fläche (Gameplay bleibt unabhängig von der Grafik).

enum Kind { WOOD, STONE, SHELF }

const DIR := "res://assets/environments/dojo/terrain/"
const CHUNK_WIDTH := 560.0
const CHUNK_OVERLAP := 200.0
const SHELF_THICKNESS := 26.0

static var _surface_cache := {}

var kind := Kind.WOOD
var size := Vector2(400, 700)
var fill_color := Color("1c1a2e")
var top_color := Color("5a3b2e")


## Oberkante der begehbaren Fläche in Texturpixeln: erste Zeile, die über die Bildmitte fast vollständig deckend ist.
static func surface_of(tex: Texture2D) -> float:
	if _surface_cache.has(tex):
		return _surface_cache[tex]
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
	_surface_cache[tex] = result
	return result


func _load(file: String) -> Texture2D:
	var path := DIR + file
	return load(path) if ResourceLoader.exists(path) else null


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	var shape := RectangleShape2D.new()
	var cs := CollisionShape2D.new()
	if kind == Kind.SHELF:
		shape.size = Vector2(size.x, SHELF_THICKNESS)
		cs.one_way_collision = true
		cs.position = shape.size * 0.5
		_build_shelf()
	else:
		shape.size = size
		cs.position = size * 0.5
		_build_ground()
	cs.shape = shape
	add_child(cs)


func _build_ground() -> void:
	var tex := _load("ground_wood.png" if kind == Kind.WOOD else "ground_stone.png")
	var fill := Polygon2D.new()
	fill.polygon = PackedVector2Array([Vector2(70, 60), Vector2(size.x - 70, 60), Vector2(size.x - 110, size.y), Vector2(110, size.y)])
	fill.color = fill_color
	fill.z_index = -3
	add_child(fill)
	if tex == null:
		_placeholder_top()
		return
	var step := CHUNK_WIDTH - CHUNK_OVERLAP
	var count := maxi(int(ceil((size.x - CHUNK_OVERLAP) / step)), 1)
	var spread := (size.x + 40.0 - CHUNK_WIDTH) / maxf(count - 1, 1)
	var seed_i := int(position.x / 100.0)
	for i in count:
		var x := -20.0 + CHUNK_WIDTH * 0.5 + spread * i if count > 1 else size.x * 0.5
		var s := CHUNK_WIDTH / tex.get_width() if count > 1 else (size.x + 40.0) / tex.get_width()
		_add_sprite(tex, Vector2(x, 0), s, (i + seed_i) % 3 == 1, -2 + (i % 2))


func _build_shelf() -> void:
	var tex := _load("platform_wood.png")
	if tex == null:
		_placeholder_top()
		return
	var s := (size.x + 60.0) / tex.get_width()
	_add_sprite(tex, Vector2(size.x * 0.5, 0), s, false, -1)


func _placeholder_top() -> void:
	var top := Polygon2D.new()
	var h := 22.0 if kind != Kind.SHELF else SHELF_THICKNESS
	top.polygon = PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, h), Vector2(0, h)])
	top.color = top_color
	top.z_index = -2
	add_child(top)


func _add_sprite(tex: Texture2D, top_center: Vector2, s: float, flip: bool, z: int) -> void:
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.centered = false
	sp.flip_h = flip
	sp.scale = Vector2(s, s)
	sp.offset = Vector2(-tex.get_width() * 0.5, -surface_of(tex) - 6.0)
	sp.position = top_center
	sp.z_index = z
	add_child(sp)
