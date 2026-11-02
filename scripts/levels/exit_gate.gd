class_name ExitGate
extends Area2D

## Levelausgang. Bleibt verschlossen (gedimmt), bis open = true gesetzt wird.

signal reached

const TEX_PATH := "res://assets/environments/dojo/props/gate.png"
const HEIGHT := 520.0

var open := false:
	set(value):
		open = value
		_refresh()

var _sprite: Sprite2D
var _glow: Sprite2D
var _used := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(160, 400)
	cs.shape = shape
	cs.position = Vector2(0, -200)
	add_child(cs)
	_sprite = Sprite2D.new()
	if ResourceLoader.exists(TEX_PATH):
		var tex: Texture2D = load(TEX_PATH)
		_sprite.texture = tex
		var s := HEIGHT / tex.get_height()
		_sprite.scale = Vector2(s, s)
		_sprite.offset = Vector2(0, -tex.get_height() * 0.5)
	else:
		var ph := Polygon2D.new()
		ph.polygon = PackedVector2Array([Vector2(-100, 0), Vector2(100, 0), Vector2(100, -HEIGHT), Vector2(-100, -HEIGHT)])
		ph.color = Color("7a1c1c")
		add_child(ph)
	add_child(_sprite)
	_glow = Effects.glow(self, Vector2(0, -HEIGHT * 0.4), 320.0, Color(0.6, 0.85, 1.0, 0.0))
	_glow.z_index = 1
	body_entered.connect(_on_body_entered)
	_refresh()


func _refresh() -> void:
	if _sprite == null:
		return
	_sprite.modulate = Color.WHITE if open else Color(0.45, 0.45, 0.6)
	_glow.modulate.a = 0.5 if open else 0.0


func _on_body_entered(body: Node2D) -> void:
	if open and not _used and body is Morilla:
		_used = true
		reached.emit()
