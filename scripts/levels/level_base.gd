class_name LevelBase
extends Node2D

## Gemeinsamer Aufbau aller Level. Unterklassen füllen in _init() die Datenfelder und überschreiben _build_extras().
## Level bestehen aus Daten (Plattformen, Dekor, Gegner ...) statt aus von Hand platzierten Knoten.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/morilla.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/white_belt_recruit.tscn")
const COACH_SCENE: PackedScene = preload("res://scenes/coaches/coach_mo.tscn")

const K_WOOD := PlatformBlock.Kind.WOOD
const K_STONE := PlatformBlock.Kind.STONE
const K_SHELF := PlatformBlock.Kind.SHELF
const K_MOSS := PlatformBlock.Kind.MOSS
const K_LOG := PlatformBlock.Kind.LOG

var level_id := "level"
var level_title := ""
var level_subtitle := ""
var level_width := 8000.0
var room_top := -700
var room_bottom := 1080
var start := Vector2(300, 800)
var music := "dojo"
var far_background := "res://assets/environments/dojo/bg_dojo.png"
var pillar_path := "res://assets/environments/dojo/props/pillar.png"
var pillar_tint := Color(0.45, 0.42, 0.6, 0.9)
var sky_top := Color("0b0a22")
var sky_bottom := Color("2a1745")
var petal_color := Color(1.0, 0.72, 0.82, 0.85)
var fireflies := false
## Szene, die nach dem Levelende geladen wird.
var next_scene: String = Game.MENU_SCENE
## [Art, x, y (Oberkante), Breite]
var platforms := []
## [Art, x, y (Fußpunkt), Höhe, gespiegelt, z]
var decor := []
## [x, y (Fußpunkt), Text]
var hints := []
## [x, y (Fußpunkt), Patrouillenradius, optional Typ (siehe Enemy.ENEMY_DATA)]
var enemies := []
## [id, x, y (Fußpunkt)]
var checkpoints := []
## [id, x, y (Mitte), optional Art: "scroll" | "tea"]
var pickups := []
## [x, y (Fußpunkt)]
var dummies := []
## [name, x, y (Fußpunkt), Figur] – NPCs, die das Levelskript selbst aufbaut (Baby Mo, Vitali).
var npcs := []
## [x, y (Fußpunkt)]
var thrones := []
## [id, x, y (Fußpunkt), Höhe]
var slabs := []
## [id, x, y (Fußpunkt), Arena-Breite]
var bosses := []

var player: Morilla
var hud: Hud
var camera: GameCamera
var dialogue: DialogueBox
## Vom Levelskript nutzbare Referenzen auf die aus Markern gebauten Objekte.
var throne_node: BeltThrone
var slab_nodes: Array[BreakSlab] = []

var _completed := false


func _ready() -> void:
	_collect_markers()
	Sound.play_music(music)
	var bg := LevelBackground.new()
	bg.level_width = level_width
	bg.far_path = far_background
	bg.pillar_path = pillar_path
	bg.pillar_tint = pillar_tint
	bg.sky_top = sky_top
	bg.sky_bottom = sky_bottom
	bg.petal_color = petal_color
	bg.fireflies = fireflies
	add_child(bg)
	_build_platforms()
	_build_walls()
	_build_decor()
	_build_props()
	_build_enemies()
	_build_extras()
	_build_player()
	_build_ui()
	_after_ready()


## Wandelt im Editor platzierte Level-Platzhalter (LevelPlatform, LevelDecor ...) in die Datenfelder um.
func _collect_markers() -> void:
	var anchor := get_node_or_null(^"Start") as Node2D
	if anchor:
		start = anchor.position
	for n in find_children("*", "", true, false):
		var pos := to_local((n as Node2D).global_position) if n is Node2D else Vector2.ZERO
		if n is LevelPlatform:
			platforms.append([(n as LevelPlatform).kind, pos.x, pos.y, (n as LevelPlatform).width])
		elif n is LevelDecor:
			var d := n as LevelDecor
			decor.append([d.kind, pos.x, pos.y, d.height, d.flip, d.z_index])
		elif n is LevelHint:
			hints.append([pos.x, pos.y, (n as LevelHint).text])
		elif n is LevelEnemy and not _in_arena(n):
			var e := n as LevelEnemy
			enemies.append([pos.x, pos.y, e.patrol_range, e.enemy_type])
		elif n is LevelCheckpoint:
			checkpoints.append([(n as LevelCheckpoint).id, pos.x, pos.y])
		elif n is LevelPickup:
			pickups.append([(n as LevelPickup).id, pos.x, pos.y, (n as LevelPickup).kind])
		elif n is LevelDummy:
			dummies.append([pos.x, pos.y])
		elif n is LevelNpc:
			npcs.append([n.name, pos.x, pos.y, (n as LevelNpc).character])
		elif n is LevelThrone:
			thrones.append([pos.x, pos.y])
		elif n is LevelSlab:
			slabs.append([(n as LevelSlab).id, pos.x, pos.y, (n as LevelSlab).height])
		elif n is LevelBoss:
			bosses.append([(n as LevelBoss).boss_id, pos.x, pos.y, (n as LevelBoss).arena_width])
		elif n is LevelBackdrop:
			var b := n as LevelBackdrop
			level_width = b.level_width
			far_background = b.far_background
			pillar_path = b.pillar_path
			pillar_tint = b.pillar_tint
			sky_top = b.sky_top
			sky_bottom = b.sky_bottom
			petal_color = b.petal_color
			fireflies = b.fireflies
		else:
			continue
		if not _in_arena(n):
			n.queue_free()


func _in_arena(node: Node) -> bool:
	var p := node.get_parent()
	while p and p != self:
		if p is LevelArena:
			return true
		p = p.get_parent()
	return false


## Für levelspezifische Objekte (Coaches, Arena, Ausgang) überschreiben. Läuft vor dem Erstellen des Spielers.
func _build_extras() -> void:
	pass


## Läuft, wenn Spieler, Kamera und UI stehen.
func _after_ready() -> void:
	pass


func _build_platforms() -> void:
	for p in platforms:
		var block := PlatformBlock.new()
		block.kind = p[0]
		block.position = Vector2(p[1], p[2])
		block.size = Vector2(p[3], 700)
		add_child(block)


func _build_walls() -> void:
	for x in [-30.0, level_width]:
		var wall := StaticBody2D.new()
		wall.collision_layer = Layers.WORLD
		wall.position = Vector2(x, -1000)
		var shape := RectangleShape2D.new()
		shape.size = Vector2(30, 5000)
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = Vector2(15, 2500)
		wall.add_child(cs)
		add_child(wall)


func _build_decor() -> void:
	for d in decor:
		var node := Decor.new()
		node.kind = d[0]
		node.position = Vector2(d[1], d[2])
		node.height = d[3]
		node.flip = d[4]
		node.z_index = d[5]
		add_child(node)


func _build_props() -> void:
	for h in hints:
		var sign_node := HintSign.new()
		sign_node.position = Vector2(h[0], h[1])
		sign_node.text = h[2]
		add_child(sign_node)
	for c in checkpoints:
		var cp := Checkpoint.new()
		cp.level_id = level_id
		cp.checkpoint_id = c[0]
		cp.position = Vector2(c[1], c[2])
		add_child(cp)
	for p in pickups:
		var pickup := ScrollPickup.new()
		pickup.pickup_id = p[0]
		pickup.position = Vector2(p[1], p[2])
		pickup.kind = p[3] if p.size() > 3 else "scroll"
		add_child(pickup)
	for d in dummies:
		var dummy := TrainingDummy.new()
		dummy.position = Vector2(d[0], d[1])
		add_child(dummy)
	for t in thrones:
		var throne := BeltThrone.new()
		throne.position = Vector2(t[0], t[1])
		add_child(throne)
		if throne_node == null:
			throne_node = throne
	for s in slabs:
		var slab := BreakSlab.new()
		slab.slab_id = s[0]
		slab.position = Vector2(s[1], s[2])
		slab.height = s[3] if s.size() > 3 else BreakSlab.HEIGHT
		add_child(slab)
		slab_nodes.append(slab)


func _build_enemies() -> void:
	for e in enemies:
		var enemy := ENEMY_SCENE.instantiate() as Enemy
		enemy.data = Enemy.data_for(e[3] if e.size() > 3 else "recruit")
		enemy.position = Vector2(e[0], e[1])
		enemy.patrol_range = e[2]
		add_child(enemy)


func _spawn_position() -> Vector2:
	var cp_id := Progression.checkpoint_for(level_id)
	for c in checkpoints:
		if c[0] == cp_id:
			return Vector2(c[1], c[2])
	return start


func _build_player() -> void:
	player = PLAYER_SCENE.instantiate() as Morilla
	player.position = _spawn_position()
	player.spawn_point = player.position
	player.fall_limit = float(room_bottom) + 500.0
	player.z_index = 2
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--x="):
			player.position = Vector2(arg.trim_prefix("--x=").to_float(), 300.0)
	add_child(player)
	player.died.connect(_on_player_died)

	camera = GameCamera.new()
	camera.target = player
	player.add_child(camera)
	camera.set_room(Rect2i(0, room_top, int(level_width), room_bottom - room_top))


func _build_ui() -> void:
	hud = Hud.new()
	hud.title = level_title
	hud.subtitle = level_subtitle
	add_child(hud)
	hud.bind_player(player)
	dialogue = DialogueBox.new()
	add_child(dialogue)
	add_child(PauseMenu.new())
	var touch := TouchControls.new()
	touch.player = player
	add_child(touch)


func _on_player_died() -> void:
	await hud.fade_to(1.0, 0.6)
	Game.reload_scene(0.3)


func complete_level(banner: String, sub: String) -> void:
	if _completed:
		return
	_completed = true
	Progression.set_flag("level_%s_cleared" % level_id)
	Sound.sfx("fanfare")
	player.freeze()
	hud.show_banner(banner, sub, 3.5)
	await get_tree().create_timer(5.0).timeout
	Game.change_scene(next_scene, 0.8)
