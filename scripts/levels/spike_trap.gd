class_name SpikeTrap
extends Area2D

## Stachelfalle: Wer hineinläuft, verliert ein Leben und wird zurückgeschleudert.
## Die Falle ist bewusst kein Gegner – sie lässt sich nicht besiegen, nur umgehen (springen, dash, Feder).

const TEX_PATH := "res://assets/environments/dojo/props/spike_trap.png"
const HEIGHT := 110.0
const WIDTH := 260.0
const PLACEHOLDER := Color("6a6f78")
const DAMAGE := 1
const KNOCKBACK := Vector2(520.0, -620.0)
## Nach einem Treffer kurz unempfindlich, damit man nicht mehrfach Schaden nimmt.
const RETRIGGER := 0.8

var _cooldown := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(WIDTH, HEIGHT)
	cs.shape = shape
	cs.position = Vector2(0, -HEIGHT * 0.5)
	add_child(cs)

	var sp := Sprite2D.new()
	if ResourceLoader.exists(TEX_PATH):
		var tex: Texture2D = load(TEX_PATH)
		sp.texture = tex
		sp.centered = false
		var s := HEIGHT / tex.get_height()
		sp.scale = Vector2(s, s)
		sp.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
		# Die Stacheln liegen im dunklen Boden; ein leichter Rotstich macht sie als Gefahr lesbar.
		sp.modulate = Color(1.25, 0.95, 0.95)
	else:
		var ph := Polygon2D.new()
		var pts := PackedVector2Array()
		var teeth := 7
		for i in teeth * 2 + 1:
			var x := -WIDTH * 0.5 + WIDTH * i / float(teeth * 2)
			pts.append(Vector2(x, 0.0 if i % 2 == 0 else -HEIGHT))
		pts.append(Vector2(WIDTH * 0.5, 0))
		ph.polygon = pts
		ph.color = PLACEHOLDER
		sp.add_child(ph)
	add_child(sp)

	# Warnlicht: Ein pulsierender roter Schein markiert die Falle schon von weitem.
	var glow := Effects.glow(self, Vector2(0, -HEIGHT * 0.4), WIDTH * 0.75, Color(1.0, 0.25, 0.2, 0.28))
	glow.z_index = -1
	var tw := glow.create_tween().set_loops()
	tw.tween_property(glow, "modulate:a", 0.55, 1.1).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "modulate:a", 0.28, 1.1).set_trans(Tween.TRANS_SINE)

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)


func _on_body_entered(body: Node2D) -> void:
	if not body is Morilla or _cooldown > 0.0:
		return
	var player := body as Morilla
	if player.health.is_invulnerable() or player.health.is_dead():
		return
	_cooldown = RETRIGGER
	var dir := 1 if player.global_position.x >= global_position.x else -1
	player.velocity = Vector2(dir * KNOCKBACK.x, KNOCKBACK.y)
	player.visual.squash(Vector2(1.2, 0.82))
	Sound.sfx("spike")
	Sound.sfx("hurt", -4.0)
	Game.shake(0.35)
	Game.hit_stop(0.06)
	Effects.burst(get_parent(), global_position + Vector2(0, -HEIGHT * 0.5), Color(0.85, 0.3, 0.25), 16, 380.0, 0.45, 8.0)
	if player.health.take_damage(DAMAGE) and not player.health.is_dead():
		player.machine.change(&"hurt", {"info": _make_info(dir)})


func _make_info(dir: int) -> HitInfo:
	var info := HitInfo.new()
	info.damage = DAMAGE
	info.direction = dir
	info.knockback = KNOCKBACK
	info.stun = 0.3
	info.shake = 0.3
	return info
