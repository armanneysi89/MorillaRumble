class_name LevelBackground
extends CanvasLayer

## Parallax-Hintergrund in Bildschirmkoordinaten: ferne Halle, wandernde Säulen/Banner und Blütenblätter im Vordergrund.
## Alles ist optional – fehlen Texturen, bleibt ein Farbverlauf im Morilla-Nachtton.

const PILLAR_PATH := "res://assets/environments/dojo/props/pillar.png"

var level_width := 8000.0
var far_path := "res://assets/environments/dojo/bg_dojo.png"
var pillar_path := PILLAR_PATH
var pillar_tint := Color(0.45, 0.42, 0.6, 0.9)
var sky_top := Color("0b0a22")
var sky_bottom := Color("2a1745")
var petals := true
var petal_color := Color(1.0, 0.72, 0.82, 0.85)
var fireflies := false

var _view := Vector2.ZERO
var _far: Sprite2D
var _far_size := Vector2.ZERO
var _pillars: Array[Sprite2D] = []
var _pillar_spacing := 620.0
var _petal_layer: CanvasLayer


func _ready() -> void:
	layer = -10
	_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_pillars.clear()
	if _petal_layer and is_instance_valid(_petal_layer):
		_petal_layer.queue_free()
	_view = get_viewport().get_visible_rect().size
	_add_gradient()

	if ResourceLoader.exists(far_path):
		var tex: Texture2D = load(far_path)
		_far = Sprite2D.new()
		_far.texture = tex
		_far.centered = false
		var s := maxf((_view.y * 1.2) / tex.get_height(), (_view.x * 1.15) / tex.get_width())
		_far.scale = Vector2(s, s)
		_far_size = tex.get_size() * s
		add_child(_far)

	if ResourceLoader.exists(pillar_path):
		var tex: Texture2D = load(pillar_path)
		var count := int(ceil(_view.x / _pillar_spacing)) + 2
		var h := _view.y * 0.85
		var s := h / tex.get_height()
		for i in count:
			var sp := Sprite2D.new()
			sp.texture = tex
			sp.centered = false
			sp.scale = Vector2(s, s)
			sp.flip_h = i % 2 == 1
			sp.modulate = pillar_tint
			sp.position.y = _view.y * 0.08
			sp.set_meta("base", float(i) * _pillar_spacing)
			add_child(sp)
			_pillars.append(sp)

	if petals:
		_petal_layer = CanvasLayer.new()
		_petal_layer.layer = 2
		get_parent().add_child.call_deferred(_petal_layer)
		_petal_layer.add_child(_make_petals())
		if fireflies:
			_petal_layer.add_child(_make_fireflies())


func _add_gradient() -> void:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([sky_top, sky_bottom])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 256
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.size = _view
	add_child(rect)


func _make_petals() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 36
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(_view.x * 0.6, 10)
	p.position = Vector2(_view.x * 0.5, -30)
	p.direction = Vector2(0.3, 1.0)
	p.spread = 25.0
	p.initial_velocity_min = 50.0
	p.initial_velocity_max = 110.0
	p.gravity = Vector2(25, 15)
	p.angular_velocity_min = -90.0
	p.angular_velocity_max = 90.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 7.0
	p.color = petal_color
	return p


## Langsam schwebende, leuchtende Punkte (additiv).
func _make_fireflies() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 26
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(_view.x * 0.55, _view.y * 0.4)
	p.position = Vector2(_view.x * 0.5, _view.y * 0.6)
	p.direction = Vector2(0.0, -1.0)
	p.spread = 180.0
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 40.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	ramp.colors = PackedColorArray([Color(0.8, 1.0, 0.4, 0.0), Color(0.8, 1.0, 0.4, 0.9), Color(0.8, 1.0, 0.4, 0.9), Color(0.8, 1.0, 0.4, 0.0)])
	p.color_ramp = ramp
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	return p


func _process(_delta: float) -> void:
	var size := get_viewport().get_visible_rect().size
	if size != _view:
		_build()
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var c := cam.get_screen_center_position()
	if _far:
		var span := maxf(_far_size.x - _view.x, 0.0)
		var tx := clampf(c.x / maxf(level_width, 1.0), 0.0, 1.0)
		_far.position = Vector2(-span * tx, -_view.y * 0.1 - c.y * 0.04)
	var total := _pillar_spacing * _pillars.size()
	for sp in _pillars:
		var base: float = sp.get_meta("base")
		sp.position.x = fposmod(base - c.x * 0.35, total) - _pillar_spacing
