class_name Morilla
extends CharacterBody2D

## Spielfigur. Bewegungsphysik liegt hier, das Verhalten in den Zuständen unter StateMachine,
## Treffer/Blocken in PlayerCombat und Griffe in PlayerGrapple.

signal died
signal interactable_changed(prompt: String)

const SPEED := 580.0
const ACCEL := 5600.0
const FRICTION := 6400.0
const AIR_ACCEL := 4200.0
## Beim Richtungswechsel beschleunigt die Figur stärker, damit sie nicht träge wirkt.
const TURN_BOOST := 2.1
const GRAVITY := 2950.0
const FALL_GRAVITY_MULT := 1.3
## Kurzes Schweben am Sprungscheitel.
const APEX_WINDOW := 220.0
const APEX_GRAVITY_MULT := 0.55
const MAX_FALL := 1750.0
const JUMP_VELOCITY := -1180.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.14
const INPUT_BUFFER := 0.16
const DASH_COOLDOWN := 0.5
const BUFFERED_ACTIONS: Array[String] = ["jump", "light_attack", "heavy_attack", "dash", "grab", "summon"]
const SUMMON_ID := "octopus"
## Ab dieser Ladung gilt der schwere Schlag als voll aufgeladen (HUD, Effekte, Schaden).
## Einzige Quelle der Wahrheit – Charge-Zustand, Attack-Zustand und HUD lesen diesen Wert.
const CHARGE_FULL := 0.94
## Unverwundbarkeit nach einem Treffer (Sekunden).
const HURT_IFRAMES := 1.2
## Unverwundbarkeit nach einem Respawn am Checkpoint.
const RESPAWN_IFRAMES := 1.5
## Ab dieser Fallgeschwindigkeit löst die Landung Staub, Klang und Erschütterung aus.
const HARD_LAND_SPEED := 350.0
## Ab dieser Geschwindigkeit läuft die Figur, darunter geht sie.
const RUN_THRESHOLD := 380.0
const WALK_THRESHOLD := 40.0
## Variable Sprunghöhe: Beim Loslassen wird der Aufstieg gekappt, aber nie unter diese Mindesthöhe.
const JUMP_CUT_SPEED := -300.0
const JUMP_CUT_FACTOR := 0.5
## Wie lange die Landung die Steuerung dämpft (Sekunden) und wie stark.
const LAND_LAG_TIME := 0.09
const LAND_LAG_SPEED := 0.45
## Dauer der Dreh-Animation beim Richtungswechsel.
const TURN_TIME := 0.08

@onready var visual: CharacterSprite = $Visual
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $AttackHitbox
@onready var grab_sensor: Area2D = $GrabSensor
@onready var interact_sensor: Area2D = $InteractSensor
@onready var combat: PlayerCombat = $Combat
@onready var grapple: PlayerGrapple = $Grapple
@onready var machine: StateMachine = $StateMachine

var facing := 1
var input_dir := 0.0
var spawn_point := Vector2.ZERO
var fall_limit := 2200.0
var coyote := 0.0
var air_dash_available := true
var dash_cooldown := 0.0
var summon_cooldown := 0.0
var combo_step := 0
var combo_timer := 0.0
## Ladung des schweren Schlags von 0.0 bis 1.0 (Charge-Zustand, siehe HUD und Effekte).
var charge_level := 0.0
var last_hit: HitInfo

var _buffers := {}
var _interactables: Array[Area2D] = []
var _prompt := ""
var _falling := false


func _ready() -> void:
	add_to_group("player")
	collision_layer = Layers.PLAYER
	collision_mask = Layers.WORLD
	hurtbox.collision_layer = Layers.PLAYER_HURT
	hurtbox.collision_mask = 0
	hitbox.collision_layer = 0
	hitbox.collision_mask = Layers.ENEMY_HURT
	grab_sensor.collision_layer = 0
	grab_sensor.collision_mask = Layers.ENEMY
	interact_sensor.collision_layer = 0
	interact_sensor.collision_mask = Layers.INTERACT
	interact_sensor.area_entered.connect(func(a: Area2D) -> void: _interactables.append(a))
	interact_sensor.area_exited.connect(func(a: Area2D) -> void: _interactables.erase(a))

	_add_shadow()
	visual.setup("morilla", true)
	visual.footstep.connect(func() -> void: Sound.sfx("step", -6.0, 1.0, 0.12))
	health.set_max(Progression.max_hp(), true)
	health.died.connect(func() -> void: machine.change(&"dead"))
	Progression.belt_changed.connect(_on_belt_changed)
	combat.setup(self)
	grapple.setup(self)
	machine.setup(self)
	machine.start(&"locomotion")


func _exit_tree() -> void:
	if Progression.belt_changed.is_connected(_on_belt_changed):
		Progression.belt_changed.disconnect(_on_belt_changed)


func _add_shadow() -> void:
	var shadow := Effects.glow(self, Vector2(0, 2), 86.0, Color(0, 0, 0, 0.55))
	shadow.scale = Vector2(1.5, 0.28)
	shadow.z_index = -1
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	shadow.material = mat


func _on_belt_changed(_belt_id: String) -> void:
	var diff := Progression.max_hp() - health.max_hp
	health.set_max(Progression.max_hp())
	if diff > 0:
		health.heal(diff)


func _physics_process(delta: float) -> void:
	_tick(delta)
	_read_input()
	machine.physics_update(delta)
	_update_prompt()
	if global_position.y > fall_limit and not health.is_dead():
		_fall_reset()


func _tick(delta: float) -> void:
	dash_cooldown = maxf(dash_cooldown - delta, 0.0)
	summon_cooldown = maxf(summon_cooldown - delta, 0.0)
	combo_timer = maxf(combo_timer - delta, 0.0)
	if combo_timer <= 0.0:
		combo_step = 0
	if is_on_floor():
		coyote = COYOTE_TIME
		air_dash_available = true
	else:
		coyote -= delta
	for action: String in _buffers:
		_buffers[action] = maxf(_buffers[action] - delta, 0.0)


func _read_input() -> void:
	input_dir = Input.get_axis("move_left", "move_right")
	for action in BUFFERED_ACTIONS:
		if Input.is_action_just_pressed(action):
			_buffers[action] = JUMP_BUFFER if action == "jump" else INPUT_BUFFER


func buffered(action: String) -> bool:
	return _buffers.get(action, 0.0) > 0.0


func consume(action: String) -> bool:
	if buffered(action):
		_buffers[action] = 0.0
		return true
	return false


func clear_buffers() -> void:
	_buffers.clear()


func apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var mult := FALL_GRAVITY_MULT if velocity.y > 0.0 else 1.0
	if absf(velocity.y) < APEX_WINDOW:
		mult *= APEX_GRAVITY_MULT
	velocity.y = minf(velocity.y + GRAVITY * mult * delta, MAX_FALL)


func apply_horizontal(delta: float, speed_mult := 1.0, accel_mult := 1.0) -> void:
	var target := input_dir * SPEED * speed_mult
	var rate := AIR_ACCEL
	if is_on_floor():
		rate = ACCEL if absf(input_dir) > 0.0 else FRICTION
	if absf(input_dir) > 0.0 and target * velocity.x < 0.0:
		rate *= TURN_BOOST
	velocity.x = move_toward(velocity.x, target, rate * accel_mult * delta)
	if absf(input_dir) > 0.0:
		facing = 1 if input_dir > 0.0 else -1


func can_dash() -> bool:
	return dash_cooldown <= 0.0 and (is_on_floor() or air_dash_available)


func summon_ability() -> AbilityData:
	return Progression.get_ability(SUMMON_ID)


func summon_unlocked() -> bool:
	return Progression.has_ability(SUMMON_ID) and summon_ability() != null


func is_busy() -> bool:
	return not machine.is_in(&"locomotion")


func freeze() -> void:
	machine.change(&"frozen")


func unfreeze() -> void:
	if machine.is_in(&"frozen"):
		clear_buffers()
		machine.change(&"locomotion")


## Setzt die Figur an einen Checkpoint zurück und räumt dabei jeden Zwischenzustand auf.
## Ohne diesen Reset schleppt ein Respawn alte Puffer, Kombo-Stufen und Abklingzeiten mit.
func respawn_at(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	coyote = 0.0
	dash_cooldown = 0.0
	summon_cooldown = 0.0
	air_dash_available = true
	combo_step = 0
	combo_timer = 0.0
	charge_level = 0.0
	last_hit = null
	clear_buffers()
	grapple.release(false)
	grapple.cooldown = 0.0
	combat.blocking = false
	combat.counter_window = 0.0
	health.make_invulnerable(RESPAWN_IFRAMES)
	if not machine.is_in(&"locomotion"):
		machine.change(&"locomotion")


func current_interactable() -> Area2D:
	var best: Area2D = null
	var best_d := INF
	for a in _interactables:
		if not is_instance_valid(a) or not a.has_method("can_interact") or not a.can_interact():
			continue
		var d := global_position.distance_to(a.global_position)
		if d < best_d:
			best_d = d
			best = a
	return best


func try_interact() -> bool:
	var target := current_interactable()
	if target == null:
		return false
	target.interact(self)
	return true


func _update_prompt() -> void:
	var target := current_interactable()
	var text: String = target.get_prompt() if target and not is_busy() else ""
	if text != _prompt:
		_prompt = text
		interactable_changed.emit(text)


## Sturz ins Leere: kostet ein Leben und setzt an den Spawnpunkt zurück.
## Der Aufruf läuft jeden Frame unterhalb des Fall-Limits, deshalb schützt `_falling` vor Mehrfachschaden.
func _fall_reset() -> void:
	if _falling:
		return
	_falling = true
	Sound.sfx("hurt")
	if health.take_damage(1, true) and not health.is_dead():
		respawn_at(spawn_point)
	_falling = false
