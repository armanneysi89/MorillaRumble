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
		# Landung: Frame 1 weich, Frame 2 hart. Der Zustand zeigt je nach Fallgeschwindigkeit einen davon.
		"land": ["jump", 8.0, false],
		"jab": ["attacks", 8.0, false],
		"cross": ["attacks", 8.0, false],
		"hook": ["attacks", 8.0, false],
		"lowkick": ["attacks", 8.0, false],
		"kick": ["attacks", 8.0, false],
		"heavy_attack": ["attacks", 8.0, false],
		"dash": ["attacks", 8.0, false],
		"block": ["attacks", 8.0, false],
		# Luftangriff, Ausweichrolle und Siegpose: eigene Posen statt geliehener Frames.
		"air_attack": ["attacks", 8.0, false],
		"roll": ["attacks", 10.0, false],
		"victory": ["attacks", 4.0, true],
		"grab": ["grappling", 8.0, false],
		"kimura": ["grappling", 8.0, false],
		"suplex": ["grappling", 8.0, false],
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

## Sibirischer Bär-Geist: erscheint beim Suplex-Aufprall aus Morillas Körper. Schwebend wie der Oktopus,
## deshalb liegt der Mittelpunkt der Leinwand im Schwerpunkt der Figur.
const BEAR := {
	"prefix": "bear",
	"root": "res://assets/characters/summons/bear",
	"canvas": Vector2(760, 760),
	"anchor_y": 380.0,
	# Etwas kleiner als Morilla, damit der Geist ihn nicht komplett verdeckt.
	"scale": 0.62,
	"faces": 1,
	"placeholder": Color(0.35, 0.2, 0.1),
	"anims": {
		"idle": ["", 4.0, true],
		"materialize": ["", 6.0, false],
		"slam": ["", 8.0, false],
	},
}

## Baby Mo: Vitalis erwachsener Schüler und ein Riese – 3,0 m, also rund 1,4x Morilla (2,2 m) und deutlich größer
## als Vitali (1,9 m). Schwarzer Gi über schwarz-bordeauxfarbenem Rashguard mit dunkelroten Chevrons, BLAUER Gürtel.
## Die Größe ist verbindlich: Sie steht auch in jedem Cutscene-Prompt (tools/gen_quarry.py, SCALE_TXT).
## scale 0,81 -> 445 px auf dem Bildschirm (Morilla: 318 px).
const BABY_MO := {
	"prefix": "baby_mo",
	"root": "res://assets/characters/coaches/baby_mo",
	"canvas": Vector2(760, 640),
	"anchor_y": 620.0,
	"scale": 0.81,
	"faces": -1,
	"placeholder": Color(0.12, 0.12, 0.16),
	"anims": {
		"idle": ["", 3.0, true],
		"talk": ["", 4.0, true],
		"point": ["", 3.0, false],
		"walk": ["", 6.0, true],
	},
}

## Vitali: Schwarzgurt mit rotem Rangfeld, kräftiger Grappler-Körperbau, offener schwarzer Gi über schwarzem
## Rashguard mit dunkelroten Chevrons. Kleiner als Morilla. Sitzen, Sprechen, Aufstehen, Idle und Suplex-Demonstration.
## scale 0,64 -> 273 px auf dem Bildschirm (Morilla: 318 px, Baby Mo: 445 px).
const VITALI := {
	"prefix": "vitali",
	"root": "res://assets/characters/coaches/vitali",
	"canvas": Vector2(640, 560),
	"anchor_y": 540.0,
	"scale": 0.64,
	"faces": -1,
	"placeholder": Color(0.14, 0.13, 0.15),
	"anims": {
		"idle": ["", 3.0, true],
		"talk": ["", 4.0, true],
		"sit": ["", 2.0, true],
		"stand": ["", 4.0, false],
		"suplex": ["", 6.0, false],
	},
}

## Eisenrücken: steinerner Boss mit schwerem Trainingsrahmen. Kampf, Taumel, Wurf und Niederlage.
const IRONBACK := {
	"prefix": "ironback",
	"root": "res://assets/characters/enemies/ironback",
	"canvas": Vector2(760, 620),
	"anchor_y": 600.0,
	"scale": 0.9,
	"faces": -1,
	"placeholder": Color(0.35, 0.33, 0.3),
	"anims": {
		"idle": ["", 3.0, true],
		"walk": ["", 5.0, true],
		"windup": ["", 5.0, false],
		"attack": ["", 6.0, false],
		"charge": ["", 6.0, false],
		"stagger": ["", 5.0, false],
		"thrown": ["", 6.0, false],
		"hurt": ["", 6.0, false],
		"death": ["", 4.0, false],
	},
}

const ALL := {"morilla": MORILLA, "recruit": RECRUIT, "mo": MO, "rival": RIVAL, "arman": ARMAN, "octopus": OCTOPUS,
	"bear": BEAR, "baby_mo": BABY_MO, "vitali": VITALI, "ironback": IRONBACK}
static func get_spec(key: String) -> Dictionary:
	return ALL[key]
