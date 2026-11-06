extends LevelBase

## Region 1 – Morilla Dojo: Bewegungs-Tutorial, Coach Mo lehrt den Kimura, Checkpoint, Schriftrolle, Arena-Kampf, Ausgang.

## Hintergrund, Plattformen, Dekor, Hinweise, Gegner, Checkpoints, Schriftrollen, Puppen, Start, Mo, Ausgang und Arena liegen als
## Platzhalter-Knoten in dojo_level.tscn und werden dort im 2D-Editor bearbeitet.

# [Sprecher, Text] – läuft direkt nach dem Intro-Film, Morilla und Mo stehen wie im letzten Filmbild.
const CONVERSATION := [
	["Morilla", "Mo! Was ist hier passiert?"],
	["Coach Mo", "Der Schattenmeister … Er kam, kurz nachdem du losgezogen bist."],
	["Morilla", "Und die anderen? Wo sind alle?"],
	["Coach Mo", "Die anderen Coaches waren unterwegs. Ich weiß nicht, ob er auch bei ihnen war."],
	["Morilla", "Ich lasse dich hier nicht allein."],
	["Coach Mo", "Ich komme zurecht. Such die anderen. Sieh nach, ob es ihnen gut geht."],
	["Morilla", "Und dann finde ich ihn."],
	["Coach Mo", "Aber nicht unvorbereitet. Lern von den Coaches. Wenn du den Schattenmeister einholen willst, brauchst du mehr als Kraft."],
	["Morilla", "Wo fange ich an?"],
	["Coach Mo", "Bei Arman. Nimm den Weg zum Mondbambus-Hain. Und Morilla … pass auf dich auf."],
]
# Zweites Gespräch mit Mo: die Kimura-Lektion.
const MO_FIRST: Array[String] = [
	"Bevor du gehst, Morilla: Kraft allein gewinnt keinen Kampf. Ein guter Kämpfer wartet auf den richtigen Moment.",
	"Jeder Gegner kündigt seinen Angriff an. Blocke im letzten Augenblick, und du parierst ihn.",
	"Ist er danach aus dem Gleichgewicht, greifst du zu. Ich zeige dir den Kimura.",
	"Greife mit F oder G nah am Gegner und hebele seinen Arm. Das betäubt ihn und tut richtig weh.",
	"Der Schattenmeister hat auch hier seine Hüllen zurückgelassen. Besiege sie, ohne dich selbst zu verlieren. Geh jetzt.",
]
const MO_REPEAT: Array[String] = [
	"Blocke im letzten Moment, dann greife zu. Geduld ist die stärkste Technik.",
]



var _mo: CoachNpc


func _init() -> void:
	level_id = "dojo"
	level_title = "MORILLA DOJO"
	level_subtitle = "Region 1 – Die Rache beginnt im Dojo"
	music = "dojo"
	next_scene = Game.BAMBOO_SCENE


func _build_extras() -> void:
	_mo = COACH_SCENE.instantiate() as CoachNpc
	_mo.position = ($Mo as Node2D).position
	_mo.first_lines = MO_FIRST
	_mo.repeat_lines = MO_REPEAT
	_mo.lesson_finished.connect(_on_lesson_finished)
	add_child(_mo)

	build_arena_and_gate("dojo_arena",
		func() -> void: complete_level("DOJO GEMEISTERT", "Der erste Schritt zur Rache ist getan."))


func _after_ready() -> void:
	arena.camera = camera
	if Progression.get_flag("intro_seen"):
		return
	Progression.set_flag("intro_seen")
	player.freeze()
	_mo.sprite().play_anim(&"talk")
	await dialogue.play_conversation(CONVERSATION)
	_mo.sprite().play_anim(&"idle")
	player.unfreeze()
	Progression.set_task("find_arman")
	hud.show_banner("NEUE AUFGABE", Progression.task_text(), 4.0)
	if not Progression.has_ability("kimura"):
		Game.toast("Coach Mo zeigt dir noch eine Technik – sprich ihn an (E).")


func _on_lesson_finished(_coach: CoachNpc) -> void:
	unlock_lesson("kimura", "NEUE TECHNIK: KIMURA", "Greifen mit F / G  –  nah am Gegner")
