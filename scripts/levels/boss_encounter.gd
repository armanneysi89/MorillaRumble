class_name BossEncounter
extends Area2D

## Boss-Begegnung: sperrt beim Betreten den Raum ab, rahmt die Kamera, aktiviert den Boss und öffnet nach
## seinem Sieg wieder. Baut auf dem bestehenden Gegner-/Kamera-System auf.

signal started
signal cleared

const IRONBACK_SCENE: PackedScene = preload("res://scenes/enemies/ironback.tscn")
const WALL_HEIGHT := 4000.0

var boss_id := "ironback"
## Weltbereich der Arena.
var arena_rect := Rect2()
## Fußpunkt, an dem der Boss erscheint (Bodenhöhe der Arena).
var spawn_point := Vector2.ZERO
var camera: GameCamera
## Boss-Knoten (wird beim Betreten erzeugt, falls noch nicht vorhanden).
var boss: Ironback

var _active := false
var _done := false
var _walls: Array[StaticBody2D] = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	_done = Progression.get_flag("boss_" + boss_id)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	# Der Auslöser spannt die ganze Arena auf: Betreten von jeder Seite startet den Kampf.
	shape.size = Vector2(maxf(arena_rect.size.x, 400.0), 1400)
	cs.shape = shape
	cs.position = Vector2(arena_rect.get_center().x - global_position.x, -400)
	add_child(cs)
	body_entered.connect(_on_body_entered)


func is_done() -> bool:
	return _done


func _on_body_entered(body: Node2D) -> void:
	if body is Morilla and not _active and not _done:
		_active = true
		_start.call_deferred()


func _start() -> void:
	_active = true
	for x in [arena_rect.position.x, arena_rect.end.x]:
		_walls.append(_make_wall(x))
	if camera:
		camera.lock_arena(Rect2i(arena_rect))
	Sound.sfx("arena_start")
	Game.toast("Eisenrücken! Weiche dem Ansturm aus und wirf ihn, wenn er benommen ist.")
	started.emit()
	_spawn_boss()


func _spawn_boss() -> void:
	if is_instance_valid(boss):
		return
	boss = IRONBACK_SCENE.instantiate() as Ironback
	boss.position = spawn_point if spawn_point != Vector2.ZERO else Vector2(arena_rect.get_center().x, arena_rect.end.y)
	boss.set_arena(arena_rect.position.x + 120.0, arena_rect.end.x - 120.0)
	boss.defeated.connect(_on_defeated)
	get_parent().add_child(boss)
	Effects.burst(get_parent(), boss.position + Vector2(0, -140), Color(0.7, 0.6, 0.45), 30, 520.0, 0.8, 12.0)


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


func _on_defeated() -> void:
	_done = true
	_active = false
	Progression.set_flag("boss_" + boss_id)
	Progression.complete_boss(boss_id)
	for wall in _walls:
		if is_instance_valid(wall):
			wall.queue_free()
	_walls.clear()
	if camera:
		camera.release_arena()
	Sound.sfx("arena_clear")
	cleared.emit()
