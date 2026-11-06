class_name VitaliSequence
extends CutsceneSequence

## Inszenierte Begegnung mit Baby Mo und Vitali: sechs einzeln animierte Einstellungen (ComfyUI-Clips, siehe
## tools/gen_quarry.py) auf einer Vollbild-Bühne, dazu die normale Dialogbox. Überspringen (Tab / Zurück-Taste /
## Knopf) bricht sauber ab; der Aufrufer bekommt dann `true` und spielt den Dialog live nach.
## Jede Einstellung wird einzeln animiert und hart geschnitten – keine Storyboard-Collage, kein Perspektiv-Morphing.


## script: {"yard": [...], "reveal": [...]} jeweils [Sprecher, Text]-Paare.
## on_black läuft, sobald alles schwarz ist (Spielerin umsetzen, Vitali platzieren). Gibt zurück, ob übersprungen wurde.
func play(dialogue: DialogueBox, script: Dictionary, on_black: Callable) -> bool:
	DIR = "res://assets/cutscenes/vitali/"
	SHOTS = {
		"yard": ["1_vorhof", false, true],
		"baby_mo": ["2_baby_mo", true, false],
		"throne_point": ["3_thron_zeigen", true, false],
		"throne_reveal": ["4_thron_enthuellung", false, true],
		"vitali_hat": ["5_vitali_hut", true, false],
		"before_throne": ["6_vor_dem_thron", false, true],
	}
	interlude_text = "Der Gürtelthron"
	begin(dialogue)

	show_shot("yard")
	await _stage.open(0.7)
	await hold()
	await cut("baby_mo")
	await talk(script["yard"])
	await cut("throne_point")
	await hold()
	await interlude()
	await cut("throne_reveal")
	await hold()
	await cut("vitali_hat")
	await talk(script["reveal"])
	await cut("before_throne")
	await hold()
	return await finish(on_black)
