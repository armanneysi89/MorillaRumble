class_name PlayerCombat
extends Node

## Angriffe der Spielfigur (Hitbox) und eingehende Treffer (Blocken, Parade, Schaden).

const PARRY_WINDOW := 0.14
const COUNTER_TIME := 0.7
const COUNTER_BONUS := 2.0

var player: Morilla
var blocking := false
var block_time := 0.0
## Nach einer Parade verstärkt der nächste Angriff (Konter).
var counter_window := 0.0

var _shape: RectangleShape2D


func setup(p: Morilla) -> void:
	player = p
	player.hurtbox.hit_received.connect(_on_hit_received)
	player.hitbox.hit_landed.connect(_on_hit_landed)
	_shape = (player.hitbox.get_node("Shape") as CollisionShape2D).shape as RectangleShape2D


func _physics_process(delta: float) -> void:
	counter_window = maxf(counter_window - delta, 0.0)


func begin_attack(data: Dictionary, extra_damage := 0) -> void:
	var info := HitInfo.new()
	info.source = player
	info.direction = player.facing
	var bonus := 1.0
	if counter_window > 0.0:
		bonus = COUNTER_BONUS
		counter_window = 0.0
	var raw := float(int(data["damage"]) + extra_damage) * Progression.damage_multiplier() * bonus
	info.damage = maxi(roundi(raw), 1)
	info.knockback = data["knockback"]
	info.stun = data["stun"]
	info.hit_stop = data["hit_stop"]
	info.shake = data["shake"]
	info.heavy = data["heavy"] or bonus > 1.0
	info.charge = clampf(float(data.get("charge", 0.0)), 0.0, 1.0)
	var reach: Vector2 = data["reach"]
	var off: Vector2 = data["offset"]
	_shape.size = reach
	player.hitbox.position = Vector2(off.x * player.facing, off.y)
	player.hitbox.activate(info)


func end_attack() -> void:
	player.hitbox.deactivate()


func _on_hit_landed(hurtbox: Hurtbox, info: HitInfo) -> void:
	var parent := player.get_parent()
	var pos := hurtbox.global_position + Vector2(0, -20)
	Effects.hit_spark(parent, pos, info.heavy, info.charge)
	if info.heavy:
		Effects.slash(parent, pos, player.facing, true, 270.0 + 170.0 * info.charge)
		var label := "KO!" if info.damage >= 4 else "BAM!"
		if info.charge >= 0.9:
			label = "MAHNSCHLAG!" if info.damage >= 4 else "HART!"
		Effects.float_text(parent, hurtbox.global_position + Vector2(0, -260), label, Color("ff7a45"))
	Sound.sfx("heavy_hit" if info.heavy else "hit")
	Game.hit_stop(info.hit_stop)
	Game.shake(info.shake)
	# Der Treffer schiebt Morilla leicht zurück: Der Schlag bekommt Gewicht.
	player.velocity.x -= player.facing * (170.0 if info.heavy else 70.0) * (1.0 + info.charge * 0.5)


func _on_hit_received(info: HitInfo) -> void:
	var health := player.health
	if health.is_dead():
		return
	# Unverwundbarkeit zuerst: Während der i-frames darf ein Treffer weder Schaden noch Parade auslösen.
	if health.is_invulnerable():
		return
	if blocking and player.facing == -info.direction and not info.unblockable:
		_on_blocked(info)
		return
	player.last_hit = info
	if health.take_damage(info.damage) and not health.is_dead():
		player.machine.change(&"hurt", {"info": info})


func _on_blocked(info: HitInfo) -> void:
	var parent := player.get_parent()
	var pos := player.global_position + Vector2(player.facing * 60.0, -100.0)
	if block_time <= PARRY_WINDOW:
		counter_window = COUNTER_TIME
		if is_instance_valid(info.source) and info.source.has_method("on_parried"):
			info.source.on_parried()
		Sound.sfx("parry")
		Effects.hit_spark(parent, pos, true)
		Effects.float_text(parent, player.global_position + Vector2(0, -230), "PARADE!", Color("ffd166"))
		Game.hit_stop(0.1)
		Game.shake(0.3)
	else:
		Sound.sfx("block")
		Effects.burst(parent, pos, Color(0.8, 0.85, 1.0), 6, 260.0, 0.25, 5.0)
		player.velocity.x = -player.facing * 260.0
		Game.shake(0.1)
		# Treffer-Pose der Deckung: Frame 2 zeigt, dass der Block die Last aufnimmt.
		player.visual.show_frame(&"block", 1)
