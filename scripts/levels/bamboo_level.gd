extends LevelBase

## Region 2 – Mondbambus-Hain: Coach Arman führt den Oktopus-Geist vor und lehrt ihn Morilla. Danach warten Gruppen von
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
	music = "dojo"


func _build_extras() -> void:
	_arman = ARMAN_SCENE.instantiate() as CoachNpc
	_arman.position = ($Arman as Node2D).position
	_arman.first_lines = ARMAN_FIRST
	_arman.repeat_lines = ARMAN_REPEAT
	_arman.lesson_finished.connect(_on_lesson_finished)
	add_child(_arman)

	_gate = ExitGate.new()
	_gate.position = ($Gate as Node2D).position
	_gate.reached.connect(func() -> void: complete_level("BAMBUSHAIN GEMEISTERT", "Der Oktopus-Geist gehorcht dir. Die Jagd geht weiter ..."))
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
