extends LevelBase

## Region 3 – Vitalis Steinbruch: Ein heller Bergsteinbruch über dem Bambushain. Morilla trifft im Vorhof
## Baby Mo, wird zum Gürtelthron geführt, lernt bei Vitali den Suplex und stellt sich am Ende dem Eisenrücken.
##
## Hintergrund, Plattformen, Dekor, Hinweise, Gegner, Checkpoints, Schriftrollen, Puppen, Start, NPCs,
## Thron, Bruchplatte, Boss und Ausgang liegen als Platzhalter-Knoten in quarry_level.tscn und werden dort
## im 2D-Editor bearbeitet.

const BABY_MO_PORTRAIT := "res://assets/ui/baby_mo_portrait.png"
const VITALI_PORTRAIT := "res://assets/ui/vitali_portrait.png"
## Begegnung mit Baby Mo und Vitali (getrennt von der Technik, damit ein Abbruch dazwischen nichts blockiert).
const VITALI_FLAG := "vitali_met"
const SUPLEX_ID := "suplex"
## Radius um Baby Mo, in dem die Begegnung ausgelöst wird.
const YARD_TRIGGER_RADIUS := 460.0

const INTRO: Array[String] = [
	"Der Bambus lichtet sich. Über dem Hain liegt ein Bergsteinbruch, in dem der Morgen das Gestein aufhellt.",
	"Hier soll Vitali trainieren. Man sagt, er habe aus den Gürteln seiner Gegner einen Thron gebaut.",
	"Ich bin stärker geworden. Aber gegen einen Gegner, der mich an Kraft übertrifft, hilft mir das nicht.",
]

## Begegnung: Morilla betritt den Vorhof und trifft Baby Mo.
const BABY_MO_FIRST: Array = [
	["Morilla", "Ich suche Vitali."],
	["Baby Mo", "Dann bist du richtig. Ich bin Baby Mo, einer seiner Schüler."],
	["Morilla", "Baby Mo? Du bist der Größte hier."],
	["Baby Mo", "Der Name ist geblieben. Komm, ich zeige dir meinen Coach."],
	["Morilla", "Sind das alles Gürtel?"],
	["Baby Mo", "Tausende. Jeder von einem Gegner, den er besiegt hat. Daraus hat er seinen Thron gebaut."],
]
## Nach der Enthüllung des Throns. Morilla blickt nur dann auf Armans Hilfe zurück, wenn die Sauna-Begegnung stattfand.
const VITALI_REVEAL: Array = [
	["Coach Vitali", "Arman hat dich geschickt."],
	["Morilla", "Er hat mir geholfen. Aber ich war nicht stark genug."],
	["Coach Vitali", "Dann lernen wir, wie du die Kraft deines Gegners gegen ihn verwendest."],
]
const VITALI_REVEAL_NO_ARMAN: Array = [
	["Coach Vitali", "Du kommst weit. Wer schickt dich?"],
	["Morilla", "Ich suche den Schattenmeister. Ich war nicht stark genug."],
	["Coach Vitali", "Dann lernen wir, wie du die Kraft deines Gegners gegen ihn verwendest."],
]
## Suplex-Lektion: Vitali demonstriert an einer Trainingspuppe, dann übt Morilla selbst.
const VITALI_LESSON: Array[String] = [
	"Der Suplex beginnt im Klinch. Nicht mit Kraft – mit Gleichgewicht.",
	"Greife mit F oder G, wenn dein Gegner aus dem Gleichgewicht ist. Dann hebst du ihn an.",
	"Wirf ihn über deine Schulter nach hinten. Der Aufprall nimmt ihm den Atem.",
	"Und wenn er aufschlägt, fährt der Bär aus dir. Er reißt alles mit, was in der Nähe steht.",
	"Große Gegner greifst du nur so. Und wenn einer nach einem Fehlschlag taumelt, ist das dein Fenster.",
]
const VITALI_REPEAT: Array[String] = [
	"Klinch, Gleichgewicht, Wurf. Warte auf das Fenster – dann greife zu.",
]
const BABY_MO_REPEAT: Array[String] = [
	"Mein Coach ist streng, aber gerecht. Zeig ihm, dass du zuhörst.",
]


var _baby_mo: CoachNpc
var _vitali: CoachNpc
var _throne: BeltThrone
var _slab: BreakSlab
var _boss: BossEncounter
var _vitali_busy := false
var _yard_trigger: Area2D


func _init() -> void:
	level_id = "quarry"
	level_title = "VITALIS STEINBRUCH"
	level_subtitle = "Region 3 – Coach Vitalis Suplex"
	music = "quarry"
	next_scene = Game.MENU_SCENE


func _build_extras() -> void:
	gate = ExitGate.new()
	gate.position = ($Gate as Node2D).position
	gate.reached.connect(func() -> void: complete_level("STEINBRUCH BEZWUNGEN", "Der Suplex sitzt. Die Spur führt weiter ..."))
	add_child(gate)

	_build_quarry()


## Steinbruch: Baby Mo im Vorhof, Gürtelthron mit Vitali, Suplex-Training, Bruchplatte und Boss-Arena.
func _build_quarry() -> void:
	# Gürtelthron (aus LevelBase gebaut) und Vitali davor.
	_throne = throne_node
	if _throne == null:
		_throne = BeltThrone.new()
		_throne.position = ($Thron as Node2D).position
		add_child(_throne)

	_baby_mo = CoachNpc.new()
	_baby_mo.coach_id = "baby_mo"
	_baby_mo.display_name = "Baby Mo"
	_baby_mo.spec_key = "baby_mo"
	_baby_mo.portrait_path = BABY_MO_PORTRAIT
	_baby_mo.position = ($BabyMo as Node2D).position
	_baby_mo.first_lines = []
	_baby_mo.repeat_lines = BABY_MO_REPEAT
	add_child(_baby_mo)

	_vitali = CoachNpc.new()
	_vitali.coach_id = "vitali"
	_vitali.display_name = "Coach Vitali"
	_vitali.spec_key = "vitali"
	_vitali.portrait_path = VITALI_PORTRAIT
	# Sitzend: Der Fußpunkt des Sitz-Sprites liegt auf der vorderen Gürtelkaskade, das Gesäß auf der Sitzfläche.
	_vitali.position = _throne.position + Vector2(0, -BeltThrone.SIT_FOOT_HEIGHT)
	# Vor der Gürtelkaskade zeichnen, sonst versinkt er in den Gürteln.
	_vitali.z_index = 3
	_vitali.idle_anim = &"sit"
	_vitali.intro_anim = &"stand"
	_vitali.first_lines = VITALI_LESSON
	_vitali.repeat_lines = VITALI_REPEAT
	_vitali.lesson_finished.connect(_on_vitali_lesson)
	add_child(_vitali)

	# Bruchplatte (aus LevelBase gebaut) – öffnet per Suplex den Nebenweg.
	_slab = slab_nodes[0] if not slab_nodes.is_empty() else null

	# Boss-Arena des Eisenrückens.
	var boss_marker := $Boss as LevelBoss
	_boss = BossEncounter.new()
	_boss.boss_id = boss_marker.boss_id
	_boss.arena_rect = Rect2(boss_marker.position.x - boss_marker.arena_width * 0.5, room_top,
		boss_marker.arena_width, room_bottom - room_top)
	_boss.spawn_point = boss_marker.position
	_boss.position = boss_marker.position
	# Der Platzhalter wird bereits in _collect_markers() freigegeben; ein zweites queue_free()
	# führt zu "Children name does not match parent name".
	_boss.cleared.connect(func() -> void:
		gate.open = true
		hud.show_banner("EISENRÜCKEN BESIEGT", "Das Tor zum Ausgang ist offen.", 3.0))
	add_child(_boss)

	# Auslöser für die Begegnung im Vorhof.
	_yard_trigger = Area2D.new()
	_yard_trigger.collision_layer = 0
	_yard_trigger.collision_mask = Layers.PLAYER
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(YARD_TRIGGER_RADIUS * 2.0, 900)
	cs.shape = shape
	cs.position = Vector2(0, -450)
	_yard_trigger.add_child(cs)
	_yard_trigger.position = _baby_mo.position
	_yard_trigger.body_entered.connect(_on_yard_entered)
	add_child(_yard_trigger)


func _after_ready() -> void:
	_boss.camera = camera
	gate.open = _boss.is_done()
	if _vitali_met():
		# Nach der Begegnung steht Vitali neben dem Thron statt darauf zu sitzen – weit genug links,
		# damit er nicht in der Gürtelkaskade steht.
		_vitali.idle_anim = &"idle"
		_vitali.position = _throne.position + Vector2(-420.0, 0.0)
		_vitali.z_index = 0
		_vitali.sprite().play_anim(&"idle")
	await play_intro_once("intro_quarry_seen", INTRO)


## Begegnung mit Baby Mo und Vitali. Läuft nur einmal; danach ist der Vorhof frei begehbar.
func _on_yard_entered(body: Node2D) -> void:
	if not body is Morilla or _vitali_busy or _vitali_met():
		return
	_vitali_busy = true
	player.freeze()
	player.health.make_invulnerable(600.0)
	var sequence := VitaliSequence.new()
	add_child(sequence)
	var reveal: Array = VITALI_REVEAL if _arman_met() else VITALI_REVEAL_NO_ARMAN
	var skipped: bool = await sequence.play(dialogue, {"yard": BABY_MO_FIRST, "reveal": reveal}, _arrive_at_throne)
	sequence.queue_free()
	Progression.set_flag(VITALI_FLAG)
	if skipped:
		await dialogue.play_conversation(BABY_MO_FIRST)
		await dialogue.play_conversation(reveal)
	player.unfreeze()
	player.health.invulnerable_time = 0.6
	_vitali_busy = false


## Läuft im Schwarz: Morilla steht vor dem Thron, Vitali sitzt darauf.
func _arrive_at_throne() -> void:
	# Vitali sitzt erhöht auf dem Thron; Morilla steht auf dem Boden davor (gleiche Standlinie wie der Thronfuß).
	player.global_position = Vector2(_throne.position.x - 260.0, _throne.position.y)
	player.velocity = Vector2.ZERO
	player.facing = 1
	player.visual.face(1)
	camera.reset_smoothing()
	_vitali.sprite().face(-1)


## Suplex-Lektion: Vitali demonstriert an einer Puppe, dann übt Morilla selbst.
func _on_vitali_lesson(_coach: CoachNpc) -> void:
	if Progression.has_ability(SUPLEX_ID):
		return
	player.freeze()
	await _demonstrate_suplex()
	await dialogue.play("Coach Vitali", _portrait(VITALI_PORTRAIT), VITALI_LESSON)
	player.unfreeze()
	unlock_lesson(SUPLEX_ID, "NEUE TECHNIK: SUPLEX", "Greifen mit F / G  –  wirft auch große Gegner")


## Vitali steht auf, greift eine Trainingspuppe und wirft sie mit dem Suplex.
func _demonstrate_suplex() -> void:
	var sprite := _vitali.sprite()
	_vitali.locked = true
	sprite.face(1)
	sprite.play_anim(&"stand")
	await get_tree().create_timer(0.6).timeout
	sprite.show_frame(&"suplex", 0)
	Sound.sfx("grab")
	await get_tree().create_timer(0.3).timeout
	sprite.show_frame(&"suplex", 1)
	Sound.sfx("strain")
	Game.shake(0.2)
	await get_tree().create_timer(0.4).timeout
	sprite.show_frame(&"suplex", 2)
	Sound.sfx("heavy_whoosh")
	await get_tree().create_timer(0.3).timeout
	sprite.show_frame(&"suplex", 3)
	Sound.sfx("land", -2.0)
	Game.shake(0.5)
	Effects.shockwave(self, _vitali.global_position + Vector2(120.0, -40.0), Color(1.0, 0.75, 0.4), 260.0, 0.4)
	Effects.dust(self, _vitali.global_position + Vector2(120.0, -20.0))
	await get_tree().create_timer(0.5).timeout
	sprite.play_anim(&"idle")
	sprite.face(-1)
	_vitali.locked = false


## Auch ältere Spielstände zählen: Wer die Begegnung schon hatte, betritt den Vorhof frei.
func _vitali_met() -> bool:
	return bool(Progression.get_flag(VITALI_FLAG)) or bool(Progression.get_flag("talked_vitali")) or Progression.has_ability(SUPLEX_ID)


## Auch ältere Spielstände zählen: Wer Arman schon gesprochen oder den Geist hat, kennt den Weg hierher.
func _arman_met() -> bool:
	return bool(Progression.get_flag("sauna_met")) or bool(Progression.get_flag("talked_arman")) or Progression.has_ability(Morilla.SUMMON_ID)
