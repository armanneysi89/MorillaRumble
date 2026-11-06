class_name CoachNpc
extends Area2D

## Mentor-NPC. Spricht man ihn an, friert die Spielfigur ein und der Dialog läuft; danach meldet er lesson_finished.

signal lesson_finished(coach: CoachNpc)

@export var coach_id := "mo"
@export var display_name := "Coach Mo"
@export var spec_key := "mo"
@export var portrait_path := "res://assets/ui/mo_portrait.png"

## Erster Dialog und Wiederholungsdialog (Textzeilen).
var first_lines: Array[String] = []
var repeat_lines: Array[String] = []

## Während einer Vorführung blickt der Coach nicht zum Spieler, sondern in die vom Level gesetzte Richtung.
var locked := false
## Ruheanimation (z. B. "sit" für Vitali auf dem Thron). Standard "idle".
var idle_anim: StringName = &"idle"
## Wird vor dem ersten Gespräch einmal gespielt (z. B. "stand", wenn Vitali aufsteht).
var intro_anim: StringName = &""
## Porträt, das im Dialog verwendet wird (leer = portrait_path).
var portrait_override := ""

var _visual: CharacterSprite
var _player: Morilla
var _talked := false


func _ready() -> void:
	collision_layer = Layers.INTERACT
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(260, 300)
	cs.shape = shape
	cs.position = Vector2(0, -150)
	add_child(cs)
	_visual = CharacterSprite.new()
	add_child(_visual)
	_visual.setup(spec_key)
	_talked = Progression.get_flag("talked_" + coach_id)
	_visual.face(-1)
	if idle_anim != &"idle":
		_visual.play_anim(idle_anim)


func _physics_process(_delta: float) -> void:
	if locked:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Morilla
	elif absf(_player.global_position.x - global_position.x) < 600.0:
		_visual.face(1 if _player.global_position.x > global_position.x else -1)


func can_interact() -> bool:
	return true


func sprite() -> CharacterSprite:
	return _visual


func get_prompt() -> String:
	return "E: Mit %s sprechen" % display_name


func interact(player: Morilla) -> void:
	var box := get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	if box == null:
		return
	player.freeze()
	if intro_anim != &"" and not _talked:
		_visual.play_anim(intro_anim)
		await get_tree().create_timer(0.6).timeout
	_visual.play_anim(&"talk")
	var path := portrait_override if portrait_override != "" else portrait_path
	var portrait: Texture2D = load(path) if ResourceLoader.exists(path) else null
	var lines: Array[String] = repeat_lines if _talked and not repeat_lines.is_empty() else first_lines
	await box.play(display_name, portrait, lines)
	_visual.play_anim(idle_anim)
	if is_instance_valid(player):
		player.unfreeze()
	if not _talked:
		_talked = true
		Progression.set_flag("talked_" + coach_id)
	lesson_finished.emit(self)
