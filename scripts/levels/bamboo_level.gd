extends LevelBase

## Region 2 – Mondbambus-Hain: Coach Arman führt den Oktopus-Geist vor und lehrt ihn Morilla. Danach warten Gruppen von
## Gegnern (Rekruten und blaue Rivalen), ein Regal-Aufstieg mit Schriftrolle und eine Arena in zwei Wellen.

const ARMAN_SCENE: PackedScene = preload("res://scenes/coaches/coach_arman.tscn")
const ARMAN_PORTRAIT := "res://assets/ui/arman_portrait.png"

const PLATFORMS := [
	[K_MOSS, 0, 800, 2000],
	[K_LOG, 2070, 730, 170],
	[K_MOSS, 2300, 800, 2400],
	[K_LOG, 4790, 700, 200],
	[K_LOG, 4990, 630, 200],
	[K_MOSS, 5150, 800, 1700],
	[K_LOG, 5450, 640, 240],
	[K_LOG, 5800, 490, 240],
	[K_LOG, 6150, 340, 240],
	[K_MOSS, 7050, 800, 2350],
]

const DECOR := [
	["bamboo_cluster", 250, 800, 800, false, -3], ["bamboo_cluster", 720, 800, 700, true, -3],
	["bamboo_cluster", 1350, 800, 860, false, -3], ["bamboo_cluster", 1830, 800, 720, true, -3],
	["stone_lantern", 1000, 800, 240, false, -1], ["stone_lantern", 1960, 800, 240, true, -1],
	["bamboo_cluster", 2500, 800, 780, true, -3], ["bamboo_cluster", 4500, 800, 820, false, -3],
	["stone_lantern", 2650, 800, 240, false, -1], ["stone_lantern", 3250, 800, 240, true, -1],
	["shrine", 4100, 800, 560, false, -3], ["stone_lantern", 3900, 800, 240, false, -1],
	["stone_lantern", 4380, 800, 240, true, -1],
	["bamboo_cluster", 5300, 800, 760, false, -3], ["bamboo_cluster", 6000, 800, 840, true, -3],
	["bamboo_cluster", 6700, 800, 740, false, -3], ["stone_lantern", 5200, 800, 240, false, -1],
	["stone_lantern", 6800, 800, 240, true, -1],
	["bamboo_cluster", 7300, 800, 860, true, -3], ["bamboo_cluster", 8000, 800, 780, false, -3],
	["bamboo_cluster", 8700, 800, 840, true, -3], ["stone_lantern", 7500, 800, 240, false, -1],
	["stone_lantern", 8300, 800, 240, true, -1], ["stone_lantern", 8950, 800, 240, false, -1],
]

const HINTS := [
	[520, 800, "Der Pfad vom Dojo endet im Mondbambus-Hain. Die Schatten sind hier schon vor dir gewesen."],
	[2500, 800, "Coach Arman wartet im Hain. Sprich ihn an: E / Enter."],
	[4300, 800, "Q / R (Gamepad: rechter Trigger): Oktopus-Geist beschwören. Er fesselt mehrere Gegner und betäubt sie."],
	[5100, 800, "Vor dir lauert eine Gruppe. Genau dafür ist der Oktopus-Geist da – danach sind sie leichte Beute."],
	[7150, 800, "Die Arena kommt in zwei Wellen. Beschwöre den Geist, wenn du umzingelt bist, und warte seine Abklingzeit ab."],
]

# [x, y (Fußpunkt), Patrouillenradius, Typ]
const ENEMIES := [
	[1150, 800, 150, "recruit"], [1650, 800, 160, "recruit"],
	[5600, 800, 80, "recruit"], [5800, 800, 100, "rival"], [6000, 800, 80, "recruit"],
	[6350, 800, 110, "recruit"], [6600, 800, 90, "rival"],
]

# [id, x, y (Fußpunkt)]
const CHECKPOINTS := [["cp_clearing", 2450, 800], ["cp_ridge", 5250, 800], ["cp_arena", 7150, 800]]

# [id, x, y (Mitte)]
const PICKUPS := [["hp_scroll_bamboo", 6150, 250]]

const DUMMIES := [[3450, 800], [3600, 800], [3750, 800]]

const ARENA_RECT := Rect2(7300, -700, 1700, 1780)
const ARENA_WAVES := [
	[Vector2(8300, 800), [Vector2(8550, 800), "rival"], Vector2(8750, 800)],
	[Vector2(7700, 800), [Vector2(8350, 800), "rival"], Vector2(8550, 800), [Vector2(8750, 800), "rival"], Vector2(8850, 800)],
]
const GATE_POS := Vector2(9200, 800)
const ARMAN_POS := Vector2(3000, 800)

const INTRO: Array[String] = [
	"Hinter dem Dojo beginnt ein Pfad, der im Mondlicht in den Bambushain führt. Hier verliert sich die Spur des Schattenmeisters.",
	"Seine Hüllen werden zahlreicher. Mit Schlägen und dem Kimura komme ich gegen mehrere von ihnen nicht weit.",
	"Irgendwo im Hain lebt Coach Arman. Man sagt, er kämpft nicht mit Kraft, sondern mit Präzision. Ich sollte ihn finden.",
]
const ARMAN_FIRST: Array[String] = [
	"Morilla. Ich habe dich kommen hören. Du läufst, wie ein Gorilla angreift: geradeaus und laut.",
	"Ich bin Arman. Technik ist das, was bleibt, wenn die Kraft nachlässt. Merk dir das.",
	"Der Schattenmeister schickt seine Hüllen nie allein. Gegen mehrere Gegner hilft dir ein einzelner Griff nicht.",
	"Deshalb zeige ich dir etwas, das ich über viele Winter gelernt habe: den Oktopus-Geist. Sieh genau zu.",
]
const ARMAN_AFTER: Array[String] = [
	"Acht Arme, ein Gedanke. Der Geist fesselt jeden Gegner in Reichweite und stößt sie mit einer Tintenwelle aus dem Gefecht.",
	"Drücke Q oder R, auf dem Gamepad den rechten Trigger. Du sammelst dich einen Atemzug lang, dann erscheint er.",
	"Danach braucht er Zeit, um sich zu erholen. Setze ihn ein, wenn sich mehrere Gegner um dich sammeln – nicht früher.",
	"Der Hain ist voller Hüllen, und hinter ihm liegt eine Arena. Geh, Morilla. Und atme.",
]
const ARMAN_REPEAT: Array[String] = [
	"Sammle dich, dann Q oder R. Warte, bis sich mehrere Gegner nähern. Timing ist alles.",
]

var _arena: ArenaEncounter
var _gate: ExitGate
var _arman: CoachNpc


func _init() -> void:
	level_id = "bamboo"
	level_title = "MONDBAMBUS-HAIN"
	level_subtitle = "Region 2 – Coach Armans Technik"
	level_width = 9400.0
	start = Vector2(300, 800)
	music = "dojo"
	far_background = "res://assets/environments/bamboo/bg_bamboo.png"
	pillar_path = "res://assets/environments/bamboo/props/bamboo_stalks.png"
	pillar_tint = Color(0.5, 0.72, 0.78, 0.85)
	sky_top = Color("06141c")
	sky_bottom = Color("12333a")
	petal_color = Color(0.55, 0.9, 0.55, 0.8)
	fireflies = true
	platforms = PLATFORMS
	decor = DECOR
	hints = HINTS
	enemies = ENEMIES
	checkpoints = CHECKPOINTS
	pickups = PICKUPS
	dummies = DUMMIES


func _build_extras() -> void:
	_arman = ARMAN_SCENE.instantiate() as CoachNpc
	_arman.position = ARMAN_POS
	_arman.first_lines = ARMAN_FIRST
	_arman.repeat_lines = ARMAN_REPEAT
	_arman.lesson_finished.connect(_on_lesson_finished)
	add_child(_arman)

	_gate = ExitGate.new()
	_gate.position = GATE_POS
	_gate.reached.connect(func() -> void: complete_level("BAMBUSHAIN GEMEISTERT", "Der Oktopus-Geist gehorcht dir. Die Jagd geht weiter ..."))
	add_child(_gate)

	_arena = ArenaEncounter.new()
	_arena.encounter_id = "bamboo_arena"
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
	if Progression.get_flag("intro_bamboo_seen"):
		return
	Progression.set_flag("intro_bamboo_seen")
	player.freeze()
	var portrait: Texture2D = load("res://assets/ui/morilla_portrait.png") if ResourceLoader.exists("res://assets/ui/morilla_portrait.png") else null
	await dialogue.play("Morilla", portrait, INTRO)
	player.unfreeze()


func _on_lesson_finished(_coach: CoachNpc) -> void:
	if Progression.has_ability(Morilla.SUMMON_ID):
		return
	player.freeze()
	await _demonstrate()
	var portrait: Texture2D = load(ARMAN_PORTRAIT) if ResourceLoader.exists(ARMAN_PORTRAIT) else null
	await dialogue.play("Coach Arman", portrait, ARMAN_AFTER)
	player.unfreeze()
	Progression.unlock_ability(Morilla.SUMMON_ID)
	Sound.sfx("learn")
	hud.show_banner("NEUE TECHNIK: OKTOPUS-GEIST", "Q / R  –  fesselt mehrere Gegner gleichzeitig", 4.0)


## Arman beschwört den Geist und lässt ihn die Übungspuppen fesseln und wegschleudern.
func _demonstrate() -> void:
	var sprite := _arman.sprite()
	var ab := Progression.get_ability(Morilla.SUMMON_ID)
	_arman.locked = true
	sprite.face(1)
	sprite.show_frame(&"demo", 0)
	Sound.sfx("summon_charge")
	var charge := get_tree().create_timer(ab.charge_time + 0.3)
	await charge.timeout
	sprite.show_frame(&"demo", 1)
	var spot := _arman.global_position + Vector2(260.0, -460.0)
	var spirit := OctopusSpirit.summon(self, spot, ab, func() -> Array: return get_tree().get_nodes_in_group("dummies"))
	await spirit.finished
	sprite.play_anim(&"idle")
	sprite.face(-1)
	_arman.locked = false
