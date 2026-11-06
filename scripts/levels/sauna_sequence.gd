class_name SaunaSequence
extends CutsceneSequence

## Inszenierte Sauna-Begegnung: sechs einzeln animierte Einstellungen (ComfyUI-Clips, siehe tools/gen_sauna.py)
## auf einer Vollbild-Bühne, dazu die normale Dialogbox. Überspringen (Tab / Zurück-Taste / Knopf) bricht sauber
## ab; der Aufrufer bekommt dann `true` und spielt den Hof-Dialog live nach.
##
## Die Einstellungen mit Dialog laufen als Ping-Pong-Schleife, die anderen einmal und mit Erzählerstimme.


## script: {"room": [...], "closeup": [...], "talk": [...]} jeweils [Sprecher, Text]-Paare.
## on_black läuft, sobald alles schwarz ist (Spielerin umsetzen, Coach platzieren). Gibt zurück, ob übersprungen wurde.
func play(dialogue: DialogueBox, script: Dictionary, on_black: Callable) -> bool:
	DIR = "res://assets/cutscenes/sauna/"
	SHOTS = {
		"approach": ["1_anreise", false, true],
		"room": ["2_sauna_innen", true, false],
		"closeup": ["3_sauna_nahaufnahme", true, false],
		"yard": ["4_trainingsplatz", false, true],
		"talk": ["5_arman_gespraech", true, false],
		"octopus": ["6_oktopus", false, true],
	}
	interlude_text = "Wenig später ..."
	begin(dialogue)

	show_shot("approach")
	await _stage.open(0.7)
	await hold()
	await cut("room")
	await talk(script["room"])
	await cut("closeup")
	await talk(script["closeup"])
	await interlude()
	await cut("yard")
	await hold()
	await cut("talk")
	await talk(script["talk"])
	await cut("octopus")
	await hold()
	return await finish(on_black)
