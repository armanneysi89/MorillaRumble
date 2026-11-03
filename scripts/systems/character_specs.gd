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
	"scale": 0.8,
	"faces": 1,
	"placeholder": Color(0.1, 0.1, 0.14),
	"anims": {
		"idle": ["idle", 6.0, true, [2]],
		"walk": ["walk", 11.0, true],
		"run": ["run", 16.0, true],
		"jump": ["jump", 8.0, false],
		"fall": ["jump", 8.0, false],
		"light_attack": ["attacks", 8.0, false],
		"jab": ["attacks", 8.0, false],
		"cross": ["attacks", 8.0, false],
		"hook": ["attacks", 8.0, false],
		"lowkick": ["attacks", 8.0, false],
		"kick": ["attacks", 8.0, false],
		"heavy_attack": ["attacks", 8.0, false],
		"dash": ["attacks", 8.0, false],
		"block": ["attacks", 8.0, false],
		"grab": ["grappling", 8.0, false],
		"kimura": ["grappling", 8.0, false],
		"summon": ["grappling", 6.0, false],
		"hurt": ["hurt", 8.0, false],
		"death": ["hurt", 4.0, false],
	},
}

const RECRUIT := {
	"prefix": "recruit",
	"root": "res://assets/characters/enemies/white_belt_recruit",
	"canvas": Vector2(560, 440),
	"anchor_y": 430.0,
	"scale": 0.66,
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
	"scale": 0.7,
	"faces": -1,
	"placeholder": Color(0.15, 0.15, 0.18),
	"anims": {
		"idle": ["", 3.0, true],
		"talk": ["", 4.0, true],
	},
}

const RIVAL := {
	"prefix": "rival",
	"root": "res://assets/characters/enemies/blue_belt_rival",
	"canvas": Vector2(560, 440),
	"anchor_y": 430.0,
	"scale": 0.66,
	"faces": -1,
	"placeholder": Color(0.2, 0.45, 0.6),
	"anims": {
		"idle": ["", 5.0, true],
		"walk": ["", 8.0, true],
		"attack": ["", 8.0, false],
		"hurt": ["", 8.0, false],
		"grabbed": ["", 8.0, false],
		"death": ["", 8.0, false],
	},
}

const ARMAN := {
	"prefix": "arman",
	"root": "res://assets/characters/coaches/arman",
	"canvas": Vector2(560, 460),
	"anchor_y": 450.0,
	"scale": 0.7,
	"faces": -1,
	"placeholder": Color(0.15, 0.15, 0.18),
	"anims": {
		"idle": ["", 3.0, true],
		"talk": ["", 4.0, true],
		"demo": ["", 3.0, false],
	},
}

## Schwebender Beschwörungsgeist: Der Mittelpunkt der Leinwand ist der Mittelpunkt der Figur.
const OCTOPUS := {
	"prefix": "octopus",
	"root": "res://assets/characters/summons/octopus",
	"canvas": Vector2(640, 640),
	"anchor_y": 320.0,
	"scale": 0.9,
	"faces": 1,
	"placeholder": Color(0.3, 0.12, 0.5),
	"anims": {
		"idle": ["", 4.0, true],
		"materialize": ["", 6.0, false],
		"charge": ["", 6.0, true],
		"strike": ["", 8.0, false],
		"blast": ["", 8.0, false],
	},
}

const ALL := {"morilla": MORILLA, "recruit": RECRUIT, "mo": MO, "rival": RIVAL, "arman": ARMAN, "octopus": OCTOPUS}


static func get_spec(key: String) -> Dictionary:
	return ALL[key]
