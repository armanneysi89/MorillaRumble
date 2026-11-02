class_name SpriteLibrary
extends RefCounted

## Baut SpriteFrames aus nummerierten Einzelframes. Fehlende Animationen erhalten einen Platzhalter,
## damit das Gameplay unabhängig vom Stand der Grafik funktioniert.

static var _cache := {}


static func build(spec: Dictionary) -> SpriteFrames:
	var key: String = spec["prefix"]
	if _cache.has(key):
		return _cache[key]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var anims: Dictionary = spec["anims"]
	for anim_name: String in anims:
		var def: Array = anims[anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, def[1])
		frames.set_animation_loop(anim_name, def[2])
		var index := 1
		while true:
			var path := frame_path(spec, def[0], anim_name, index)
			if not ResourceLoader.exists(path):
				break
			frames.add_frame(anim_name, load(path))
			index += 1
		if frames.get_frame_count(anim_name) == 0:
			frames.add_frame(anim_name, _placeholder(spec))
	_cache[key] = frames
	return frames


static func frame_path(spec: Dictionary, folder: String, anim_name: String, index: int) -> String:
	var dir: String = spec["root"] if folder == "" else "%s/%s" % [spec["root"], folder]
	return "%s/%s_%s_%03d.png" % [dir, spec["prefix"], anim_name, index]


static func _placeholder(spec: Dictionary) -> Texture2D:
	var canvas: Vector2 = spec["canvas"]
	var img := Image.create(int(canvas.x), int(canvas.y), false, Image.FORMAT_RGBA8)
	var body := Rect2i(int(canvas.x * 0.5) - 70, int(spec["anchor_y"]) - 340, 140, 340)
	img.fill_rect(body, spec["placeholder"])
	var face_x := body.position.x + (90 if int(spec["faces"]) > 0 else 20)
	img.fill_rect(Rect2i(face_x, body.position.y + 40, 30, 16), Color(1, 1, 1))
	return ImageTexture.create_from_image(img)
