class_name Ironback
extends Enemy

## Boss „Eisenrücken": trägt einen schweren steinernen Trainingsrahmen. Seine schweren Angriffe und sein Ansturm
## erzeugen nach einem Fehlschlag ein deutlich sichtbares Fenster für den Suplex (Taumel-Phase).
## Baut auf dem bestehenden Gegner-System auf (Enemy) und ergänzt nur den Ansturm und die Boss-Reaktionen.

signal defeated

enum B { IDLE, CHASE, WINDUP, ATTACK, CHARGE, CHARGE_RECOVER, STAGGER, THROWN, DEAD }

const CHARGE_SPEED := 900.0
const CHARGE_TIME := 0.9
## Nach dem Ansturm ist der Boss lange benommen – das Suplex-Fenster.
const CHARGE_RECOVER := 1.6
const STAGGER_TIME := 1.4
const THROWN_TIME := 2.4
const WALL_HIT_DAMAGE := 2

var boss := B.IDLE
var _bt := 0.0
var _charge_dir := -1
var _charge_hits := 0
var _arena_left := 0.0
var _arena_right := 0.0
var _defeated := false


func _ready() -> void:
	super()
	add_to_group("bosses")
	health.set_max(data.max_hp, true)
	_arena_left = global_position.x - 900.0
	_arena_right = global_position.x + 900.0


## Grenzen der Boss-Arena (vom Level gesetzt), damit der Ansturm nicht aus dem Raum läuft.
func set_arena(left: float, right: float) -> void:
	_arena_left = left
	_arena_right = right


func _physics_process(delta: float) -> void:
	if _defeated:
		return
	_bt += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Morilla

	if state == S.GRABBED:
		_update_grabbed()
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	match boss:
		B.IDLE: _b_idle(delta)
		B.CHASE: _b_chase(delta)
		B.WINDUP: _b_windup(delta)
		B.ATTACK: _b_attack(delta)
		B.CHARGE: _b_charge(delta)
		B.CHARGE_RECOVER: _b_charge_recover(delta)
		B.STAGGER: _b_stagger(delta)
		B.THROWN: _b_thrown(delta)
		B.DEAD: _b_dead(delta)
	move_and_slide()
	ledge_check.position.x = facing * LEDGE_PROBE
	visual.face(facing)


func _set_boss(new_state: B, duration := 0.0) -> void:
	boss = new_state
	_bt = 0.0
	_duration = duration
	_alert.visible = new_state == B.WINDUP
	visual.modulate = Color.WHITE
	match new_state:
		B.IDLE, B.CHASE:
			visual.play_anim(&"idle" if new_state == B.IDLE else &"walk")
		B.WINDUP:
			visual.show_frame(&"windup", 0)
		B.ATTACK:
			visual.show_frame(&"attack", 0)
		B.CHARGE:
			visual.play_anim(&"charge")
		B.CHARGE_RECOVER, B.STAGGER:
			visual.play_anim(&"stagger", true)
		B.THROWN:
			visual.play_anim(&"thrown", true)
		B.DEAD:
			visual.play_anim(&"death", true)


func _b_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	if _sees_player():
		_set_boss(B.CHASE)
	elif _bt >= _duration:
		_set_boss(B.IDLE, randf_range(0.6, 1.2))


func _b_chase(delta: float) -> void:
	if not _sees_player() and _bt > 1.5:
		_set_boss(B.IDLE, 0.8)
		return
	_face_player()
	var dx := absf(_player.global_position.x - global_position.x) if _player else 0.0
	var dy := absf(_player.global_position.y - global_position.y) if _player else 0.0
	if dx <= data.attack_range and dy < 160.0 and _cooldown <= 0.0:
		velocity.x = 0.0
		_set_boss(B.WINDUP, data.windup_time)
		return
	# Aus mittlerer Distanz setzt der Boss zum Ansturm an.
	if dx > data.attack_range * 1.6 and dx < 900.0 and _cooldown <= 0.0 and randf() < 0.02:
		_begin_charge()
		return
	if dx > data.attack_range * 0.7:
		velocity.x = move_toward(velocity.x, facing * data.move_speed, 1600.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)


func _b_windup(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	var pulse := 0.6 + 0.4 * sin(_bt * 24.0)
	visual.modulate = Color(1.0, pulse, pulse * 0.6)
	if _bt >= _duration:
		_begin_attack()


func _begin_attack() -> void:
	_set_boss(B.ATTACK, data.attack_time)
	var info := HitInfo.new()
	info.source = self
	info.direction = facing
	info.damage = data.attack_damage
	info.knockback = data.attack_knockback
	info.stun = 0.4
	info.hit_stop = 0.08
	info.shake = 0.3
	info.heavy = true
	hitbox.position = Vector2(facing * (data.attack_range * 0.5 + 50.0), -110.0)
	hitbox.activate(info)
	velocity.x = facing * data.lunge_speed
	Sound.sfx("enemy_swing", -2.0)
	Game.shake(0.2)


func _b_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * 0.5 * delta)
	if _bt >= _duration:
		hitbox.deactivate()
		_cooldown = data.attack_cooldown
		# Nach dem schweren Schlag ist der Boss kurz offen (Suplex-Fenster).
		_set_boss(B.STAGGER, STAGGER_TIME * 0.6)


func _begin_charge() -> void:
	_set_boss(B.CHARGE, CHARGE_TIME)
	_charge_dir = facing
	_charge_hits = 0
	Sound.sfx("heavy_whoosh", -2.0)
	Game.shake(0.3)
	Effects.float_text(get_parent(), global_position + Vector2(0, -420), "ANSTURM!", Color("ff9a4d"), 44)


func _b_charge(_delta: float) -> void:
	velocity.x = _charge_dir * CHARGE_SPEED
	# Trefferfläche während des Ansturms.
	if _charge_hits == 0:
		var info := HitInfo.new()
		info.source = self
		info.direction = _charge_dir
		info.damage = data.attack_damage
		info.knockback = Vector2(760, -360)
		info.stun = 0.5
		info.hit_stop = 0.1
		info.shake = 0.5
		info.heavy = true
		hitbox.position = Vector2(_charge_dir * 90.0, -110.0)
		hitbox.activate(info)
		_charge_hits = 1
	# Wand oder Arena-Rand: Ansturm endet mit einem Fehlschlag -> großes Suplex-Fenster.
	var hit_wall := is_on_wall() or global_position.x <= _arena_left or global_position.x >= _arena_right
	if hit_wall or _bt >= _duration:
		hitbox.deactivate()
		_end_charge(hit_wall)


func _end_charge(hit_wall: bool) -> void:
	velocity.x = 0.0
	_cooldown = data.attack_cooldown + 0.4
	if hit_wall:
		Sound.sfx("heavy_hit")
		Game.shake(0.8)
		Game.hit_stop(0.12)
		Effects.shockwave(get_parent(), global_position + Vector2(0, -120.0), Color(1.0, 0.7, 0.4), 420.0, 0.5)
		Effects.burst(get_parent(), global_position + Vector2(0, -120.0), Color(0.7, 0.68, 0.6), 26, 520.0, 0.7, 12.0)
		health.take_damage(WALL_HIT_DAMAGE)
		Effects.float_text(get_parent(), global_position + Vector2(0, -440), "BENOMMEN!", Color("ffd166"), 48)
		_set_boss(B.CHARGE_RECOVER, CHARGE_RECOVER)
	else:
		_set_boss(B.STAGGER, STAGGER_TIME * 0.5)


func _b_charge_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	if _bt >= _duration:
		_set_boss(B.CHASE if _sees_player() else B.IDLE, 0.6)


func _b_stagger(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	if _bt >= _duration:
		_set_boss(B.CHASE if _sees_player() else B.IDLE, 0.6)


func _b_thrown(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * 0.4 * delta)
	if _bt >= _duration:
		_set_boss(B.CHASE if _sees_player() else B.IDLE, 0.6)


func _b_dead(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * _delta)


# --- Griff-Schnittstelle: Der Boss lässt sich nur per Suplex werfen (size_class 2). ---

func can_be_grappled(ab: AbilityData) -> bool:
	if _defeated or not data.grapple_vulnerable or data.size_class > ab.max_size_class:
		return false
	# Nur wenn der Boss offen ist: nach Ansturm-Fehlschlag, im Taumel oder nach dem schweren Schlag.
	return boss == B.CHARGE_RECOVER or boss == B.STAGGER or boss == B.THROWN


func begin_grapple(by: Node2D) -> void:
	_grappler = by
	hitbox.deactivate()
	hurtbox.enabled = false
	velocity = Vector2.ZERO
	facing = 1 if by.global_position.x > global_position.x else -1
	_set_state(S.GRABBED)
	_set_boss(B.THROWN, THROWN_TIME)


func apply_suplex_hit(info: HitInfo) -> void:
	visual.flash(0.3, Color(1.0, 0.7, 0.35))
	health.take_damage(info.damage)
	if health.is_dead():
		return
	velocity = Vector2(info.direction * info.knockback.x, info.knockback.y)
	_set_boss(B.THROWN, THROWN_TIME)


func end_grapple(submitted: bool) -> void:
	if state != S.GRABBED:
		return
	_grappler = null
	hurtbox.enabled = true
	if submitted:
		_set_boss(B.THROWN, THROWN_TIME)
	else:
		_set_boss(B.STAGGER, STAGGER_TIME * 0.5)


func _on_hit(info: HitInfo) -> void:
	if _defeated or state == S.GRABBED:
		return
	if not health.take_damage(info.damage):
		return
	visual.flash(0.12)
	if health.is_dead():
		return
	# Super-Rüstung im Anlauf und während des Ansturms: nur schwere Treffer unterbrechen.
	if (boss == B.WINDUP or boss == B.CHARGE) and not info.heavy:
		return
	hitbox.deactivate()
	velocity = Vector2(info.direction * info.knockback.x, info.knockback.y)
	facing = -info.direction
	_set_boss(B.STAGGER, STAGGER_TIME)


func _die() -> void:
	if _defeated:
		return
	_defeated = true
	hitbox.deactivate()
	hurtbox.enabled = false
	collision_layer = 0
	_grappler = null
	_set_boss(B.DEAD, 99.0)
	velocity.x = -facing * 120.0
	Sound.sfx("enemy_down")
	Game.shake(0.9)
	Effects.burst(get_parent(), global_position + Vector2(0, -140), Color(0.7, 0.6, 0.45), 40, 620.0, 0.9, 14.0)
	Effects.shockwave(get_parent(), global_position + Vector2(0, -140), Color(1.0, 0.75, 0.4), 520.0, 0.6)
	died.emit(self)
	defeated.emit()
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(visual, "modulate:a", 0.0, 1.0)
	tw.tween_callback(queue_free)
