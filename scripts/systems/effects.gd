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
	burst(parent, pos, Color(1.0, 0.72, 0.25) if not heavy else Color(1.0, 0.45, 0.2), 16 if heavy else 9, 520.0 if heavy else 380.0, 0.3, 9.0 if heavy else 6.0)


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
