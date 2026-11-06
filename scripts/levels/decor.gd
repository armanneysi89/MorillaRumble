class_name Decor
extends Node2D

## Reines Dekor-Sprite am Fußpunkt (Säulen, Laternen, Bäume ...). Laternen erhalten einen pendelnden Lichtschein.

## Ordner, in denen nach dem Sprite gesucht wird (zuerst der Steinbruch, dann der Bambushain, dann das Dojo).
const PATHS: Array[String] = [
	"res://assets/environments/quarry/props/%s.png",
	"res://assets/environments/bamboo/props/%s.png",
	"res://assets/environments/dojo/props/%s.png",
]
# Art -> [Lichtfarbe, Radius, Höhenanteil des Lichts]
const GLOWS := {
	"lantern": [Color(1.0, 0.6, 0.25, 0.5), 260.0, 0.5],
	"gong": [Color(1.0, 0.7, 0.3, 0.3), 220.0, 0.55],
	"banner": [Color(1.0, 0.3, 0.2, 0.08), 200.0, 0.5],
	"stone_lantern": [Color(1.0, 0.6, 0.25, 0.45), 240.0, 0.6],
	"shrine": [Color(1.0, 0.5, 0.25, 0.22), 380.0, 0.35],
	"quarry_lantern": [Color(1.0, 0.62, 0.28, 0.5), 280.0, 0.55],
	"quarry_banner": [Color(1.0, 0.35, 0.2, 0.1), 220.0, 0.5],
}

var kind := ""
var height := 200.0
var flip := false


func _ready() -> void:
	var path := ""
	for pattern in PATHS:
		if ResourceLoader.exists(pattern % kind):
			path = pattern % kind
			break
	if path == "":
		return
	var tex: Texture2D = load(path)
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.centered = false
	sp.flip_h = flip
	var s := height / tex.get_height()
	sp.scale = Vector2(s, s)
	sp.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	add_child(sp)
	if GLOWS.has(kind):
		var def: Array = GLOWS[kind]
		var glow := Effects.glow(self, Vector2(0, -height * float(def[2])), def[1], def[0])
		glow.z_index = 1
		var tw := glow.create_tween().set_loops()
		var base := glow.modulate
		tw.tween_property(glow, "modulate", Color(base, base.a * 0.7), randf_range(0.9, 1.6)).set_trans(Tween.TRANS_SINE)
		tw.tween_property(glow, "modulate", base, randf_range(0.9, 1.6)).set_trans(Tween.TRANS_SINE)
	if kind == "lantern":
		rotation = 0.0
		var sway := create_tween().set_loops()
		sway.tween_property(self, "rotation", 0.03, randf_range(1.8, 2.6)).set_trans(Tween.TRANS_SINE)
		sway.tween_property(self, "rotation", -0.03, randf_range(1.8, 2.6)).set_trans(Tween.TRANS_SINE)
