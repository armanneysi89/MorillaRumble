extends LevelBase

## Region 1 – Morilla Dojo: Bewegungs-Tutorial, Coach Mo lehrt den Kimura, Checkpoint, Schriftrolle, Arena-Kampf, Ausgang.

const PLATFORMS := [
	[K_WOOD, 0, 800, 2700],
	[K_WOOD, 3080, 800, 2520],
	[K_SHELF, 3200, 640, 220],
	[K_SHELF, 3560, 490, 220],
	[K_SHELF, 3900, 340, 240],
	[K_STONE, 5600, 800, 3100],
]

const DECOR := [
	["pillar", 220, 800, 900, false, -3], ["pillar", 920, 800, 900, true, -3], ["pillar", 1620, 800, 900, false, -3],
	["pillar", 2320, 800, 900, true, -3], ["pillar", 3320, 800, 900, false, -3], ["pillar", 4020, 800, 900, true, -3],
	["pillar", 4720, 800, 900, false, -3], ["pillar", 5420, 800, 900, true, -3],
	["banner", 570, 520, 330, false, -2], ["banner", 1270, 520, 330, true, -2], ["banner", 1970, 520, 330, false, -2],
	["banner", 3670, 380, 330, true, -2], ["banner", 4370, 520, 330, false, -2],
	["lantern", 800, 330, 170, false, -1], ["lantern", 1500, 330, 170, false, -1], ["lantern", 2200, 330, 170, false, -1],
	["lantern", 3400, 300, 170, false, -1], ["lantern", 4100, 330, 170, false, -1], ["lantern", 4800, 330, 170, false, -1],
	["weapon_rack", 1000, 800, 200, false, -1],
	["cherry_tree", 5850, 810, 820, false, -3], ["cherry_tree", 6650, 810, 760, true, -3], ["cherry_tree", 7450, 810, 840, false, -3],
	["cherry_tree", 8450, 810, 800, true, -3],
	["lantern", 6250, 360, 170, false, -1], ["lantern", 7050, 360, 170, false, -1], ["lantern", 7850, 360, 170, false, -1],
]

const HINTS := [
	[520, 800, "A / D oder Stick: laufen.  Leertaste: springen – länger halten, höher springen."],
	[1130, 800, "Shift / Z: Dash. Er macht dich kurz unverwundbar – auch in der Luft (einmal pro Sprung)."],
	[1700, 800, "J / X: leichter Schlag.  K / C: schwerer Schlag (langsamer, aber stärker). Übe an der Puppe!"],
	[2560, 800, "Spring über die Lücke. Wer fällt, verliert ein Leben und startet am letzten Checkpoint."],
	[3050, 800, "Regale lassen sich von unten durchspringen. Dort oben liegt etwas verborgen."],
	[3480, 800, "Gegner kündigen Angriffe mit einem roten ! an. Weiche mit Dash aus oder blocke mit L / V."],
	[5150, 800, "Block im allerletzten Moment pariert den Angriff. Danach greifst du zu: F / G (Kimura)."],
]

# [x, y (Fußpunkt), Patrouillenradius]
const ENEMIES := [[3700, 800, 140], [4300, 800, 160], [4950, 800, 120]]

# [id, x, y (Fußpunkt)]
const CHECKPOINTS := [["cp_mo", 2150, 800], ["cp_hall", 4650, 800]]

# [id, x, y (Mitte)]
const PICKUPS := [["hp_scroll_dojo", 4020, 250]]

const DUMMIES := [[1950, 800]]

const ARENA_RECT := Rect2(5900, -700, 1600, 1780)
const ARENA_WAVES := [
	[Vector2(7000, 800), Vector2(7250, 800)],
	[Vector2(6150, 800), Vector2(7100, 800), Vector2(7300, 800)],
]
const GATE_POS := Vector2(8250, 800)
const MO_POS := Vector2(2450, 800)

const INTRO: Array[String] = [
	"Eine Nacht. Mehr hat der Schattenmeister gebraucht, um mein Dojo zu zerstören.",
	"Meine Trainingspartner hat er in leere Hüllen verwandelt. Sie erkennen mich nicht mehr.",
	"Ich war nicht da, um sie zu beschützen. Das werde ich ihm nie verzeihen.",
	"Ich will Rache. Und ich fange hier an: im Dojo, wo alles begann.",
]
const MO_FIRST: Array[String] = [
	"Du bist zurück, Morilla. Ich habe die Wut in deinen Augen schon gesehen, bevor du das Tor erreicht hast.",
	"Der Schattenmeister hat dir alles genommen. Rache wird dich nicht heilen, aber sie kann dich antreiben.",
	"Kraft allein gewinnt keinen Kampf. Ein guter Kämpfer wartet auf den richtigen Moment.",
	"Jeder Gegner kündigt seinen Angriff an. Blocke im letzten Augenblick, und du parierst ihn.",
	"Ist er danach aus dem Gleichgewicht, greifst du zu. Ich zeige dir den Kimura.",
	"Greife mit F oder G nah am Gegner und hebele seinen Arm. Das betäubt ihn und tut richtig weh.",
	"Diese Rekruten waren deine Freunde. Besiege sie, ohne dich selbst zu verlieren. Geh jetzt.",
]
const MO_REPEAT: Array[String] = [
	"Blocke im letzten Moment, dann greife zu. Geduld ist die stärkste Technik.",
]

var _arena: ArenaEncounter
var _gate: ExitGate


func _init() -> void:
	level_id = "dojo"
	level_title = "MORILLA DOJO"
	level_subtitle = "Region 1 – Die Rache beginnt im Dojo"
	level_width = 8700.0
	start = Vector2(300, 800)
	music = "dojo"
	next_scene = Game.BAMBOO_SCENE
	platforms = PLATFORMS
	decor = DECOR
	hints = HINTS
	enemies = ENEMIES
	checkpoints = CHECKPOINTS
	pickups = PICKUPS
	dummies = DUMMIES


func _build_extras() -> void:
	var mo := COACH_SCENE.instantiate() as CoachNpc
	mo.position = MO_POS
	mo.first_lines = MO_FIRST
	mo.repeat_lines = MO_REPEAT
	mo.lesson_finished.connect(_on_lesson_finished)
	add_child(mo)

	_gate = ExitGate.new()
	_gate.position = GATE_POS
	_gate.reached.connect(func() -> void: complete_level("DOJO GEMEISTERT", "Der erste Schritt zur Rache ist getan."))
	add_child(_gate)

	_arena = ArenaEncounter.new()
	_arena.encounter_id = "dojo_arena"
	_arena.arena_rect = ARENA_RECT
	_arena.waves = ARENA_WAVES
	_arena.position = Vector2(ARENA_RECT.position.x + 120.0, 800.0)
	_arena.cleared.connect(func() -> void:
		_gate.open = true
		hud.show_banner("ARENA GESCHAFFT", "Das Tor zum Ausgang ist offen.", 2.5))
	add_child(_arena)
	_gate.open = _arena.is_done()


func _after_ready() -> void:
	_arena.camera = camera
	if Progression.get_flag("intro_seen"):
		return
	Progression.set_flag("intro_seen")
	player.freeze()
	var portrait: Texture2D = load("res://assets/ui/morilla_portrait.png") if ResourceLoader.exists("res://assets/ui/morilla_portrait.png") else null
	await dialogue.play("Morilla", portrait, INTRO)
	player.unfreeze()


func _on_lesson_finished(_coach: CoachNpc) -> void:
	if Progression.has_ability("kimura"):
		return
	Progression.unlock_ability("kimura")
	Sound.sfx("learn")
	hud.show_banner("NEUE TECHNIK: KIMURA", "Greifen mit F / G  –  nah am Gegner", 3.5)
