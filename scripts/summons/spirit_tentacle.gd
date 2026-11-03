class_name SpiritTentacle
extends Node2D

## Peitschender Tentakel des Oktopus-Geists. Der Ursprung liegt in (0, 0); das Ziel wird in Weltkoordinaten verfolgt.
## `extend` (0..1) bestimmt, wie weit der Tentakel ausgefahren ist; im gespannten Zustand bleibt nur ein leichtes Zittern.

const SEGMENTS := 18
const BODY_WIDTH := 46.0
const GLOW_WIDTH := 20.0

var target: Node2D
var target_offset := Vector2(0.0, -100.0)
var extend := 0.0

var _tip := Vector2(300.0, 0.0)
var _body: Line2D
var _glow: Line2D
var _phase := randf() * TAU
var _t := 0.0


func _ready() -> void:
	var taper := Curve.new()
	taper.add_point(Vector2(0.0, 1.0))
	taper.add_point(Vector2(1.0, 0.22))
	_body = _make_line(BODY_WIDTH, taper)
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(0.2, 0.08, 0.38), Color(0.5, 0.2, 0.75)])
	_body.gradient = ramp
	_glow = _make_line(GLOW_WIDTH, taper)
	_glow.default_color = Color(1.0, 0.3, 0.38, 0.8)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat


func _make_line(width: float, taper: Curve) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.width_curve = taper
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(line)
	return line


func _process(delta: float) -> void:
	_t += delta
	if is_instance_valid(target):
		_tip = get_parent().to_local(target.global_position + target_offset) - position
	var dir := _tip.normalized()
	var normal := dir.orthogonal()
	var length := _tip.length()
	var reach := clampf(extend, 0.0, 1.0)
	var points := PackedVector2Array()
	for i in SEGMENTS + 1:
		var s := float(i) / SEGMENTS
		var wave := sin(s * TAU * 1.25 + _phase + _t * 9.0) * s * (14.0 + (1.0 - reach) * 80.0)
		points.append(dir * length * s * reach + normal * wave)
	_body.points = points
	_glow.points = points
