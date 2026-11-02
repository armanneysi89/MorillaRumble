class_name ArenaEncounter
extends Area2D

## Kampfbegegnung in Wellen: schließt beim Betreten den Raum, rahmt die Kamera und öffnet nach der letzten Welle wieder.

signal started
signal cleared

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/white_belt_recruit.tscn")
const WALL_HEIGHT := 4000.0

var encounter_id := ""
## Weltbereich der Arena.
var arena_rect := Rect2()
## Pro Welle eine Liste von Spawn-Positionen (Fußpunkte).
var waves: Array = []
var camera: GameCamera

var _wave := -1
var _alive := 0
var _active := false
var _done := false
var _walls: Array[StaticBody2D] = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	_done = Progression.get_flag("arena_" + encounter_id)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(80, 1400)
	cs.shape = shape
	cs.position = Vector2(0, -400)
	add_child(cs)
	body_entered.connect(_on_body_entered)


func is_done() -> bool:
	return _done


func _on_body_entered(body: Node2D) -> void:
	if body is Morilla and not _active and not _done:
		_start()


func _start() -> void:
	_active = true
	for x in [arena_rect.position.x, arena_rect.end.x]:
		_walls.append(_make_wall(x))
	if camera:
		camera.lock_arena(Rect2i(arena_rect))
	Sound.sfx("arena_start")
	Game.toast("Kampf! Besiege alle Gegner.")
	started.emit()
	_next_wave()


func _make_wall(x: float) -> StaticBody2D:
	var wall := StaticBody2D.new()
	wall.collision_layer = Layers.WORLD
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, WALL_HEIGHT)
	cs.shape = shape
	wall.position = Vector2(x, arena_rect.end.y - WALL_HEIGHT * 0.5)
	wall.add_child(cs)
	get_parent().add_child.call_deferred(wall)
	return wall


func _next_wave() -> void:
	_wave += 1
	if _wave >= waves.size():
		_finish()
		return
	var spawns: Array = waves[_wave]
	_alive = spawns.size()
	for pos: Vector2 in spawns:
		var enemy := ENEMY_SCENE.instantiate() as Enemy
		enemy.position = pos
		enemy.patrol_range = 80.0
		enemy.died.connect(_on_enemy_died)
		get_parent().add_child(enemy)
		Effects.burst(get_parent(), pos + Vector2(0, -90), Color(0.65, 0.45, 0.95), 14, 300.0, 0.5, 7.0)
	if waves.size() > 1:
		Game.toast("Welle %d von %d" % [_wave + 1, waves.size()])


func _on_enemy_died(_enemy: Enemy) -> void:
	_alive -= 1
	if _alive <= 0:
		get_tree().create_timer(1.2).timeout.connect(_next_wave)


func _finish() -> void:
	_done = true
	_active = false
	Progression.set_flag("arena_" + encounter_id)
	for wall in _walls:
		if is_instance_valid(wall):
			wall.queue_free()
	_walls.clear()
	if camera:
		camera.release_arena()
	Sound.sfx("arena_clear")
	cleared.emit()
