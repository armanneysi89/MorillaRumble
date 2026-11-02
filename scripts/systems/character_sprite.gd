class_name CharacterSprite
extends AnimatedSprite2D

## Zeigt eine Figur aus nummerierten Frames (CharacterSpecs). Kümmert sich um Ausrichtung am Fußpunkt, Blickrichtung,
## Squash & Stretch, Treffer-Blitz, Afterimages und die Gürtelfarbe.

signal footstep

const SHADER: Shader = preload("res://assets/shaders/belt_key.gdshader")

var spec: Dictionary = {}
var base_scale := 0.5

var _faces := 1
var _squash := Vector2.ONE
var _mat: ShaderMaterial
var _breathe_t := 0.0
var _lean := 0.0
var _body: CharacterBody2D


func setup(spec_key: String, belt_key := false) -> void:
	spec = CharacterSpecs.get_spec(spec_key)
	_body = get_parent() as CharacterBody2D
	sprite_frames = SpriteLibrary.build(spec)
	var canvas: Vector2 = spec["canvas"]
	centered = true
	offset = Vector2(0.0, canvas.y * 0.5 - float(spec["anchor_y"]))
	base_scale = spec["scale"]
	_faces = spec["faces"]
	scale = Vector2.ONE * base_scale
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("key_enabled", belt_key)
	material = _mat
	_mat.set_shader_parameter("belt_color", Color.WHITE)
	frame_changed.connect(_on_frame_changed)
	play_anim(&"idle")


## dir ist die Blickrichtung im Spiel; der Sprite blickt von Haus aus in Richtung spec.faces.
func face(dir: int) -> void:
	flip_h = dir != _faces


func has_anim(anim: StringName) -> bool:
	return sprite_frames != null and sprite_frames.has_animation(anim)


func play_anim(anim: StringName, restart := false) -> void:
	if not has_anim(anim):
		return
	if animation == anim and not restart:
		return
	speed_scale = 1.0
	play(anim)


## Spielt die Animation so, dass sie genau `duration` Sekunden dauert.
func play_timed(anim: StringName, duration: float) -> void:
	if not has_anim(anim):
		return
	var count := sprite_frames.get_frame_count(anim)
	var fps := sprite_frames.get_animation_speed(anim)
	animation = anim
	speed_scale = float(count) / maxf(fps * duration, 0.01)
	play(anim)


func show_frame(anim: StringName, index: int) -> void:
	if not has_anim(anim):
		return
	animation = anim
	speed_scale = 1.0
	stop()
	frame = clampi(index, 0, sprite_frames.get_frame_count(anim) - 1)


func squash(amount: Vector2) -> void:
	_squash = amount


func flash(duration := 0.12, color := Color.WHITE) -> void:
	_mat.set_shader_parameter("flash_color", color)
	_mat.set_shader_parameter("flash", 1.0)
	var tw := create_tween()
	tw.tween_property(_mat, "shader_parameter/flash", 0.0, duration)


func set_tint(color: Color) -> void:
	modulate = color


func spawn_ghost(color := Color(1.0, 0.8, 0.4, 0.55)) -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite_frames.get_frame_texture(animation, frame)
	ghost.centered = true
	ghost.offset = offset
	ghost.flip_h = flip_h
	ghost.global_position = global_position
	ghost.scale = scale
	ghost.modulate = color
	ghost.z_index = z_index - 1
	get_tree().current_scene.add_child(ghost)
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tw.tween_callback(ghost.queue_free)


func _process(delta: float) -> void:
	_squash = _squash.lerp(Vector2.ONE, minf(delta * 9.0, 1.0))
	_breathe_t += delta
	var breathe := Vector2.ONE
	var sway := 0.0
	if animation == &"idle":
		var s := sin(_breathe_t * 2.2)
		breathe = Vector2(1.0 - s * 0.012, 1.0 + s * 0.026)
		sway = sin(_breathe_t * 1.1) * 0.008
	scale = Vector2.ONE * base_scale * _squash * breathe
	var want_lean := 0.0
	if _body:
		want_lean = clampf(_body.velocity.x / 1100.0, -1.0, 1.0) * 0.1
		if not _body.is_on_floor():
			want_lean *= 0.5
	_lean = lerpf(_lean, want_lean, minf(delta * 7.0, 1.0))
	rotation = _lean + sway


func _on_frame_changed() -> void:
	if (animation == &"walk" or animation == &"run") and (frame == 0 or frame == 4):
		footstep.emit()
