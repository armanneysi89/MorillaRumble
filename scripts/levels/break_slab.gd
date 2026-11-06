class_name BreakSlab
extends StaticBody2D

## Markierte Bruchplatte: versperrt einen vorbereiteten Nebenweg und lässt sich NUR per Suplex zerstören.
## Sie ist ein gültiges Griffziel (can_be_grappled/begin_grapple/apply_suplex_hit), damit der Suplex-Zustand sie
## wie einen Gegner werfen kann. Normale Schläge richten nichts aus – keine freie Zerstörung der Umgebung.

signal broken

const TEX_PATH := "res://assets/environments/quarry/props/break_slab.png"
const HEIGHT := 300.0
const WIDTH := 220.0
const PLACEHOLDER := Color("8a8f98")

var slab_id := "slab"
## Höhe der Platte. Höher als die Sprunghöhe der Spielfigur = unüberwindbare Wand.
var height := HEIGHT
## Größenklasse 2: nur der Suplex (max_size_class 2) darf greifen.
var size_class := 2

var _sprite: Sprite2D
var _shape: CollisionShape2D
var _broken := false
var _bound := false


func _ready() -> void:
	# WORLD: blockiert die Spielerin. ENEMY: damit der Griff-Sensor (Maske ENEMY) die Platte als Ziel findet.
	collision_layer = Layers.WORLD | Layers.ENEMY
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(WIDTH, height)
	_shape.shape = shape
	_shape.position = Vector2(0, -height * 0.5)
	add_child(_shape)

	_sprite = Sprite2D.new()
	if ResourceLoader.exists(TEX_PATH):
		var tex: Texture2D = load(TEX_PATH)
		_sprite.texture = tex
		_sprite.centered = false
		var s := height / tex.get_height()
		_sprite.scale = Vector2(s, s)
		_sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	else:
		var ph := Polygon2D.new()
		ph.polygon = PackedVector2Array([Vector2(-WIDTH * 0.5, 0), Vector2(WIDTH * 0.5, 0), Vector2(WIDTH * 0.5, -height), Vector2(-WIDTH * 0.5, -height)])
		ph.color = PLACEHOLDER
		_sprite.add_child(ph)
	add_child(_sprite)

	# Markierung: pulsierender Hinweis, dass hier der Suplex greift.
	var glow := Effects.glow(self, Vector2(0, -height * 0.5), 260.0, Color(1.0, 0.75, 0.35, 0.35))
	glow.z_index = 1
	var tw := glow.create_tween().set_loops()
	tw.tween_property(glow, "modulate:a", 0.25, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "modulate:a", 0.5, 1.0).set_trans(Tween.TRANS_SINE)

	if Progression.get_flag("slab_" + slab_id):
		_break(false)


# --- Griff-Schnittstelle (siehe PlayerGrapple / Suplex-Zustand) ---

func can_be_grappled(ab: AbilityData) -> bool:
	return not _broken and ab != null and ab.id == "suplex" and size_class <= ab.max_size_class


func is_grappled() -> bool:
	return _bound


func begin_grapple(_by: Node2D) -> void:
	_bound = true


func end_grapple(_submitted: bool) -> void:
	_bound = false


## Der Suplex-Aufprall zerbricht die Platte.
func apply_suplex_hit(_info: HitInfo) -> void:
	_break(true)


func _break(announce: bool) -> void:
	if _broken:
		return
	_broken = true
	Progression.set_flag("slab_" + slab_id)
	_shape.set_deferred("disabled", true)
	collision_layer = 0
	if announce:
		Sound.sfx("heavy_hit")
		Sound.sfx("land", -2.0)
		Game.shake(0.7)
		Game.hit_stop(0.12)
		Effects.shockwave(get_parent(), global_position + Vector2(0, -height * 0.5), Color(1.0, 0.8, 0.45), 320.0, 0.4)
		Effects.burst(get_parent(), global_position + Vector2(0, -height * 0.5), Color(0.7, 0.7, 0.75), 30, 520.0, 0.7, 12.0)
		Effects.float_text(get_parent(), global_position + Vector2(0, -height - 40.0), "WEG FREI!", Color("ffd166"))
		Game.toast("Die Bruchplatte ist zersplittert – der Nebenweg ist offen.")
		broken.emit()
	var tw := create_tween()
	tw.tween_property(_sprite, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func() -> void: _sprite.visible = false)
