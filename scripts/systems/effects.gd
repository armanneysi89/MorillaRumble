class_name Effects
extends RefCounted

## Kleine, kostengünstige Partikel-Effekte (CPUParticles2D läuft auf allen Plattformen inkl. Web).


static func burst(parent: Node, pos: Vector2, color: Color, count := 10, speed := 420.0, lifetime := 0.35, size := 7.0, up := true) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = count
	p.lifetime = lifetime
	p.explosiveness = 1.0
	p.direction = Vector2.UP if up else Vector2.RIGHT
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 1100)
	p.scale_amount_min = size * 0.4
	p.scale_amount_max = size
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([color, Color(color, 0.0)])
	p.color_ramp = ramp
	p.position = pos
	p.z_index = 10
	parent.add_child(p)
	parent.get_tree().create_timer(lifetime + 0.3).timeout.connect(p.queue_free)


static func hit_spark(parent: Node, pos: Vector2, heavy: bool) -> void:
	var color := Color(1.0, 0.45, 0.2) if heavy else Color(1.0, 0.72, 0.25)
	burst(parent, pos, color, 22 if heavy else 12, 700.0 if heavy else 440.0, 0.3, 11.0 if heavy else 6.0)
	shockwave(parent, pos, color, 170.0 if heavy else 95.0, 0.26)
	spark_lines(parent, pos, color, 7 if heavy else 4, 150.0 if heavy else 90.0)


## Expandierender Ring als Aufschlagwelle.
static func shockwave(parent: Node, pos: Vector2, color: Color, radius: float, duration := 0.28) -> void:
	var ring := Line2D.new()
	var points := PackedVector2Array()
	for i in 25:
		var a := TAU * i / 24.0
		points.append(Vector2(cos(a), sin(a) * 0.72))
	ring.points = points
	# Die Breite wird mitskaliert, daher gegenläufig herunterregeln.
	ring.width = 6.0
	ring.default_color = color
	ring.position = pos
	ring.z_index = 11
	ring.scale = Vector2.ONE * 8.0
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ring.material = mat
	parent.add_child(ring)
	var tw := ring.create_tween().set_parallel()
	tw.tween_property(ring, "scale", Vector2.ONE * radius, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(ring, "width", 14.0 / radius, duration)
	tw.tween_property(ring, "modulate:a", 0.0, duration)
	tw.chain().tween_callback(ring.queue_free)


## Kurze, radial nach außen schießende Impact-Striche.
static func spark_lines(parent: Node, pos: Vector2, color: Color, count: int, length: float) -> void:
	var root := Node2D.new()
	root.position = pos
	root.z_index = 12
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	root.material = mat
	parent.add_child(root)
	for i in count:
		var a := randf() * TAU
		var line := Line2D.new()
		var len_i := length * randf_range(0.6, 1.4)
		line.points = PackedVector2Array([Vector2.ZERO, Vector2(cos(a), sin(a)) * len_i])
		line.width = 9.0
		line.default_color = color
		line.position = Vector2(cos(a), sin(a)) * len_i * 0.35
		root.add_child(line)
	var tw := root.create_tween().set_parallel()
	tw.tween_property(root, "scale", Vector2.ONE * 1.9, 0.22).set_ease(Tween.EASE_OUT)
	tw.tween_property(root, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(root.queue_free)


## Sichelförmiger Schlagbogen vor der Figur.
static func slash(parent: Node, pos: Vector2, dir: int, heavy: bool) -> void:
	var reach := 230.0 if heavy else 150.0
	var arc := Line2D.new()
	var points := PackedVector2Array()
	for i in 13:
		var a := lerpf(-1.1, 1.1, i / 12.0)
		points.append(Vector2(cos(a) * reach * dir, sin(a) * reach * 0.85))
	arc.points = points
	arc.width = 34.0 if heavy else 20.0
	arc.width_curve = _taper()
	arc.default_color = Color(1.0, 0.55, 0.3) if heavy else Color(0.85, 0.93, 1.0)
	arc.position = pos
	arc.z_index = 11
	arc.rotation = randf_range(-0.12, 0.12)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	arc.material = mat
	parent.add_child(arc)
	arc.scale = Vector2(0.45, 1.25)
	var dur := 0.2 if heavy else 0.14
	var tw := arc.create_tween().set_parallel()
	tw.tween_property(arc, "scale", Vector2(1.15, 0.8), dur).set_ease(Tween.EASE_OUT)
	tw.tween_property(arc, "modulate:a", 0.0, dur)
	tw.chain().tween_callback(arc.queue_free)


static func _taper() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.1))
	c.add_point(Vector2(0.5, 1.0))
	c.add_point(Vector2(1.0, 0.1))
	return c


static func float_text(parent: Node, pos: Vector2, text: String, color: Color, size := 54) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.1))
	label.add_theme_constant_override("outline_size", 12)
	label.position = pos - Vector2(100, 0)
	label.z_index = 20
	parent.add_child(label)
	var tw := label.create_tween().set_parallel()
	tw.tween_property(label, "position:y", label.position.y - 80.0, 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.4)
	tw.chain().tween_callback(label.queue_free)


static func dust(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, Color(0.85, 0.8, 0.9, 0.7), 6, 160.0, 0.4, 10.0)


## Weicher, additiver Lichtschein für Laternen, Gong und Fackeln.
static func glow(parent: Node2D, pos: Vector2, radius: float, color: Color) -> Sprite2D:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.position = pos
	sp.scale = Vector2.ONE * radius / 64.0
	sp.modulate = color
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sp.material = mat
	parent.add_child(sp)
	return sp
