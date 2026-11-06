extends LevelBase

## Region 2 – Mondbambus-Hain: Auf halber Strecke wartet die Sauna. Dort trifft Morilla Coach Arman (Zwischensequenz),
## auf dem Trainingsplatz führt Arman den Oktopus-Geist vor und lehrt ihn. Danach warten Gruppen von
## Gegnern (Rekruten und blaue Rivalen), ein Regal-Aufstieg mit Schriftrolle und eine Arena in zwei Wellen.

const ARMAN_SCENE: PackedScene = preload("res://scenes/coaches/coach_arman.tscn")
const ARMAN_PORTRAIT := "res://assets/ui/arman_portrait.png"

## Hintergrund, Plattformen, Dekor, Hinweise, Gegner, Checkpoints, Schriftrollen, Puppen, Start, Arman, Ausgang und Arena liegen als
## Platzhalter-Knoten in bamboo_level.tscn und werden dort im 2D-Editor bearbeitet.

const INTRO: Array[String] = [
	"Hinter dem Dojo beginnt ein Pfad, der im Mondlicht in den Bambushain führt. Hier verliert sich die Spur des Schattenmeisters.",
	"Seine Hüllen werden zahlreicher. Mit Schlägen und dem Kimura komme ich gegen mehrere von ihnen nicht weit.",
	"Irgendwo im Hain lebt Coach Arman. Man sagt, er kämpft nicht mit Kraft, sondern mit Präzision. Ich sollte ihn finden.",
]
## Trainingsplatz: führt in die Oktopus-Vorführung. Wird live nachgespielt, wenn die Zwischensequenz übersprungen wurde.
const YARD_TALK: Array = [
	["Coach Arman", "Die Schatten haben auch den Hain erreicht. Du wirst ihnen hier nicht einzeln begegnen."],
	["Morilla", "Dann muss ich stärker werden."],
	["Coach Arman", "Du musst lernen, mehrere Gegner zu kontrollieren. Ich zeige dir den Oktopus-Geist. Sieh genau zu."],
]
## Sauna: Morilla trifft Arman. Der Schnitt zwischen den Einstellungen liegt zwischen "room" und "closeup".
const SAUNA_TALK := {
	"room": [
		["Morilla", "Arman! Mo schickt mich. Der Schattenmeister hat unser Dojo verwüstet."],
		["Coach Arman", "Atme erst einmal. Geht es Mo gut?"],
	],
	"closeup": [
		["Morilla", "Er ist verletzt, aber er kommt zurecht. Ich soll nach euch sehen."],
		["Coach Arman", "Gut, dass du hier bist. Warte draußen auf mich. Ich komme gleich und erzähle dir, was ich weiß."],
	],
	"talk": YARD_TALK,
}
## Spielstand mit abgeschlossener Sauna-Begegnung, aber noch ohne Technik: Arman steht auf dem Trainingsplatz.
const ARMAN_RESUME: Array[String] = [
	"Du bist zurück. Gut. Ich wollte dir den Oktopus-Geist zeigen. Sieh genau zu.",
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

## Abgeschlossene Sauna-Begegnung; getrennt von der Technik (Morilla.SUMMON_ID), damit ein Abbruch dazwischen nichts blockiert.
const SAUNA_FLAG := "sauna_met"
## Morillas Platz auf dem Trainingsplatz, links von Arman.
const YARD_OFFSET := -130.0

var _arena: ArenaEncounter
var _gate: ExitGate
var _arman: CoachNpc
var _sauna: SaunaHouse
var _sauna_busy := false


func _init() -> void:
	level_id = "bamboo"
	level_title = "MONDBAMBUS-HAIN"
	level_subtitle = "Region 2 – Coach Armans Technik"
	music = "dojo"
	next_scene = Game.QUARRY_SCENE


func _build_extras() -> void:
	_sauna = SaunaHouse.new()
	_sauna.position = ($Sauna as Node2D).position
	_sauna.done = _sauna_done()
	_sauna.entered.connect(_on_sauna_entered)
	add_child(_sauna)

	# Arman sitzt bis zur Begegnung in der Sauna und steht danach auf dem Trainingsplatz.
	_arman = ARMAN_SCENE.instantiate() as CoachNpc
	_arman.position = ($Arman as Node2D).position
	_arman.first_lines = ARMAN_RESUME
	_arman.repeat_lines = ARMAN_REPEAT if Progression.has_ability(Morilla.SUMMON_ID) else ARMAN_RESUME
	_arman.lesson_finished.connect(_on_lesson_finished)
	if _sauna_done():
		add_child(_arman)

	_gate = ExitGate.new()
	_gate.position = ($Gate as Node2D).position
	_gate.reached.connect(func() -> void:
		Progression.set_task("find_vitali")
		complete_level("BAMBUSHAIN GEMEISTERT", "Der Oktopus-Geist gehorcht dir. Über dem Hain liegt der Steinbruch ..."))
	add_child(_gate)

	var arena_marker := $Arena as LevelArena
	_arena = ArenaEncounter.new()
	_arena.encounter_id = "bamboo_arena"
	_arena.arena_rect = arena_marker.rect
	_arena.waves = arena_marker.waves()
	_arena.position = arena_marker.position
	arena_marker.queue_free()
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


## Auch ältere Spielstände zählen: Wer Arman schon gesprochen oder die Technik hat, überspringt die Sauna.
func _sauna_done() -> bool:
	return bool(Progression.get_flag(SAUNA_FLAG)) or bool(Progression.get_flag("talked_arman")) or Progression.has_ability(Morilla.SUMMON_ID)


## Sauna-Begegnung, danach Hof-Gespräch und Vorführung. Die Technik wird erst am Ende von _on_lesson_finished freigeschaltet.
func _on_sauna_entered(_who: Morilla) -> void:
	if _sauna_busy:
		return
	_sauna_busy = true
	_sauna.done = true
	player.freeze()
	player.health.make_invulnerable(600.0)
	var sequence := SaunaSequence.new()
	add_child(sequence)
	var skipped: bool = await sequence.play(dialogue, SAUNA_TALK, _arrive_in_yard)
	sequence.queue_free()
	Progression.set_flag(SAUNA_FLAG)
	if Progression.quest_state("task") == "find_arman":
		Progression.set_task("")
	if skipped:
		await dialogue.play_conversation(YARD_TALK)
	await _on_lesson_finished(_arman)
	player.health.invulnerable_time = 0.6
	_sauna_busy = false


## Läuft im Schwarz: Morilla wartet auf dem Trainingsplatz, Arman kommt im schwarzen Gi dazu.
func _arrive_in_yard() -> void:
	var spot := ($Arman as Node2D).position
	player.global_position = spot + Vector2(YARD_OFFSET, 0.0)
	player.velocity = Vector2.ZERO
	player.facing = 1
	player.visual.face(1)
	camera.reset_smoothing()
	if _arman.get_parent() == null:
		add_child(_arman)
	_arman.sprite().face(-1)


func _on_lesson_finished(_coach: CoachNpc) -> void:
	if Progression.quest_state("task") == "find_arman":
		Progression.set_task("")
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
