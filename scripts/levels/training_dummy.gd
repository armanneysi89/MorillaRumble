class_name TrainingDummy
extends Node2D

## Übungspuppe: reagiert auf Treffer, ist aber unzerstörbar. Dient dem Angriffs-Tutorial.

const TEX_PATH := "res://assets/environments/dojo/props/dummy.png"
const HEIGHT := 230.0

var _sprite: Sprite2D
var _hurtbox: Hurtbox
var _tween: Tween


func _ready() -> void:
	_sprite = Sprite2D.new()
	if ResourceLoader.exists(TEX_PATH):
		var tex: Texture2D = load(TEX_PATH)
		_sprite.texture = tex
		_sprite.centered = false
		var s := HEIGHT / tex.get_height()
		_sprite.scale = Vector2(s, s)
		_sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	add_child(_sprite)

	_hurtbox = Hurtbox.new()
	_hurtbox.collision_layer = Layers.ENEMY_HURT
	_hurtbox.collision_mask = 0
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(90, HEIGHT)
	cs.shape = shape
	cs.position = Vector2(0, -HEIGHT * 0.5)
	_hurtbox.add_child(cs)
	add_child(_hurtbox)
	_hurtbox.hit_received.connect(_on_hit)


func _on_hit(info: HitInfo) -> void:
	Effects.float_text(get_parent(), global_position + Vector2(0, -HEIGHT - 30.0), str(info.damage), Color("ffd166"), 44)
	if _tween and _tween.is_valid():
		_tween.kill()
	_sprite.position = Vector2.ZERO
	_tween = create_tween()
	var lean := 0.12 * info.direction * (2.0 if info.heavy else 1.0)
	_tween.tween_property(self, "rotation", lean, 0.06)
	_tween.tween_property(self, "rotation", -lean * 0.5, 0.12).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
