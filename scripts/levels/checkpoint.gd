class_name Checkpoint
extends Area2D

## Gong-Checkpoint: Berührung speichert die Position, heilt und merkt sich den Checkpoint im Fortschritt.

const TEX_PATH := "res://assets/environments/dojo/props/gong.png"
const HEIGHT := 260.0
const PLACEHOLDER := Color("8a5a2b")

var level_id := ""
var checkpoint_id := ""

var _glow: Sprite2D
var _active := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(240, 300)
	cs.shape = shape
	cs.position = Vector2(0, -150)
	add_child(cs)

	if ResourceLoader.exists(TEX_PATH):
		var tex: Texture2D = load(TEX_PATH)
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = false
		var s := HEIGHT / tex.get_height()
		sp.scale = Vector2(s, s)
		sp.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
		sp.z_index = -1
		add_child(sp)
	else:
		var ph := Polygon2D.new()
		ph.polygon = PackedVector2Array([Vector2(-50, 0), Vector2(50, 0), Vector2(50, -HEIGHT), Vector2(-50, -HEIGHT)])
		ph.color = PLACEHOLDER
		add_child(ph)

	_glow = Effects.glow(self, Vector2(0, -HEIGHT * 0.5), 260.0, Color(1.0, 0.65, 0.25, 0.0))
	_glow.z_index = 1
	_active = Progression.checkpoint_for(level_id) == checkpoint_id
	if _active:
		_glow.modulate.a = 0.45
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body is Morilla:
		return
	var player := body as Morilla
	var first := not _active
	_active = true
	Progression.discover_checkpoint(level_id, checkpoint_id)
	player.spawn_point = global_position
	player.health.heal(player.health.max_hp)
	if first:
		# Gong plus aufsteigender Glockenklang: Der Checkpoint soll sich nach Fortschritt anfühlen.
		Sound.sfx("gong")
		Sound.sfx("checkpoint", -6.0)
		Game.toast("Checkpoint erreicht")
		Game.shake(0.2)
		var tw := create_tween()
		tw.tween_property(_glow, "modulate:a", 0.9, 0.2)
		tw.tween_property(_glow, "modulate:a", 0.45, 1.0)
