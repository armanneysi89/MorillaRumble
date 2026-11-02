class_name CharacterSpecs
extends RefCounted

## Beschreibt, wo die Frames einer Figur liegen und wie sie ausgerichtet sind.
## Dateischema: <root>/<ordner>/<prefix>_<anim>_NNN.png, NNN ab 001 lückenlos. Anims: [Ordner, fps, Schleife].
## Die Frames liegen auf einer festen Leinwand, der Fußpunkt sitzt unten mittig (siehe tools/process_assets.py).

const MORILLA := {
	"prefix": "morilla",
	"root": "res://assets/characters/morilla",
	"canvas": Vector2(640, 480),
	"anchor_y": 470.0,
	"scale": 0.64,
	"faces": 1,
	"placeholder": Color(0.1, 0.1, 0.14),
	"anims": {
		"idle": ["idle", 6.0, true],
		"walk": ["walk", 11.0, true],
		"run": ["run", 16.0, true],
		"jump": ["jump", 8.0, false],
		"fall": ["jump", 8.0, false],
		"light_attack": ["attacks", 8.0, false],
		"heavy_attack": ["attacks", 8.0, false],
		"dash": ["attacks", 8.0, false],
		"block": ["attacks", 8.0, false],
		"grab": ["grappling", 8.0, false],
		"kimura": ["grappling", 8.0, false],
		"hurt": ["hurt", 8.0, false],
		"death": ["hurt", 4.0, false],
	},
}

const RECRUIT := {
	"prefix": "recruit",
	"root": "res://assets/characters/enemies/white_belt_recruit",
	"canvas": Vector2(560, 440),
	"anchor_y": 430.0,
	"scale": 0.5,
	"faces": -1,
	"placeholder": Color(0.45, 0.3, 0.7),
	"anims": {
		"idle": ["", 4.0, true],
		"walk": ["", 6.0, true],
		"attack": ["", 8.0, false],
		"hurt": ["", 8.0, false],
		"grabbed": ["", 8.0, false],
		"death": ["", 8.0, false],
	},
}

const MO := {
	"prefix": "mo",
	"root": "res://assets/characters/coaches/mo",
	"canvas": Vector2(560, 460),
	"anchor_y": 450.0,
	"scale": 0.5,
	"faces": -1,
	"placeholder": Color(0.15, 0.15, 0.18),
	"anims": {
		"idle": ["", 3.0, true],
		"talk": ["", 4.0, true],
	},
}

const ALL := {"morilla": MORILLA, "recruit": RECRUIT, "mo": MO}


static func get_spec(key: String) -> Dictionary:
	return ALL[key]
