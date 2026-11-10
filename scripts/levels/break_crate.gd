class_name BreakCrate
extends StaticBody2D

## Zerbrechliche Holzkiste: blockiert den Weg, bis Morilla sie zerschlägt.
## Sie ist ein gültiges Trefferziel (Hurtbox auf ENEMY_HURT), damit Schläge, Suplex-Aufprall und
## Geister sie zerstören. Beim Zerbrechen fällt je nach Inhalt ein Kristall oder ein Heiltee heraus.

signal broken

const TEX_PATH := "res://assets/environments/dojo/props/crate.png"
const SIZE := Vector2(150, 150)
const PLACEHOLDER := Color("8a6234")
## Inhalt: "" (nichts), "gem" oder "tea".
const CONTENTS := ["", "gem", "gem", "tea"]

var crate_id := "crate"
## Inhalt der Kiste ("" = leer). Leer heißt: nur Weg frei.
var content := ""
## Größenklasse für Griffe: Kisten sind klein und lassen sich auch per Kimura zerschlagen.
var size_class := 0

var _sprite: Sprite2D
var _shape: CollisionShape2D
var _broken := false
var _bound := false


func _ready() -> void:
	collision_layer = Layers.WORLD | Layers.ENEMY
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	_shape.shape = shape
	_shape.position = Vector2(0, -SIZE.y * 0.5)
	add_child(_shape)

	_sprite = Sprite2D.new()
	if ResourceLoader.exists(TEX_PATH):
		var tex: Texture2D = load(TEX_PATH)
		_sprite.texture = tex
		_sprite.centered = false
		var s := SIZE.y / tex.get_height()
		_sprite.scale = Vector2(s, s)
		_sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
		# Die Kiste steht im dunklen Dojo; ein warmer Stich hebt sie vom Boden ab.
		_sprite.modulate = Color(1.35, 1.2, 1.05)
	else:
		var ph := Polygon2D.new()
		ph.polygon = PackedVector2Array([Vector2(-SIZE.x * 0.5, 0), Vector2(SIZE.x * 0.5, 0),
			Vector2(SIZE.x * 0.5, -SIZE.y), Vector2(-SIZE.x * 0.5, -SIZE.y)])
		ph.color = PLACEHOLDER
		_sprite.add_child(ph)
	add_child(_sprite)

	var hurtbox := Hurtbox.new()
	hurtbox.collision_layer = Layers.ENEMY_HURT
	hurtbox.collision_mask = 0
	var cs := CollisionShape2D.new()
	var hshape := RectangleShape2D.new()
	hshape.size = SIZE
	cs.shape = hshape
	cs.position = Vector2(0, -SIZE.y * 0.5)
	hurtbox.add_child(cs)
	add_child(hurtbox)
	hurtbox.hit_received.connect(_on_hit)

	if Progression.get_flag("crate_" + crate_id):
		_break(false)


# --- Griff-Schnittstelle (siehe PlayerGrapple / Suplex-Zustand) ---

func can_be_grappled(ab: AbilityData) -> bool:
	return not _broken and ab != null and size_class <= ab.max_size_class


func is_grappled() -> bool:
	return _bound


func begin_grapple(_by: Node2D) -> void:
	_bound = true


func end_grapple(_submitted: bool) -> void:
	_bound = false


func apply_suplex_hit(_info: HitInfo) -> void:
	_break(true)


func _on_hit(info: HitInfo) -> void:
	# Jeder Treffer zerbricht die Kiste; schwere Schläge wirken nur lauter.
	_break(true, info.heavy)


func _break(announce: bool, heavy := false) -> void:
	if _broken:
		return
	_broken = true
	Progression.set_flag("crate_" + crate_id)
	_shape.set_deferred("disabled", true)
	collision_layer = 0
	if announce:
		Sound.sfx("crate_break")
		Game.shake(0.22 if heavy else 0.12)
		Game.hit_stop(0.05)
		var center := global_position + Vector2(0, -SIZE.y * 0.5)
		Effects.burst(get_parent(), center, Color(0.72, 0.52, 0.3), 22, 420.0, 0.6, 10.0)
		Effects.burst(get_parent(), center, Color(0.95, 0.85, 0.6), 10, 260.0, 0.45, 6.0)
		Effects.shockwave(get_parent(), center, Color(1.0, 0.85, 0.55, 0.8), 150.0, 0.25)
		_drop_content()
	var tw := create_tween().set_parallel()
	tw.tween_property(_sprite, "scale", _sprite.scale * Vector2(1.25, 0.55), 0.18)
	tw.tween_property(_sprite, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(func() -> void: _sprite.visible = false)
	broken.emit()


## Lässt den Inhalt herausfallen. Der Kristall/Heiltee ist ein normales Sammelobjekt und
## verschwindet wie alle anderen dauerhaft (Weltzustand über die Pickup-ID).
func _drop_content() -> void:
	if content == "":
		return
	var pickup := ScrollPickup.new()
	pickup.pickup_id = "crate_%s_%s" % [crate_id, content]
	pickup.kind = "tea" if content == "tea" else "gem"
	pickup.position = global_position + Vector2(0, -SIZE.y * 0.5)
	get_parent().add_child(pickup)
