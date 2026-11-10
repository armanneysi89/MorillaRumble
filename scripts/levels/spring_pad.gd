class_name SpringPad
extends Area2D

## Sprungfeder: schleudert Morilla beim Aufsetzen nach oben. Damit lassen sich Ebenen erreichen,
## die höher liegen als ein normaler Sprung. Nach dem Absprung ist die Feder kurz gespannt.

const TEX_PATH := "res://assets/environments/dojo/props/spring_pad.png"
const HEIGHT := 130.0
const WIDTH := 240.0
const PLACEHOLDER := Color("c25a3a")
## Absprunggeschwindigkeit (negativ = nach oben). Deutlich stärker als ein normaler Sprung.
const LAUNCH_VELOCITY := -2050.0
## Zusätzlicher waagerechter Schub in Blickrichtung (0 = rein senkrecht).
const LAUNCH_PUSH := 260.0
const COOLDOWN := 0.35

var _sprite: Sprite2D
var _arrows: Node2D
var _arrow_t := 0.0
var _cooldown := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(WIDTH, 70)
	cs.shape = shape
	cs.position = Vector2(0, -35)
	add_child(cs)

	_sprite = Sprite2D.new()
	if ResourceLoader.exists(TEX_PATH):
		var tex: Texture2D = load(TEX_PATH)
		_sprite.texture = tex
		_sprite.centered = false
		var s := HEIGHT / tex.get_height()
		_sprite.scale = Vector2(s, s)
		_sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	else:
		var ph := Polygon2D.new()
		ph.polygon = PackedVector2Array([Vector2(-WIDTH * 0.5, 0), Vector2(WIDTH * 0.5, 0),
			Vector2(WIDTH * 0.5, -HEIGHT), Vector2(-WIDTH * 0.5, -HEIGHT)])
		ph.color = PLACEHOLDER
		_sprite.add_child(ph)
	add_child(_sprite)

	# Kein flächiger Schein: Ein großer Glow-Ring um die Feder wirkte wie ein Fremdkörper.
	# Stattdessen pulsieren die Pfeile am Rand der Plattform (siehe _process).

	# Zwei Pfeile über der Plattform: Sie zeigen ohne Glow, wohin die Feder schleudert.
	_arrows = Node2D.new()
	_arrows.z_index = 1
	add_child(_arrows)
	for i in 2:
		var arrow := Polygon2D.new()
		var y := -HEIGHT - 26.0 - i * 26.0
		arrow.polygon = PackedVector2Array([Vector2(-16, y + 14), Vector2(16, y + 14), Vector2(0, y - 10)])
		arrow.color = Color(1.0, 0.82, 0.45, 0.85)
		_arrows.add_child(arrow)

	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	# Die Pfeile wandern nach oben und blenden dabei aus: ein ruhiger, lesbarer Hinweis.
	if _arrows == null:
		return
	_arrow_t += delta
	for i in _arrows.get_child_count():
		var arrow := _arrows.get_child(i) as Polygon2D
		var phase := fposmod(_arrow_t * 1.6 + i * 0.5, 1.0)
		arrow.position.y = -phase * 22.0
		arrow.modulate.a = sin(phase * PI)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)


func _on_body_entered(body: Node2D) -> void:
	if not body is Morilla or _cooldown > 0.0:
		return
	var player := body as Morilla
	# Nur von oben: Wer seitlich dagegen läuft, soll nicht abheben.
	if player.global_position.y > global_position.y + 20.0:
		return
	_cooldown = COOLDOWN
	player.velocity.y = LAUNCH_VELOCITY
	player.velocity.x += player.facing * LAUNCH_PUSH
	player.coyote = 0.0
	player.air_dash_available = true
	player.visual.squash(Vector2(0.78, 1.28))
	Sound.sfx("spring")
	Effects.burst(get_parent(), global_position + Vector2(0, -HEIGHT * 0.5), Color(1.0, 0.8, 0.45), 14, 320.0, 0.4, 7.0)
	Effects.shockwave(get_parent(), global_position + Vector2(0, -HEIGHT * 0.5), Color(1.0, 0.85, 0.5, 0.8), 130.0, 0.22)
	Game.shake(0.1)
	# Die Feder drückt sich zusammen und federt zurück.
	var tw := create_tween()
	tw.tween_property(_sprite, "scale:y", _sprite.scale.y * 0.55, 0.06)
	tw.tween_property(_sprite, "scale:y", _sprite.scale.y, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
