class_name RescueSequence
extends CutsceneSequence

## Rettungsszene im Mondbambus-Hain: Der Schattenkämpfer hat Morilla am Boden, Arman greift ein und vertreibt ihn
## mit dem Oktopus-Geist. Sechs einzeln animierte Einstellungen (ComfyUI-Clips, siehe tools/gen_rescue.py) auf einer
## Vollbild-Bühne, dazu die normale Dialogbox.
##
## Die Kampf-Einstellung ("fight") ist EIN durchgehender Clip von ~9 s, erzeugt mit dem H3-Fight-Flow-LoRA: Angriff,
## Antwort, Kontakt und Führungswechsel gehen ineinander über, statt nach jedem Schlag in die neutrale Pose
## zurückzufallen. Deshalb steht sie allein und ohne Dialog – sie soll einfach durchlaufen.
##
## Musik: eigenes Stück "rescue" (tools/gen_music.py) statt der Levelmusik; danach läuft der Bambushain-Titel weiter.
## Soundeffekte je Einstellung: Aufprall, Parieren, Schwung, Beschwörung, Verlöschen.
##
## Überspringen (Tab / Zurück-Taste / Knopf) bricht sauber ab; der Aufrufer bekommt dann `true`.


## script: {"save": [...], "spirit": [...], "after": [...]} jeweils [Sprecher, Text]-Paare.
## on_black läuft, sobald alles schwarz ist. Gibt zurück, ob übersprungen wurde.
func play(dialogue: DialogueBox, script: Dictionary, on_black: Callable) -> bool:
	DIR = "res://assets/cutscenes/rescue/"
	music = "rescue"
	SHOTS = {
		"down": ["1_zu_boden", false, "heavy_hit"],
		"save": ["2_arman_einsatz", false, "parry"],
		"fight": ["3_kampf", false, "heavy_whoosh"],
		"spirit": ["4_oktopus", true, "summon"],
		"vanish": ["5_schatten_loest_sich", false, "spirit_vanish"],
		"after": ["6_aufhelfen", true, ""],
	}
	# Der Kampf-Clip ist mit 217 Frames (~9 s) deutlich länger als die übrigen Einstellungen.
	once_timeout = 11.0
	begin(dialogue)

	show_shot("down")
	await _stage.open(0.7)
	await hold()
	await cut("save")
	await talk(script["save"])
	await cut("fight")
	await hold()
	await cut("spirit")
	await talk(script["spirit"])
	await cut("vanish")
	await hold()
	await cut("after")
	await talk(script["after"])
	return await finish(on_black)
