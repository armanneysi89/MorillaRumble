class_name ScrollPickup
extends Area2D

## Sammelobjekt: Schriftrolle (dauerhaft +1 maximales Leben) oder Heiltee (+2 Leben). Einmal eingesammelt, bleibt es weg (Weltzustand).

const TEX_PATH := "res://assets/environments/dojo/props/scroll.png"
const HEIGHT := 90.0
const PLACEHOLDER := Color("e8c872")
const TEA_TEX_PATH := "res://assets/environments/bamboo/props/tea_jar.png"
const TEA_HEAL := 2

var pickup_id := ""
var upgrade_key := "max_hp"
## "scroll" oder "tea".
var kind := "scroll"

var _holder: Node2D


func _ready() -> void:
	if Progression.get_flag("pickup_" + pickup_id):
		queue_free()
		return
	var tea := kind == "tea"
	var tex_path := TEA_TEX_PATH if tea else TEX_PATH
	var glow_color := Color(0.5, 1.0, 0.6, 0.45) if tea else Color(1.0, 0.85, 0.4, 0.45)
	collision_layer = 0
	collision_mask = Layers.PLAYER
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 60.0
	cs.shape = shape
	add_child(cs)
	_holder = Node2D.new()
	add_child(_holder)
	if ResourceLoader.exists(tex_path):
		var tex: Texture2D = load(tex_path)
		var sp := Sprite2D.new()
		sp.texture = tex
		var s := (80.0 if tea else HEIGHT) / tex.get_height()
		sp.scale = Vector2(s, s)
		_holder.add_child(sp)
	else:
		var ph := Polygon2D.new()
		ph.polygon = PackedVector2Array([Vector2(-14, -40), Vector2(14, -40), Vector2(14, 40), Vector2(-14, 40)])
		ph.color = Color("7be0a0") if tea else PLACEHOLDER
		_holder.add_child(ph)
	Effects.glow(self, Vector2.ZERO, 120.0, glow_color)
	var bob := create_tween().set_loops()
	bob.tween_property(_holder, "position:y", -10.0, 1.0).set_trans(Tween.TRANS_SINE)
	bob.tween_property(_holder, "position:y", 10.0, 1.0).set_trans(Tween.TRANS_SINE)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body is Morilla:
		return
	var player := body as Morilla
	Progression.set_flag("pickup_" + pickup_id)
	if kind == "tea":
		player.health.heal(TEA_HEAL)
		Sound.sfx("learn", -8.0, 1.4)
		Game.toast("Heiltee: +%d Leben" % TEA_HEAL)
		Effects.burst(get_parent(), global_position, Color(0.5, 1.0, 0.6), 14, 260.0, 0.6, 7.0)
		queue_free()
		return
	Progression.add_upgrade(upgrade_key)
	player.health.set_max(Progression.max_hp())
	player.health.heal(1)
	Sound.sfx("scroll")
	Game.toast("Schriftrolle gefunden: +1 Leben")
	Effects.burst(get_parent(), global_position, Color(1.0, 0.85, 0.4), 16, 300.0, 0.6, 7.0)
	queue_free()
