class_name Enemy
extends CharacterBody2D

## Datengetriebener Gegner (EnemyData). Zustände: Idle, Patrouille, Verfolgen, Anlauf (Telegraph), Angriff, Erholung,
## Getroffen, Betäubt, Gegriffen, Tot. Die Erholung nach einem Angriff ist das Zeitfenster für Konter und Griffe.

signal died(enemy: Enemy)

enum S { IDLE, PATROL, CHASE, WINDUP, ATTACK, RECOVER, HURT, STUNNED, GRABBED, DEAD }

const GRAVITY := 2400.0
const FRICTION := 2600.0
const LEDGE_PROBE := 55.0
const GRAB_TIMEOUT := 4.0
const PARRY_STUN := 0.9

## Gegnertypen der Level (Schlüssel -> EnemyData).
const ENEMY_DATA := {
	"recruit": "res://resources/enemies/white_belt_recruit.tres",
	"rival": "res://resources/enemies/blue_belt_rival.tres",
}
const INK_TINT := Color(0.72, 0.55, 1.0)

@export var data: EnemyData
@export var patrol_range := 160.0

@onready var visual: CharacterSprite = $Visual
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $AttackHitbox
@onready var ledge_check: RayCast2D = $LedgeCheck

var state := S.IDLE
var facing := -1
## Größenklasse für Griffe (0 klein, 1 mittel, 2 groß). Große Gegner lassen sich nur per Suplex werfen.
var size_class := 0

var _home_x := 0.0
var _player: Morilla
var _t := 0.0
var _duration := 0.0
var _cooldown := 0.0
var _patrol_dir := 1
var _grappler: Node2D
var _pending_stun := 0.0
var _alert: Label
var _hit_shape: RectangleShape2D


static func data_for(kind: String) -> EnemyData:
	return load(ENEMY_DATA.get(kind, ENEMY_DATA["recruit"]))


func _ready() -> void:
	if data == null:
		data = data_for("recruit")
	add_to_group("enemies")
	collision_layer = Layers.ENEMY
	collision_mask = Layers.WORLD
	hurtbox.collision_layer = Layers.ENEMY_HURT
	hurtbox.collision_mask = 0
	hitbox.collision_layer = 0
	hitbox.collision_mask = Layers.PLAYER_HURT
	ledge_check.collision_mask = Layers.WORLD
	var hit_cs := hitbox.get_node("Shape") as CollisionShape2D
	hit_cs.shape = hit_cs.shape.duplicate()
	_hit_shape = hit_cs.shape as RectangleShape2D
	_hit_shape.size = Vector2(data.attack_range + 20.0, 110.0)

	visual.setup(data.spec_key)
	size_class = data.size_class
	health.set_max(data.max_hp, true)
	health.died.connect(_die)
	hurtbox.hit_received.connect(_on_hit)

	_alert = Label.new()
	_alert.text = "!"
	_alert.add_theme_font_size_override("font_size", 72)
	_alert.add_theme_color_override("font_color", Color("ff5a3c"))
	_alert.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.1))
	_alert.add_theme_constant_override("outline_size", 14)
	_alert.position = Vector2(-18, -250)
	_alert.visible = false
	_alert.z_index = 15
	add_child(_alert)

	_home_x = global_position.x
	_set_state(S.IDLE, randf_range(0.2, 1.0))


func _physics_process(delta: float) -> void:
	_t += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Morilla

	if state == S.GRABBED:
		_update_grabbed()
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	match state:
		S.IDLE: _idle(delta)
		S.PATROL: _patrol(delta)
		S.CHASE: _chase(delta)
		S.WINDUP: _windup(delta)
		S.ATTACK: _attack(delta)
		S.RECOVER: _recover(delta)
		S.HURT, S.STUNNED, S.DEAD: _stagger(delta)
	move_and_slide()
	ledge_check.position.x = facing * LEDGE_PROBE
	visual.face(facing)


func _set_state(new_state: S, duration := 0.0) -> void:
	state = new_state
	_t = 0.0
	_duration = duration
	_alert.visible = new_state == S.WINDUP
	visual.modulate = Color.WHITE
	match new_state:
		S.IDLE, S.PATROL, S.CHASE:
			visual.play_anim(&"idle" if new_state == S.IDLE else &"walk")
		S.WINDUP:
			visual.show_frame(&"attack", 0)
		S.ATTACK:
			visual.show_frame(&"attack", 1)
		S.RECOVER:
			visual.play_anim(&"idle")
		S.HURT, S.STUNNED:
			visual.play_anim(&"hurt", true)
		S.GRABBED:
			visual.play_anim(&"grabbed", true)
		S.DEAD:
			visual.play_anim(&"death", true)


func _sees_player() -> bool:
	if _player == null or _player.health.is_dead():
		return false
	var d := _player.global_position - global_position
	return absf(d.x) < data.detect_range and absf(d.y) < 240.0


func _face_player() -> void:
	if _player:
		facing = 1 if _player.global_position.x > global_position.x else -1


func _ledge_or_wall() -> bool:
	return is_on_wall() or (is_on_floor() and not ledge_check.is_colliding())


func _idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	if _sees_player():
		_set_state(S.CHASE)
	elif _t >= _duration:
		_patrol_dir = -_patrol_dir if randf() < 0.5 else _patrol_dir
		_set_state(S.PATROL, randf_range(1.5, 3.0))


func _patrol(_delta: float) -> void:
	facing = _patrol_dir
	velocity.x = _patrol_dir * data.move_speed * 0.4
	if _ledge_or_wall() or absf(global_position.x - _home_x) > patrol_range:
		_patrol_dir = -_patrol_dir
		if absf(global_position.x - _home_x) > patrol_range:
			_patrol_dir = 1 if _home_x > global_position.x else -1
		facing = _patrol_dir
	if _sees_player():
		_set_state(S.CHASE)
	elif _t >= _duration:
		_set_state(S.IDLE, randf_range(0.6, 1.4))


func _chase(delta: float) -> void:
	if not _sees_player() and _t > 1.0:
		_set_state(S.IDLE, 0.8)
		return
	_face_player()
	var dx := absf(_player.global_position.x - global_position.x) if _player else 0.0
	var dy := absf(_player.global_position.y - global_position.y) if _player else 0.0
	if dx <= data.attack_range and dy < 140.0 and _cooldown <= 0.0:
		velocity.x = 0.0
		_set_state(S.WINDUP, data.windup_time)
		return
	if dx > data.attack_range * 0.7 and not _ledge_or_wall():
		velocity.x = move_toward(velocity.x, facing * data.move_speed, 1800.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)


func _windup(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	var pulse := 0.65 + 0.35 * sin(_t * 28.0)
	visual.modulate = Color(1.0, pulse, pulse * 0.7)
	if _t >= _duration:
		_begin_attack()


func _begin_attack() -> void:
	_set_state(S.ATTACK, data.attack_time)
	var info := HitInfo.new()
	info.source = self
	info.direction = facing
	info.damage = data.attack_damage
	info.knockback = data.attack_knockback
	info.stun = 0.35
	info.hit_stop = 0.06
	info.shake = 0.15
	hitbox.position = Vector2(facing * (data.attack_range * 0.5 + 40.0), -85.0)
	hitbox.activate(info)
	velocity.x = facing * data.lunge_speed
	Sound.sfx("enemy_swing", -4.0)


func _attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * 0.5 * delta)
	if _t >= _duration:
		hitbox.deactivate()
		_cooldown = data.attack_cooldown
		_set_state(S.RECOVER, data.recover_time)


func _recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	if _t >= _duration:
		_set_state(S.CHASE if _sees_player() else S.IDLE, 0.8)


func _stagger(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	if state != S.DEAD and _t >= _duration:
		_set_state(S.CHASE if _sees_player() else S.IDLE, 0.6)


func _update_grabbed() -> void:
	velocity = Vector2.ZERO
	if not is_instance_valid(_grappler) or _t > GRAB_TIMEOUT:
		end_grapple(false)


func _on_hit(info: HitInfo) -> void:
	if state == S.DEAD or state == S.GRABBED:
		return
	if not health.take_damage(info.damage):
		return
	visual.flash(0.12)
	if health.is_dead():
		return
	if data.super_armor_windup and state == S.WINDUP and not info.heavy:
		return
	hitbox.deactivate()
	velocity = Vector2(info.direction * info.knockback.x, info.knockback.y)
	facing = -info.direction
	_set_state(S.HURT, info.stun)


## Von PlayerCombat bei perfektem Block aufgerufen.
func on_parried() -> void:
	if state != S.WINDUP and state != S.ATTACK:
		return
	hitbox.deactivate()
	velocity.x = -facing * 260.0
	_set_state(S.STUNNED, PARRY_STUN)


func _die() -> void:
	hitbox.deactivate()
	hurtbox.enabled = false
	collision_layer = 0
	_grappler = null
	_set_state(S.DEAD, 99.0)
	velocity.x = -facing * 120.0
	Sound.sfx("enemy_down")
	Effects.burst(get_parent(), global_position + Vector2(0, -90), Color(0.65, 0.45, 0.95), 18, 380.0, 0.6, 8.0)
	died.emit(self)
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.tween_property(visual, "modulate:a", 0.0, 0.8)
	tw.tween_callback(queue_free)


# --- Oktopus-Geist (siehe OctopusSpirit) ---

func can_be_spirit_targeted() -> bool:
	return state != S.DEAD and state != S.GRABBED


## Der Geist hält den Gegner fest: betäubt, ohne Angriff.
func spirit_bind(duration: float) -> void:
	if not can_be_spirit_targeted():
		return
	hitbox.deactivate()
	velocity = Vector2.ZERO
	_set_state(S.STUNNED, duration)
	visual.modulate = INK_TINT


func apply_spirit_hit(info: HitInfo) -> void:
	if not can_be_spirit_targeted() or not health.take_damage(info.damage):
		return
	visual.flash(0.2, Color(0.75, 0.45, 1.0))
	if health.is_dead():
		return
	velocity = Vector2(info.direction * info.knockback.x, info.knockback.y)
	_set_state(S.STUNNED, info.stun)
	visual.modulate = INK_TINT


# --- Griff-Schnittstelle (siehe PlayerGrapple) ---

func can_be_grappled(ab: AbilityData) -> bool:
	if not data.grapple_vulnerable or data.size_class > ab.max_size_class:
		return false
	return state != S.ATTACK and state != S.GRABBED and state != S.DEAD


func is_grappled() -> bool:
	return state == S.GRABBED


func begin_grapple(by: Node2D) -> void:
	_grappler = by
	hitbox.deactivate()
	hurtbox.enabled = false
	velocity = Vector2.ZERO
	facing = 1 if by.global_position.x > global_position.x else -1
	_set_state(S.GRABBED)


func apply_grapple_hit(info: HitInfo) -> void:
	_pending_stun = info.stun
	visual.flash(0.2, Color(1.0, 0.6, 0.3))
	health.take_damage(info.damage)


## Suplex-Aufprall: Der Gegner wird geworfen, auf den Boden geschlagen und lange betäubt.
func apply_suplex_hit(info: HitInfo) -> void:
	_pending_stun = info.stun
	visual.flash(0.25, Color(1.0, 0.7, 0.35))
	health.take_damage(info.damage)
	if health.is_dead():
		return
	velocity = Vector2(info.direction * info.knockback.x, info.knockback.y)
	_set_state(S.STUNNED, info.stun)


## Wird immer aufgerufen, wenn der Griff endet – regulär oder durch Unterbrechung.
func end_grapple(submitted: bool) -> void:
	if state != S.GRABBED:
		return
	_grappler = null
	hurtbox.enabled = true
	if submitted:
		_set_state(S.STUNNED, maxf(_pending_stun, 0.5))
	else:
		_set_state(S.RECOVER, 0.4)
