class_name SaunaHouse
extends Area2D

## Japanische Holzsauna am Rand des Trainingsplatzes. Die Tür ist ein Interaktionspunkt (E); solange noch Gegner
## in der Nähe sind, bleibt sie zu, damit die Begegnung in einem sicheren Bereich stattfindet.

signal entered(player: Morilla)

const TEX_PATH := "res://assets/environments/bamboo/props/sauna_house.png"
const HEIGHT := 820.0
## Gegner innerhalb dieser Entfernung (x) halten die Tür verschlossen.
const SAFE_RADIUS := 1300.0
const DOOR_OFFSET := Vector2(0, -150)

## Nach der Begegnung (oder in älteren Spielständen) lässt sich die Tür nicht mehr benutzen.
var done := false


func _ready() -> void:
	collision_layer = Layers.INTERACT
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(190, 300)
	cs.shape = shape
	cs.position = DOOR_OFFSET
	add_child(cs)
	z_index = -2
	if ResourceLoader.exists(TEX_PATH):
		var tex: Texture2D = load(TEX_PATH)
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = false
		var s := HEIGHT / tex.get_height()
		sp.scale = Vector2(s, s)
		sp.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
		add_child(sp)
	var glow := Effects.glow(self, Vector2(0, -HEIGHT * 0.36), 380.0, Color(1.0, 0.6, 0.25, 0.4))
	glow.z_index = 1
	var tw := glow.create_tween().set_loops()
	tw.tween_property(glow, "modulate:a", 0.28, 1.3).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "modulate:a", 0.4, 1.1).set_trans(Tween.TRANS_SINE)
	_add_steam()


func can_interact() -> bool:
	return not done


func get_prompt() -> String:
	return "E: Sauna betreten" if _is_safe() else "Erst die Gegner in der Nähe besiegen"


func interact(player: Morilla) -> void:
	if done:
		return
	if not _is_safe():
		Game.toast("Hier sind noch Gegner unterwegs. Erst besiegen, dann in Ruhe saunieren.")
		return
	entered.emit(player)


func _is_safe() -> bool:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy.state != Enemy.S.DEAD and absf(enemy.global_position.x - global_position.x) < SAFE_RADIUS:
			return false
	return true


## Dezenter Dampf aus dem Schornstein.
func _add_steam() -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(HEIGHT * 0.18, -HEIGHT * 0.86)
	p.amount = 10
	p.lifetime = 4.0
	p.direction = Vector2.UP
	p.spread = 14.0
	p.initial_velocity_min = 24.0
	p.initial_velocity_max = 44.0
	p.gravity = Vector2(14, 0)
	p.scale_amount_min = 14.0
	p.scale_amount_max = 30.0
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(0.9, 0.92, 1.0, 0.0), Color(0.9, 0.92, 1.0, 0.22), Color(0.9, 0.92, 1.0, 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	p.color_ramp = ramp
	p.z_index = 1
	add_child(p)
